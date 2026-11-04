npm warn Unknown env config "http-proxy". This will stop working in the next major version of npm.

  ../../../tmp/chismoeti-api.js  6.6kb

⚡ Done in 6ms
// Chismoeti · lector privado del blog guardado en Dropbox.
// Deploy with Verify JWT disabled. This function validates the Supabase session itself.
const ALLOWED_ORIGINS = new Set([
  "https://grupobure.github.io",
]);
const BLOG_ROOT = "/Chismoeti/Blog/Edicion_01";

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

function injected(name: string, legacy: string) {
  const old = Deno.env.get(legacy);
  if (old) return old;
  try {
    return JSON.parse(Deno.env.get(name) || "{}").default;
  } catch {
    return undefined;
  }
}

const config = () => ({
  url: Deno.env.get("SUPABASE_URL")?.replace(/\/$/, ""),
  anon: injected("SUPABASE_PUBLISHABLE_KEYS", "SUPABASE_ANON_KEY"),
  service: injected("SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY"),
  dbxKey: Deno.env.get("DROPBOX_APP_KEY"),
  dbxSecret: Deno.env.get("DROPBOX_APP_SECRET"),
  refresh: Deno.env.get("DROPBOX_REFRESH_TOKEN"),
  secret: Deno.env.get("RH_ENCRYPTION_SECRET") ||
    injected("SUPABASE_SECRET_KEYS", "SUPABASE_SERVICE_ROLE_KEY"),
});

function cors(request: Request) {
  const origin = request.headers.get("origin") || "";
  if (origin && !ALLOWED_ORIGINS.has(origin)) throw new ApiError(403, "Solicitud no permitida.");
  return {
    "Access-Control-Allow-Origin": origin || "https://grupobure.github.io",
    "Access-Control-Allow-Methods": "GET,OPTIONS",
    "Access-Control-Allow-Headers": "authorization,content-type",
    "Access-Control-Expose-Headers": "content-type,content-length",
    "Vary": "Origin",
  };
}

async function supa(path: string, init: RequestInit = {}, bearer?: string) {
  const c = config();
  if (!c.url || !c.anon || !c.service) throw new ApiError(503, "La conexión privada no está disponible.");
  const headers = new Headers(init.headers);
  const key = bearer || c.service;
  headers.set("apikey", bearer ? c.anon : c.service);
  if (!key.startsWith("sb_")) headers.set("Authorization", "Bearer " + key);
  headers.set("Content-Type", "application/json");
  const response = await fetch(c.url + path, { ...init, headers });
  if (!response.ok) throw new ApiError(response.status === 401 ? 401 : 502, "No pude validar el acceso al blog.");
  const text = await response.text();
  return text ? JSON.parse(text) : null;
}

async function requireProfile(request: Request) {
  const token = request.headers.get("authorization")?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) throw new ApiError(401, "Inicia sesión para leer el blog.");
  const user = await supa("/auth/v1/user", {}, token);
  const rows = await supa(
    "/rest/v1/perfiles?select=id&user_id=eq." + encodeURIComponent(user.id) + "&limit=1",
  );
  if (!rows?.length) throw new ApiError(403, "Necesitas un perfil vinculado para leer el blog.");
  return user;
}

async function encrypted(value: string) {
  const secret = config().secret;
  if (!secret) throw new ApiError(503, "Falta activar la conexión protegida.");
  const key = await crypto.subtle.importKey(
    "raw",
    await crypto.subtle.digest("SHA-256", new TextEncoder().encode(secret)),
    { name: "AES-GCM" },
    false,
    ["decrypt"],
  );
  const [a, b] = value.split(".");
  const iv = Uint8Array.from(atob(a), (char) => char.charCodeAt(0));
  const data = Uint8Array.from(atob(b), (char) => char.charCodeAt(0));
  return new TextDecoder().decode(await crypto.subtle.decrypt({ name: "AES-GCM", iv }, key, data));
}

async function setting(key: string) {
  const rows = await supa("/rest/v1/rh_settings?select=value&key=eq." + encodeURIComponent(key));
  return rows?.[0]?.value as string | undefined;
}

let tokenCache: { token: string; until: number } | undefined;
async function dropboxToken() {
  if (tokenCache && Date.now() < tokenCache.until) return tokenCache.token;
  const c = config();
  if (!c.dbxKey || !c.dbxSecret) throw new ApiError(503, "Dropbox no está conectado.");
  const stored = c.refresh || await setting("dropbox_refresh");
  const refresh = c.refresh ? stored : stored ? await encrypted(stored) : undefined;
  if (!refresh) throw new ApiError(503, "Dropbox necesita volver a conectarse.");
  const response = await fetch("https://api.dropboxapi.com/oauth2/token", {
    method: "POST",
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: refresh,
      client_id: c.dbxKey,
      client_secret: c.dbxSecret,
    }),
  });
  const data = await response.json();
  if (!response.ok || !data.access_token) throw new ApiError(503, "Dropbox necesita volver a conectarse.");
  tokenCache = {
    token: data.access_token,
    until: Date.now() + Math.max(60, data.expires_in - 120) * 1000,
  };
  return tokenCache.token;
}

function dropboxArg(value: unknown) {
  return JSON.stringify(value).replace(/[\u007f-\uffff]/g, (char) =>
    "\\u" + char.charCodeAt(0).toString(16).padStart(4, "0")
  );
}

async function download(path: string) {
  const response = await fetch("https://content.dropboxapi.com/2/files/download", {
    method: "POST",
    headers: {
      "Authorization": "Bearer " + await dropboxToken(),
      "Dropbox-API-Arg": dropboxArg({ path }),
    },
  });
  if (!response.ok) throw new ApiError(response.status === 409 ? 404 : 502, "El archivo del blog no está disponible.");
  return response;
}

function json(data: unknown, status: number, headers: HeadersInit) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...headers, "Content-Type": "application/json", "Cache-Control": "no-store" },
  });
}

Deno.serve(async (request) => {
  let headers: HeadersInit = {};
  try {
    headers = cors(request);
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });
    if (request.method !== "GET") throw new ApiError(405, "Método no permitido.");
    await requireProfile(request);
    const url = new URL(request.url);
    const op = url.searchParams.get("op");
    if (op === "manifest") {
      const source = await download(BLOG_ROOT + "/manifest.json");
      return new Response(source.body, {
        status: 200,
        headers: { ...headers, "Content-Type": "application/json", "Cache-Control": "no-store" },
      });
    }
    if (op === "media") {
      const file = url.searchParams.get("file") || "";
      if (!/^[A-Za-z0-9][A-Za-z0-9._-]{0,119}\.(?:jpe?g|png|webp)$/i.test(file)) {
        throw new ApiError(400, "Archivo no válido.");
      }
      const source = await download(BLOG_ROOT + "/media/" + file);
      return new Response(source.body, {
        status: 200,
        headers: {
          ...headers,
          "Content-Type": source.headers.get("content-type") || "application/octet-stream",
          "Cache-Control": "private, max-age=900",
        },
      });
    }
    throw new ApiError(404, "Ruta no disponible.");
  } catch (error) {
    const problem = error instanceof ApiError ? error : new ApiError(500, "No pude abrir el blog.");
    console.error(error);
    return json({ error: problem.message }, problem.status, headers);
  }
});

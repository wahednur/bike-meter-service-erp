import type { AuthUser } from "./types";

const ACCESS_KEY = "bme_access_token";
const REFRESH_KEY = "bme_refresh_token";
const USER_KEY = "bme_user";

// Guard every call: these pages are client components, but Next.js still
// renders them once on the server for the initial HTML, where `window`
// (and localStorage) doesn't exist.
const isBrowser = () => typeof window !== "undefined";

export function getAccessToken(): string | null {
  return isBrowser() ? window.localStorage.getItem(ACCESS_KEY) : null;
}

export function getRefreshToken(): string | null {
  return isBrowser() ? window.localStorage.getItem(REFRESH_KEY) : null;
}

export function getStoredUser(): AuthUser | null {
  if (!isBrowser()) return null;
  const raw = window.localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AuthUser;
  } catch {
    return null;
  }
}

export function setSession(access: string, refresh: string, user: AuthUser): void {
  if (!isBrowser()) return;
  window.localStorage.setItem(ACCESS_KEY, access);
  window.localStorage.setItem(REFRESH_KEY, refresh);
  window.localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function setAccessToken(access: string): void {
  if (!isBrowser()) return;
  window.localStorage.setItem(ACCESS_KEY, access);
}

export function clearSession(): void {
  if (!isBrowser()) return;
  window.localStorage.removeItem(ACCESS_KEY);
  window.localStorage.removeItem(REFRESH_KEY);
  window.localStorage.removeItem(USER_KEY);
}

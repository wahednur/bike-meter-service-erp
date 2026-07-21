"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";

import { login as apiLogin, logout as apiLogout } from "./api";
import { clearSession, getAccessToken, getRefreshToken, getStoredUser, setSession } from "./token-storage";
import type { AuthUser } from "./types";

interface AuthContextValue {
  user: AuthUser | null;
  accessToken: string | null;
  /** True until the initial localStorage rehydration on mount finishes -
   * lets pages avoid flashing a "logged out" state on first paint. */
  isLoading: boolean;
  login: (identifier: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [accessToken, setAccessTokenState] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // One-time rehydration from localStorage, which doesn't exist during
    // SSR - this has to run in an effect (post-mount, client-only), and
    // the resulting extra render is the intended "loading -> ready"
    // transition, not the accidental cascading-render pattern this rule
    // otherwise guards against.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setUser(getStoredUser());
    setAccessTokenState(getAccessToken());
    setIsLoading(false);
  }, []);

  const login = useCallback(async (identifier: string, password: string) => {
    const data = await apiLogin(identifier, password);
    setSession(data.access, data.refresh, data.user);
    setUser(data.user);
    setAccessTokenState(data.access);
  }, []);

  const logout = useCallback(() => {
    const refresh = getRefreshToken();
    clearSession();
    setUser(null);
    setAccessTokenState(null);
    if (refresh) {
      // best-effort - the token is already gone locally either way
      apiLogout(refresh).catch(() => {});
    }
  }, []);

  return (
    <AuthContext.Provider value={{ user, accessToken, isLoading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}

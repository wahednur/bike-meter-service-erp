"use client";

import { createContext, useCallback, useContext, useEffect, useState } from "react";

import { getShopProfile } from "./api";
import type { ShopProfile } from "./types";

const DEFAULT_SHOP_PROFILE: ShopProfile = {
  id: 0,
  shop_name: "Nurain Motorcycle Meter Service Center",
  address: "",
  phone: "",
  invoice_footer_text: "Development by Wahed Nur",
  created_at: "",
  updated_at: "",
  created_by: null,
};

interface ShopProfileContextValue {
  shopProfile: ShopProfile;
  /** True only until the very first fetch attempt resolves (success or
   * failure) - lets callers avoid a flash of the fallback before knowing
   * whether the real profile is even reachable. */
  isLoading: boolean;
  refresh: () => void;
}

const ShopProfileContext = createContext<ShopProfileContextValue>({
  shopProfile: DEFAULT_SHOP_PROFILE,
  isLoading: true,
  refresh: () => {},
});

export function ShopProfileProvider({ children }: { children: React.ReactNode }) {
  const [shopProfile, setShopProfile] = useState<ShopProfile>(DEFAULT_SHOP_PROFILE);
  const [isLoading, setIsLoading] = useState(true);

  const refresh = useCallback(() => {
    getShopProfile()
      .then(setShopProfile)
      .catch(() => {
        // Not logged in yet (public/login page), or the request otherwise
        // failed - keep showing DEFAULT_SHOP_PROFILE. Call refresh() again
        // once auth succeeds (see login page) rather than retrying here.
      })
      .finally(() => setIsLoading(false));
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  useEffect(() => {
    if (shopProfile.shop_name) {
      document.title = shopProfile.shop_name;
    }
  }, [shopProfile.shop_name]);

  return (
    <ShopProfileContext.Provider value={{ shopProfile, isLoading, refresh }}>
      {children}
    </ShopProfileContext.Provider>
  );
}

export function useShopProfile(): ShopProfileContextValue {
  return useContext(ShopProfileContext);
}

"use client";

import {
  BarChart3,
  Boxes,
  FileText,
  Gauge,
  History,
  LayoutDashboard,
  Landmark,
  Package,
  Receipt,
  Settings,
  Tags,
  Truck,
  Users,
  Wallet,
  Wrench,
  Wand2,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";

import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar";
import { useAuth } from "@/lib/auth-context";
import { useShopProfile } from "@/lib/shop-profile-context";

// The rest are dead links (matching href to their eventual future route)
// until those pages get built.
const NAV_ITEMS = [
  { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard },
  { title: "Customers", url: "/customers", icon: Users },
  { title: "Suppliers", url: "/suppliers", icon: Truck },
  { title: "Meters", url: "/meters", icon: Gauge },
  { title: "Correction Devices", url: "/devices", icon: Wand2 },
  { title: "Service Categories", url: "/service-categories", icon: Tags },
  { title: "Services", url: "/services", icon: Wrench },
  { title: "Products", url: "/products", icon: Package },
  { title: "Invoices", url: "/invoices", icon: FileText },
  { title: "Payments", url: "/payments", icon: Wallet },
  { title: "Expenses", url: "/expenses", icon: Receipt },
  { title: "Assets", url: "/assets", icon: Boxes },
  { title: "Loans", url: "/loans", icon: Landmark },
  { title: "Reports", url: "/reports", icon: BarChart3 },
  { title: "Audit Log", url: "/audit-log", icon: History, adminOnly: true },
  { title: "Settings", url: "/settings", icon: Settings },
];

export function AppSidebar() {
  const pathname = usePathname();
  const { shopProfile } = useShopProfile();
  const { user } = useAuth();
  const navItems = NAV_ITEMS.filter((item) => !item.adminOnly || user?.role === "admin");

  return (
    <Sidebar collapsible="icon">
      <SidebarHeader>
        <div className="flex items-center gap-2 px-2 py-1.5">
          <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-md bg-primary text-sm font-semibold text-white">
            {shopProfile.shop_name.charAt(0).toUpperCase() || "S"}
          </div>
          <span className="truncate font-semibold group-data-[collapsible=icon]:hidden">
            {shopProfile.shop_name}
          </span>
        </div>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Menu</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {navItems.map((item) => {
                const isActive = pathname === item.url || pathname.startsWith(`${item.url}/`);
                return (
                  <SidebarMenuItem key={item.url}>
                    <SidebarMenuButton asChild isActive={isActive} tooltip={item.title}>
                      <Link href={item.url}>
                        <item.icon />
                        <span>{item.title}</span>
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                );
              })}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>
    </Sidebar>
  );
}

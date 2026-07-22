import { Plus } from "lucide-react";
import Link from "next/link";

import { AppSidebar } from "@/components/app-sidebar";
import { RequireAuth } from "@/components/require-auth";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { SidebarInset, SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { TooltipProvider } from "@/components/ui/tooltip";
import { UserMenu } from "@/components/user-menu";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <RequireAuth>
      <TooltipProvider>
        <SidebarProvider>
          <AppSidebar />
          <SidebarInset>
            <header className="flex h-14 shrink-0 items-center gap-2 border-b px-4">
              <SidebarTrigger className="-ml-1" />
              <Separator orientation="vertical" className="mr-2 h-4" />
              <div className="flex flex-1 items-center justify-end gap-2">
                <Button asChild size="sm">
                  <Link href="/invoices/new">
                    <Plus /> Add Invoice
                  </Link>
                </Button>
                <ThemeToggle />
                <UserMenu />
              </div>
            </header>
            <main className="flex flex-1 flex-col gap-4 p-4">{children}</main>
          </SidebarInset>
        </SidebarProvider>
      </TooltipProvider>
    </RequireAuth>
  );
}

import React, { useState } from "react";
import { Link, Outlet, useLocation } from "react-router-dom";
import { 
  Home,
  Monitor,
  Package,
  Bell,
  Settings, 
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { cn } from "@/lib/utils";
import { useAuth } from "@/contexts/AuthContext";
import { ThemeToggle } from "./ThemeToggle";
import { OfflineBanner } from "./OfflineBanner";

const Layout = () => {
  const location = useLocation();
  const [activeTab, setActiveTab] = useState(location.pathname);
  const { signOut } = useAuth();

  const navItems = [
    { icon: Home, label: "Dashboard", path: "/dashboard" },
    { icon: Monitor, label: "Machines", path: "/machines" },
    { icon: Package, label: "Inventory", path: "/inventory" },
    { icon: Bell, label: "Events", path: "/notifications" },
    { icon: Settings, label: "Settings", path: "/settings" },
  ];

  // Removed preferred landing persistence per request

  return (
          <div className="min-h-screen bg-background font-sans">
        <OfflineBanner />

        {/* Main Content */}
      <main className="pb-20">
        <Outlet />
      </main>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-card border-t border-border shadow-elevated">
        <div className="flex justify-around items-center py-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            
            return (
              <Link
                key={item.path}
                to={item.path}
                className={cn(
                  "flex flex-col items-center justify-center w-28 h-16 rounded-lg transition-all duration-200",
                  isActive 
                    ? "ring-1 ring-primary/30 shadow-[0_0_12px_hsl(195_100%_50%/0.25)] bg-card/40" 
                    : "hover:ring-1 hover:ring-primary/20"
                )}
              >
                <Icon className={cn(
                  "h-5 w-5 mb-1 transition-none",
                  isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
                )} />
                <span className={cn(
                  "text-xs font-medium transition-none",
                  isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
                )}>{item.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
};

export default Layout;
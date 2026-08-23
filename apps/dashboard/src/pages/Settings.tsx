import { LogOut, Settings as SettingsIcon } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { useTheme } from "@/contexts/ThemeContext";
import { getEdgeBaseUrl } from "@/lib/edgeConfig";
import * as React from "react";

const Settings = () => {
  const { user, signOut } = useAuth();
  const { theme, setTheme } = useTheme();
  const edgeBaseUrl = React.useMemo(() => getEdgeBaseUrl(), []);

  return (
    <div className="p-4 space-y-6 animate-fade-in">
      <Card className="bg-card border-border shadow-card animate-slide-up">
        <CardHeader className="pb-3">
          <CardTitle className="text-lg font-semibold text-foreground flex items-center gap-2">
            <SettingsIcon className="h-5 w-5" />
            Settings
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="text-sm">
            <div className="text-muted-foreground">Signed in as</div>
            <div className="font-medium">{user?.email || user?.id || "Unknown user"}</div>
          </div>

          <div className="text-sm">
            <div className="text-muted-foreground">Edge Base URL</div>
            <div className="font-mono text-xs break-all">
              {edgeBaseUrl || "Not set (VITE_EDGE_BASE_URL)"}
            </div>
          </div>

          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => setTheme(theme === "dark" ? "light" : "dark")}
            >
              Toggle Theme
            </Button>
            <Button variant="destructive" onClick={signOut} className="gap-2">
              <LogOut className="h-4 w-4" />
              Sign out
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default Settings;
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { supabaseAuth } from "@/integrations/supabase/authClient";

export default function Onboarding() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const complete = async () => {
    setSaving(true);
    setError(null);
    try {
      // Auth-only: store completion flags in user metadata.
      const { error: updateError } = await supabaseAuth.auth.updateUser({
        data: {
          profile_complete: true,
          skip_onboarding: true,
        },
      });
      if (updateError) throw updateError;
      navigate("/dashboard", { replace: true });
    } catch (e: any) {
      setError(e?.message || "Failed to complete onboarding");
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="p-4 space-y-4 animate-fade-in">
      <Card className="bg-card border-border shadow-card">
        <CardHeader>
          <CardTitle>Onboarding</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="text-sm text-muted-foreground">
            {user?.email
              ? `Signed in as ${user.email}.`
              : "Signed in."}{" "}
            This edge-first build stores onboarding completion in Supabase Auth user metadata only.
          </div>
          {error && <div className="text-sm text-destructive">{error}</div>}
          <Button onClick={complete} disabled={saving}>
            {saving ? "Saving..." : "Continue"}
          </Button>
        </CardContent>
      </Card>
    </div>
  );
}




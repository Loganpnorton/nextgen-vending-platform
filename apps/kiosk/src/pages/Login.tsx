import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { supabase } from "@/lib/supabase";
import logo from "@/assets/logo-kiosk.png";

const Login = () => {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    document.title = "Sign In - Vending Kiosk";
    const meta = document.querySelector('meta[name="description"]');
    if (meta) meta.setAttribute("content", "Sign in to the vending kiosk demo UI.");

    // Check if already authenticated
    const checkAuth = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (session) {
        navigate("/kiosk");
      }
    };
    checkAuth();
  }, [navigate]);

  const handleLogin = async () => {
    if (!email || !password) {
      setError("Please enter both email and password");
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        setError(error.message);
      } else {
        navigate("/kiosk");
      }
    } catch (err) {
      setError("An unexpected error occurred");
    } finally {
      setLoading(false);
    }
  };

  const handleForgotPassword = async () => {
    if (!email) {
      setError("Please enter your email address first");
      return;
    }

    try {
      const { error } = await supabase.auth.resetPasswordForEmail(email);
      if (error) {
        setError(error.message);
      } else {
        setError("Password reset email sent (check your inbox)");
      }
    } catch (err) {
      setError("Failed to send reset email");
    }
  };

  return (
    <div className="min-h-screen">
      <header className="flex items-center justify-end px-6 py-4">
        <Select defaultValue="en">
          <SelectTrigger className="w-36">
            <SelectValue placeholder="Language" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="en">English</SelectItem>
            <SelectItem value="es">Español</SelectItem>
            <SelectItem value="fr">Français</SelectItem>
          </SelectContent>
        </Select>
      </header>
      <main className="container mx-auto grid min-h-[80vh] place-items-center">
        <h1 className="sr-only">Sign In</h1>
        <Card className="w-full max-w-md border-0 bg-card/60 shadow-[var(--shadow-elegant)] backdrop-blur-sm">
          <CardHeader className="space-y-4 text-center">
            <img src={logo} alt="Kiosk logo" className="mx-auto h-14 w-14 animate-float" />
            <CardTitle className="text-2xl">Sign In</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input 
                id="email" 
                type="email" 
                placeholder="you@example.com" 
                autoComplete="username"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleLogin()}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input 
                id="password" 
                type="password" 
                placeholder="••••••••" 
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleLogin()}
              />
            </div>
            {error && (
              <p className="text-sm text-red-500">{error}</p>
            )}
          </CardContent>
          <CardFooter className="flex flex-col gap-3">
            <Button 
              className="w-full" 
              variant="hero" 
              onClick={handleLogin}
              disabled={loading}
            >
              {loading ? "Signing In..." : "Log In"}
            </Button>
            <Button 
              variant="link" 
              className="text-sm"
              onClick={handleForgotPassword}
            >
              Forgot Password?
            </Button>
          </CardFooter>
        </Card>
      </main>
    </div>
  );
};

export default Login;

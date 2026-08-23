import { useEffect } from "react";
import { Button } from "@/components/ui/button";
import { useNavigate } from "react-router-dom";

const ErrorScreen = () => {
  const navigate = useNavigate();

  useEffect(() => {
    document.title = "Error - Vending Kiosk";
  }, []);

  return (
    <main className="grid min-h-[70vh] place-items-center px-4 py-10">
      <div className="text-center">
        <h1 className="mb-2 text-3xl font-semibold">Machine not found</h1>
        <p className="mb-6 text-muted-foreground">Please check the token and try again.</p>
        <Button variant="hero" onClick={() => navigate("/kiosk")}>Retry</Button>
      </div>
    </main>
  );
};

export default ErrorScreen;

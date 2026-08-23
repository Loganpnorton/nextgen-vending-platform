import { useEffect } from "react";
import { Wrench } from "lucide-react";

const Maintenance = () => {
  useEffect(() => {
    document.title = "Maintenance - Vending Kiosk";
  }, []);

  return (
    <main className="grid min-h-[70vh] place-items-center px-4 py-10">
      <div className="flex flex-col items-center gap-4 text-center">
        <div className="rounded-full bg-muted/40 p-4 shadow-[var(--shadow-elegant)]">
          <Wrench className="h-8 w-8 text-foreground" />
        </div>
        <h1 className="text-2xl font-semibold">Temporarily unavailable</h1>
        <p className="max-w-sm text-muted-foreground">This machine is currently in maintenance mode. Please check back later.</p>
      </div>
    </main>
  );
};

export default Maintenance;

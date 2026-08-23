import { useEffect } from "react";

const LoadingScreen = () => {
  useEffect(() => {
    document.title = "Syncing - Vending Kiosk";
  }, []);

  return (
    <main className="grid min-h-[70vh] place-items-center px-4 py-10">
      <h1 className="sr-only">Syncing</h1>
      <div className="flex flex-col items-center gap-4">
        <div className="h-10 w-10 animate-spin rounded-full border-2 border-muted border-t-[hsl(var(--ring))]" />
        <p className="text-muted-foreground">Syncing with machine…</p>
      </div>
    </main>
  );
};

export default LoadingScreen;

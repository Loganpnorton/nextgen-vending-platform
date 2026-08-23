import { cn } from "@/lib/utils";

interface StatusDotProps {
  status: "online" | "offline";
  label?: string;
  className?: string;
}

export function StatusDot({ status, label, className }: StatusDotProps) {
  const colorVar = status === "online" ? "--status-online" : "--status-offline";
  return (
    <div className={cn("flex items-center gap-2", className)}>
      <span
        aria-hidden
        className={cn(
          "h-2.5 w-2.5 rounded-full shadow",
          status === "online" ? "animate-pulse-soft" : ""
        )}
        style={{ backgroundColor: `hsl(var(${colorVar}))` }}
      />
      {label && (
        <span className="text-sm text-muted-foreground select-none">{label}</span>
      )}
    </div>
  );
}

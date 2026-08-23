import { cn } from "@/lib/utils";

interface QRScannerMockProps {
  className?: string;
}

export function QRScannerMock({ className }: QRScannerMockProps) {
  return (
    <div
      className={cn(
        "relative mx-auto aspect-square w-full max-w-xs overflow-hidden rounded-lg border border-dashed",
        "border-input bg-card/40 shadow-sm backdrop-blur-sm",
        className
      )}
      aria-label="Mock QR scanner"
    >
      {/* corner brackets */}
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute left-2 top-2 h-6 w-6 rounded-tl-lg border-l-2 border-t-2 border-[hsl(var(--ring))]/70" />
        <div className="absolute right-2 top-2 h-6 w-6 rounded-tr-lg border-r-2 border-t-2 border-[hsl(var(--ring))]/70" />
        <div className="absolute bottom-2 left-2 h-6 w-6 rounded-bl-lg border-b-2 border-l-2 border-[hsl(var(--ring))]/70" />
        <div className="absolute bottom-2 right-2 h-6 w-6 rounded-br-lg border-b-2 border-r-2 border-[hsl(var(--ring))]/70" />
      </div>
      {/* scanning line */}
      <div className="pointer-events-none absolute inset-x-0 top-0 h-1.5 animate-scan-y bg-[linear-gradient(90deg,transparent,hsla(var(--brand)/0.6),transparent)]" />
      <div className="absolute inset-0 grid place-items-center text-center">
        <div className="space-y-2">
          <div className="text-sm text-muted-foreground">Align QR code within the frame</div>
          <div className="text-xs text-muted-foreground/70">(Mock scanner)</div>
        </div>
      </div>
    </div>
  );
}

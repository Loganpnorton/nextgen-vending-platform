declare module 'html5-qrcode' {
  export class Html5QrcodeScanner {
    constructor(
      elementId: string,
      config: {
        fps: number;
        qrbox: { width: number; height: number };
        aspectRatio: number;
      },
      verbose: boolean
    );

    render(
      onScanSuccess: (decodedText: string) => void,
      onScanError: (errorMessage: string) => void
    ): void;

    clear(): void;
  }
} 
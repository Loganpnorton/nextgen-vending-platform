import React, { useEffect, useRef, useState } from 'react';
import { Html5QrcodeScanner } from 'html5-qrcode';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { X, Camera, QrCode } from 'lucide-react';

interface QRCodeScannerProps {
  onScan: (result: string) => void;
  onClose: () => void;
  isOpen: boolean;
}

export const QRCodeScanner: React.FC<QRCodeScannerProps> = ({ onScan, onClose, isOpen }) => {
  const scannerRef = useRef<Html5QrcodeScanner | null>(null);
  const [isScanning, setIsScanning] = useState(false);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    if (isOpen) {
      // Defer to next tick to ensure container is rendered in DOM
      const id = setTimeout(() => {
        if (!scannerRef.current) {
          initializeScanner();
        }
      }, 0);
      return () => clearTimeout(id);
    }

    return () => {
      if (scannerRef.current) {
        scannerRef.current.clear();
        scannerRef.current = null;
      }
    };
  }, [isOpen]);

  const initializeScanner = () => {
    try {
      const scanner = new Html5QrcodeScanner(
        "qr-reader",
        {
          fps: 10,
          // Use a slightly smaller box on mobile to ensure camera permission sheets fit
          qrbox: window.innerWidth < 640 ? { width: 220, height: 220 } : { width: 280, height: 280 },
          aspectRatio: 1.0,
          rememberLastUsedCamera: true,
        },
        false
      );

      scanner.render(
        (decodedText) => {
          console.log('QR Code scanned:', decodedText);
          onScan(decodedText);
          setIsScanning(false);
        },
        (errorMessage) => {
          // Handle scan errors silently
          console.log('Scan error:', errorMessage);
        }
      );

      scannerRef.current = scanner;
      setIsScanning(true);
      setError('');
    } catch (err) {
      console.error('Failed to initialize scanner:', err);
      setError('Failed to access camera. Please grant permission and try again.');
      setIsScanning(false);
    }
  };

  const handleClose = () => {
    if (scannerRef.current) {
      scannerRef.current.clear();
      scannerRef.current = null;
    }
    setIsScanning(false);
    setError('');
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
      <Card className="w-full max-w-md mx-4">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="flex items-center gap-2">
            <Camera className="h-5 w-5" />
            Scan QR Code
          </CardTitle>
          <Button
            variant="ghost"
            size="sm"
            onClick={handleClose}
            className="h-8 w-8 p-0"
          >
            <X className="h-4 w-4" />
          </Button>
        </CardHeader>
        <CardContent className="space-y-4">
          {error && (
            <div className="text-sm text-destructive bg-destructive/10 p-3 rounded-md">
              {error}
            </div>
          )}
          
          <div className="space-y-2">
            <div className="text-sm text-muted-foreground">
              Position the QR code within the frame to scan
            </div>
            <div id="qr-reader" className="w-full min-h-[260px]"></div>
          </div>

          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={handleClose}
              className="flex-1"
            >
              Cancel
            </Button>
            <Button
              onClick={() => {
                if (!scannerRef.current) {
                  initializeScanner();
                }
              }}
              className="flex-1"
              disabled={isScanning}
            >
              <QrCode className="mr-2 h-4 w-4" />
              {isScanning ? 'Scanning...' : 'Start Scanner'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}; 
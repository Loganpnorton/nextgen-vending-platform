import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { ScrollArea } from "@/components/ui/scroll-area";
import { CreditCard } from "lucide-react";

export interface CartItem {
  id: string;
  name: string;
  price: number;
  qty: number;
}

interface CartSidebarProps {
  items: CartItem[];
  onCheckout?: () => void;
  onClear?: () => void;
  processing?: boolean;
}

export function CartSidebar({ items, onCheckout, onClear, processing = false }: CartSidebarProps) {
  const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);

  return (
    <aside aria-label="Cart preview" className="w-full lg:w-80">
      <Card className="sticky top-6 border-0 bg-card shadow-[var(--shadow-elegant)]">
        <CardHeader>
          <CardTitle className="text-lg">Cart</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <ScrollArea className="h-64 px-6">
            <ul className="space-y-3 py-4">
              {items.length === 0 && (
                <li className="text-sm text-muted-foreground">No items selected.</li>
              )}
              {items.map((item) => (
                <li key={`${item.id}`} className="flex items-center justify-between text-sm">
                  <div>
                    <div className="font-medium">{item.name}</div>
                    <div className="text-muted-foreground">
                      {item.qty} × ${item.price.toFixed(2)}
                    </div>
                  </div>
                  <div className="font-medium">${(item.qty * item.price).toFixed(2)}</div>
                </li>
              ))}
            </ul>
          </ScrollArea>
        </CardContent>
        <CardFooter className="flex flex-col gap-3">
          <div className="flex w-full items-center justify-between">
            <span className="text-sm text-muted-foreground">Total</span>
            <span className="text-lg font-semibold">${total.toFixed(2)}</span>
          </div>
          <Button 
            className="w-full" 
            variant="default"
            size="lg"
            disabled={items.length === 0 || processing}
            onClick={onCheckout}
          >
            <CreditCard />
            {processing ? 'Processing...' : 'Checkout'}
          </Button>
          <Button className="w-full" variant="outline" onClick={onClear} disabled={items.length === 0}>
            Clear
          </Button>
        </CardFooter>
      </Card>
    </aside>
  );
}

import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { useState } from "react";

export interface Product {
  id: string;
  name: string;
  price: number;
  image: string;
  inStock: boolean;
  slot?: string;
}

interface ProductCardProps {
  product: Product;
  onBuy: (product: Product) => void;
}

export function ProductCard({ product, onBuy }: ProductCardProps) {
  const [imageError, setImageError] = useState(false);

  const handleImageError = () => {
    setImageError(true);
  };

  return (
    <Card className="group overflow-hidden border-0 bg-card shadow-[var(--shadow-elegant)]">
      <CardHeader className="p-0">
        <div className="relative aspect-square w-full overflow-hidden">
          {!imageError ? (
            <img
              src={product.image}
              alt={`${product.name} product image`}
              loading="lazy"
              className="h-full w-full object-cover"
              onError={handleImageError}
            />
          ) : (
            <div className="flex h-full w-full items-center justify-center bg-muted">
              <div className="text-center text-muted-foreground">
                <div className="text-4xl mb-2">📦</div>
                <div className="text-sm">{product.name}</div>
              </div>
            </div>
          )}
          {!product.inStock && (
            <div className="absolute right-2 top-2">
              <Badge variant="secondary">Out of Stock</Badge>
            </div>
          )}
        </div>
      </CardHeader>
      <CardContent className="space-y-1 p-4">
        <CardTitle className="text-base font-semibold tracking-tight">{product.name}</CardTitle>
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span>{product.slot ?? ""}</span>
          <span className="font-medium text-foreground">${product.price.toFixed(2)}</span>
        </div>
      </CardContent>
      <CardFooter className="p-4 pt-0">
        <Button
          className="w-full"
          variant={product.inStock ? "default" : undefined}
          onClick={() => onBuy(product)}
          disabled={!product.inStock}
        >
          {product.inStock ? "Add to Cart" : "Unavailable"}
        </Button>
      </CardFooter>
    </Card>
  );
}

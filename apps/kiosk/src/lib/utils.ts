import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Import fallback images
import prodWater from "@/assets/prod-water.png";
import prodSoda from "@/assets/prod-soda.png";
import prodEnergy from "@/assets/prod-energy.png";
import prodJuice from "@/assets/prod-juice.png";
import prodCandy from "@/assets/prod-candy.png";
import prodChips from "@/assets/prod-chips.png";

// Map of product categories to fallback images
const categoryImages: Record<string, string> = {
  'beverages': prodWater,
  'soda': prodSoda,
  'energy': prodEnergy,
  'juice': prodJuice,
  'candy': prodCandy,
  'snacks': prodChips,
  'chips': prodChips,
  'water': prodWater,
  'default': prodWater,
};

export function getFallbackImage(category?: string, productName?: string): string {
  if (!category && !productName) {
    return categoryImages.default;
  }

  // Try to match by category first
  const lowerCategory = category?.toLowerCase() || '';
  for (const [key, image] of Object.entries(categoryImages)) {
    if (lowerCategory.includes(key)) {
      return image;
    }
  }

  // Try to match by product name
  const lowerName = productName?.toLowerCase() || '';
  for (const [key, image] of Object.entries(categoryImages)) {
    if (lowerName.includes(key)) {
      return image;
    }
  }

  return categoryImages.default;
}

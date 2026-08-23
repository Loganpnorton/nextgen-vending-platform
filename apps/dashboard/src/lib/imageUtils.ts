export interface ImageValidationResult {
  isValid: boolean;
  errors: string[];
  width?: number;
  height?: number;
  fileSize?: number;
  mimeType?: string;
}

export interface ProcessedImage {
  file: File;
  width: number;
  height: number;
  fileSize: number;
  mimeType: string;
  fileHash: string;
}

// Allowed file types
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
const MIN_DIMENSIONS = 500;
const MAX_DIMENSIONS = 1024;

/**
 * Validate image file against requirements
 */
export const validateImage = async (file: File): Promise<ImageValidationResult> => {
  const errors: string[] = [];
  
  // Check file type
  if (!ALLOWED_MIME_TYPES.includes(file.type)) {
    errors.push(`File type not supported. Please use JPG, PNG, or WebP files.`);
  }
  
  // Check file size
  if (file.size > MAX_FILE_SIZE) {
    errors.push(`File size too large. Maximum size is 5MB.`);
  }
  
  // Check dimensions
  try {
    const dimensions = await getImageDimensions(file);
    if (dimensions.width < MIN_DIMENSIONS || dimensions.height < MIN_DIMENSIONS) {
      errors.push(`Image dimensions too small. Minimum size is ${MIN_DIMENSIONS}x${MIN_DIMENSIONS} pixels.`);
    }
    
    return {
      isValid: errors.length === 0,
      errors,
      width: dimensions.width,
      height: dimensions.height,
      fileSize: file.size,
      mimeType: file.type
    };
  } catch (error) {
    errors.push('Unable to read image dimensions. Please try a different image.');
    return {
      isValid: false,
      errors,
      fileSize: file.size,
      mimeType: file.type
    };
  }
};

/**
 * Get image dimensions from file
 */
export const getImageDimensions = (file: File): Promise<{ width: number; height: number }> => {
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      resolve({ width: img.width, height: img.height });
    };
    img.onerror = () => {
      reject(new Error('Failed to load image'));
    };
    img.src = URL.createObjectURL(file);
  });
};

/**
 * Generate file hash for duplicate detection
 */
export const generateFileHash = async (file: File): Promise<string> => {
  const buffer = await file.arrayBuffer();
  const hashBuffer = await crypto.subtle.digest('SHA-256', buffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
};

/**
 * Resize and compress image
 */
export const processImage = async (
  file: File,
  options?: { outputType?: string; quality?: number }
): Promise<ProcessedImage> => {
  return new Promise((resolve, reject) => {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    const img = new Image();
    
    img.onload = async () => {
      try {
        // Calculate new dimensions (maintain aspect ratio)
        let { width, height } = img;
        
        if (width > MAX_DIMENSIONS || height > MAX_DIMENSIONS) {
          if (width > height) {
            height = (height * MAX_DIMENSIONS) / width;
            width = MAX_DIMENSIONS;
          } else {
            width = (width * MAX_DIMENSIONS) / height;
            height = MAX_DIMENSIONS;
          }
        }
        
        // Set canvas dimensions
        canvas.width = width;
        canvas.height = height;
        
        // Draw and compress image
        ctx?.drawImage(img, 0, 0, width, height);
        
        // Convert to blob with compression. Try requested type first; fallback to PNG if unsupported
        const toBlobWithFallback = (preferredType: string, quality = 0.8) => new Promise<Blob | null>((resolve) => {
          canvas.toBlob((blob) => resolve(blob), preferredType, quality);
        });

        (async () => {
          const preferredType = options?.outputType || file.type;
          const quality = options?.quality ?? 0.8;
          let blob = await toBlobWithFallback(preferredType, quality);
          if (!blob) {
            // Fallback for browsers that don't support WebP or requested codec in canvas
            blob = await toBlobWithFallback('image/png', 0.92);
          }
          if (!blob) {
            reject(new Error('Failed to process image'));
            return;
          }

          const processedFile = new File([blob], file.name, {
            type: blob.type || file.type,
            lastModified: Date.now()
          });

          const fileHash = await generateFileHash(processedFile);

          resolve({
            file: processedFile,
            width: Math.round(width),
            height: Math.round(height),
            fileSize: processedFile.size,
            mimeType: processedFile.type,
            fileHash
          });
        })();
        
      } catch (error) {
        reject(error);
      }
    };
    
    img.onerror = () => {
      reject(new Error('Failed to load image'));
    };
    
    img.src = URL.createObjectURL(file);
  });
};

/**
 * Check if file is a duplicate based on hash
 */
export const checkDuplicateFile = async (file: File, existingHashes: string[]): Promise<boolean> => {
  const fileHash = await generateFileHash(file);
  return existingHashes.includes(fileHash);
};

/**
 * Format file size for display
 */
export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

/**
 * Get file extension from filename
 */
export const getFileExtension = (filename: string): string => {
  return filename.split('.').pop()?.toLowerCase() || '';
};

/**
 * Validate filename
 */
export const validateFilename = (filename: string): boolean => {
  // Basic filename validation - no special characters except dots and hyphens
  const validFilenameRegex = /^[a-zA-Z0-9._-]+$/;
  return validFilenameRegex.test(filename);
}; 
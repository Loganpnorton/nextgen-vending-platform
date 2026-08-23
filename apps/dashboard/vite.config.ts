import { defineConfig } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      "crypto": "crypto-browserify",
      "stream": "stream-browserify",
      "buffer": "buffer",
    },
  },
  define: {
    global: 'globalThis',
  },
  optimizeDeps: {
    include: ['otplib'],
  },
  build: {
    rollupOptions: {
      external: [],
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        secure: false,
      },
    },
  },
});

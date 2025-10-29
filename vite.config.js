import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    host: true, // Allow network access for mobile testing
    port: 3000,
    https: false // Using demo mode (camera requires HTTPS on network, but demo works great!)
  },
  build: {
    target: 'es2015',
    outDir: 'dist',
    sourcemap: true
  }
});


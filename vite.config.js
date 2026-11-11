import { defineConfig } from "vite";

export default defineConfig({
  base: process.env.GITHUB_ACTIONS === "true" ? "/btw-menu/" : "/",
  build: {
    rollupOptions: {
      input: {
        main: "index.html",
        qr: "qr-code.html"
      }
    }
  }
});
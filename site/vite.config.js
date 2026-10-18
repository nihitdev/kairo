import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [tailwindcss(), {
    name: "kairo-module-metadata",
    transformIndexHtml(html) {
      const installer = fileURLToPath(new URL("../install.sh", import.meta.url));
      const modules = execFileSync("bash", [installer, "--list-modules"], { encoding: "utf8" }).trim().split("\n");
      return html.replaceAll("%KAIRO_MODULE_COUNT%", String(modules.length))
        .replaceAll("%KAIRO_DEFAULT_COUNT%", String(modules.filter((row) => row.endsWith("\ttrue")).length));
    },
  }],
  server: {
    host: "127.0.0.1",
  },
});

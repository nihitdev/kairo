# Kairo website

Production: [get-kairo.vercel.app](https://get-kairo.vercel.app)

The project site uses Vite and Tailwind CSS v4. It works with pnpm or Bun. The landing page uses real captures from `screenshots/`, copied into `public/showcase/` so the production build is self-contained. Module and default-selection counts are read from `install.sh` during the build.

```sh
cd site
pnpm install
pnpm dev
```

With Bun:

```sh
cd site
bun install
bun run dev
```

Create a production build with `pnpm build` or `bun run build`. Generated files are written to `site/dist/`.

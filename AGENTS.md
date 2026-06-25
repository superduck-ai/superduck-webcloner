# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.

# Website Reverse-Engineer Template

## What This Is
A reusable template for reverse-engineering any website into a clean, modern codebase using AI coding agents. Two interchangeable framework templates are pre-scaffolded under `templates/`:
- `templates/nextjs/` — Next.js 16 (App Router, React 19)
- `templates/tanstack-start/` — TanStack Start RC (TanStack Router, Vite)

Both share the same shadcn/ui + Tailwind v4 component layer and the same SuperDuck-driven extraction pipeline. Pick one at clone time with `--framework nextjs|tanstack` (default: `nextjs`): `/clone-website-superduck <url1> [<url2> ...] [--framework nextjs|tanstack]`.

Browser automation is powered by **SuperDuck** — an open-source Chrome/Edge extension that exposes the user's real browser (with existing cookies and login state) to AI agents via the `superduck` CLI. SuperDuck works with any model (DeepSeek, Qwen, Kimi, Gemini, GPT, or any OpenAI-compatible API) and has no region restrictions. It is the only browser backend this project supports — the clone pipeline will not run without it.

## Tech Stack
- **Frameworks (pick one at clone time):**
  - `templates/nextjs/` — Next.js 16 (App Router, React 19, `next/font`, TypeScript strict)
  - `templates/tanstack-start/` — TanStack Start RC (TanStack Router, Vite, `@fontsource-variable`)
- **UI:** shadcn/ui (Base UI primitives, Tailwind CSS v4, `cn()` utility) — shared by both templates
- **Icons:** Lucide React (default — will be replaced/supplemented by extracted SVGs)
- **Styling:** Tailwind CSS v4 with oklch design tokens
- **Browser automation:** SuperDuck CLI (`superduck` command, driven through Bash)
- **Deployment:** Vercel (Next.js native; TanStack Start via its Vercel adapter)

## Prerequisites

All are **hard prerequisites** — the skill aborts at Pre-Flight if any is missing.

- [Node.js](https://nodejs.org/) 24+
- [SuperDuck](https://github.com/superduck-ai/superduck) installed and `superduck doctor` passing — the only browser backend; no fallback
- An AI coding agent (Claude Code recommended, but any agent that can run Bash works)

## Commands
The repo is an npm workspace with two templates. Run commands against a specific template with `-w`:
- `npm -w nextjs run dev` / `npm -w tanstack-start run dev` — Start dev server
- `npm -w nextjs run build` / `npm -w tanstack-start run build` — Production build
- `npm -w nextjs run lint` / `npm -w tanstack-start run lint` — ESLint check
- `npm -w nextjs run typecheck` / `npm -w tanstack-start run typecheck` — TypeScript check
- `npm -w nextjs run check` / `npm -w tanstack-start run check` — Run lint + typecheck + build
- `npm run check` — Run `check` for both templates

## Code Style
- TypeScript strict mode, no `any`
- Named exports, PascalCase components, camelCase utils
- Tailwind utility classes, no inline styles
- 2-space indentation
- Responsive: mobile-first

## Design Principles
- **Pixel-perfect emulation** — match the target's spacing, colors, typography exactly
- **No personal aesthetic changes during emulation phase** — match 1:1 first, customize later
- **Real content** — use actual text and assets from the target site, not placeholders
- **Beauty-first** — every pixel matters

## Project Structure
```
templates/
  nextjs/           # Next.js 16 template (App Router)
    src/
      app/            # routes (layout.tsx, page.tsx, globals.css)
      components/     # React components
        ui/             # shadcn/ui primitives
        icons.tsx       # Extracted SVG icons as React components
      lib/utils.ts     # cn() utility (shadcn)
      types/            # TypeScript interfaces
      hooks/            # Custom React hooks
    public/            # images/, videos/, seo/ (downloaded from target)
  tanstack-start/   # TanStack Start RC template (TanStack Router + Vite)
    src/
      routes/          # __root.tsx, index.tsx (createFileRoute)
      styles/app.css   # global CSS (tokens, fonts via @fontsource-variable)
      components/      # same shadcn/ui layer as nextjs
      lib/utils.ts
      types/ hooks/
    public/
docs/
  research/         # Inspection output (design tokens, components, layout)
  design-references/ # Screenshots and visual references
scripts/
  fullpage-screenshot.sh  # SuperDuck-based full-page screenshot stitching
  download-assets.mjs     # Asset download script (written during clone)
  sync-agent-rules.sh     # Regenerate agent instruction files from AGENTS.md
  sync-skills.mjs         # Regenerate skill for all 9 supported platforms
```

## MOST IMPORTANT NOTES
- When launching Claude Code agent teams, ALWAYS have each teammate work in their own worktree branch and merge everyone's work at the end, resolving any merge conflicts smartly since you are basically serving the orchestrator role and have full context to our goals, work given, work achieved, and desired outcomes.
- All browser interaction goes through the `superduck` CLI via Bash. Never assume a browser MCP is available — use `superduck --tab "$TAB" <command>`. Run `superduck doctor` first if anything seems off.
- The `superduck exec` command appends a human-readable `Tab Context` trailer after the JavaScript result. Always strip it before `JSON.parse`-ing — define `strip_tc() { awk '/^Tab Context:/{exit} {print}'; }` and pipe through it, or split on `/\n\s*\nTab Context:/`.
- After editing `AGENTS.md`, run `bash scripts/sync-agent-rules.sh` to regenerate platform-specific instruction files (Cline, Continue, Amazon Q, Copilot Chat).
- After editing `.claude/skills/clone-website-superduck/SKILL.md`, run `node scripts/sync-skills.mjs` to regenerate the skill for all 9 supported platforms.

@docs/research/INSPECTION_GUIDE.md

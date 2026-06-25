# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.

# Website Reverse-Engineer Template

## What This Is
A reusable template for reverse-engineering any website into a clean, modern Next.js codebase using AI coding agents. The Next.js + shadcn/ui + Tailwind v4 base is pre-scaffolded — just run `/clone-website-superduck <url1> [<url2> ...]`.

Browser automation is powered by **SuperDuck** — an open-source Chrome/Edge extension that exposes the user's real browser (with existing cookies and login state) to AI agents via the `superduck` CLI. SuperDuck works with any model (DeepSeek, Qwen, Kimi, Gemini, GPT, or any OpenAI-compatible API) and has no region restrictions. It is the only browser backend this project supports — the clone pipeline will not run without it.

## Tech Stack
- **Framework:** Next.js 16 (App Router, React 19, TypeScript strict)
- **UI:** shadcn/ui (Radix primitives, Tailwind CSS v4, `cn()` utility)
- **Icons:** Lucide React (default — will be replaced/supplemented by extracted SVGs)
- **Styling:** Tailwind CSS v4 with oklch design tokens
- **Browser automation:** SuperDuck CLI (`superduck` command, driven through Bash)
- **Deployment:** Vercel

## Prerequisites

All are **hard prerequisites** — the skill aborts at Pre-Flight if any is missing.

- [Node.js](https://nodejs.org/) 24+
- [SuperDuck](https://github.com/superduck-ai/superduck) installed and `superduck doctor` passing — the only browser backend; no fallback
- An AI coding agent (Claude Code recommended, but any agent that can run Bash works)

## Commands
- `npm run dev` — Start dev server
- `npm run build` — Production build
- `npm run lint` — ESLint check
- `npm run typecheck` — TypeScript check
- `npm run check` — Run lint + typecheck + build

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
src/
  app/              # Next.js routes
  components/       # React components
    ui/             # shadcn/ui primitives
    icons.tsx       # Extracted SVG icons as React components
  lib/
    utils.ts        # cn() utility (shadcn)
  types/            # TypeScript interfaces
  hooks/            # Custom React hooks
public/
  images/           # Downloaded images from target site
  videos/           # Downloaded videos from target site
  seo/              # Favicons, OG images, webmanifest
docs/
  research/         # Inspection output (design tokens, components, layout)
  design-references/ # Screenshots and visual references
scripts/
  fullpage-screenshot.sh  # SuperDuck-based full-page screenshot stitching
  download-assets.mjs     # Asset download script (written during clone)
```

## MOST IMPORTANT NOTES
- When launching Claude Code agent teams, ALWAYS have each teammate work in their own worktree branch and merge everyone's work at the end, resolving any merge conflicts smartly since you are basically serving the orchestrator role and have full context to our goals, work given, work achieved, and desired outcomes.
- All browser interaction goes through the `superduck` CLI via Bash. Never assume a browser MCP is available — use `superduck --tab "$TAB" <command>`. Run `superduck doctor` first if anything seems off.
- The `superduck exec` command appends a human-readable `Tab Context` trailer after the JavaScript result. Always strip it before `JSON.parse`-ing — define `strip_tc() { awk '/^Tab Context:/{exit} {print}'; }` and pipe through it, or split on `/\n\s*\nTab Context:/`.
- After editing `AGENTS.md`, run `bash scripts/sync-agent-rules.sh` to regenerate platform-specific instruction files (Cline, Continue, Amazon Q, Copilot Chat).
- After editing `.claude/skills/clone-website-superduck/SKILL.md`, run `node scripts/sync-skills.mjs` to regenerate the skill for all 9 supported platforms.

@docs/research/INSPECTION_GUIDE.md

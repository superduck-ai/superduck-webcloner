<div align="center">
  <img src="https://raw.githubusercontent.com/superduck-ai/superduck/main/chrome-crx/extension_icon.svg" alt="Superduck WebCloner" width="120" height="120" />

# Superduck WebCloner

Reverse-engineer any website into a clean Next.js codebase — powered by [SuperDuck](https://github.com/superduck-ai/superduck) browser automation.

[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE) [![Node](https://img.shields.io/badge/node-%E2%89%A524-green)](https://nodejs.org/) [![Next.js](https://img.shields.io/badge/Next.js-16-black)](https://nextjs.org/) [![SuperDuck](https://img.shields.io/badge/browser-SuperDuck-4A90D9)](https://github.com/superduck-ai/superduck)

</div>

Point it at a URL, run `/clone-website-superduck`, and your AI agent inspects the site, extracts design tokens and assets, writes component specs, and dispatches parallel builders to reconstruct every section — all through SuperDuck controlling your real browser.

Browser automation is powered by **SuperDuck** — an open-source Chrome/Edge extension that drives the user's real browser via the `superduck` CLI. It is the **only** browser backend this project supports; the clone pipeline will not run without it.

## Why SuperDuck?

SuperDuck gives the agent full CDP control of your real Chrome — same cookies, same login state, no headless browser. It works with **any model** (DeepSeek, Qwen, Kimi, Gemini, GPT, or any OpenAI-compatible API), **anywhere** in the world, on your own API budget. No subscription, no region lock, no headless browser fighting captchas.

## Features

- **Pixel-perfect cloning** — exact colors, spacing, typography, animations via `getComputedStyle()` extraction
- **Real content & assets** — downloads actual images, videos, fonts, SVGs from the target site
- **Parallel build** — each section gets its own builder agent in a git worktree
- **Auditable specs** — every component has a `*.spec.md` file with exact CSS values and interaction models
- **Multi-model** — works with any AI agent + any LLM via SuperDuck's model routing
- **Full behavior capture** — scroll-driven, click-driven, hover states, multi-state content
- **Responsive** — tests at 1440px / 768px / 390px during extraction

## Quick Start

> **Important:** Start by making your own copy with GitHub's **Use this template** button. Do not clone this repository directly for your website project, and do not open pull requests here with your generated website.

1. **Create your own repository from this template**

   On the GitHub page for this project, click **Use this template**, then **Create a new repository**. Give it a name, choose public/private, and click **Create repository**. Leave "Include all branches" off.

2. **Clone your new repository**

   ```bash
   git clone https://github.com/YOUR-USERNAME/YOUR-REPO.git
   cd YOUR-REPO
   ```

3. **Install SuperDuck** (the only browser backend — hard prerequisite)

   ```bash
   npm install -g superduck-cli
   superduck setup          # installs native host + permissions
   superduck doctor         # verify everything is ready
   ```

   Then load the SuperDuck extension in Chrome/Edge (see the [SuperDuck README](https://github.com/superduck-ai/superduck)).

4. **Install ImageMagick** (for full-page screenshot stitching)

   ```bash
   brew install imagemagick      # macOS
   # apt install imagemagick     # Debian/Ubuntu
   ```

5. **Install dependencies**

   ```bash
   npm install
   ```

6. **Start your AI agent and run the skill**

   ```bash
   claude                       # Claude Code — recommended
   ```

   Then in the agent:
   ```
   /clone-website-superduck https://example.com
   ```

   No `--chrome` flag needed. SuperDuck handles the browser.

7. **Customize** (optional) — after the base clone is built, modify as needed.

## How It Works

```
Target URL ──▶ superduck navigate ──▶ Phase 1: Reconnaissance
                                          ├─ full-page screenshots (desktop + mobile)
                                          ├─ design tokens (fonts, colors, favicons)
                                          └─ interaction sweep (scroll / click / hover / responsive)
                                                      │
                                                      ▼
                                   Phase 2: Foundation (fonts, globals.css, types, icons, assets)
                                                      │
                                                      ▼
                                   Phase 3: per section ─▶ extract (superduck exec)
                                                         ─▶ write *.spec.md
                                                         ─▶ dispatch builder agent (worktree) ─▶ merge
                                                      │
                                                      ▼
                                   Phase 4: Page Assembly (page.tsx, page-level behaviors)
                                                      │
                                                      ▼
                                   Phase 5: Visual QA Diff (side-by-side in 2 superduck tabs)
```

The `/clone-website-superduck` skill runs a 5-phase pipeline:

1. **Reconnaissance** — SuperDuck navigates to the target, takes full-page screenshots (desktop + mobile via scroll-and-stitch), extracts design tokens, and runs an interaction sweep (scroll, click, hover, responsive) via `superduck exec`
2. **Foundation** — updates fonts, colors, globals, downloads all assets
3. **Component Specs** — writes detailed spec files (`docs/research/components/`) with exact `getComputedStyle()` values, states, behaviors, and content — all extracted via `superduck exec`
4. **Parallel Build** — dispatches builder agents in git worktrees, one per section/component
5. **Assembly & QA** — merges worktrees, wires up the page, runs visual diff against the target site (side-by-side in two SuperDuck tabs)

Each builder agent receives the full component specification inline — exact computed CSS values, interaction models, multi-state content, responsive breakpoints, and asset paths. No guessing.

## Supported Platforms

| Agent | Status | How to run the skill |
| --- | --- | --- |
| [Claude Code](https://docs.anthropic.com/en/docs/claude-code) | **Recommended** | `/clone-website-superduck <url>` |
| [Codex CLI](https://github.com/openai/codex) | Supported | `/clone-website-superduck <url>` |
| [OpenCode](https://opencode.ai/) | Supported | `/clone-website-superduck <url>` |
| [GitHub Copilot](https://github.com/features/copilot) | Supported | `/clone-website-superduck <url>` |
| [Cursor](https://cursor.com/) | Supported | `clone-website-superduck` command |
| [Windsurf](https://codeium.com/windsurf) | Supported | `clone-website-superduck` workflow |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | Supported | `/clone-website-superduck <url>` |
| [Cline](https://github.com/cline/cline) | Supported | reads `.clinerules` + skill file |
| [Roo Code](https://github.com/RooCodeInc/Roo-Code) | Supported | reads `.clinerules` |
| [Continue](https://continue.dev/) | Supported | `clone-website-superduck` command |
| [Amazon Q](https://aws.amazon.com/q/developer/) | Supported | `clone-website-superduck` agent |
| [Augment Code](https://www.augmentcode.com/) | Supported | `clone-website-superduck` command |
| [Aider](https://aider.chat/) | Supported | reads `AGENTS.md` |

> Using a different agent? Open `AGENTS.md` for project instructions — most agents pick it up automatically. All browser interaction goes through the `superduck` CLI, so any agent that can run Bash works.

## Prerequisites

All four are **hard prerequisites** — the skill aborts at Pre-Flight until each is satisfied.

- [Node.js](https://nodejs.org/) 24+
- [SuperDuck](https://github.com/superduck-ai/superduck) installed and `superduck doctor` passing — the only browser backend; no fallback
- [ImageMagick](https://imagemagick.org/) (`convert`) for full-page screenshot stitching
- An AI coding agent (Claude Code recommended; any agent that can run Bash works since SuperDuck is a CLI)

## Tech Stack

- **Next.js 16** — App Router, React 19, TypeScript strict
- **shadcn/ui** — Radix primitives + Tailwind CSS v4
- **Tailwind CSS v4** — oklch design tokens
- **Lucide React** — default icons (replaced by extracted SVGs during cloning)
- **SuperDuck** — browser automation via CLI (full CDP access to the user's real Chrome)
- **Deployment** — Vercel

## Commands

```bash
npm run dev        # Start dev server
npm run build      # Production build
npm run lint       # ESLint check
npm run typecheck  # TypeScript check
npm run check      # Run lint + typecheck + build
```

## Updating for Other Platforms

Two source-of-truth files power all platform support. Edit the source, then run the sync script:

| What | Source of truth | Sync command |
| --- | --- | --- |
| Project instructions | `AGENTS.md` | `bash scripts/sync-agent-rules.sh` |
| `/clone-website-superduck` skill | `.claude/skills/clone-website-superduck/SKILL.md` | `node scripts/sync-skills.mjs` |

Each script regenerates the platform-specific copies automatically. Agents that read the source files natively (Codex CLI, OpenCode, Cursor, Windsurf, Copilot Coding Agent, Roo Code, Aider, Augment Code) need no regeneration.

## Project Structure

```
src/
  app/              # Next.js routes
  components/       # React components
    ui/             # shadcn/ui primitives
    icons.tsx       # Extracted SVG icons
  lib/utils.ts      # cn() utility
  types/            # TypeScript interfaces
  hooks/            # Custom React hooks
public/
  images/           # Downloaded images from target
  videos/           # Downloaded videos from target
  seo/              # Favicons, OG images
docs/
  research/         # Extraction output & component specs
  design-references/ # Screenshots
scripts/
  fullpage-screenshot.sh  # SuperDuck scroll-and-stitch full-page capture
  sync-agent-rules.sh     # Regenerate agent instruction files from AGENTS.md
  sync-skills.mjs         # Regenerate /clone-website-superduck for all platforms
AGENTS.md           # Agent instructions (single source of truth)
CLAUDE.md           # Claude Code config (imports AGENTS.md)
GEMINI.md           # Gemini CLI config (imports AGENTS.md)
```

## Use Cases

- **Platform migration** — rebuild a site you own from WordPress/Webflow/Squarespace into a modern Next.js codebase
- **Lost source code** — your site is live but the repo is gone, the developer left, or the stack is legacy. Get the code back in a modern format
- **Learning** — deconstruct how production sites achieve specific layouts, animations, and responsive behavior by working with real code

## Not Intended For

- **Phishing or impersonation** — this project must not be used for deceptive purposes, impersonation, or any activity that breaks the law.
- **Passing off someone's design as your own** — logos, brand assets, and original copy belong to their owners.
- **Violating terms of service** — some sites explicitly prohibit scraping or reproduction. Check first.

## Acknowledgements

This project is built on top of [ai-website-cloner-template](https://github.com/JCodesMore/ai-website-cloner-template) by [JCodesMore](https://github.com/JCodesMore). Thanks for the excellent Next.js + shadcn/ui scaffolding and the inspection guide that made this project possible.

## License

MIT

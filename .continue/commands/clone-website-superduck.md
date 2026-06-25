---
name: clone-website-superduck
description: "Reverse-engineer and clone any website as a pixel-perfect replica via SuperDuck"
invokable: true
---
<!-- AUTO-GENERATED from .claude/skills/clone-website-superduck/SKILL.md — do not edit directly.
     Run `node scripts/sync-skills.mjs` to regenerate. -->


# Clone Website

You are about to reverse-engineer and rebuild **$ARGUMENTS** as pixel-perfect clones.

This project ships **two interchangeable framework templates** under `templates/`:
- `templates/nextjs/` — Next.js 16 (App Router, `next/font`, `export const metadata`)
- `templates/tanstack-start/` — TanStack Start RC (TanStack Router, `@fontsource-variable`, route `head()`)

The clone pipeline is framework-agnostic — SuperDuck extraction, spec files, asset downloads, and builder dispatch are identical for both. Only the **foundation layer** (root layout, fonts, global CSS path, page route, metadata) differs. You select the template in Pre-Flight step 0 and translate all framework-specific paths via the Framework Path Map.

When multiple URLs are provided, process them independently and in parallel where possible, while keeping each site's extraction artifacts isolated in dedicated folders (for example, `docs/research/<hostname>/`).

This is not a two-phase process (inspect then build). You are a **foreman walking the job site** — as you inspect each section of the page, you write a detailed specification to a file, then hand that file to a specialist builder agent with everything they need. Extraction and construction happen in parallel, but extraction is meticulous and produces auditable artifacts.

## Browser Automation: SuperDuck

All browser interaction goes through the `superduck` CLI via Bash. SuperDuck controls the user's real Chrome/Edge browser — same cookies, same login state, no headless browser. This means you can clone sites the user is logged into, and sites behind region restrictions (as long as the user's browser can reach them).

**Tab lifecycle:** Every command targets a tab by ID. Open one at the start and reuse it:
```bash
superduck doctor                    # verify install
TAB=$(superduck tab_group new | grep -o 'Tab ID: [0-9]*' | grep -o '[0-9]*')
superduck --tab "$TAB" navigate https://example.com/
superduck --tab "$TAB" context       # verify page loaded
```

**Executing JavaScript:** Use `superduck --tab "$TAB" exec '<js>'` to run JS in the page and capture stdout. This is your primary extraction tool — `getComputedStyle()`, DOM walks, asset enumeration, all run through `exec`.

**CRITICAL — strip the Tab Context trailer:** `exec` appends a human-readable `Tab Context` block after the JS result. Never `JSON.parse` the raw stdout. Strip it first. Define this helper once per session and pipe every extraction through it:
```bash
strip_tc() { awk '/^Tab Context:/{exit} {print}'; }

# Usage:
superduck --tab "$TAB" exec "$JS" | strip_tc
```

**Quoting:** For short JS, wrap in single quotes and use double quotes inside the JS. For long scripts (the asset-discovery and style-extraction blocks below), pipe the JS via a heredoc to avoid quoting hell:
```bash
superduck --tab "$TAB" exec "$(cat <<'JS'
JSON.stringify({ title: document.title, url: location.href })
JS
)" | strip_tc
```

**Full command reference:** This section covers the SuperDuck commands used most during a clone (`navigate`, `exec`, `screenshot`, `zoom`, `scroll`, `left_click`, `hover`, `resize`, `read_page`). For any other command — `form_input`, `network`/`console` monitoring, `tab_group` management, `key`, `upload`, etc. — run `superduck --help` to list all commands and `superduck <command> --help` for version-specific syntax. The CLI help is the authoritative, always up-to-date reference.

## Scope Defaults

The target is whatever page `$ARGUMENTS` resolves to. Clone exactly what's visible at that URL. Unless the user specifies otherwise, use these defaults:

- **Fidelity level:** Pixel-perfect — exact match in colors, spacing, typography, animations
- **In scope:** Visual layout and styling, component structure and interactions, responsive design, mock data for demo purposes
- **Out of scope:** Real backend / database, authentication, real-time features, SEO optimization, accessibility audit
- **Customization:** None — pure emulation

If the user provides additional instructions (specific fidelity level, customizations, extra context), honor those over the defaults.

## Pre-Flight

0. **Select the target framework.** Parse `--framework nextjs|tanstack` from `$ARGUMENTS` (default: `nextjs`). Set shell vars for the rest of the session:
   ```bash
   case "$FW_FLAG" in
     tanstack) FW=tanstack-start; TPL=templates/tanstack-start ;;
     *)        FW=nextjs;         TPL=templates/nextjs ;;
   esac
   ```
   All subsequent `npm run` commands MUST run inside the selected workspace: `npm -w "$FW" run <script>`. All file paths below are relative to the repo root unless noted; translate Next.js-conventional paths via the **Framework Path Map**:

   | What | Next.js (`FW=nextjs`, `templates/nextjs/`) | TanStack Start (`FW=tanstack-start`, `templates/tanstack-start/`) |
   |------|--------------------------------------------|-------------------------------------------------------------------|
   | Root layout / HTML shell | `src/app/layout.tsx` — `export const metadata`, `next/font/google` or `next/font/local` | `src/routes/__root.tsx` — `head()` returns `{ meta, links }`, fonts via `@import "@fontsource-variable/<name>"` at top of `src/styles/app.css` |
   | Home page | `src/app/page.tsx` — `export default function Page()` | `src/routes/index.tsx` — `createFileRoute('/')({ component })` |
   | Nested page `/foo/bar` | `src/app/foo/bar/page.tsx` | `src/routes/foo/bar.tsx` — `createFileRoute('/foo/bar')(...)` |
   | Global CSS | `src/app/globals.css` | `src/styles/app.css` |
   | Fonts | `next/font/google` / `next/font/local` in `layout.tsx`; sets `--font-geist-sans` CSS var | `@import "@fontsource-variable/<name>"` at top of `app.css`; set `--font-sans` / `--font-mono` in the `@theme inline` block |
   | Metadata / SEO | `export const metadata: Metadata` in `layout.tsx` | `head()` on the route — `meta` array + `links` array |
   | Client component | `"use client"` directive at top | Not needed (client-first by default); harmless if present |
   | Path alias | `@/* → ./src/*` | `@/* → ./src/*` (same) |
   | Build / typecheck / lint | `npm -w nextjs run build\|typecheck\|lint` | `npm -w tanstack-start run build\|typecheck\|lint` |
   | Dev server | `npm -w nextjs run dev` (port 3000) | `npm -w tanstack-start run dev` (port 3000) |

   When a step below says "update `layout.tsx`" or "update `globals.css`", translate it via this map. When it says `npm run build`, run `npm -w "$FW" run build`.

1. **SuperDuck is a hard prerequisite — do not proceed until it passes.** Run `superduck doctor` to verify the extension and native host are working. If it fails, STOP: tell the user to run `superduck setup` and retry, and do not begin any other step until `superduck doctor` exits clean. Then open a tab and verify it can navigate:
   ```bash
   TAB=$(superduck tab_group new | grep -o 'Tab ID: [0-9]*' | grep -o '[0-9]*')
   superduck --tab "$TAB" navigate https://example.com/
   superduck --tab "$TAB" context
   ```
   If `superduck` is not installed, ask the user to install it (`npm install -g superduck-cli && superduck setup`) before proceeding. SuperDuck is the only browser backend this skill supports — there is no fallback to a browser MCP, Playwright, Puppeteer, or any other tool. If the user cannot install SuperDuck, the clone cannot run; tell them so and stop.
2. Parse `$ARGUMENTS` as one or more URLs. Normalize and validate each URL; if any are invalid, ask the user to correct them before proceeding. For each valid URL, navigate to it via `superduck --tab "$TAB" navigate <url>` and verify with `context`.
3. Verify the base project builds: `npm -w "$FW" run build`. The selected template's shadcn/ui + Tailwind v4 scaffold should already be in place under `templates/$FW/`. If not, tell the user to set it up first.
4. Create the output directories if they don't exist: `docs/research/`, `docs/research/components/`, `docs/design-references/`, `scripts/`. For multiple clones, also prepare per-site folders like `docs/research/<hostname>/` and `docs/design-references/<hostname>/`.
5. When working with multiple sites in one command, optionally confirm whether to run them in parallel (recommended, if resources allow) or sequentially to avoid overload.

## Guiding Principles

These are the truths that separate a successful clone from a "close enough" mess. Internalize them — they should inform every decision you make.

### 1. Completeness Beats Speed

Every builder agent must receive **everything** it needs to do its job perfectly: screenshot, exact CSS values, downloaded assets with local paths, real text content, component structure. If a builder has to guess anything — a color, a font size, a padding value — you have failed at extraction. Take the extra minute to extract one more property rather than shipping an incomplete brief.

### 2. Small Tasks, Perfect Results

When an agent gets "build the entire features section," it glosses over details — it approximates spacing, guesses font sizes, and produces something "close enough" but clearly wrong. When it gets a single focused component with exact CSS values, it nails it every time.

Look at each section and judge its complexity. A simple banner with a heading and a button? One agent. A complex section with 3 different card variants, each with unique hover states and internal layouts? One agent per card variant plus one for the section wrapper. When in doubt, make it smaller.

**Complexity budget rule:** If a builder prompt exceeds ~150 lines of spec content, the section is too complex for one agent. Break it into smaller pieces. This is a mechanical check — don't override it with "but it's all related."

### 3. Real Content, Real Assets

Extract the actual text, images, videos, and SVGs from the live site. This is a clone, not a mockup. Use `element.textContent`, download every `<img>` and `<video>`, extract inline `<svg>` elements as React components. The only time you generate content is when something is clearly server-generated and unique per session.

**Layered assets matter.** A section that looks like one image is often multiple layers — a background watercolor/gradient, a foreground UI mockup PNG, an overlay icon. Inspect each container's full DOM tree and enumerate ALL `<img>` elements and background images within it, including absolutely-positioned overlays. Missing an overlay image makes the clone look empty even if the background is correct.

### 4. Foundation First

Nothing can be built until the foundation exists: global CSS with the target site's design tokens (colors, fonts, spacing), TypeScript types for the content structures, and global assets (fonts, favicons). This is sequential and non-negotiable. Everything after this can be parallel.

### 5. Extract How It Looks AND How It Behaves

A website is not a screenshot — it's a living thing. Elements move, change, appear, and disappear in response to scrolling, hovering, clicking, resizing, and time. If you only extract the static CSS of each element, your clone will look right in a screenshot but feel dead when someone actually uses it.

For every element, extract its **appearance** (exact computed CSS via `getComputedStyle()`) AND its **behavior** (what changes, what triggers the change, and how the transition happens). Not "it looks like 16px" — extract the actual computed value. Not "the nav changes on scroll" — document the exact trigger (scroll position, IntersectionObserver threshold, viewport intersection), the before and after states (both sets of CSS values), and the transition (duration, easing, CSS transition vs. JS-driven vs. CSS `animation-timeline`).

Examples of behaviors to watch for — these are illustrative, not exhaustive. The page may do things not on this list, and you must catch those too:
- A navbar that shrinks, changes background, or gains a shadow after scrolling past a threshold
- Elements that animate into view when they enter the viewport (fade-up, slide-in, stagger delays)
- Sections that snap into place on scroll (`scroll-snap-type`)
- Parallax layers that move at different rates than the scroll
- Hover states that animate (not just change — the transition duration and easing matter)
- Dropdowns, modals, accordions with enter/exit animations
- Scroll-driven progress indicators or opacity transitions
- Auto-playing carousels or cycling content
- Dark-to-light (or any theme) transitions between page sections
- **Tabbed/pill content that cycles** — buttons that switch visible card sets with transitions
- **Scroll-driven tab/accordion switching** — sidebars where the active item auto-changes as content scrolls past (IntersectionObserver, NOT click handlers)
- **Smooth scroll libraries** (Lenis, Locomotive Scroll) — check for `.lenis` class or scroll container wrappers

### 6. Identify the Interaction Model Before Building

This is the single most expensive mistake in cloning: building a click-based UI when the target site is scroll-driven, or vice versa. Before writing any builder prompt for an interactive section, you must definitively answer: **Is this section driven by clicks, scrolls, hovers, time, or some combination?**

How to determine this:
1. **Don't click first.** Scroll through the section slowly and observe if things change on their own as you scroll. Use `superduck --tab "$TAB" scroll <x> <y> --direction down --amount 5` and watch via screenshots.
2. If they do, it's scroll-driven. Extract the mechanism: `IntersectionObserver`, `scroll-snap`, `position: sticky`, `animation-timeline`, or JS scroll listeners.
3. If nothing changes on scroll, THEN click/hover to test for click/hover-driven interactivity.
4. Document the interaction model explicitly in the component spec: "INTERACTION MODEL: scroll-driven with IntersectionObserver" or "INTERACTION MODEL: click-to-switch with opacity transition."

A section with a sticky sidebar and scrolling content panels is fundamentally different from a tabbed interface where clicking switches content. Getting this wrong means a complete rewrite, not a CSS tweak.

### 7. Extract Every State, Not Just the Default

Many components have multiple visual states — a tab bar shows different cards per tab, a header looks different at scroll position 0 vs 100, a card has hover effects. You must extract ALL states, not just whatever is visible on page load.

For tabbed/stateful content:
- Click each tab/button via `superduck --tab "$TAB" left_click --ref <ref>` (get refs from `read_page --filter interactive` first)
- Extract the content, images, and card data for EACH state
- Record which content belongs to which state
- Note the transition animation between states (opacity, slide, fade, etc.)

For scroll-dependent elements:
- Capture computed styles at scroll position 0 (initial state)
- Scroll past the trigger threshold via `superduck --tab "$TAB" exec 'window.scrollTo(0, N)'` and capture computed styles again (scrolled state)
- Diff the two to identify exactly which CSS properties change
- Record the transition CSS (duration, easing, properties)
- Record the exact trigger threshold (scroll position in px, or viewport intersection ratio)

### 8. Spec Files Are the Source of Truth

Every component gets a specification file in `docs/research/components/` BEFORE any builder is dispatched. This file is the contract between your extraction work and the builder agent. The builder receives the spec file contents inline in its prompt — the file also persists as an auditable artifact that the user (or you) can review if something looks wrong.

The spec file is not optional. It is not a nice-to-have. If you dispatch a builder without first writing a spec file, you are shipping incomplete instructions based on whatever you can remember from a browser session, and the builder will guess to fill gaps.

### 9. Build Must Always Compile

Every builder agent must verify `npm -w "$FW" run typecheck` passes before finishing. After merging worktrees, you verify `npm -w "$FW" run build` passes. A broken build is never acceptable, even temporarily. Builder agents work inside the `templates/$FW/` directory, so they can also run `npx tsc --noEmit` directly from there.

## Phase 1: Reconnaissance

Navigate to the target URL:
```bash
superduck --tab "$TAB" navigate <url>
superduck --tab "$TAB" context
sleep 2  # let dynamic content settle
```

### Screenshots

Take **full-page screenshots** at desktop (1440px) and mobile (390px) viewports using the stitching helper (SuperDuck's `screenshot` only captures the viewport, so the helper scrolls and stitches):
```bash
bash scripts/fullpage-screenshot.sh "$TAB" 1440 docs/design-references/<name>-desktop.png
bash scripts/fullpage-screenshot.sh "$TAB" 390 docs/design-references/<name>-mobile.png
```
These are your master reference — builders will receive section-specific crops/screenshots later.

For section-specific screenshots during extraction, use `zoom` (captures a rectangular region) or scroll the section into view and capture the viewport:
```bash
superduck --tab "$TAB" scroll_to --ref <ref>
superduck --tab "$TAB" screenshot --output docs/design-references/<section>.jpg
# Or capture a specific region:
superduck --tab "$TAB" zoom 100 200 800 600 --output docs/design-references/<section>.jpg
```

### Global Extraction

Extract these from the page before doing anything else. All JS runs via `superduck --tab "$TAB" exec` — remember to pipe through `strip_tc`.

**Fonts** — Inspect `<link>` tags for Google Fonts or self-hosted fonts. Check computed `font-family` on key elements (headings, body, code, labels). Document every family, weight, and style actually used. Configure them per the Framework Path Map: Next.js uses `next/font/google` or `next/font/local` in `layout.tsx`; TanStack Start uses `@import "@fontsource-variable/<name>"` (or `@fontsource/<name>` for non-variable fonts) at the top of `src/styles/app.css`, plus the matching `--font-sans` / `--font-mono` entries in the `@theme inline` block.

```bash
superduck --tab "$TAB" exec "$(cat <<'JS'
JSON.stringify({
  linkTags: [...document.querySelectorAll('link[href*="fonts"]')].map(l => ({ href: l.href, rel: l.rel })),
  fontFamilies: [...new Set([...document.querySelectorAll('*')].slice(0, 300).map(el => getComputedStyle(el).fontFamily))]
})
JS
)" | strip_tc
```

**Colors** — Extract the site's color palette from computed styles across the page. Update the template's global CSS (see Framework Path Map: `src/app/globals.css` for Next.js, `src/styles/app.css` for TanStack Start) with the target's actual colors in the `:root` and `.dark` CSS variable blocks. Map them to shadcn's token names (background, foreground, primary, muted, etc.) where they fit. Add custom properties for colors that don't map to shadcn tokens.

**Favicons & Meta** — Download favicons, apple-touch-icons, OG images, webmanifest to `templates/$FW/public/seo/`. Update metadata in the root layout (see Framework Path Map: `layout.tsx` `export const metadata` for Next.js, `__root.tsx` `head()` for TanStack Start). Enumerate them via `exec`:
```bash
superduck --tab "$TAB" exec "$(cat <<'JS'
JSON.stringify([...document.querySelectorAll('link[rel*="icon"], link[rel="manifest"], link[rel="apple-touch-icon"], meta[property*="og:"]')].map(l => ({ rel: l.rel, href: l.href || l.content, sizes: l.sizes?.toString() })))
JS
)" | strip_tc
```

**Global UI patterns** — Identify any site-wide CSS or JS: custom scrollbar hiding, scroll-snap on the page container, global keyframe animations, backdrop filters, gradients used as overlays, **smooth scroll libraries** (Lenis, Locomotive Scroll — check for `.lenis`, `.locomotive-scroll`, or custom scroll container classes). Add these to the template's global CSS (see Framework Path Map) and note any libraries that need to be installed.

### Mandatory Interaction Sweep

This is a dedicated pass AFTER screenshots and BEFORE anything else. Its purpose is to discover every behavior on the page — many of which are invisible in a static screenshot.

**Scroll sweep:** Scroll the page slowly from top to bottom. At each section, pause and observe:
```bash
superduck --tab "$TAB" exec 'window.scrollTo(0, 0)'   # reset to top
superduck --tab "$TAB" scroll 800 700 --direction down --amount 3
superduck --tab "$TAB" screenshot --output /tmp/scroll-check-1.jpg
# repeat in increments, screenshotting after each scroll
```
At each section, observe:
- Does the header change appearance? Record the scroll position where it triggers.
- Do elements animate into view? Record which ones and the animation type.
- Does a sidebar or tab indicator auto-switch as you scroll? Record the mechanism.
- Are there scroll-snap points? Record which containers.
- Is there a smooth scroll library active? Check via `exec 'typeof lenis !== "undefined" || document.querySelector(".lenis")?.className'`.

**Click sweep:** Click every element that looks interactive. Get refs first, then click:
```bash
superduck --tab "$TAB" read_page --filter interactive
superduck --tab "$TAB" left_click --ref ref_3
superduck --tab "$TAB" screenshot --output /tmp/click-after-ref3.jpg
```
- Every button, tab, pill, link, card
- Record what happens: does content change? Does a modal open? Does a dropdown appear?
- For tabs/pills: click EACH ONE and record the content that appears for each state

**Hover sweep:** Hover over every element that might have hover states:
```bash
superduck --tab "$TAB" hover --ref ref_4
superduck --tab "$TAB" screenshot --output /tmp/hover-ref4.jpg
```
- Buttons, cards, links, images, nav items
- Record what changes: color, scale, shadow, underline, opacity

**Responsive sweep:** Test at 3 viewport widths:
```bash
superduck --tab "$TAB" resize 1440 900   # desktop
superduck --tab "$TAB" resize 768 1024   # tablet
superduck --tab "$TAB" resize 390 844    # mobile
```
At each width, note which sections change layout (column → stack, sidebar disappears, etc.) and at approximately which breakpoint the change occurs.

Save all findings to `docs/research/BEHAVIORS.md`. This is your behavior bible — reference it when writing every component spec.

### Page Topology

Map out every distinct section of the page from top to bottom. Give each a working name. Document:
- Their visual order
- Which are fixed/sticky overlays vs. flow content
- The overall page layout (scroll container, column structure, z-index layers)
- Dependencies between sections (e.g., a floating nav that overlays everything)
- **The interaction model** of each section (static, click-driven, scroll-driven, time-driven)

Save this as `docs/research/PAGE_TOPOLOGY.md` — it becomes your assembly blueprint.

## Phase 2: Foundation Build

This is sequential. Do it yourself (not delegated to an agent) since it touches many files. All paths are under `templates/$FW/` — translate via the Framework Path Map.

1. **Update fonts** in the root layout (see Framework Path Map) to match the target site's actual fonts. Next.js: `next/font/google` or `next/font/local` in `layout.tsx`. TanStack Start: `@import "@fontsource-variable/<name>"` at the top of `src/styles/app.css` and set `--font-sans` / `--font-mono` in the `@theme inline` block.
2. **Update the template's global CSS** (see Framework Path Map) with the target's color tokens, spacing values, keyframe animations, utility classes, and any **global scroll behaviors** (Lenis, smooth scroll CSS, scroll-snap on body)
3. **Create TypeScript interfaces** in `templates/$FW/src/types/` for the content structures you've observed
4. **Extract SVG icons** — find all inline `<svg>` elements on the page, deduplicate them, and save as named React components in `templates/$FW/src/components/icons.tsx`. Name them by visual function (e.g., `SearchIcon`, `ArrowRightIcon`, `LogoIcon`).
5. **Download global assets** — write and run a Node.js script (`scripts/download-assets.mjs`) that downloads all images, videos, and other binary assets from the page to `templates/$FW/public/`. Preserve meaningful directory structure.
6. Verify: `npm -w "$FW" run build` passes

### Asset Discovery Script Pattern

Use `superduck exec` to enumerate all assets on the page, then pipe through `strip_tc` to get clean JSON:

```bash
superduck --tab "$TAB" exec "$(cat <<'JS'
JSON.stringify({
  images: [...document.querySelectorAll('img')].map(img => ({
    src: img.src || img.currentSrc,
    alt: img.alt,
    width: img.naturalWidth,
    height: img.naturalHeight,
    parentClasses: img.parentElement?.className,
    siblings: img.parentElement ? [...img.parentElement.querySelectorAll('img')].length : 0,
    position: getComputedStyle(img).position,
    zIndex: getComputedStyle(img).zIndex
  })),
  videos: [...document.querySelectorAll('video')].map(v => ({
    src: v.src || v.querySelector('source')?.src,
    poster: v.poster,
    autoplay: v.autoplay,
    loop: v.loop,
    muted: v.muted
  })),
  backgroundImages: [...document.querySelectorAll('*')].filter(el => {
    const bg = getComputedStyle(el).backgroundImage;
    return bg && bg !== 'none';
  }).map(el => ({
    url: getComputedStyle(el).backgroundImage,
    element: el.tagName + '.' + el.className?.split(' ')[0]
  })),
  svgCount: document.querySelectorAll('svg').length,
  fonts: [...new Set([...document.querySelectorAll('*')].slice(0, 200).map(el => getComputedStyle(el).fontFamily))],
  favicons: [...document.querySelectorAll('link[rel*="icon"]')].map(l => ({ href: l.href, sizes: l.sizes?.toString() }))
})
JS
)" | strip_tc
```

Then write a download script that fetches everything to `public/`. Use batched parallel downloads (4 at a time) with proper error handling. The download itself runs in Node.js (via `fetch`), not in the browser — SuperDuck only enumerates the URLs.

## Phase 3: Component Specification & Dispatch

This is the core loop. For each section in your page topology (top to bottom), you do THREE things: **extract**, **write the spec file**, then **dispatch builders**.

### Step 1: Extract

For each section, use SuperDuck to extract everything:

1. **Screenshot** the section in isolation. Scroll it into view, then capture:
   ```bash
   superduck --tab "$TAB" scroll_to --ref <ref_of_section>
   superduck --tab "$TAB" screenshot --output docs/design-references/<section>.jpg
   ```
   Or capture a specific region with `zoom x y w h --output`.

2. **Extract CSS** for every element in the section. Use the extraction script below — don't hand-measure individual properties. Run it once per component container and capture the full output. Pass the selector as an argument by replacing `SELECTOR` in the JS:

   ```bash
   superduck --tab "$TAB" exec "$(cat <<'JS'
   (function(selector) {
     const el = document.querySelector(selector);
     if (!el) return JSON.stringify({ error: 'Element not found: ' + selector });
     const props = [
       'fontSize','fontWeight','fontFamily','lineHeight','letterSpacing','color',
       'textTransform','textDecoration','backgroundColor','background',
       'padding','paddingTop','paddingRight','paddingBottom','paddingLeft',
       'margin','marginTop','marginRight','marginBottom','marginLeft',
       'width','height','maxWidth','minWidth','maxHeight','minHeight',
       'display','flexDirection','justifyContent','alignItems','gap',
       'gridTemplateColumns','gridTemplateRows',
       'borderRadius','border','borderTop','borderBottom','borderLeft','borderRight',
       'boxShadow','overflow','overflowX','overflowY',
       'position','top','right','bottom','left','zIndex',
       'opacity','transform','transition','cursor',
       'objectFit','objectPosition','mixBlendMode','filter','backdropFilter',
       'whiteSpace','textOverflow','WebkitLineClamp'
     ];
     function extractStyles(element) {
       const cs = getComputedStyle(element);
       const styles = {};
       props.forEach(p => { const v = cs[p]; if (v && v !== 'none' && v !== 'normal' && v !== 'auto' && v !== '0px' && v !== 'rgba(0, 0, 0, 0)') styles[p] = v; });
       return styles;
     }
     function walk(element, depth) {
       if (depth > 4) return null;
       const children = [...element.children];
       return {
         tag: element.tagName.toLowerCase(),
         classes: element.className?.toString().split(' ').slice(0, 5).join(' '),
         text: element.childNodes.length === 1 && element.childNodes[0].nodeType === 3 ? element.textContent.trim().slice(0, 200) : null,
         styles: extractStyles(element),
         images: element.tagName === 'IMG' ? { src: element.src, alt: element.alt, naturalWidth: element.naturalWidth, naturalHeight: element.naturalHeight } : null,
         childCount: children.length,
         children: children.slice(0, 20).map(c => walk(c, depth + 1)).filter(Boolean)
       };
     }
     return JSON.stringify(walk(el, 0), null, 2);
   })('SELECTOR')
   JS
   )" | strip_tc
   ```

3. **Extract multi-state styles** — for any element with multiple states (scroll-triggered, hover, active tab), capture BOTH states:
   ```bash
   # State A: capture styles at current state (e.g., scroll position 0)
   superduck --tab "$TAB" exec 'window.scrollTo(0, 0)'
   # run the extraction script above → save as State A

   # Trigger the state change
   superduck --tab "$TAB" exec 'window.scrollTo(0, 500)'   # scroll
   # OR: superduck --tab "$TAB" left_click --ref ref_3      # click
   # OR: superduck --tab "$TAB" hover --ref ref_4            # hover

   # State B: re-run the extraction script on the same element
   # The diff between A and B IS the behavior specification
   ```
   Record the diff explicitly: "Property X changes from VALUE_A to VALUE_B, triggered by TRIGGER, with transition: TRANSITION_CSS."

4. **Extract real content** — all text, alt attributes, aria labels, placeholder text. Use `element.textContent` for each text node. For tabbed/stateful content, **click each tab and extract content per state**.

5. **Identify assets** this section uses — which downloaded images/videos from `public/`, which icon components from `icons.tsx`. Check for **layered images** (multiple `<img>` or background-images stacked in the same container).

6. **Assess complexity** — how many distinct sub-components does this section contain? A distinct sub-component is an element with its own unique styling, structure, and behavior (e.g., a card, a nav item, a search panel).

### Step 2: Write the Component Spec File

For each section (or sub-component, if you're breaking it up), create a spec file in `docs/research/components/`. This is NOT optional — every builder must have a corresponding spec file.

**File path:** `docs/research/components/<component-name>.spec.md`

**Template:**

```markdown
# <ComponentName> Specification

## Overview
- **Target file:** `src/components/<ComponentName>.tsx`
- **Screenshot:** `docs/design-references/<screenshot-name>.png`
- **Interaction model:** <static | click-driven | scroll-driven | time-driven>

## DOM Structure
<Describe the element hierarchy — what contains what>

## Computed Styles (exact values from getComputedStyle)

### Container
- display: ...
- padding: ...
- maxWidth: ...
- (every relevant property with exact values)

### <Child element 1>
- fontSize: ...
- color: ...
- (every relevant property)

### <Child element N>
...

## States & Behaviors

### <Behavior name, e.g., "Scroll-triggered floating mode">
- **Trigger:** <exact mechanism — scroll position 50px, IntersectionObserver rootMargin "-30% 0px", click on .tab-button, hover>
- **State A (before):** maxWidth: 100vw, boxShadow: none, borderRadius: 0
- **State B (after):** maxWidth: 1200px, boxShadow: 0 4px 20px rgba(0,0,0,0.1), borderRadius: 16px
- **Transition:** transition: all 0.3s ease
- **Implementation approach:** <CSS transition + scroll listener | IntersectionObserver | CSS animation-timeline | etc.>

### Hover states
- **<Element>:** <property>: <before> → <after>, transition: <value>

## Per-State Content (if applicable)

### State: "Featured"
- Title: "..."
- Subtitle: "..."
- Cards: [{ title, description, image, link }, ...]

### State: "Productivity"
- Title: "..."
- Cards: [...]

## Assets
- Background image: `public/images/<file>.webp`
- Overlay image: `public/images/<file>.png`
- Icons used: <ArrowIcon>, <SearchIcon> from icons.tsx

## Text Content (verbatim)
<All text content, copy-pasted from the live site>

## Responsive Behavior
- **Desktop (1440px):** <layout description>
- **Tablet (768px):** <what changes — e.g., "maintains 2-column, gap reduces to 16px">
- **Mobile (390px):** <what changes — e.g., "stacks to single column, images full-width">
- **Breakpoint:** layout switches at ~<N>px
```

Fill every section. If a section doesn't apply (e.g., no states for a static footer), write "N/A" — but think twice before marking States & Behaviors as N/A. Even a footer might have hover states on links.

### Step 3: Dispatch Builders

Based on complexity, dispatch builder agent(s) in worktree(s):

**Simple section** (1-2 sub-components): One builder agent gets the entire section.

**Complex section** (3+ distinct sub-components): Break it up. One agent per sub-component, plus one agent for the section wrapper that imports them. Sub-component builders go first since the wrapper depends on them.

**What every builder agent receives:**
- The full contents of its component spec file (inline in the prompt — don't say "go read the spec file")
- Path to the section screenshot in `docs/design-references/`
- Which shared components to import (`icons.tsx`, `cn()`, shadcn primitives)
- The target file path (e.g., `src/components/HeroSection.tsx`)
- Instruction to verify with `npm -w "$FW" run typecheck` before finishing
- For responsive behavior: the specific breakpoint values and what changes

**Don't wait.** As soon as you've dispatched the builder(s) for one section, move to extracting the next section. Builders work in parallel in their worktrees while you continue extraction.

### Step 4: Merge

As builder agents complete their work:
- Merge their worktree branches into main
- You have full context on what each agent built, so resolve any conflicts intelligently
- After each merge, verify the build still passes: `npm -w "$FW" run build`
- If a merge introduces type errors, fix them immediately

The extract → spec → dispatch → merge cycle continues until all sections are built.

## Phase 4: Page Assembly

After all sections are built and merged, wire everything together in the home page route (see Framework Path Map: `src/app/page.tsx` for Next.js, `src/routes/index.tsx` — inside the `createFileRoute('/')` component — for TanStack Start):

- Import all section components
- Implement the page-level layout from your topology doc (scroll containers, column structures, sticky positioning, z-index layering)
- Connect real content to component props
- Implement page-level behaviors: scroll snap, scroll-driven animations, dark-to-light transitions, intersection observers, smooth scroll (Lenis etc.)
- Verify: `npm -w "$FW" run build` passes clean

## Phase 5: Visual QA Diff

After assembly, do NOT declare the clone complete. Take side-by-side comparison screenshots:

1. Open the target site in one SuperDuck tab and your clone dev server (`npm -w "$FW" run dev`) in another:
   ```bash
   TAB_ORIG=$(superduck tab_group new | grep -o 'Tab ID: [0-9]*' | grep -o '[0-9]*')
   superduck --tab "$TAB_ORIG" navigate <target-url>
   TAB_CLONE=$(superduck tab_group new | grep -o 'Tab ID: [0-9]*' | grep -o '[0-9]*')
   superduck --tab "$TAB_CLONE" navigate http://localhost:3000
   ```
2. Compare section by section, top to bottom, at desktop (1440px):
   ```bash
   superduck --tab "$TAB_ORIG" resize 1440 900
   superduck --tab "$TAB_CLONE" resize 1440 900
   # screenshot both at matching scroll positions
   ```
3. Compare again at mobile (390px) via `resize 390 844`.
4. For each discrepancy found:
   - Check the component spec file — was the value extracted correctly?
   - If the spec was wrong: re-extract via `superduck exec`, update the spec, fix the component
   - If the spec was right but the builder got it wrong: fix the component to match the spec
5. Test all interactive behaviors: scroll through the page (`superduck --tab "$TAB" scroll ...`), click every button/tab (`left_click --ref ...`), hover over interactive elements (`hover --ref ...`)
6. Verify smooth scroll feels right, header transitions work, tab switching works, animations play

Only after this visual QA pass is the clone complete.

## Pre-Dispatch Checklist

Before dispatching ANY builder agent, verify you can check every box. If you can't, go back and extract more.

- [ ] Spec file written to `docs/research/components/<name>.spec.md` with ALL sections filled
- [ ] Every CSS value in the spec is from `getComputedStyle()` (via `superduck exec`), not estimated
- [ ] Interaction model is identified and documented (static / click / scroll / time)
- [ ] For stateful components: every state's content and styles are captured
- [ ] For scroll-driven components: trigger threshold, before/after styles, and transition are recorded
- [ ] For hover states: before/after values and transition timing are recorded
- [ ] All images in the section are identified (including overlays and layered compositions)
- [ ] Responsive behavior is documented for at least desktop and mobile
- [ ] Text content is verbatim from the site, not paraphrased
- [ ] The builder prompt is under ~150 lines of spec; if over, the section needs to be split

## What NOT to Do

These are lessons from previous failed clones — each one cost hours of rework:

- **Don't build click-based tabs when the target site is scroll-driven (or vice versa).** Determine the interaction model FIRST by scrolling before clicking. This is the #1 most expensive mistake — it requires a complete rewrite, not a CSS fix.
- **Don't extract only the default state.** If there are tabs showing "Featured" on load, click Productivity, Creative, Lifestyle and extract each one's cards/content. If the header changes on scroll, capture styles at position 0 AND position 100+.
- **Don't miss overlay/layered images.** A background watercolor + foreground UI mockup = 2 images. Check every container's DOM tree for multiple `<img>` elements and positioned overlays.
- **Don't build mockup components for content that's actually videos/animations.** Check if a section uses `<video>`, Lottie, or canvas before building elaborate HTML mockups of what the video shows.
- **Don't approximate CSS classes.** "It looks like `text-lg`" is wrong if the computed value is `18px` and `text-lg` is `18px/28px` but the actual line-height is `24px`. Extract exact values.
- **Don't build everything in one monolithic commit.** The whole point of this pipeline is incremental progress with verified builds at each step.
- **Don't reference docs from builder prompts.** Each builder gets the CSS spec inline in its prompt — never "see DESIGN_TOKENS.md for colors." The builder should have zero need to read external docs.
- **Don't skip asset extraction.** Without real images, videos, and fonts, the clone will always look fake regardless of how perfect the CSS is.
- **Don't give a builder agent too much scope.** If you're writing a builder prompt and it's getting long because the section is complex, that's a signal to break it into smaller tasks.
- **Don't bundle unrelated sections into one agent.** A CTA section and a footer are different components with different designs — don't hand them both to one agent and hope for the best.
- **Don't skip responsive extraction.** If you only inspect at desktop width, the clone will break at tablet and mobile. Test at 1440, 768, and 390 during extraction.
- **Don't forget smooth scroll libraries.** Check for Lenis (`.lenis` class), Locomotive Scroll, or similar. Default browser scrolling feels noticeably different and the user will spot it immediately.
- **Don't dispatch builders without a spec file.** The spec file forces exhaustive extraction and creates an auditable artifact. Skipping it means the builder gets whatever you can fit in a prompt from memory.
- **Don't `JSON.parse` raw `superduck exec` output.** It always has a trailing `Tab Context` block. Pipe through `strip_tc` (or split on `/\n\s*\nTab Context:/`) first, or you'll get parse errors and silently lose data.
- **Don't use a stale tab ref without `context`.** If `navigate` or `left_click` behaves unexpectedly, run `superduck --tab "$TAB" context` to confirm the tab is still on the expected page. Tabs can redirect or close.

## Completion

When done, report:
- Total sections built
- Total components created
- Total spec files written (should match components)
- Total assets downloaded (images, videos, SVGs, fonts)
- Build status (`npm -w "$FW" run build` result)
- Visual QA results (any remaining discrepancies)
- Any known gaps or limitations

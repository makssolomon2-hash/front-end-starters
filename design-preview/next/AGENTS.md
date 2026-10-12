# AGENTS.md

## 0. Agent role
Act as a senior frontend engineer. Read this file and the relevant source before making changes. Keep the starter easy to understand, accessible, and straightforward to remove.

## 1. Project intent
**Product:** A polished, removable technology showcase and starting canvas for a new Next.js application.
**Audience:** Developers evaluating the stack or replacing the demo with their own product.
**Core experience:** A responsive editorial hero, an interactive 3D prism, linked technology cards, and clear guidance for removing the demo.
**Differentiator:** A restrained glass-and-light visual system with a pointer-reactive faceted model and scroll-aware motion.
**Non-goals:** No accounts, database, API, persistence, analytics, content service, or application-specific product features.
**Definition of done:** The app builds, the demo works on desktop and mobile, reduced-motion and unavailable-WebGL states remain usable, and the demo can be removed without disturbing the Next.js foundation.

## 2. How to work
1. Inspect the relevant app routes, components, styles, and package scripts before editing.
2. Keep changes within the requested scope and preserve accessible semantics.
3. Run the relevant lint, type, and production-build checks after changes.
4. Report the files changed and checks run; state any check that could not run.

## 3. Architecture and boundaries
**Structure:** Single Next.js App Router application under `src/app`.
**Server/client:** Keep the root layout and route as Server Components. Browser animation and WebGL belong only in `src/components/StarterExperience.tsx` and `src/components/PrismScene.tsx`.
**Data:** No application data or secrets. Technology cards link to public documentation.
**Third parties:** No service integrations. Do not add client-side secrets or remote data dependencies.

## 4. Tech stack
- Next.js App Router and React
- TypeScript
- Tailwind CSS v4, imported from `src/app/globals.css`
- GSAP and ScrollTrigger for progressive entrance and card-reveal motion
- Three.js for the responsive, pointer-reactive prism

## 5. Key decisions
- The dark glass visual treatment is the demo, not a required product design.
- Keep all demo UI in `StarterExperience.tsx`, its styles in `globals.css`, and WebGL resources in `PrismScene.tsx`.
- Respect `prefers-reduced-motion`; cap the WebGL pixel ratio and dispose all Three.js resources.
- A failed WebGL initialization must leave an informative fallback, not a blank panel.
- Preserve normal Next.js server rendering outside the isolated client components.

## 6. Data model
There is no stored or user-generated data. The technology-card list is static presentation content.

## 7. Required checks
- `npm run lint`
- `npx tsc --noEmit`
- `npm run build`
- Manually check responsive layout, pointer interaction, card links, reduced motion, and demo-removal instructions.

## 8. Constraints and gotchas
- This starter targets Tailwind CSS v4; use its CSS-first `@import "tailwindcss"` setup.
- Keep browser APIs, GSAP, and Three.js out of Server Components.
- Clean up animation contexts, observers, event listeners, geometries, materials, and renderer resources.
- Do not reintroduce the default Create Next App landing page or assets.

## 9. When in doubt
Keep the app server-first, the showcase removable, and the interaction lightweight. Avoid adding dependencies or features without a clear need.

<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

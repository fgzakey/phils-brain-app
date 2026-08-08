# Phil's Brain — Android app

The synthesis-and-analysis companion to the Book and YT dashboards. It reads
the **same Phils Library backend and database**, but shows the library-wide,
cross-source layer rather than any single book or video:

- **Essays** — syntopical synthesis essays (the living Adlerian essays that weave one idea/theme across every analyzed source), rendered as Markdown.
- **Graph** — the knowledge graph at the conceptual level: headline counts, a breakdown by node/edge type, a searchable/filterable node list, and per-node detail with typed edges (points-to / pointed-to-by).
- **Praxis** — the themes → goals → projects → tasks spine (serves/enacts edges), with inline add actions. The skeleton for planning and cognitive tools.
- **Scribe** — turn any essay into a whiteboard, memory palace, or knowledge-graph board with AI-painted art. A mnemonic tool.

No credentials live in the app. It calls the dashboard's existing routes
(`/api/essays`, `/api/graph`, `/api/graph/praxis`, `/api/models`, `/api/scribe`)
and authenticates with the same `APP_PASSWORD` (sent as the `book_auth` cookie).

## Build (GitHub Actions — no local toolchain)

Push to `main`; the **Build Android APK** workflow builds a release APK, signs
it with the shared keystore (so updates install in place), and publishes it to
Releases → "Latest APK" plus a permanent `v0.1.0-b<N>` release per push.

The repo ships only `pubspec.yaml` + `lib/`; CI runs `flutter create
--platforms=android .` to generate the Android boilerplate.

## First-run setup

1. Server URL: the Phils Library Space's direct URL (e.g. `https://fgza-book-dashboard.hf.space`).
2. App password: the same `APP_PASSWORD` as the web login.
3. Save & test connection, then pick a model for Visual Scribe.

## Developing

Start with [AGENTS.md](AGENTS.md) — project conventions and institutional knowledge, shared by humans and every coding harness (Claude Code reads it through CLAUDE.md; Codex and Hermes read it natively). Then see [CONTRIBUTING.md](CONTRIBUTING.md) for setup and the PR flow.

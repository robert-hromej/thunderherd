# Contributing to thunderherd

Thanks for your interest! thunderherd is a small, focused tool — contributions
that keep it that way are very welcome.

## Getting set up

```bash
bundle install
npm install
bin/rails db:prepare   # create + migrate + seed demo data
bin/dev                # Rails + the Vite dev server (HMR) → http://localhost:3000
```

You'll also need [`hey`](https://github.com/rakyll/hey) on your `PATH`
(`brew install hey`). See the README's [Configuration](README.md#configuration)
section for the optional environment variables.

## Before you open a PR

Run the full suite — the same checks CI runs. Build the frontend once first
(`bin/vite build`): the request specs render the HTML shell, which references a
Vite entrypoint.

```bash
bundle exec rspec        # backend: models, services, requests, jobs
npm test                 # frontend: Vitest + React Testing Library
npm run test:e2e         # end-to-end: Playwright (boots an isolated server)
bundle exec rubocop      # Ruby style
npm run lint             # JavaScript/React style (ESLint, incl. rules-of-hooks)
bundle exec brakeman -q  # security scan
```

Please keep everything green and add tests for new behaviour. Match the existing
style (RuboCop Omakase for Ruby; the surrounding conventions for React).

## Project layout

- `app/services/load_test/` — the runner (`HeyRunner` wraps `hey`, `Executor`
  orchestrates a run and persists results + context).
- `app/controllers/api/` — the JSON API consumed by the SPA.
- `app/frontend/` — the Vite + React + Ant Design frontend. Pages compose three
  shared pieces: `useCollection`/`mutate` (`src/hooks.js`) for loading and
  mutations, `components/ResourceModal` for create/edit dialogs, and
  `components/tableActions` for the Edit/Delete column. Prefer extending those
  over hand-rolling a fourth variant.
- `db/DATABASE.md` — the data model.

## Scope

thunderherd deliberately delegates load generation to `hey` and stays a thin
orchestration + storage + UI layer. Please open an issue to discuss larger
features before building them.

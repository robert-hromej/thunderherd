# ⚡ thunderherd

[![CI](https://github.com/robert-hromej/thunderherd/actions/workflows/ci.yml/badge.svg)](https://github.com/robert-hromej/thunderherd/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**A self-hostable HTTP endpoint benchmarker that never forgets a result.**

thunderherd fires a burst of concurrent requests at a list of URLs and stores every
run in PostgreSQL *alongside the deploy, environment, machine and network it ran on*
— so six months later you can still answer **"which release made this endpoint
slow?"**. Web UI or CLI, one app and one database, MIT licensed.

> The name is the ["thundering herd"](https://en.wikipedia.org/wiki/Thundering_herd_problem)
> — a swarm of requests hitting a service at once.

---

## Why

Benchmarking an endpoint is easy; *remembering* the answer is not. Most CLI
benchmarkers print a table and forget it, and the mainstream frameworks keep
history only in their paid cloud. thunderherd keeps the numbers **and the context
that makes them comparable** — environment, deployed release, dyno formation,
operator, machine, network — in a schema you can query, not a tag convention you
have to remember.

## What it is not

It fires a **flat burst** at each URL, one URL at a time. There are no ramping
virtual users, no multi-step user journeys, no sessions or think time, no
distributed generation. If you need those, use [k6](https://k6.io),
[Gatling](https://gatling.io) or [Locust](https://locust.io) — see
[Why not just k6 + Grafana?](#why-not-just-k6--grafana) below.

## Features

- **Ruby orchestrates, [`hey`](https://github.com/rakyll/hey) generates the load.** A thin
  Rails service drives the `hey` CLI once per URL — no heavyweight framework.
- **Every run is stored** in Postgres (14 tables) — results and the full run
  context. No more CSV files to lose.
- **Per-URL metrics:** throughput (rps), error rate, min / avg / p50 / p90 / p95 /
  p99 / max, std-dev, a DNS/connect/server/transfer breakdown, and the full
  status-code distribution.
- **Web UI** (React + Ant Design + Recharts): dashboard, runs, run detail with charts,
  a **compare** view for before/after deltas, and full CRUD for sites, environments,
  URLs and run configs. **Or the CLI** via a `rake` task.
- **Reusable run configs** — presets of environment + load params + an optional URL
  subset, driven from both the web form and the CLI.
- **Any HTTP method** (GET/POST/PUT/PATCH/DELETE, optional JSON body).
- **Environments are first-class** — staging vs production, and **production runs
  require an explicit opt-in** so you never nuke a live site by accident.
- **Full run context captured automatically:** who ran it (operator), on what
  machine, over what network (connection kind + RTT), plus — optionally — the target
  app's Heroku dyno formation and deployed release. Browse it all under **Directory**.

## Why not just k6 + Grafana?

Use **k6** (or Gatling, Locust, Artillery) if you need real load *scenarios*:
ramping VUs, multi-step journeys, sessions, distributed generation, CI thresholds.
thunderherd does none of that and never will.

Use **thunderherd** if what you actually want is a *record*. k6 + Prometheus +
Grafana gets you there too — but that is four moving parts, and your run context is
whatever tags you remembered to pass. Here it is one app, one Postgres, and the
context is a **schema, not a tag convention**: environment, deployed release, dyno
formation, operator, machine and network are captured automatically and are
queryable, and the compare view warns you when two runs are not comparable.

Related projects worth knowing about, since this is a crowded category:
[Fortio](https://github.com/fortio/fortio) (own engine, results in JSON files),
[JtlReporter](https://github.com/ludeknovy/jtl-reporter) (ingests JMeter/Taurus
results into TimescaleDB), [Perfana](https://github.com/perfana/perfana) (heavier
Gatling/JMeter/k6 analysis platform) and
[Predator](https://github.com/Zooz/predator) (Artillery + a UI, no longer
maintained).

## Status

v0.1 — feature-complete for what it claims and covered by tests (RSpec, Vitest,
Playwright), but young: it has one author and no production track record yet.
The schema and JSON API may still change. Issues and PRs welcome —
see [CONTRIBUTING.md](CONTRIBUTING.md).

## Requirements

- Ruby 4.0 (as pinned in `.ruby-version`; no lower bound is enforced by the
  Gemfile, but that is the only version CI exercises) and Rails 8.1
- PostgreSQL 14+
- Node 20+ (for the Vite/React frontend)
- [`hey`](https://github.com/rakyll/hey) — `brew install hey` (or `go install github.com/rakyll/hey@latest`)
- `heroku` CLI — optional, only for the dyno-formation/release integration

## Configuration

Everything runs with sensible defaults; every variable below is optional.

| Variable | Effect |
|---|---|
| `THUNDERHERD_HTTP_USER`, `THUNDERHERD_HTTP_PASSWORD` | Lock the whole app (UI + API) behind one shared HTTP Basic credential. Unset = no auth (local dev). |
| `THUNDERHERD_DB` | Override the development database name (handy for an isolated e2e database). |
| `THUNDERHERD_DATABASE_PASSWORD` | Password for the `thunderherd` role in production. |
| `RAILS_MAX_THREADS` | Puma threads and the matching connection-pool size. |
| `THUNDERHERD_NET_LOOKUP=1` | Also resolve ISP/city via ipinfo.io when recording a run's network (one external call; the public IP is stored coarsened to /24, never raw). Off by default — only connection kind and RTT are measured locally. |
| `THUNDERHERD_OPERATOR`, `THUNDERHERD_OPERATOR_EMAIL` | Override the recorded operator (defaults to `git config user.name` / `user.email`). |
| `ALLOW_PROD=1` | Required for `rake loadtest:run` against a production environment. |
| `STORE_SAMPLES=1` | Persist one row per request (`result_samples`) for true histograms. High volume — enable per run. |
| `THUNDERHERD_DISABLE_SSL=1` | Serve plain HTTP in production when you terminate TLS in your own proxy. |

## Quick start

```bash
bundle install
npm install
bin/rails db:prepare   # create + migrate + seed demo data
bin/dev                # Rails + the Vite dev server → http://localhost:3000
```

Open http://localhost:3000, pick an environment, and hit **New run**. Mark a run
with the ★ in the runs list to make it your baseline, then use **Compare** to see
per-page deltas against it.

### Run from the command line

```bash
# by run-config name, or by "<site-key>/<env-name>"
bin/rails "loadtest:run[demo-staging-smoke,100,20,before-caching]"
bin/rails "loadtest:run[demo/staging,50,10]"

# production is refused unless you opt in
ALLOW_PROD=1 bin/rails "loadtest:run[demo/production,10,2,off-peak]"

# import a URL list, compare two runs
bin/rails "loadtest:import[examples/urls.example.txt,MySite,staging]"
bin/rails "loadtest:compare[12,15]"

# keep one row per request (result_samples) for a run you want to analyse deeply
STORE_SAMPLES=1 bin/rails "loadtest:run[demo/staging,100,20,detailed]"
```

A URL-list line is `[METHOD] url [| json-body]` (GET is the default) — see
[`examples/urls.example.txt`](examples/urls.example.txt).

## Architecture

```
Web UI (React/Vite/AntD/Recharts)  ─┐
CLI (rake loadtest:*)              ─┼─▶  LoadTest::Executor  ──▶  hey (per URL)
                                    │         │
                                    │         └─▶ Postgres: runs · results · run_dynos ·
                                    │                        run_networks · status codes …
Heroku integration (optional) ──────┘
```

- `app/services/load_test/hey_runner.rb` — wraps `hey`, parses its CSV, aggregates stats.
- `app/services/load_test/executor.rb` — creates the run, captures context, persists results.
- `app/services/infra/heroku.rb`, `host_info.rb`, `network_info.rb` — optional context collectors.
- Web-triggered runs execute in a background `ActiveJob` on the async adapter, so no
  separate worker is needed. The trade-off: they live in the web process, so
  restarting the server ends any run in flight — such runs are marked `aborted` on
  the next boot rather than being left "running" forever. Long unattended runs are
  better started from the CLI (`rake loadtest:run`).

The data model is documented in [`db/DATABASE.md`](db/DATABASE.md).

## Testing

```bash
bundle exec rspec     # backend: models, services, requests, jobs
npm test              # frontend: Vitest + React Testing Library
npm run test:e2e      # end-to-end: Playwright (boots an isolated server + demo data)
```

## Using it for your own project

thunderherd ships with only a generic `demo` example. Add your own via the web UI
(**Environments**) or `rake loadtest:import`, and it stays entirely yours — nothing
about any particular company is baked in.

## Security

thunderherd **sends HTTP requests to whatever hosts you configure** and ships
**without a user model** — treat it as a powerful internal tool:

- **Don't expose it to untrusted networks.** Run it on localhost or a trusted
  network. To lock down the whole app (UI + API) with a shared credential, set
  `THUNDERHERD_HTTP_USER` / `THUNDERHERD_HTTP_PASSWORD` (HTTP Basic), or put it
  behind your own reverse-proxy auth / VPN.
- **Configuring an environment/URL means the server (and `hey`) will request it** —
  including internal addresses. That is an SSRF vector if people who shouldn't
  configure targets can reach the app; the credential above is the intended control.
- **The production opt-in is a confirmation, not a security boundary.** An
  `is_production` environment needs an explicit `allow_prod` to run — a guard
  against *accidents*, deliberately bypassable by an authorized operator.
- CSRF protection is on for the API (the SPA sends the token); `run_networks`
  stores a coarsened `/24`, never a raw IP.

## License

[MIT](LICENSE).

// Shared UI constants + table helpers — one source of truth across pages.

// Run-status tag colors (mirrors Run::STATUSES on the backend).
export const statusColor = {
  running: 'blue',
  completed: 'green',
  aborted: 'orange',
  failed: 'red',
}

// Mirrors Url::METHODS on the backend.
export const HTTP_METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD']

// Defaults for a new run / run config (mirrors the DB column defaults).
export const RUN_DEFAULTS = { requests_per_url: 50, concurrency: 10, timeout_s: 30 }

// antd Table sorter factories — keep column definitions declarative.
export const num = (key) => (a, b) => (a[key] ?? 0) - (b[key] ?? 0)
export const str = (key) => (a, b) => String(a[key] ?? '').localeCompare(String(b[key] ?? ''))
export const by = (fn) => (a, b) => String(fn(a) ?? '').localeCompare(String(fn(b) ?? ''))
export const byNum = (fn) => (a, b) => (fn(a) ?? 0) - (fn(b) ?? 0)
export const byDate = (key) => (a, b) => new Date(a[key] || 0) - new Date(b[key] || 0)

import axios from 'axios'

const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')

const client = axios.create({
  headers: { 'X-CSRF-Token': csrf, 'Content-Type': 'application/json' },
})

// The API reports failures as {error: "..."} or {errors: [...]}; unwrap either
// into a single string so every page shows the server's own message.
export const apiError = (error, fallback = 'Request failed') => {
  const data = error?.response?.data
  const detail = data?.errors ?? data?.error
  return (Array.isArray(detail) ? detail.join(', ') : detail) || fallback
}

const api = {
  // dashboard + runs
  dashboard: () => client.get('/api/dashboard').then((r) => r.data),
  runs: () => client.get('/api/runs').then((r) => r.data),
  run: (id) => client.get(`/api/runs/${id}`).then((r) => r.data),
  createRun: (payload) => client.post('/api/runs', payload).then((r) => r.data),
  updateRun: (id, run) => client.patch(`/api/runs/${id}`, { run }).then((r) => r.data),
  deleteRun: (id) => client.delete(`/api/runs/${id}`).then((r) => r.data),
  compare: (id, to) => client.get(`/api/runs/${id}/compare`, { params: { to } }).then((r) => r.data),

  // sites
  sites: () => client.get('/api/sites').then((r) => r.data),
  createSite: (site) => client.post('/api/sites', { site }).then((r) => r.data),
  updateSite: (id, site) => client.patch(`/api/sites/${id}`, { site }).then((r) => r.data),
  deleteSite: (id) => client.delete(`/api/sites/${id}`).then((r) => r.data),

  // environments
  environments: () => client.get('/api/environments').then((r) => r.data),
  environment: (id) => client.get(`/api/environments/${id}`).then((r) => r.data),
  createEnvironment: (payload) => client.post('/api/environments', payload).then((r) => r.data),
  updateEnvironment: (id, environment) =>
    client.patch(`/api/environments/${id}`, { environment }).then((r) => r.data),
  deleteEnvironment: (id) => client.delete(`/api/environments/${id}`).then((r) => r.data),

  // urls (nested under an environment for create; shallow for update/delete)
  createUrl: (environmentId, url) =>
    client.post(`/api/environments/${environmentId}/urls`, { url }).then((r) => r.data),
  updateUrl: (id, url) => client.patch(`/api/urls/${id}`, { url }).then((r) => r.data),
  deleteUrl: (id) => client.delete(`/api/urls/${id}`).then((r) => r.data),

  // directory (read-only dimensions)
  operators: () => client.get('/api/operators').then((r) => r.data),
  machines: () => client.get('/api/machines').then((r) => r.data),
  deploys: () => client.get('/api/app_deploys').then((r) => r.data),

  // run configs
  runConfigs: () => client.get('/api/run_configs').then((r) => r.data),
  createRunConfig: (runConfig) => client.post('/api/run_configs', { run_config: runConfig }).then((r) => r.data),
  updateRunConfig: (id, runConfig) =>
    client.patch(`/api/run_configs/${id}`, { run_config: runConfig }).then((r) => r.data),
  deleteRunConfig: (id) => client.delete(`/api/run_configs/${id}`).then((r) => r.data),
}

export default api

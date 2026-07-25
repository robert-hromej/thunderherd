import React, { useEffect, useState } from 'react'
import { Card, Select, Row, Col, Table, Alert, Empty, Space } from 'antd'
import { useSearchParams } from 'react-router-dom'
import api from '../api'
import { num, str } from '../constants'

const round = (v) => Math.round(Number(v) || 0)

const dash = (v) => v || 'n/a'

// Everything that must match for a delta to mean "the code changed". Load params
// are here too: 20×10 against 100×20 is a different experiment, not a regression.
const COMPARABILITY = [
  { label: 'Environment', of: (r) => `${r.site}/${r.env}` },
  { label: 'Dyno formation', of: (r) => r.dyno_formation },
  { label: 'Load', of: (r) => `${r.requests_per_url}×${r.concurrency}` },
  { label: 'Machine', of: (r) => r.machine },
  { label: 'Network', of: (r) => r.network?.kind },
]

export function comparabilityWarnings(before, after) {
  return COMPARABILITY.flatMap(({ label, of }) => {
    const a = of(before)
    const b = of(after)
    return a === b ? [] : [{ label, before: dash(a), after: dash(b) }]
  })
}

// Negative delta = faster (good) → green; positive = slower → red.
const delta = (v) => {
  const n = round(v)
  const color = n < 0 ? '#3f8600' : n > 0 ? '#cf1322' : undefined
  return <span style={{ color }}>{n > 0 ? `+${n}` : n}</span>
}

export default function Compare() {
  const [params, setParams] = useSearchParams()
  const [runs, setRuns] = useState([])
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)

  const beforeId = params.get('before') ? Number(params.get('before')) : null
  const afterId = params.get('after') ? Number(params.get('after')) : null
  const setId = (which) => (value) => {
    const next = new URLSearchParams(params)
    value ? next.set(which, value) : next.delete(which)
    setParams(next, { replace: true })
    // Showing the spinner belongs to the interaction, not to the effect.
    if (value) setLoading(true)
  }

  useEffect(() => {
    let active = true
    api.runs().then((r) => {
      if (active) setRuns(r.filter((x) => x.status === 'completed'))
    })
    return () => {
      active = false
    }
  }, [])

  useEffect(() => {
    if (!beforeId || !afterId) return undefined

    let active = true
    ;(async () => {
      try {
        const diff = await api.compare(beforeId, afterId)
        if (active) setData(diff)
      } finally {
        if (active) setLoading(false)
      }
    })()
    return () => {
      active = false
    }
  }, [beforeId, afterId])

  // Render from the selection, not from stale data of a previous pair.
  const comparison = beforeId && afterId ? data : null

  const options = runs.map((r) => ({
    value: r.id,
    label: `#${r.id} · ${r.site}/${r.env}${r.label ? ` · ${r.label}` : ''}`,
  }))

  const columns = [
    { title: 'Page', dataIndex: 'path', ellipsis: true, sorter: str('path') },
    { title: 'Method', dataIndex: 'method', width: 80 },
    { title: 'p95 before', dataIndex: 'before_p95', width: 100, render: round },
    { title: 'p95 after', dataIndex: 'after_p95', width: 100, render: round },
    { title: 'Δ p95', dataIndex: 'p95_delta', width: 90, defaultSortOrder: 'descend', sorter: num('p95_delta'), render: delta },
    { title: 'avg before', dataIndex: 'before_avg', width: 100, render: round },
    { title: 'avg after', dataIndex: 'after_avg', width: 100, render: round },
    { title: 'Δ avg', dataIndex: 'avg_delta', width: 90, sorter: num('avg_delta'), render: delta },
    { title: 'rps before', dataIndex: 'before_rps', width: 100, render: (v) => Number(v).toFixed(1) },
    { title: 'rps after', dataIndex: 'after_rps', width: 100, render: (v) => Number(v).toFixed(1) },
  ]

  // Stored context is only worth capturing if it is acted on: anything that differs
  // between the two runs makes the deltas mix a code change with an infra/client
  // change, so say so instead of letting the numbers look authoritative.
  const differences = comparison ? comparabilityWarnings(comparison.before, comparison.after) : []

  return (
    <Space direction="vertical" size={16} style={{ width: '100%' }}>
      <Card title="Compare runs">
        <Row gutter={16}>
          <Col xs={24} md={12}>
            <div style={{ marginBottom: 6, color: '#888' }}>Before (baseline)</div>
            <Select style={{ width: '100%' }} allowClear showSearch optionFilterProp="label"
              placeholder="Pick the baseline run" options={options} value={beforeId} onChange={setId('before')} />
          </Col>
          <Col xs={24} md={12}>
            <div style={{ marginBottom: 6, color: '#888' }}>After</div>
            <Select style={{ width: '100%' }} allowClear showSearch optionFilterProp="label"
              placeholder="Pick the run to compare" options={options} value={afterId} onChange={setId('after')} />
          </Col>
        </Row>
      </Card>

      {!comparison && <Card><Empty description="Pick two completed runs to see per-page deltas" /></Card>}

      {comparison && (
        <>
          {differences.length > 0 && (
            <Alert
              type="warning"
              showIcon
              message="These runs are not directly comparable"
              description={
                <ul style={{ margin: 0, paddingLeft: 18 }}>
                  {differences.map((d) => (
                    <li key={d.label}>
                      <strong>{d.label}:</strong> {d.before} → {d.after}
                    </li>
                  ))}
                </ul>
              }
            />
          )}
          <Row gutter={16}>
            {[comparison.before, comparison.after].map((r, i) => (
              <Col xs={24} md={12} key={r.id}>
                <Card size="small" title={`${i === 0 ? 'Before' : 'After'} — #${r.id}`}>
                  {r.site}/{r.env} · {r.label || '—'} · {r.requests_per_url}×{r.concurrency} · {r.dyno_formation || 'n/a'}
                </Card>
              </Col>
            ))}
          </Row>
          <Card title="Per-page deltas (negative = faster)" styles={{ body: { padding: 0 } }}>
            <Table
              rowKey={(r) => `${r.method} ${r.path}`}
              size="small"
              loading={loading}
              dataSource={comparison.diff}
              columns={columns}
              pagination={false}
              scroll={{ x: 'max-content' }}
            />
          </Card>
        </>
      )}
    </Space>
  )
}

import React, { useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import {
  Card, Row, Col, Statistic, Descriptions, Tag, Table, Spin, Segmented, Space, Alert,
} from 'antd'
import api from '../api'
import PagesBarChart from '../components/PagesBarChart'
import { statusColor, num, str } from '../constants'

const metrics = [
  { key: 'p95_ms', label: 'p95' },
  { key: 'p99_ms', label: 'p99' },
  { key: 'avg_ms', label: 'avg' },
  { key: 'server_ms', label: 'server' },
  { key: 'rps', label: 'rps' },
]

export default function RunDetail() {
  const { id } = useParams()
  const [run, setRun] = useState(null)
  const [metric, setMetric] = useState('p95_ms')

  useEffect(() => {
    // `active` guards against a stale in-flight response landing after the id
    // changed/unmounted — without it the old run's data would overwrite the page
    // and re-arm an unclearable poll chain.
    let timer
    let active = true
    const load = () =>
      api.run(id).then((r) => {
        if (!active) return
        setRun(r)
        if (r.status === 'running') timer = setTimeout(load, 3000)
      })
    load()
    return () => {
      active = false
      clearTimeout(timer)
    }
  }, [id])

  // Derive staleness instead of clearing state up front: while the new id loads,
  // `run` still holds the previous one.
  if (!run || String(run.id) !== String(id)) {
    return <Spin size="large" style={{ display: 'block', marginTop: 80 }} />
  }

  const codeStr = (c) => Object.entries(c || {}).map(([k, v]) => `${k}:${v}`).join(' ')

  const columns = [
    { title: 'Method', dataIndex: 'method', width: 80, sorter: str('method') },
    { title: 'Page', dataIndex: 'path', ellipsis: true, sorter: str('path') },
    { title: 'n', dataIndex: 'requests', width: 60, sorter: num('requests') },
    { title: 'err', dataIndex: 'error_count', width: 70, sorter: num('error_count'), render: (v) => (v > 0 ? <Tag color="red">{v}</Tag> : v) },
    { title: 'rps', dataIndex: 'rps', width: 70, sorter: num('rps') },
    { title: 'min', dataIndex: 'min_ms', width: 70, sorter: num('min_ms') },
    { title: 'avg', dataIndex: 'avg_ms', width: 70, sorter: num('avg_ms') },
    { title: 'p50', dataIndex: 'p50_ms', width: 70, sorter: num('p50_ms') },
    { title: 'p95', dataIndex: 'p95_ms', width: 80, sorter: num('p95_ms'), defaultSortOrder: 'descend' },
    { title: 'p99', dataIndex: 'p99_ms', width: 80, sorter: num('p99_ms') },
    { title: 'max', dataIndex: 'max_ms', width: 80, sorter: num('max_ms') },
    { title: 'server', dataIndex: 'server_ms', width: 80, sorter: num('server_ms') },
    { title: 'codes', dataIndex: 'status_codes', sorter: (a, b) => codeStr(a.status_codes).localeCompare(codeStr(b.status_codes)), render: codeStr },
  ]

  return (
    <Space direction="vertical" size={16} style={{ width: '100%' }}>
      <Card
        title={
          <Space>
            Run #{run.id}
            <Tag color={statusColor[run.status]}>{run.status}</Tag>
            {run.is_production && <Tag color="volcano">production</Tag>}
          </Space>
        }
      >
        {run.status === 'running' && <Alert type="info" showIcon message="Run in progress — refreshing…" style={{ marginBottom: 16 }} />}
        <Descriptions size="small" column={{ xs: 1, sm: 2, lg: 3 }} bordered>
          <Descriptions.Item label="Target">{run.site}/{run.env}</Descriptions.Item>
          <Descriptions.Item label="Base URL">{run.base_url}</Descriptions.Item>
          <Descriptions.Item label="Label">{run.label || '—'}</Descriptions.Item>
          <Descriptions.Item label="Dyno formation">{run.dyno_formation || '—'}</Descriptions.Item>
          <Descriptions.Item label="Deploy">{run.deploy || '—'}</Descriptions.Item>
          <Descriptions.Item label="Load">{run.requests_per_url}×{run.concurrency} (timeout {run.timeout_s}s)</Descriptions.Item>
          <Descriptions.Item label="Operator">{run.operator || '—'}</Descriptions.Item>
          <Descriptions.Item label="Machine">{run.machine || '—'}</Descriptions.Item>
          <Descriptions.Item label="Tool">{run.tool_version || run.tool} · harness {run.harness_version}</Descriptions.Item>
          <Descriptions.Item label="Duration">{run.duration_s ? `${run.duration_s}s` : '—'}</Descriptions.Item>
          <Descriptions.Item label="Network">
            {run.network
              ? [
                  run.network.kind,
                  run.network.isp,
                  run.network.rtt_ms ? `rtt ${run.network.rtt_ms} ms` : null,
                  run.network.downlink_mbps ? `${run.network.downlink_mbps} Mbps↓` : null,
                  run.network.city ? `${run.network.city}, ${run.network.country}` : null,
                ]
                  .filter(Boolean)
                  .join(' · ')
              : '—'}
          </Descriptions.Item>
        </Descriptions>
      </Card>

      <Row gutter={16}>
        {[
          { title: 'Pages', value: run.summary.pages },
          { title: 'Total requests', value: run.summary.total_requests },
          { title: 'Total errors', value: run.summary.total_errors },
          { title: 'Max p95 (ms)', value: run.summary.max_p95_ms },
        ].map((c) => (
          <Col xs={12} md={6} key={c.title}>
            <Card><Statistic title={c.title} value={c.value} /></Card>
          </Col>
        ))}
      </Row>

      <Card
        title="Per-page latency"
        extra={
          <Segmented
            options={metrics.map((m) => ({ label: m.label, value: m.key }))}
            value={metric}
            onChange={setMetric}
          />
        }
      >
        <PagesBarChart rows={run.results} dataKey={metric} name={metrics.find((m) => m.key === metric).label} />
      </Card>

      <Card title="Results" styles={{ body: { padding: 0 } }}>
        <Table
          rowKey="id"
          size="small"
          dataSource={run.results}
          columns={columns}
          pagination={false}
          scroll={{ x: 'max-content' }}
        />
      </Card>
    </Space>
  )
}

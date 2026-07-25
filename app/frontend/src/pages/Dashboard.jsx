import React, { useEffect, useState } from 'react'
import { Row, Col, Card, Statistic, Table, Tag, Spin, Empty } from 'antd'
import { Link } from 'react-router-dom'
import api from '../api'
import PagesBarChart from '../components/PagesBarChart'
import { statusColor, num, str, by } from '../constants'

export default function Dashboard() {
  const [data, setData] = useState(null)

  useEffect(() => {
    api.dashboard().then(setData)
  }, [])

  if (!data) return <Spin size="large" style={{ display: 'block', marginTop: 80 }} />

  const target = (r) => `${r.site}/${r.env}`

  const runColumns = [
    { title: 'Run', dataIndex: 'id', sorter: num('id'), render: (id) => <Link to={`/runs/${id}`}>#{id}</Link> },
    { title: 'Target', sorter: by(target), render: (_, r) => target(r) },
    { title: 'Label', dataIndex: 'label', sorter: str('label') },
    { title: 'Status', dataIndex: 'status', sorter: str('status'), render: (s) => <Tag color={statusColor[s]}>{s}</Tag> },
    { title: 'Pages', dataIndex: 'pages', sorter: num('pages') },
    { title: 'avg p95', dataIndex: 'avg_p95_ms', sorter: num('avg_p95_ms'), render: (v) => (v ? `${v} ms` : '—') },
    { title: 'Errors', dataIndex: 'total_errors', sorter: num('total_errors') },
  ]

  const slowColumns = [
    { title: 'Run', dataIndex: 'run_id', sorter: num('run_id'), render: (id) => <Link to={`/runs/${id}`}>#{id}</Link> },
    { title: 'Target', sorter: by(target), render: (_, r) => target(r) },
    { title: 'Page', dataIndex: 'path', ellipsis: true, sorter: str('path') },
    { title: 'p95 (ms)', dataIndex: 'p95_ms', sorter: num('p95_ms'), defaultSortOrder: 'descend' },
    { title: 'rps', dataIndex: 'rps', sorter: num('rps') },
    { title: 'err', dataIndex: 'error_count', sorter: num('error_count') },
  ]

  return (
    <>
      <Row gutter={16}>
        {[
          { title: 'Sites', value: data.counts.sites },
          { title: 'Environments', value: data.counts.environments },
          { title: 'Runs', value: data.counts.runs },
          { title: 'Completed', value: data.counts.completed_runs },
        ].map((c) => (
          <Col xs={12} md={6} key={c.title}>
            <Card><Statistic title={c.title} value={c.value} /></Card>
          </Col>
        ))}
      </Row>

      <Row gutter={16} style={{ marginTop: 16 }}>
        <Col xs={24} lg={14}>
          <Card title="Latest runs">
            <Table
              rowKey="id"
              size="small"
              dataSource={data.latest_runs}
              columns={runColumns}
              pagination={false}
              locale={{ emptyText: <Empty description="No runs yet" /> }}
            />
          </Card>
        </Col>
        <Col xs={24} lg={10}>
          <Card title="Slowest pages (p95)">
            {data.slowest_pages.length ? (
              <PagesBarChart rows={data.slowest_pages} />
            ) : (
              <Empty description="No results yet" />
            )}
          </Card>
        </Col>
      </Row>

      <Card title="Slowest pages — detail" style={{ marginTop: 16 }}>
        <Table
          rowKey={(r, i) => `${r.run_id}-${i}`}
          size="small"
          dataSource={data.slowest_pages}
          columns={slowColumns}
          pagination={false}
          locale={{ emptyText: <Empty description="No results yet" /> }}
        />
      </Card>
    </>
  )
}

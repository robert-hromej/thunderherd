import React, { useCallback, useEffect, useState } from 'react'
import { Card, Table, Tag, Button, Space, Tooltip, message } from 'antd'
import { StarFilled, StarOutlined } from '@ant-design/icons'
import { Link, useNavigate } from 'react-router-dom'
import api from '../api'
import { statusColor, num, str, by, byDate } from '../constants'
import { mutate } from '../hooks'
import { actionsColumn } from '../components/tableActions'

const POLL_MS = 5000

export default function Runs() {
  const [runs, setRuns] = useState([])
  const [loading, setLoading] = useState(true)
  const navigate = useNavigate()

  // `accept` lets the caller drop a response that is no longer wanted: the poll
  // passes a sequence check so a slow older request cannot overwrite a newer one,
  // and an unmounted page accepts nothing.
  const fetchRuns = useCallback(async (accept = () => true) => {
    try {
      const rows = await api.runs()
      if (accept()) setRuns(rows)
    } catch {
      if (accept()) message.error('Failed to load runs')
    } finally {
      if (accept()) setLoading(false)
    }
  }, [])

  useEffect(() => {
    let active = true
    let seq = 0
    const poll = () => {
      const mine = ++seq
      // Background refreshes must not flash the table into its loading state.
      return fetchRuns(() => active && mine === seq)
    }
    poll()
    const timer = setInterval(poll, POLL_MS)
    return () => {
      active = false
      clearInterval(timer)
    }
  }, [fetchRuns])

  const refresh = () => {
    setLoading(true)
    return fetchRuns()
  }

  const toggleBaseline = (run) =>
    mutate(api.updateRun(run.id, { is_baseline: !run.is_baseline }), {
      success: run.is_baseline ? `Run #${run.id} is no longer a baseline` : `Run #${run.id} marked as baseline`,
      error: 'Failed to update run',
      onDone: fetchRuns,
    })

  const columns = [
    {
      title: '',
      dataIndex: 'is_baseline',
      width: 40,
      render: (isBaseline, run) => (
        <Tooltip title={isBaseline ? 'Baseline — click to unmark' : 'Mark as baseline to compare against'}>
          <Button
            type="text"
            size="small"
            aria-label={isBaseline ? 'Unmark baseline' : 'Mark as baseline'}
            icon={isBaseline ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
            onClick={() => toggleBaseline(run)}
          />
        </Tooltip>
      ),
    },
    { title: 'Run', dataIndex: 'id', sorter: num('id'), render: (id) => <Link to={`/runs/${id}`}>#{id}</Link> },
    { title: 'Target', sorter: by((r) => `${r.site}/${r.env}`), render: (_, r) => `${r.site}/${r.env}` },
    { title: 'Label', dataIndex: 'label', sorter: str('label') },
    { title: 'Status', dataIndex: 'status', sorter: str('status'), render: (s) => <Tag color={statusColor[s]}>{s}</Tag> },
    { title: 'Dynos', dataIndex: 'dynos', ellipsis: true, render: (d) => d || '—' },
    { title: 'Load', render: (_, r) => `${r.requests_per_url}×${r.concurrency}` },
    { title: 'Pages', dataIndex: 'pages', sorter: num('pages') },
    { title: 'avg p95', dataIndex: 'avg_p95_ms', sorter: num('avg_p95_ms'), render: (v) => (v ? `${v} ms` : '—') },
    { title: 'Errors', dataIndex: 'total_errors', sorter: num('total_errors') },
    {
      title: 'Started',
      dataIndex: 'started_at',
      sorter: byDate('started_at'),
      defaultSortOrder: 'descend',
      render: (t) => (t ? new Date(t).toLocaleString() : '—'),
    },
    actionsColumn({
      width: 90,
      onDelete: (run) =>
        mutate(api.deleteRun(run.id), {
          success: `Run #${run.id} deleted`,
          error: 'Failed to delete run',
          onDone: fetchRuns,
        }),
      confirmTitle: 'Delete this run?',
      disabled: (run) => run.status === 'running',
    }),
  ]

  return (
    <Card
      title="Runs"
      extra={
        <Space>
          <Button onClick={refresh}>Refresh</Button>
          <Button type="primary" onClick={() => navigate('/runs/new')}>New run</Button>
        </Space>
      }
    >
      <Table rowKey="id" loading={loading} dataSource={runs} columns={columns} size="small" />
    </Card>
  )
}

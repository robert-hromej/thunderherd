import React from 'react'
import { Card, Tabs, Table } from 'antd'
import api from '../api'
import { num, str, byDate } from '../constants'
import { useCollection } from '../hooks'

const fmt = (t) => (t ? new Date(t).toLocaleString() : '—')
const dash = (v) => v ?? '—'

function OperatorsTab() {
  const { rows, loading } = useCollection(api.operators)
  return (
    <Table
      rowKey="id"
      size="small"
      loading={loading}
      dataSource={rows}
      pagination={false}
      columns={[
        { title: 'Name', dataIndex: 'name', sorter: str('name') },
        { title: 'Email', dataIndex: 'email', render: dash },
        { title: 'Runs', dataIndex: 'runs_count', sorter: num('runs_count') },
        { title: 'Last run', dataIndex: 'last_run_at', render: fmt, sorter: byDate('last_run_at') },
      ]}
    />
  )
}

function MachinesTab() {
  const { rows, loading } = useCollection(api.machines)
  return (
    <Table
      rowKey="id"
      size="small"
      loading={loading}
      dataSource={rows}
      pagination={false}
      scroll={{ x: 'max-content' }}
      columns={[
        { title: 'Hostname', dataIndex: 'hostname', sorter: str('hostname') },
        { title: 'OS', dataIndex: 'os', render: dash },
        { title: 'Arch', dataIndex: 'arch', render: dash },
        { title: 'CPU', dataIndex: 'cpu_model', render: dash },
        { title: 'Cores', dataIndex: 'cpu_cores', render: dash },
        { title: 'RAM (MB)', dataIndex: 'ram_mb', render: dash },
        { title: 'Runs', dataIndex: 'runs_count', sorter: num('runs_count') },
        { title: 'Last run', dataIndex: 'last_run_at', render: fmt },
      ]}
    />
  )
}

function DeploysTab() {
  const { rows, loading } = useCollection(api.deploys)
  return (
    <Table
      rowKey="id"
      size="small"
      loading={loading}
      dataSource={rows}
      pagination={false}
      columns={[
        { title: 'Environment', dataIndex: 'environment', sorter: str('environment') },
        { title: 'Release', dataIndex: 'heroku_release', render: dash },
        { title: 'Git SHA', dataIndex: 'git_sha', render: (v) => (v ? v.slice(0, 7) : '—') },
        { title: 'Deployed at', dataIndex: 'deployed_at', render: fmt },
        { title: 'Description', dataIndex: 'description', ellipsis: true, render: dash },
        { title: 'Runs', dataIndex: 'runs_count', sorter: num('runs_count') },
      ]}
    />
  )
}

// Read-only reference data captured automatically with each run: who ran tests,
// on which machines, and which deployed versions were measured.
export default function Directory() {
  return (
    <Card title="Directory">
      <Tabs
        defaultActiveKey="operators"
        items={[
          { key: 'operators', label: 'Operators', children: <OperatorsTab /> },
          { key: 'machines', label: 'Machines', children: <MachinesTab /> },
          { key: 'deploys', label: 'Deploys', children: <DeploysTab /> },
        ]}
      />
    </Card>
  )
}

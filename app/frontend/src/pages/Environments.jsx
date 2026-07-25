import React, { useCallback, useEffect, useState } from 'react'
import { Card, Table, Tag, Button, Space, Form, Input, Select, Switch } from 'antd'
import { PlusOutlined } from '@ant-design/icons'
import api from '../api'
import { str, num, HTTP_METHODS } from '../constants'
import { useCollection, mutate } from '../hooks'
import ResourceModal from '../components/ResourceModal'
import { actionsColumn } from '../components/tableActions'

export default function Environments() {
  const { rows, loading, reload } = useCollection(api.environments)
  const [editing, setEditing] = useState(null) // null | {} (new) | env (edit)

  const columns = [
    { title: 'Site', dataIndex: 'site', sorter: str('site') },
    { title: 'Environment', dataIndex: 'name', sorter: str('name') },
    {
      title: 'Type',
      dataIndex: 'is_production',
      render: (p) => <Tag color={p ? 'volcano' : 'green'}>{p ? 'production' : 'staging'}</Tag>,
    },
    { title: 'Base URL', dataIndex: 'base_url' },
    { title: 'Heroku app', dataIndex: 'heroku_app', render: (v) => v || '—' },
    { title: 'URLs', dataIndex: 'urls_count', sorter: num('urls_count') },
    { title: 'Runs', dataIndex: 'runs_count', sorter: num('runs_count') },
    actionsColumn({
      onEdit: setEditing,
      onDelete: (env) =>
        mutate(api.deleteEnvironment(env.id), {
          success: 'Environment deleted',
          error: 'Delete failed',
          onDone: reload,
        }),
      confirmTitle: 'Delete this environment?',
      confirmDescription: 'Its URLs and configs are deleted too. Environments with runs cannot be deleted.',
      disabled: (env) => env.runs_count > 0,
    }),
  ]

  return (
    <>
      <Card
        title="Environments"
        extra={
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setEditing({})}>
            New environment
          </Button>
        }
      >
        <Table
          rowKey="id"
          loading={loading}
          dataSource={rows}
          columns={columns}
          expandable={{ expandedRowRender: (env) => <UrlManager environmentId={env.id} /> }}
          pagination={false}
        />
      </Card>

      <EnvironmentModal
        environment={editing}
        onClose={() => setEditing(null)}
        onSaved={() => {
          setEditing(null)
          return reload()
        }}
      />
    </>
  )
}

function EnvironmentModal({ environment, onClose, onSaved }) {
  const [sites, setSites] = useState([])
  const open = environment != null
  const isEdit = !!environment?.id

  useEffect(() => {
    if (open) api.sites().then(setSites)
  }, [open])

  // Creating may reference an existing site or name a new one; editing never
  // moves an environment between sites, so those fields are create-only.
  const submit = (values) => {
    const { site_id, site_key, site_name, ...env } = values
    if (isEdit) return api.updateEnvironment(environment.id, env)

    return api.createEnvironment({
      environment: { ...env, site_id: site_id || undefined },
      site_key: site_id ? undefined : site_key,
      site_name: site_id ? undefined : site_name,
    })
  }

  return (
    <ResourceModal
      open={open}
      title={isEdit ? `Edit ${environment.site}/${environment.name}` : 'New environment'}
      initialValues={isEdit ? environment : { is_production: false }}
      successMessage={isEdit ? 'Environment updated' : 'Environment created'}
      onSubmit={submit}
      onClose={onClose}
      onSaved={onSaved}
    >
      {!isEdit && (
        <>
          <Form.Item name="site_id" label="Existing site">
            <Select
              allowClear
              placeholder="Pick a site, or create one below"
              options={sites.map((s) => ({ value: s.id, label: `${s.key} — ${s.name}` }))}
            />
          </Form.Item>
          <Space>
            <Form.Item name="site_key" label="…or new site key"><Input placeholder="my-app" /></Form.Item>
            <Form.Item name="site_name" label="new site name"><Input placeholder="My App" /></Form.Item>
          </Space>
        </>
      )}
      <Form.Item name="name" label="Environment name" rules={[{ required: true }]}>
        <Input placeholder="staging" />
      </Form.Item>
      <Form.Item
        name="base_url"
        label="Base URL"
        rules={[{ required: true, pattern: /^https?:\/\//, message: 'Must start with http(s)://' }]}
      >
        <Input placeholder="https://staging.example.com" />
      </Form.Item>
      <Form.Item name="heroku_app" label="Heroku app (optional)">
        <Input placeholder="my-app-staging" />
      </Form.Item>
      <Form.Item name="is_production" label="Production" valuePropName="checked">
        <Switch />
      </Form.Item>
      <Form.Item name="description" label="Description">
        <Input.TextArea rows={2} />
      </Form.Item>
    </ResourceModal>
  )
}

function UrlManager({ environmentId }) {
  const fetchUrls = useCallback(
    () => api.environment(environmentId).then((e) => e.urls),
    [environmentId],
  )
  const { rows: urls, loading, reload } = useCollection(fetchUrls, { errorMessage: 'Failed to load URLs' })
  const [editing, setEditing] = useState(null)

  const columns = [
    { title: 'Method', dataIndex: 'method', width: 90 },
    { title: 'Path', dataIndex: 'path' },
    { title: 'Active', dataIndex: 'is_active', width: 80, render: (v) => (v ? '✓' : '—') },
    actionsColumn({
      onEdit: setEditing,
      onDelete: (url) =>
        mutate(api.deleteUrl(url.id), { success: 'URL deleted', error: 'Delete failed', onDone: reload }),
      confirmTitle: 'Delete this URL?',
    }),
  ]

  return (
    <>
      <Space style={{ marginBottom: 8 }}>
        <Button size="small" icon={<PlusOutlined />} onClick={() => setEditing({})}>Add URL</Button>
      </Space>
      <Table rowKey="id" size="small" loading={loading} dataSource={urls} columns={columns} pagination={false} />
      <UrlModal
        environmentId={environmentId}
        url={editing}
        onClose={() => setEditing(null)}
        onSaved={() => {
          setEditing(null)
          return reload()
        }}
      />
    </>
  )
}

function UrlModal({ environmentId, url, onClose, onSaved }) {
  const open = url != null
  const isEdit = !!url?.id

  return (
    <ResourceModal
      open={open}
      title={isEdit ? 'Edit URL' : 'Add URL'}
      initialValues={
        isEdit ? { ...url, body: url.body ? JSON.stringify(url.body) : '' } : { method: 'GET', is_active: true }
      }
      successMessage={isEdit ? 'URL updated' : 'URL added'}
      transform={({ method, path, is_active, body }) => ({
        method,
        path,
        is_active,
        body: parseBody(body),
      })}
      onSubmit={(payload) => (isEdit ? api.updateUrl(url.id, payload) : api.createUrl(environmentId, payload))}
      onClose={onClose}
      onSaved={onSaved}
    >
      <Form.Item name="method" label="Method">
        <Select options={HTTP_METHODS.map((m) => ({ value: m, label: m }))} />
      </Form.Item>
      <Form.Item name="path" label="Path" rules={[{ required: true }]}>
        <Input placeholder="/en-US/products?sort_by=price_asc" />
      </Form.Item>
      <Form.Item name="is_active" label="Active" valuePropName="checked">
        <Switch />
      </Form.Item>
      <Form.Item name="body" label="JSON body (optional, for write methods)">
        <Input.TextArea rows={3} placeholder='{"key":"value"}' />
      </Form.Item>
    </ResourceModal>
  )
}

// An empty box clears the body (the API stores JSON null); anything else must parse.
function parseBody(raw) {
  if (!raw?.trim()) return null

  try {
    return JSON.parse(raw)
  } catch {
    throw new Error('Body must be valid JSON')
  }
}

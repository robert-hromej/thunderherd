import React, { useEffect, useState } from 'react'
import { Card, Table, Button, Space, Form, Input, Select, InputNumber } from 'antd'
import { PlusOutlined } from '@ant-design/icons'
import api from '../api'
import { num, str, RUN_DEFAULTS } from '../constants'
import { useCollection, mutate } from '../hooks'
import ResourceModal from '../components/ResourceModal'
import { actionsColumn } from '../components/tableActions'

export default function Configs() {
  const { rows, loading, reload } = useCollection(api.runConfigs)
  const [editing, setEditing] = useState(null)

  const columns = [
    { title: 'Name', dataIndex: 'name', sorter: str('name') },
    { title: 'Environment', dataIndex: 'environment', sorter: str('environment') },
    { title: 'Requests / URL', dataIndex: 'requests_per_url', sorter: num('requests_per_url') },
    { title: 'Concurrency', dataIndex: 'concurrency', sorter: num('concurrency') },
    { title: 'Timeout (s)', dataIndex: 'timeout_s', sorter: num('timeout_s') },
    {
      title: 'URLs',
      dataIndex: 'target_urls_count',
      sorter: num('target_urls_count'),
      render: (v, c) => (c.url_ids?.length ? `${v} selected` : `${v} (all)`),
    },
    { title: 'Description', dataIndex: 'description', render: (v) => v || '—' },
    actionsColumn({
      onEdit: setEditing,
      onDelete: (config) =>
        mutate(api.deleteRunConfig(config.id), { success: 'Config deleted', error: 'Delete failed', onDone: reload }),
      confirmTitle: 'Delete this config?',
    }),
  ]

  return (
    <>
      <Card
        title="Run configs"
        extra={
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setEditing({})}>
            New config
          </Button>
        }
      >
        <Table rowKey="id" loading={loading} dataSource={rows} columns={columns} pagination={false} />
      </Card>

      <ConfigModal
        config={editing}
        onClose={() => setEditing(null)}
        onSaved={() => {
          setEditing(null)
          return reload()
        }}
      />
    </>
  )
}

function ConfigModal({ config, onClose, onSaved }) {
  const [environments, setEnvironments] = useState([])
  const [urls, setUrls] = useState([])
  const open = config != null
  const isEdit = !!config?.id

  const loadUrls = (environmentId) =>
    environmentId ? api.environment(environmentId).then((e) => setUrls(e.urls)) : setUrls([])

  useEffect(() => {
    if (!open) return undefined

    let active = true
    ;(async () => {
      const [envs, envUrls] = await Promise.all([
        api.environments(),
        config.environment_id ? api.environment(config.environment_id).then((e) => e.urls) : [],
      ])
      if (!active) return

      setEnvironments(envs)
      setUrls(envUrls)
    })()
    return () => {
      active = false
    }
  }, [open, config?.environment_id])

  return (
    <ResourceModal
      open={open}
      title={isEdit ? `Edit ${config.name}` : 'New run config'}
      initialValues={isEdit ? config : { ...RUN_DEFAULTS, url_ids: [] }}
      successMessage={isEdit ? 'Config updated' : 'Config created'}
      onSubmit={(values) => (isEdit ? api.updateRunConfig(config.id, values) : api.createRunConfig(values))}
      onClose={onClose}
      onSaved={onSaved}
    >
      {(form) => (
        <>
          <Form.Item name="name" label="Name" rules={[{ required: true }]}>
            <Input placeholder="staging-smoke" />
          </Form.Item>
          <Form.Item name="environment_id" label="Environment" rules={[{ required: true }]}>
            <Select
              placeholder="Choose an environment…"
              onChange={(id) => {
                form.setFieldsValue({ url_ids: [] })
                loadUrls(id)
              }}
              options={environments.map((e) => ({ value: e.id, label: `${e.site}/${e.name}` }))}
            />
          </Form.Item>
          <Form.Item
            name="url_ids"
            label="URLs"
            extra="Leave empty to hit every active URL of the environment; pick specific ones to target a subset."
          >
            <Select
              mode="multiple"
              allowClear
              showSearch
              optionFilterProp="label"
              placeholder="All active URLs"
              options={urls.map((u) => ({ value: u.id, label: `${u.method} ${u.path}` }))}
            />
          </Form.Item>
          <Space size="large" wrap>
            <Form.Item name="requests_per_url" label="Requests / URL"><InputNumber min={1} max={100000} /></Form.Item>
            <Form.Item name="concurrency" label="Concurrency"><InputNumber min={1} max={1000} /></Form.Item>
            <Form.Item name="timeout_s" label="Timeout (s)"><InputNumber min={1} max={600} /></Form.Item>
          </Space>
          <Form.Item name="description" label="Description"><Input.TextArea rows={2} /></Form.Item>
        </>
      )}
    </ResourceModal>
  )
}

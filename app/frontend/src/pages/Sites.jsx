import React, { useState } from 'react'
import { Card, Table, Button, Space, Form, Input, Tag } from 'antd'
import { PlusOutlined } from '@ant-design/icons'
import api from '../api'
import { str, byNum } from '../constants'
import { useCollection, mutate } from '../hooks'
import ResourceModal from '../components/ResourceModal'
import { actionsColumn } from '../components/tableActions'

export default function Sites() {
  const { rows, loading, reload } = useCollection(api.sites)
  const [editing, setEditing] = useState(null)
  const isEdit = !!editing?.id

  const columns = [
    { title: 'Key', dataIndex: 'key', sorter: str('key') },
    { title: 'Name', dataIndex: 'name', sorter: str('name') },
    {
      title: 'Environments',
      render: (_, s) => s.environments.length,
      sorter: byNum((s) => s.environments.length),
    },
    actionsColumn({
      onEdit: setEditing,
      onDelete: (site) =>
        mutate(api.deleteSite(site.id), { success: 'Site deleted', error: 'Delete failed', onDone: reload }),
      confirmTitle: 'Delete this site?',
      confirmDescription: 'Only possible when it has no environments.',
      disabled: (site) => site.environments.length > 0,
    }),
  ]

  return (
    <>
      <Card
        title="Sites"
        extra={
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setEditing({})}>
            New site
          </Button>
        }
      >
        <Table
          rowKey="id"
          loading={loading}
          dataSource={rows}
          columns={columns}
          pagination={false}
          expandable={{ expandedRowRender: environmentTags }}
        />
      </Card>

      <ResourceModal
        open={editing != null}
        title={isEdit ? `Edit ${editing.key}` : 'New site'}
        initialValues={isEdit ? editing : null}
        successMessage={isEdit ? 'Site updated' : 'Site created'}
        onSubmit={(values) => (isEdit ? api.updateSite(editing.id, values) : api.createSite(values))}
        onClose={() => setEditing(null)}
        onSaved={() => {
          setEditing(null)
          return reload()
        }}
      >
        <Form.Item name="key" label="Key" rules={[{ required: true }]}>
          <Input placeholder="my-app" />
        </Form.Item>
        <Form.Item name="name" label="Name" rules={[{ required: true }]}>
          <Input placeholder="My App" />
        </Form.Item>
      </ResourceModal>
    </>
  )
}

function environmentTags(site) {
  if (!site.environments.length) return <span style={{ color: '#999' }}>No environments yet</span>

  return (
    <Space wrap>
      {site.environments.map((e) => (
        <Tag key={e.id} color={e.is_production ? 'volcano' : 'green'}>
          {e.name} — {e.base_url}
        </Tag>
      ))}
    </Space>
  )
}

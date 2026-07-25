import React from 'react'
import { Button, Popconfirm, Space } from 'antd'

// The Edit/Delete column every resource table ends with. `disabled` guards
// deletions the API would reject anyway (e.g. a site that still has
// environments), so the UI never invites a 422.
export function actionsColumn({ onEdit, onDelete, confirmTitle, confirmDescription, disabled, width = 150 }) {
  return {
    title: 'Actions',
    width,
    render: (_, record) => (
      <Space>
        {onEdit && (
          <Button size="small" onClick={() => onEdit(record)}>
            Edit
          </Button>
        )}
        {onDelete && (
          <Popconfirm
            title={confirmTitle}
            description={confirmDescription}
            onConfirm={() => onDelete(record)}
          >
            <Button size="small" danger disabled={disabled?.(record)}>
              Delete
            </Button>
          </Popconfirm>
        )}
      </Space>
    ),
  }
}

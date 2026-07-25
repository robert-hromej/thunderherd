import React, { useEffect, useState } from 'react'
import { Modal, Form, message } from 'antd'
import { apiError } from '../api'

// Create/edit dialog shared by every resource page: owns the form instance, the
// saving flag and error reporting, so pages only declare their fields and the
// submit call. `children` may be a render-prop when a field needs the form
// instance (e.g. resetting dependent fields on change).
export default function ResourceModal({
  open,
  title,
  initialValues,
  onSubmit,
  onClose,
  onSaved,
  successMessage,
  transform,
  children,
}) {
  const [form] = Form.useForm()
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (!open) return
    form.resetFields()
    if (initialValues) form.setFieldsValue(initialValues)
    // Values never change while the dialog is open; reopening re-runs this.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  const submit = async () => {
    let values
    try {
      values = await form.validateFields()
    } catch {
      return // antd already highlights the offending fields
    }
    if (transform) {
      try {
        values = transform(values)
      } catch (e) {
        message.error(e.message)
        return
      }
    }

    setSaving(true)
    try {
      await onSubmit(values)
      if (successMessage) message.success(successMessage)
      await onSaved?.()
    } catch (e) {
      message.error(apiError(e, 'Save failed'))
    } finally {
      setSaving(false)
    }
  }

  return (
    <Modal
      open={open}
      title={title}
      onCancel={onClose}
      onOk={submit}
      confirmLoading={saving}
      destroyOnClose
    >
      <Form form={form} layout="vertical">
        {typeof children === 'function' ? children(form) : children}
      </Form>
    </Modal>
  )
}

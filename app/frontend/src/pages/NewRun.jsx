import React, { useEffect, useState } from 'react'
import { Card, Form, Select, InputNumber, Input, Checkbox, Button, message, Alert, Space, Typography } from 'antd'
import { useNavigate } from 'react-router-dom'
import api from '../api'

export default function NewRun() {
  const [environments, setEnvironments] = useState([])
  const [configs, setConfigs] = useState([])
  const [envId, setEnvId] = useState(null)
  const [fromConfig, setFromConfig] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [form] = Form.useForm()
  const navigate = useNavigate()

  useEffect(() => {
    api.environments().then(setEnvironments)
    api.runConfigs().then(setConfigs)
  }, [])

  const selectedEnv = environments.find((e) => e.id === envId)

  // Picking a config fills the whole form — you don't re-enter anything.
  const onConfigChange = (id) => {
    const c = configs.find((x) => x.id === id)
    setFromConfig(!!c)
    if (!c) return
    form.setFieldsValue({
      environment_id: c.environment_id,
      requests_per_url: c.requests_per_url,
      concurrency: c.concurrency,
      timeout_s: c.timeout_s,
    })
    setEnvId(c.environment_id)
  }

  const onFinish = (values) => {
    setSubmitting(true)
    api
      .createRun(values)
      .then(() => {
        message.success('Run enqueued')
        navigate('/runs')
      })
      .catch((err) => {
        message.error(err.response?.data?.error || 'Failed to enqueue run')
        setSubmitting(false)
      })
  }

  return (
    <Card title="New load-test run" style={{ maxWidth: 640 }}>
      <Form
        form={form}
        layout="vertical"
        initialValues={{ requests_per_url: 50, concurrency: 10, timeout_s: 30 }}
        onFinish={onFinish}
      >
        <Form.Item
          name="run_config_id"
          label="Run config"
          extra="Pick a saved config to fill the fields below, or leave empty to run ad-hoc. You can still override any value."
        >
          <Select
            allowClear
            placeholder="Pick a saved config…"
            onChange={onConfigChange}
            options={configs.map((c) => ({
              value: c.id,
              label: `${c.name} — ${c.environment} · ${c.requests_per_url}×${c.concurrency}`,
            }))}
          />
        </Form.Item>

        <Form.Item
          name="environment_id"
          label="Environment"
          rules={[{ required: true, message: 'Choose an environment' }]}
        >
          <Select
            placeholder="Choose an environment…"
            onChange={setEnvId}
            options={environments.map((e) => ({
              value: e.id,
              label: `${e.site}/${e.name}${e.is_production ? '  ⚠ production' : ''}`,
            }))}
          />
        </Form.Item>

        {selectedEnv?.is_production && (
          <Alert
            type="warning"
            showIcon
            style={{ marginBottom: 16 }}
            message="This is a production environment"
            description="Load-testing production hits real users. Tick the box below only if you really mean it."
          />
        )}

        {fromConfig && (
          <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 8 }}>
            Values below came from the config — adjust them here to override just this run.
          </Typography.Text>
        )}

        <Space size="large" wrap>
          <Form.Item name="requests_per_url" label="Requests / URL">
            <InputNumber min={1} max={100000} />
          </Form.Item>
          <Form.Item name="concurrency" label="Concurrency">
            <InputNumber min={1} max={1000} />
          </Form.Item>
          <Form.Item name="timeout_s" label="Timeout (s)">
            <InputNumber min={1} max={600} />
          </Form.Item>
        </Space>

        <Form.Item name="label" label="Label">
          <Input placeholder="e.g. before-caching" />
        </Form.Item>

        {selectedEnv?.is_production && (
          <Form.Item name="allow_prod" valuePropName="checked">
            <Checkbox>I understand — allow running against production</Checkbox>
          </Form.Item>
        )}

        <Button type="primary" htmlType="submit" loading={submitting}>
          Start run
        </Button>
      </Form>
    </Card>
  )
}

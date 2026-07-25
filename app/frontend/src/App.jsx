import React from 'react'
import { Layout, Menu, Typography, Result, Button } from 'antd'
import {
  DashboardOutlined,
  ThunderboltOutlined,
  PlusCircleOutlined,
  CloudServerOutlined,
  SettingOutlined,
  AppstoreOutlined,
  DatabaseOutlined,
  DiffOutlined,
} from '@ant-design/icons'
import { Link, Routes, Route, useLocation } from 'react-router-dom'
import Dashboard from './pages/Dashboard'
import Runs from './pages/Runs'
import RunDetail from './pages/RunDetail'
import NewRun from './pages/NewRun'
import Compare from './pages/Compare'
import Sites from './pages/Sites'
import Environments from './pages/Environments'
import Configs from './pages/Configs'
import Directory from './pages/Directory'

const { Header, Content, Sider } = Layout

// Two groups: what you do with the tool, then what you configure once.
const NAV = [
  {
    label: 'Testing',
    links: [
      { key: '/', icon: <DashboardOutlined />, text: 'Dashboard' },
      { key: '/runs', icon: <ThunderboltOutlined />, text: 'Runs' },
      { key: '/runs/new', icon: <PlusCircleOutlined />, text: 'New run' },
      { key: '/compare', icon: <DiffOutlined />, text: 'Compare' },
    ],
  },
  {
    label: 'Setup',
    links: [
      { key: '/sites', icon: <AppstoreOutlined />, text: 'Sites' },
      { key: '/environments', icon: <CloudServerOutlined />, text: 'Environments' },
      { key: '/configs', icon: <SettingOutlined />, text: 'Configs' },
      { key: '/directory', icon: <DatabaseOutlined />, text: 'Directory' },
    ],
  },
]

const NAV_KEYS = NAV.flatMap((group) => group.links.map((l) => l.key))

const items = NAV.map((group) => ({
  key: group.label,
  type: 'group',
  label: group.label,
  children: group.links.map(({ key, icon, text }) => ({
    key,
    icon,
    label: <Link to={key}>{text}</Link>,
  })),
}))

export default function App() {
  const location = useLocation()
  // Longest matching prefix wins so /runs/new highlights "New run", not "Runs".
  const selected =
    NAV_KEYS.filter((k) => k !== '/' && location.pathname.startsWith(k)).sort(
      (a, b) => b.length - a.length,
    )[0] || '/'

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider breakpoint="lg" collapsedWidth="0" theme="dark">
        <div style={{ color: '#fff', padding: '18px 16px', fontWeight: 700, fontSize: 18, letterSpacing: 0.5 }}>
          ⚡ thunderherd
        </div>
        <Menu theme="dark" mode="inline" selectedKeys={[selected]} items={items} />
      </Sider>
      <Layout>
        <Header style={{ background: '#fff', paddingInline: 24, display: 'flex', alignItems: 'center' }}>
          <Typography.Text type="secondary">Load testing — metrics, runs & trends</Typography.Text>
        </Header>
        <Content style={{ margin: 24 }}>
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/runs" element={<Runs />} />
            <Route path="/runs/new" element={<NewRun />} />
            <Route path="/compare" element={<Compare />} />
            <Route path="/runs/:id" element={<RunDetail />} />
            <Route path="/sites" element={<Sites />} />
            <Route path="/environments" element={<Environments />} />
            <Route path="/configs" element={<Configs />} />
            <Route path="/directory" element={<Directory />} />
            <Route
              path="*"
              element={
                <Result
                  status="404"
                  title="Page not found"
                  extra={<Link to="/"><Button type="primary">Back to dashboard</Button></Link>}
                />
              }
            />
          </Routes>
        </Content>
      </Layout>
    </Layout>
  )
}

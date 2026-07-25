import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { ConfigProvider } from 'antd'
import 'antd/dist/reset.css'
import App from '../src/App'

const root = document.getElementById('root')
if (root) {
  createRoot(root).render(
    <BrowserRouter>
      <ConfigProvider theme={{ token: { colorPrimary: '#6C4BF4' } }}>
        <App />
      </ConfigProvider>
    </BrowserRouter>,
  )
}

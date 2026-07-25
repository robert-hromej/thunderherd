import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './app/frontend/test/setup.js',
    include: ['app/frontend/**/*.test.{js,jsx}'],
    css: false,
  },
})

import React from 'react'
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts'

const short = (p) => (p.length > 34 ? `…${p.slice(-33)}` : p)

// Show the slowest `top` pages, sorted descending. A fixed-height wrapper with the
// ResponsiveContainer at height="100%" gives Recharts a concrete box to measure even
// when the chart mounts below the fold (avoids the zero-measure "no bars" bug).
export default function PagesBarChart({ rows, dataKey = 'p95_ms', name = 'p95 (ms)', color = '#6C4BF4', top = 15 }) {
  const data = (rows || [])
    .map((r) => ({ page: short(r.path), value: Number(r[dataKey]) || 0 }))
    .sort((a, b) => b.value - a.value)
    .slice(0, top)
  const height = Math.max(200, data.length * 28)

  return (
    <div style={{ width: '100%', height }}>
      <ResponsiveContainer width="100%" height="100%" debounce={50}>
        <BarChart data={data} layout="vertical" margin={{ left: 20, right: 24, top: 8, bottom: 8 }}>
          <CartesianGrid strokeDasharray="3 3" horizontal={false} />
          <XAxis type="number" />
          <YAxis type="category" dataKey="page" width={190} tick={{ fontSize: 11 }} />
          <Tooltip formatter={(v) => [`${v}`, name]} />
          <Bar dataKey="value" name={name} fill={color} radius={[0, 3, 3, 0]} isAnimationActive={false} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  )
}

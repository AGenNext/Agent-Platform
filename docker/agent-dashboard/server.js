const express = require('express')
const path = require('path')
const { createProxyMiddleware } = require('http-proxy-middleware')

const app = express()
const PORT = process.env.PORT || 3000
const KNOWLEDGE_URL = process.env.AGENT_KNOWLEDGE_URL || 'http://agent-knowledge:8001'
const SURREAL_API_URL = process.env.SURREAL_API_URL || 'http://surrealdb:8000/api/agent_platform/agent_platform'

app.use(express.json())

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'realgraph-dashboard', version: '0.2.0' })
})

app.use('/.well-known', createProxyMiddleware({
  target: SURREAL_API_URL,
  changeOrigin: true,
  pathRewrite: (_path, req) => req.originalUrl,
}))

app.use('/api', createProxyMiddleware({
  target: KNOWLEDGE_URL,
  changeOrigin: true,
  pathRewrite: { '^/api': '' },
}))

app.use(express.static(path.join(__dirname, 'public')))

app.get('*', (_req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'))
})

app.listen(PORT, () => {
  console.log(`RealGraph Dashboard running on port ${PORT}`)
  console.log(`Proxying /api → ${KNOWLEDGE_URL}`)
})

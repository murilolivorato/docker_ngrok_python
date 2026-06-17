<template>
  <div class="container">
    <h1>🐍 + 💚 + 🐳 + 🔗 It works!</h1>
    <p>Vue.js frontend talking to a Python Flask backend via Docker + ngrok</p>

    <section class="info-card">
      <h2>Backend Info</h2>
      <div v-if="loading" class="loading">Loading...</div>
      <div v-else-if="error" class="error">{{ error }}</div>
      <div v-else class="info">
        <p><strong>Message:</strong> {{ backendData.message }}</p>
        <p><strong>Host:</strong> {{ backendData.host }}</p>
        <p><strong>Time:</strong> {{ backendData.time }}</p>
      </div>
    </section>

    <section class="webhook-section">
      <h2>Test Webhook</h2>
      <button @click="testWebhook" :disabled="webhookLoading">
        {{ webhookLoading ? 'Sending...' : 'Send Test Webhook' }}
      </button>
      <div v-if="webhookStatus" :class="['webhook-status', webhookSuccess ? 'success' : 'error']">
        {{ webhookStatus }}
      </div>
    </section>
  </div>
</template>

<script>
import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000'

export default {
  name: 'App',
  data() {
    return {
      backendData: {},
      loading: true,
      error: null,
      webhookLoading: false,
      webhookStatus: null,
      webhookSuccess: false,
    }
  },
  mounted() {
    this.fetchBackendData()
  },
  methods: {
    async fetchBackendData() {
      try {
        this.loading = true
        this.error = null
        const response = await axios.get(`${API_URL}/api/hello`)
        this.backendData = response.data
      } catch (err) {
        this.error = `Failed to connect to backend: ${err.message}`
      } finally {
        this.loading = false
      }
    },
    async testWebhook() {
      try {
        this.webhookLoading = true
        this.webhookStatus = null
        const payload = {
          test: true,
          timestamp: new Date().toISOString(),
          message: 'Test webhook from Vue frontend'
        }
        const response = await axios.post(`${API_URL}/webhook`, payload)
        this.webhookSuccess = true
        this.webhookStatus = `✓ Webhook received: ${JSON.stringify(response.data)}`
      } catch (err) {
        this.webhookSuccess = false
        this.webhookStatus = `✗ Webhook failed: ${err.message}`
      } finally {
        this.webhookLoading = false
      }
    }
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  padding: 20px;
}

#app {
  min-height: 100vh;
}

.container {
  max-width: 640px;
  margin: 40px auto;
  background: white;
  border-radius: 12px;
  padding: 40px;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
}

h1 {
  color: #333;
  margin-bottom: 10px;
  font-size: 28px;
}

p {
  color: #666;
  margin-bottom: 30px;
  line-height: 1.6;
}

.info-card {
  background: #f8f9fa;
  border-left: 4px solid #667eea;
  padding: 20px;
  border-radius: 6px;
  margin-bottom: 30px;
}

.info-card h2 {
  color: #333;
  font-size: 18px;
  margin-bottom: 15px;
}

.info {
  color: #555;
  line-height: 1.8;
}

.info p {
  margin-bottom: 10px;
  font-family: 'Monaco', 'Courier New', monospace;
  font-size: 14px;
}

.loading, .error {
  padding: 15px;
  border-radius: 4px;
  font-weight: 500;
}

.loading {
  color: #667eea;
  background: #e8eaf6;
}

.error {
  color: #c62828;
  background: #ffebee;
}

.webhook-section {
  text-align: center;
}

.webhook-section h2 {
  color: #333;
  font-size: 18px;
  margin-bottom: 15px;
}

button {
  background: #667eea;
  color: white;
  border: none;
  padding: 12px 30px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  transition: all 0.3s ease;
}

button:hover:not(:disabled) {
  background: #5568d3;
  transform: translateY(-2px);
  box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.webhook-status {
  margin-top: 15px;
  padding: 15px;
  border-radius: 6px;
  font-family: 'Monaco', 'Courier New', monospace;
  font-size: 12px;
  word-break: break-all;
}

.webhook-status.success {
  color: #2e7d32;
  background: #e8f5e9;
}

.webhook-status.error {
  color: #c62828;
  background: #ffebee;
}
</style>

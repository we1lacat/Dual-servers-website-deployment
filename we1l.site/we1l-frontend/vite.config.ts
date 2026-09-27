import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    port: 5173,
    proxy: {
      '/api': {
        // 默认代理到本地 8080 后端；可用环境变量 BACKEND_URL 覆盖（联调用）
        target: process.env.BACKEND_URL || 'http://localhost:8080',
        changeOrigin: true,
      },
      // 后台上传的图片（缩略图等）由后端 /uploads/** 静态提供，dev 下同样需要代理
      '/uploads': {
        target: process.env.BACKEND_URL || 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  build: {
    chunkSizeWarningLimit: 1200,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['vue', 'vue-router', 'pinia', 'axios'],
          'element-plus': ['element-plus'],
          echarts: ['echarts'],
        },
      },
    },
  },
})

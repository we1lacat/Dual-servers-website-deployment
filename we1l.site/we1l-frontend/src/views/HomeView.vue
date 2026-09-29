<template>
  <div class="page">
    <h1 class="page-title">{{ profile?.siteName || 'we1l.site' }}</h1>
    <p class="page-desc">
      <!-- 站点标语只有 /api/profile 一个来源（库里的 site_profile 表），此处不再硬编码兜底，
           避免与后端默认值 / index.html meta 三处漂移；接口未回来时仅短暂为空 -->
      {{ profile?.siteSlogan }}
    </p>

    <!-- 站点趋势折线图：GET /api/trends -->
    <section>
      <div class="chart-block">
        <div class="chart-head">
          <span class="chart-title">站点数据 · 2026</span>
          <span class="chart-meta">GET /api/trends · 每月自动汇总</span>
        </div>

        <div v-if="loading" class="skeleton-block" style="border: none; padding: 0">
          <div style="height: 280px; display: flex; align-items: center; justify-content: center; color: var(--text-faint); font-size: 13px">
            图表数据加载中…
          </div>
        </div>
        <div v-else-if="error" class="error-block">
          {{ error }}　<button style="color: var(--blue); border: none; background: none; cursor: pointer" @click="load">重试</button>
        </div>
        <TrendChart v-else-if="trend.length" :data="trend" />
        <div v-else class="error-block">暂无趋势数据，请到后台添加</div>

        <div class="chart-api-note">
          <span class="tag">访问量</span>
          <span class="tag">负载</span>
          <span class="tag">工作量</span>
          <span class="tag">预期</span>
          <span>数据可视化面板</span>
        </div>
      </div>
    </section>

    <div class="n-divider"></div>

    <!-- 快速入口 -->
    <section>
      <h2 class="section-title">快速入口</h2>
      <p class="section-sub">常用</p>
      <div class="quick-grid">
        <router-link to="/service" class="quick-card">
          <div class="qc-title">服务</div>
          <div class="qc-desc">作品展示 / 学习笔记 / 简历模板</div>
        </router-link>
        <router-link to="/about" class="quick-card">
          <div class="qc-title">关于</div>
          <div class="qc-desc">正在学习 ·/技术栈 </div>
        </router-link>
        <router-link to="/admin" class="quick-card">
          <div class="qc-title">站点管理</div>
          <div class="qc-desc">内容修改 </div>
        </router-link>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import TrendChart from '@/components/TrendChart.vue'
import { fetchProfile, fetchTrend, type SiteProfile, type SiteTrend } from '@/api'

const profile = ref<SiteProfile | null>(null)
const trend = ref<SiteTrend[]>([])
const loading = ref(true)
const error = ref('')

async function load() {
  loading.value = true
  error.value = ''
  try {
    const [p, t] = await Promise.all([fetchProfile(), fetchTrend()])
    profile.value = p
    trend.value = t
  } catch (e: any) {
    error.value = e?.message || '数据加载失败，请确认后端服务已启动'
  } finally {
    loading.value = false
  }
}

onMounted(load)
</script>

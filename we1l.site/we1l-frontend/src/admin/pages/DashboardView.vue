<template>
  <div>
    <div class="admin-page-header">
      <div>
        <h2 class="admin-page-title">概览</h2>
        <p class="admin-page-desc">
          各模块内容数量统计 · 接口 GET /api/admin/stats
        </p>
      </div>
    </div>

    <div v-if="loading" class="skeleton-block">
      <div class="skeleton-line" style="width: 80%"></div>
      <div class="skeleton-line" style="width: 60%"></div>
    </div>

    <template v-else>
      <div class="stat-grid">
        <div v-for="c in cards" :key="c.label" class="stat-card">
          <div class="sc-value">{{ c.value }}</div>
          <div class="sc-label">{{ c.label }}</div>
        </div>
      </div>

      <div class="callout" style="margin: 0">
        左侧菜单进入各模块进行增删改查；前台页面实时读取接口数据，修改保存后立即生效。
        前台访问：<router-link to="/" target="_blank" style="color: var(--blue)">we1l.site ↗</router-link>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { fetchStats, type AdminStats } from '@/api'

const stats = ref<AdminStats | null>(null)
const loading = ref(true)

const cards = ref<{ label: string; value: number }[]>([])

onMounted(async () => {
  try {
    stats.value = await fetchStats()
    const s = stats.value
    cards.value = [
      { label: '站点趋势数据点', value: s.trendCount },
      { label: '正在学习', value: s.learningCount },
      { label: '技能条目', value: s.skillCount },
      { label: '社交渠道', value: s.socialCount },
      { label: '作品', value: s.workCount },
      { label: '笔记', value: s.noteCount },
      { label: '简历模板', value: s.resumeCount },
    ]
  } catch {
    /* 错误已由拦截器统一提示 */
  } finally {
    loading.value = false
  }
})
</script>

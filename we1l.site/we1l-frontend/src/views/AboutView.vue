<template>
  <div class="page">
    <h1 class="page-title">关于我</h1>
    <p class="page-desc">
      {{ profile?.ownerName || 'we1l' }} · {{ profile?.ownerTitle || ' 持续学习中' }}
    </p>

    <div class="callout">
      邮箱：<a :href="`mailto:${profile?.email || ''}`" style="color: var(--blue)">{{ profile?.email || 'hi@we1l.site' }}</a>
      　·　当前专注方向持续更新中
    </div>

    <!-- 正在学习：GET /api/learnings -->
    <section>
      <h2 class="section-title">正在学习</h2>
      <p class="section-sub">{{ learnings.length }} 项进行中</p>
      <div v-if="loading" class="skeleton-block">
        <div class="skeleton-line" style="width: 80%"></div>
        <div class="skeleton-line" style="width: 65%"></div>
      </div>
      <div v-else class="learning-grid">
        <div v-for="l in learnings" :key="l.id" class="learn-card">
          <div class="lc-head">{{ l.title }}</div>
          <div class="lc-desc">{{ l.description }}</div>
        </div>
      </div>
    </section>

    <div class="n-divider"></div>

    <!-- 技能进度条：GET /api/skills?type=BAR -->
    <section>
      <h2 class="section-title">技能栈</h2>
      <p class="section-sub">并非精通，并非并非</p>
      <div v-if="loading" class="skeleton-block">
        <div class="skeleton-line" style="width: 90%"></div>
        <div class="skeleton-line" style="width: 76%"></div>
        <div class="skeleton-line" style="width: 83%"></div>
      </div>
      <div v-else class="skill-list">
        <div v-for="s in barSkills" :key="s.id" class="skill-item">
          <div class="skill-head">
            <span>{{ s.skillName }}</span>
            <span>{{ s.percentValue }}%</span>
          </div>
          <div class="skill-bar">
            <div
              class="skill-fill"
              :class="colorClass(s.colorKey)"
              :style="{ width: loaded ? s.percentValue + '%' : '0%' }"
            ></div>
          </div>
        </div>
      </div>
    </section>

    <div class="n-divider"></div>

    <!-- 能力雷达：GET /api/skills?type=RADAR -->
    <section>
      <h2 class="section-title">能力雷达</h2>
      <p class="section-sub">六维评估</p>
      <div class="radar-block">
        <SkillRadar v-if="radarSkills.length" :skills="radarSkills" />
        <div v-else class="radar-canvas" style="display: flex; align-items: center; justify-content: center; color: var(--text-faint); font-size: 13px">
          暂无数据
        </div>
        <div class="radar-legend">
          <b>综合评估</b>
          数据来自 <code>GET /api/skills?type=RADAR</code>，正在填补空缺；
          雷达图由 ECharts 渲染，随接口数据实时更新。
        </div>
      </div>
    </section>

    <div class="n-divider"></div>

    <!-- 社交矩阵：GET /api/socials -->
    <section>
      <h2 class="section-title">社交矩阵</h2>
      <p class="section-sub">{{ socials.length }} 个渠道找到我</p>
      <div v-if="loading" class="skeleton-block">
        <div class="skeleton-line" style="width: 88%"></div>
        <div class="skeleton-line" style="width: 72%"></div>
      </div>
      <div v-else class="social-grid">
        <component
          :is="s.url ? 'a' : 'div'"
          v-for="s in socials"
          :key="s.id"
          :href="s.url || undefined"
          :target="s.url ? '_blank' : undefined"
          :rel="s.url ? 'noopener' : undefined"
          class="social-card"
        >
          <div>
            <div class="sc-name">{{ s.platform }}</div>
            <div class="sc-handle">{{ s.handle }}</div>
          </div>
        </component>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import SkillRadar from '@/components/SkillRadar.vue'
import {
  fetchProfile, fetchLearnings, fetchSkills, fetchSocials,
  type SiteProfile, type LearningItem, type Skill, type SocialLink,
} from '@/api'

const profile = ref<SiteProfile | null>(null)
const learnings = ref<LearningItem[]>([])
const barSkills = ref<Skill[]>([])
const radarSkills = ref<Skill[]>([])
const socials = ref<SocialLink[]>([])
const loading = ref(true)
const loaded = ref(false)

function colorClass(key?: string) {
  const allowed = ['blue', 'green', 'orange', 'purple']
  return key && allowed.includes(key) ? `c-${key}` : ''
}

onMounted(async () => {
  try {
    const [p, l, bar, radar, s] = await Promise.all([
      fetchProfile(), fetchLearnings(), fetchSkills('BAR'), fetchSkills('RADAR'), fetchSocials(),
    ])
    profile.value = p
    learnings.value = l
    barSkills.value = bar
    radarSkills.value = radar
    socials.value = s
    // 下一帧再展开进度条，触发过渡动画
    requestAnimationFrame(() => setTimeout(() => { loaded.value = true }, 60))
  } finally {
    loading.value = false
  }
})
</script>

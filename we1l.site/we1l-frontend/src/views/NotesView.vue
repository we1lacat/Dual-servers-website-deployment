<template>
  <div class="page">
    <h1 class="page-title">笔记 / 服务</h1>
    <p class="page-desc">展示 · 简历模板 —— 全部数据来自后端接口</p>

    <div class="callout">
      本页内容更新于九月二十七日。
    </div>

    <!-- 作品展示：GET /api/works -->
    <section>
      <h2 class="section-title">作品展示</h2>
      <p class="section-sub">{{ works.length }} 个项目对外开放</p>
      <div v-if="loading" class="skeleton-block">
        <div class="skeleton-line" style="width: 85%"></div>
        <div class="skeleton-line" style="width: 70%"></div>
      </div>
      <div v-else class="gallery">
        <component
          :is="w.link ? 'a' : 'div'"
          v-for="(w, i) in works"
          :key="w.id"
          :href="w.link || undefined"
          :target="w.link ? '_blank' : undefined"
          :rel="w.link ? 'noopener' : undefined"
          class="work-card"
        >
          <div class="work-thumb" :class="`thumb-${(i % 6) + 1}`"></div>
          <div class="work-body">
            <div class="work-title">{{ w.title }}</div>
            <div class="work-meta">{{ w.techMeta }}<span v-if="w.category"> · {{ w.category }}</span></div>
          </div>
        </component>
      </div>
    </section>

    <div class="n-divider"></div>

    <!-- 学习笔记：GET /api/notes -->
    <section>
      <h2 class="section-title">学习笔记</h2>
      <p class="section-sub">{{ notes.length }} 篇 · 点击查看全文</p>
      <div v-if="loading" class="skeleton-block">
        <div class="skeleton-line" style="width: 88%"></div>
        <div class="skeleton-line" style="width: 76%"></div>
        <div class="skeleton-line" style="width: 82%"></div>
      </div>
      <div v-else class="notion-list">
        <div v-for="n in notes" :key="n.id" class="row" @click="openNote(n)">
          <!-- 可选缩略图：配了 cover 才渲染；无 cover 时行内只有标题，与原本样式完全一致 -->
          <div class="row-main">
            <img v-if="n.cover" :src="n.cover" class="row-thumb" alt="" loading="lazy" />
            <span class="row-title">{{ n.title }}</span>
          </div>
          <span class="row-tag">{{ n.category }}</span>
          <span class="row-date">{{ n.publishedAt }}</span>
        </div>
      </div>
    </section>

    <div class="n-divider"></div>

    <!-- 简历模板：GET /api/resumes -->
    <section>
      <h2 class="section-title">简历模板</h2>
      <p class="section-sub">{{ resumes.length }} 套可下载</p>
      <div v-if="loading" class="skeleton-block">
        <div class="skeleton-line" style="width: 78%"></div>
        <div class="skeleton-line" style="width: 64%"></div>
      </div>
      <div v-else class="resume-grid">
        <component
          :is="r.fileUrl ? 'a' : 'div'"
          v-for="r in resumes"
          :key="r.id"
          :href="r.fileUrl || undefined"
          :target="r.fileUrl ? '_blank' : undefined"
          :rel="r.fileUrl ? 'noopener' : undefined"
          class="resume-card"
        >
          <div class="resume-thumb">
            <div class="resume-doc">
              <div class="ln head"></div>
              <div class="ln w60"></div>
              <div class="ln w80 dark"></div>
              <div class="ln w40"></div>
              <div class="ln w60 dark"></div>
              <div class="ln w80"></div>
            </div>
          </div>
          <div class="resume-body">
            <div class="resume-title">{{ r.title }}</div>
            <div class="resume-meta">
              <span>{{ r.fileType }} · {{ r.fileSize }}</span>
              <span v-if="r.fileUrl" class="dl-link">下载</span>
            </div>
          </div>
        </component>
      </div>
    </section>

    <!-- 笔记详情抽屉（移动端全屏） -->
    <el-drawer v-model="drawerVisible" :title="currentNote?.title || '笔记'" :size="isMobile ? '100%' : '480px'">
      <div v-if="currentNote">
        <!-- 可选缩略图：笔记配了图才在详情顶部展示 -->
        <img v-if="currentNote.cover" :src="currentNote.cover" class="drawer-cover" alt="" />
        <div style="font-size: 12.5px; color: var(--text-faint); margin-bottom: 16px">
          {{ currentNote.category }} · {{ currentNote.publishedAt }} · 阅读 {{ currentNote.views }}
        </div>
        <p style="font-size: 14px; color: var(--text-secondary); margin-bottom: 16px; padding: 12px 14px; background: var(--bg-gray); border-radius: 6px">
          {{ currentNote.summary }}
        </p>
        <div style="font-size: 14.5px; line-height: 2; white-space: pre-wrap">{{ currentNote.content }}</div>
      </div>
    </el-drawer>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { fetchWorks, fetchNotes, fetchNote, type WorkItem, type Note, type ResumeTemplate } from '@/api'

const works = ref<WorkItem[]>([])
const notes = ref<Note[]>([])
const resumes = ref<ResumeTemplate[]>([])
const loading = ref(true)

const drawerVisible = ref(false)
const currentNote = ref<Note | null>(null)

/* 移动端判定：抽屉全屏展示，正文内容更宽松 */
const isMobile = ref(typeof window !== 'undefined' && window.innerWidth <= 768)
function onResize() {
  isMobile.value = window.innerWidth <= 768
}
onMounted(() => window.addEventListener('resize', onResize))
onBeforeUnmount(() => window.removeEventListener('resize', onResize))

async function openNote(n: Note) {
  try {
    currentNote.value = await fetchNote(n.id!)
    drawerVisible.value = true
  } catch {
    /* 错误已由拦截器提示 */
  }
}

onMounted(async () => {
  try {
    const [w, n, r] = await Promise.all([fetchWorks(), fetchNotes(), fetchResumesSafe()])
    works.value = w
    notes.value = n
    resumes.value = r
  } finally {
    loading.value = false
  }
})

async function fetchResumesSafe(): Promise<ResumeTemplate[]> {
  try {
    const { fetchResumes } = await import('@/api')
    return await fetchResumes()
  } catch {
    return []
  }
}
</script>

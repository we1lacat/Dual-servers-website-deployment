<template>
  <header class="site-header">
    <nav class="nav-primary">
      <!-- 移动端汉堡按钮 -->
      <button class="nav-hamburger" type="button" aria-label="打开导航菜单" @click="drawer = true">
        <el-icon :size="20"><Menu /></el-icon>
      </button>

      <router-link to="/" class="brand">we1l<span class="dot">.</span>site</router-link>

      <div class="nav-links">
        <router-link to="/">首页</router-link>
        <router-link to="/notes">笔记 / 服务</router-link>
        <router-link to="/about">关于我</router-link>
      </div>

      <div class="nav-status" :title="statusTip">
        <span class="status-dot" :class="dotClass"></span>
        <span>{{ statusText }}</span>
      </div>

      <!-- 右上角登录入口 -->
      <div class="auth-entry">
        <template v-if="authStore.isAuthenticated() && user">
          <el-dropdown trigger="click" @command="onCommand">
            <span class="auth-login-btn auth-logged" title="已登录" aria-label="已登录">
              <el-icon><User /></el-icon>
              <span class="auth-login-text">已登录</span>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="admin">
                  <el-icon><Setting /></el-icon> 进入后台
                </el-dropdown-item>
                <el-dropdown-item command="logout" divided>
                  <el-icon><SwitchButton /></el-icon> 退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </template>
        <template v-else>
          <router-link to="/login" class="auth-login-btn" title="Admin 登录" aria-label="Admin 登录">
            <el-icon><User /></el-icon>
            <span class="auth-login-text">登录</span>
          </router-link>
        </template>
      </div>
    </nav>

    <!-- 移动端抽屉导航 -->
    <el-drawer
      v-model="drawer"
      title="导航"
      direction="ltr"
      size="74%"
      class="mobile-nav-drawer"
    >
      <nav class="mobile-nav-list">
        <router-link to="/">首页</router-link>
        <router-link to="/notes">笔记 / 服务</router-link>
        <router-link to="/about">关于我</router-link>
        <router-link v-if="!authStore.isAuthenticated()" to="/login">登录</router-link>
        <template v-else>
          <router-link to="/admin">进入后台</router-link>
          <a href="javascript:void(0)" @click="onCommand('logout')">退出登录</a>
        </template>
      </nav>
      <div class="mobile-nav-foot">
        <span class="status-dot" :class="dotClass"></span>
        <span>{{ statusText }}</span>
      </div>
    </el-drawer>
  </header>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Setting, SwitchButton, Menu } from '@element-plus/icons-vue'
import { authStore } from '@/auth/store'
import { fetchOpsStatus, type OpsStatus } from '@/api'

const router = useRouter()
const route = useRoute()
const user = computed(() => authStore.user())
const drawer = ref(false)

// ---------- 运行状态指示器 ----------
// ok=站点正常(绿) / warn=风险运行中(黄, 备份失效) / danger=无风控运行(红, 监控失效)
const opsLevel = ref<'ok' | 'warn' | 'danger' | 'unknown'>('unknown')
const opsDetail = ref('')
const POLL_MS = 60_000

const STATUS_META: Record<string, { dot: string; text: string }> = {
  ok: { dot: 'is-ok', text: '站点正常' },
  warn: { dot: 'is-warn', text: '风险运行中' },
  danger: { dot: 'is-danger', text: '无风控运行' },
  unknown: { dot: 'is-unknown', text: '状态未知' },
}

const dotClass = computed(() => STATUS_META[opsLevel.value]?.dot || 'is-unknown')
const statusText = computed(() => STATUS_META[opsLevel.value]?.text || '状态未知')
const statusTip = computed(() => opsDetail.value || statusText.value)

async function refreshOpsStatus() {
  try {
    const s: OpsStatus = await fetchOpsStatus()
    opsLevel.value = s.level
    const mon = s.monitor?.up ? '监控正常' : '监控失效'
    const bak = s.backup?.ok
      ? `备份正常(最近 ${s.backup.lastTime || '-'})`
      : '备份异常'
    opsDetail.value = `${mon} · ${bak}`
  } catch {
    opsLevel.value = 'unknown'
    opsDetail.value = '状态接口不可达，请稍后重试'
  }
}

let timer: number | undefined
onMounted(() => {
  refreshOpsStatus()
  timer = window.setInterval(refreshOpsStatus, POLL_MS)
})
onUnmounted(() => {
  if (timer) window.clearInterval(timer)
})

// 路由变化后自动关闭抽屉
watch(() => route.fullPath, () => { drawer.value = false })

function onCommand(cmd: string) {
  if (cmd === 'admin') {
    drawer.value = false
    router.push('/admin')
  } else if (cmd === 'logout') {
    authStore.clear()
    drawer.value = false
    ElMessage.success('已退出登录')
    router.push('/')
  }
}
</script>

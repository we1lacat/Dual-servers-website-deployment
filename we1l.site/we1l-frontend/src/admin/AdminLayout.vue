<template>
  <el-container style="min-height: 100vh">
    <!-- 桌面端固定侧栏（≤768px 由 CSS 隐藏） -->
    <el-aside class="admin-aside-desktop" width="220px" style="background: var(--nav-black-solid)">
      <div class="admin-logo">
        we1l.site
        <span class="badge">Admin</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        router
        background-color="#151515"
        text-color="rgba(255,255,255,0.6)"
        active-text-color="#ffffff"
      >
        <el-menu-item v-for="m in menus" :key="m.path" :index="m.path">{{ m.label }}</el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="admin-header">
        <button class="admin-hamburger" type="button" aria-label="打开后台菜单" @click="drawer = true">
          <el-icon :size="20"><Menu /></el-icon>
        </button>
        <div style="font-size: 14px; color: var(--text-secondary)">
          we1l.site 内容管理系统 · Spring Boot 3 + MyBatis-Plus
        </div>
        <div style="display: flex; gap: 14px; align-items: center">
          <router-link to="/" target="_blank" style="font-size: 13.5px; color: var(--blue)">查看前台 ↗</router-link>
        </div>
      </el-header>
      <el-main class="admin-main">
        <router-view />
      </el-main>
      <SiteFooter />
    </el-container>

    <!-- 移动端抽屉菜单 -->
    <el-drawer v-model="drawer" direction="ltr" size="72%" class="mobile-nav-drawer">
      <template #header>
        <div class="admin-logo" style="padding: 0; border: none; height: auto">
          we1l.site <span class="badge">Admin</span>
        </div>
      </template>
      <el-menu
        :default-active="activeMenu"
        router
        @select="drawer = false"
      >
        <el-menu-item v-for="m in menus" :key="m.path" :index="m.path">{{ m.label }}</el-menu-item>
      </el-menu>
    </el-drawer>
  </el-container>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Menu } from '@element-plus/icons-vue'
import SiteFooter from '@/components/SiteFooter.vue'

const route = useRoute()
const activeMenu = computed(() => route.path)
const drawer = ref(false)

const menus = [
  { path: '/admin', label: '概览' },
  { path: '/admin/profile', label: '站点档案' },
  { path: '/admin/trend', label: '站点趋势' },
  { path: '/admin/learnings', label: '正在学习' },
  { path: '/admin/skills', label: '技能' },
  { path: '/admin/socials', label: '社交矩阵' },
  { path: '/admin/works', label: '作品展示' },
  { path: '/admin/notes', label: '学习笔记' },
  { path: '/admin/resumes', label: '简历模板' },
]

// 路由变化后关闭抽屉
watch(() => route.fullPath, () => { drawer.value = false })
</script>

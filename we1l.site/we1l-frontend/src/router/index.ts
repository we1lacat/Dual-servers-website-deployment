import { createRouter, createWebHistory } from 'vue-router'
import { authStore } from '@/auth/store'

/* ============================================================
   路由表

   命名约定（改路由请一并遵守）：
   · 路由 path 与页面显示名对齐：显示「服务」→ 路径 /service
   · 路由 name：前台用短名（home / service / about / login）；
     后台统一加 admin- 前缀（admin-dashboard / admin-notes …）
   · meta.title：浏览器标签标题，由 afterEach 拼成 `${title} · we1l.site`
   · meta.requiresAuth：只在 /admin 父路由声明一次即可 —— vue-router
     会把父级 meta 合并进 to.meta，子路由无需重复声明
   ============================================================ */

declare module 'vue-router' {
  interface RouteMeta {
    /** 浏览器标签标题，最终拼成 `${title} · we1l.site` */
    title?: string
    /** 需要登录；在父路由声明即可，子路由自动继承 */
    requiresAuth?: boolean
  }
}

const routes = [
  /* ---------- 前台：带站点头部 / 页脚 ---------- */
  {
    path: '/',
    component: () => import('@/views/FrontLayout.vue'),
    children: [
      { path: '', name: 'home', component: () => import('@/views/HomeView.vue'), meta: { title: '首页' } },
      { path: 'service', name: 'service', component: () => import('@/views/ServiceView.vue'), meta: { title: '服务' } },
      { path: 'about', name: 'about', component: () => import('@/views/AboutView.vue'), meta: { title: '关于我' } },
    ],
  },

  /* ---------- 登录：独立布局，不含站点头部 ---------- */
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
    meta: { title: '登录' },
  },

  /* ---------- 后台：需登录（requiresAuth 在父级声明，子路由继承） ---------- */
  {
    path: '/admin',
    component: () => import('@/admin/AdminLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', name: 'admin-dashboard', component: () => import('@/admin/pages/DashboardView.vue'), meta: { title: '概览' } },
      { path: 'profile', name: 'admin-profile', component: () => import('@/admin/pages/ProfileView.vue'), meta: { title: '站点档案' } },
      { path: 'trend', name: 'admin-trend', component: () => import('@/admin/pages/TrendPage.vue'), meta: { title: '站点趋势' } },
      { path: 'learnings', name: 'admin-learnings', component: () => import('@/admin/pages/LearningPage.vue'), meta: { title: '正在学习' } },
      { path: 'skills', name: 'admin-skills', component: () => import('@/admin/pages/SkillPage.vue'), meta: { title: '技能' } },
      { path: 'socials', name: 'admin-socials', component: () => import('@/admin/pages/SocialPage.vue'), meta: { title: '社交矩阵' } },
      { path: 'works', name: 'admin-works', component: () => import('@/admin/pages/WorkPage.vue'), meta: { title: '作品展示' } },
      { path: 'notes', name: 'admin-notes', component: () => import('@/admin/pages/NotePage.vue'), meta: { title: '学习笔记' } },
      { path: 'resumes', name: 'admin-resumes', component: () => import('@/admin/pages/ResumePage.vue'), meta: { title: '简历模板' } },
    ],
  },

  /* ---------- 旧地址兼容：前台页面由「笔记 / 服务」更名为「服务」，
       保留 /notes → /service 的永久重定向，避免既有外链 404 ---------- */
  { path: '/notes', redirect: { name: 'service' } },

  /* ---------- 兜底：未匹配路径一律回首页（用具名路由，路径再变也不会失效） ---------- */
  { path: '/:pathMatch(.*)*', redirect: { name: 'home' } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})

/* 路由守卫：返回「目标位置」即改道，返回 true / undefined 即放行 */
router.beforeEach((to) => {
  // 未登录访问受保护页面 → 去登录页，并记住原目标以便登录后跳回
  if (to.meta.requiresAuth && !authStore.isAuthenticated()) {
    return { path: '/login', query: { redirect: to.fullPath } }
  }
  // 已登录却访问登录页 → 直接放行到 redirect 目标或后台首页
  if (to.path === '/login' && authStore.isAuthenticated()) {
    return (to.query.redirect as string) || '/admin'
  }
  return true
})

/* 浏览器标签标题统一在此拼接，页面内无需各自维护 */
router.afterEach((to) => {
  document.title = to.meta.title ? `${to.meta.title} · we1l.site` : 'we1l.site'
})

export default router

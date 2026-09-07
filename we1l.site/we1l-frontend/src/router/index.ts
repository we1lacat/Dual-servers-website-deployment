import { createRouter, createWebHistory } from 'vue-router'
import { authStore } from '@/auth/store'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      component: () => import('@/views/FrontLayout.vue'),
      children: [
        { path: '', name: 'home', component: () => import('@/views/HomeView.vue'), meta: { title: '首页' } },
        { path: 'notes', name: 'notes', component: () => import('@/views/NotesView.vue'), meta: { title: '笔记 / 服务' } },
        { path: 'about', name: 'about', component: () => import('@/views/AboutView.vue'), meta: { title: '关于我' } },
      ],
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
      meta: { title: '登录', hideHeader: true },
    },
    {
      path: '/admin',
      component: () => import('@/admin/AdminLayout.vue'),
      meta: { requiresAuth: true },
      children: [
        { path: '', name: 'admin-dashboard', component: () => import('@/admin/pages/DashboardView.vue'), meta: { title: '概览', requiresAuth: true } },
        { path: 'profile', name: 'admin-profile', component: () => import('@/admin/pages/ProfileView.vue'), meta: { title: '站点档案', requiresAuth: true } },
        { path: 'trend', name: 'admin-trend', component: () => import('@/admin/pages/TrendPage.vue'), meta: { title: '站点趋势', requiresAuth: true } },
        { path: 'learnings', name: 'admin-learnings', component: () => import('@/admin/pages/LearningPage.vue'), meta: { title: '正在学习', requiresAuth: true } },
        { path: 'skills', name: 'admin-skills', component: () => import('@/admin/pages/SkillPage.vue'), meta: { title: '技能', requiresAuth: true } },
        { path: 'socials', name: 'admin-socials', component: () => import('@/admin/pages/SocialPage.vue'), meta: { title: '社交矩阵', requiresAuth: true } },
        { path: 'works', name: 'admin-works', component: () => import('@/admin/pages/WorkPage.vue'), meta: { title: '作品展示', requiresAuth: true } },
        { path: 'notes', name: 'admin-notes', component: () => import('@/admin/pages/NotePage.vue'), meta: { title: '学习笔记', requiresAuth: true } },
        { path: 'resumes', name: 'admin-resumes', component: () => import('@/admin/pages/ResumePage.vue'), meta: { title: '简历模板', requiresAuth: true } },
      ],
    },
    { path: '/:pathMatch(.*)*', redirect: '/' },
  ],
  scrollBehavior: () => ({ top: 0 }),
})

// 进入 admin 前：未登录 → /login?redirect= 目标
router.beforeEach((to, _from, next) => {
  if (to.meta?.requiresAuth && !authStore.isAuthenticated()) {
    return next({ path: '/login', query: { redirect: to.fullPath } })
  }
  // 已登录访问 /login 直接跳目标或首页
  if (to.path === '/login' && authStore.isAuthenticated()) {
    const redirect = (to.query.redirect as string) || '/admin'
    return next(redirect)
  }
  next()
})

router.afterEach((to) => {
  const title = (to.meta?.title as string) || ''
  document.title = title ? `${title} · we1l.site` : 'we1l.site'
})

export default router

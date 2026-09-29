import { http } from './request'

/* ============================================================
   统一 API 层：对接后端 Result<T> 结构 { code, message, data }

   复用 ./request.ts 的 http 实例：
   - 请求拦截器已自动注入 Authorization: Bearer <token>
   - 响应拦截器已自动按 code===0 解包（失败抛 Error、401 跳登录）
   - 因此这里所有 wrapper 直接返回 Promise<T>，由调用方 try/catch
   ============================================================ */

function get<T>(url: string, config?: Record<string, any>): Promise<T> {
  return http.get(url, config) as unknown as Promise<T>
}
function post<T>(url: string, data?: unknown): Promise<T> {
  return http.post(url, data) as unknown as Promise<T>
}
function put<T>(url: string, data?: unknown): Promise<T> {
  return http.put(url, data) as unknown as Promise<T>
}
function del<T = void>(url: string): Promise<T> {
  return http.delete(url) as unknown as Promise<T>
}

/* ---------------- 类型定义 ---------------- */

export interface SiteProfile {
  id?: number
  siteName: string
  siteSlogan: string
  ownerName: string
  ownerTitle: string
  ownerAvatar?: string
  email: string
  icpNo?: string
  icpUrl?: string
  footerNote?: string
}

export interface SiteTrend {
  id?: number
  statLabel: string
  statValue: number
  sortOrder?: number
  remark?: string
}

export interface LearningItem {
  id?: number
  title: string
  description: string
  icon?: string
  sortOrder?: number
  status?: number
}

export interface Skill {
  id?: number
  skillType: string
  skillName: string
  percentValue: number
  colorKey?: string
  sortOrder?: number
  status?: number
}

export interface SocialLink {
  id?: number
  platform: string
  handle?: string
  url?: string
  icon?: string
  sortOrder?: number
  status?: number
}

export interface WorkItem {
  id?: number
  title: string
  techMeta?: string
  /** 可选缩略图：/uploads/xxx.png；为空时前台沿用默认渐变色块 */
  cover?: string
  link?: string
  category?: string
  sortOrder?: number
  status?: number
  /** 最后更新时间（后端 BaseEntity 维护），供前台「本页内容更新于…」取最大值 */
  updatedAt?: string
}

export interface Note {
  id?: number
  title: string
  category?: string
  summary?: string
  content?: string
  /** 可选缩略图：/uploads/xxx.png；为空时前台按默认样式展示 */
  cover?: string
  author?: string
  views?: number
  publishedAt?: string
  status?: number
  /** 最后更新时间（后端 BaseEntity 维护） */
  updatedAt?: string
}

export interface ResumeTemplate {
  id?: number
  title: string
  fileType?: string
  fileSize?: string
  fileUrl?: string
  sortOrder?: number
  status?: number
  /** 最后更新时间（后端 BaseEntity 维护） */
  updatedAt?: string
}

export interface PageResult<T> {
  records: T[]
  total: number
  size: number
  current: number
  pages?: number
}

export interface AdminStats {
  trendCount: number
  learningCount: number
  skillCount: number
  socialCount: number
  workCount: number
  noteCount: number
  resumeCount: number
}

/** 运维状态（右上角指示器）：level = ok 站点正常 / warn 风险运行中 / danger 无风控运行 */
export interface OpsMonitorInfo {
  up: boolean
  detail?: string
}

export interface OpsBackupInfo {
  ok: boolean
  lastTime?: string
  ageHours?: number
  detail?: string
}

export interface OpsStatus {
  level: 'ok' | 'warn' | 'danger'
  label: string
  monitor: OpsMonitorInfo
  backup: OpsBackupInfo
}

/* ---------------- 前台只读接口 ---------------- */

export const fetchProfile = () => get<SiteProfile>('/profile')
export const fetchTrend = () => get<SiteTrend[]>('/trends')
export const fetchLearnings = () => get<LearningItem[]>('/learnings')
export const fetchSkills = (type: string) => get<Skill[]>('/skills', { params: { type } })
export const fetchSocials = () => get<SocialLink[]>('/socials')
export const fetchWorks = () => get<WorkItem[]>('/works')
export const fetchNotes = () => get<Note[]>('/notes')
export const fetchNote = (id: number | string) => get<Note>(`/notes/${id}`)
export const fetchResumes = () => get<ResumeTemplate[]>('/resumes')
export const fetchOpsStatus = () => get<OpsStatus>('/ops/status')

/* ---------------- 后台管理接口 ---------------- */

export const fetchStats = () => get<AdminStats>('/admin/stats')
export const updateProfile = (data: SiteProfile) => put<SiteProfile>('/admin/profile', data)

export function adminPage<T = any>(base: string, params: Record<string, any>) {
  return get<PageResult<T>>(`/admin/${base}/page`, { params })
}
export function adminCreate<T = any>(base: string, data: Record<string, any>) {
  return post<T>(`/admin/${base}`, data)
}
export function adminUpdate<T = any>(base: string, data: Record<string, any>) {
  return put<T>(`/admin/${base}`, data)
}
export function adminDelete(base: string, id: number | string) {
  return del(`/admin/${base}/${id}`)
}

/**
 * 上传单张图片（后台），表单字段名固定为 file。
 * 返回可直接用于 <img :src> 的 URL，如 /uploads/20260927102030_ab12cd34.png
 */
export function uploadImage(file: File) {
  const fd = new FormData()
  fd.append('file', file)
  return post<string>('/admin/upload', fd)
}

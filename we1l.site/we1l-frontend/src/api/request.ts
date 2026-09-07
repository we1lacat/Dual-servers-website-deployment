import axios from 'axios'
import { ElMessage } from 'element-plus'
import { authStore } from '@/auth/store'

/** 后端统一响应结构 */
export interface Result<T = any> {
  code: number
  message: string
  data: T
}

/** MyBatis-Plus 分页结构 */
export interface Page<T = any> {
  records: T[]
  total: number
  size: number
  current: number
  pages: number
}

export const http = axios.create({
  baseURL: '/api',
  timeout: 15000,
})

// 请求拦截：附加时间戳 + JWT
http.interceptors.request.use((config) => {
  if (config.method === 'get') {
    config.params = { ...(config.params || {}), _t: Date.now() }
  }
  const token = authStore.currentToken()
  if (token) {
    config.headers = config.headers || {}
    ;(config.headers as any).Authorization = `Bearer ${token}`
  }
  return config
})

// 是否正在被路由层处理 401 跳转，避免与"业务正常返回的 401 code"双重 toast
let redirectingToLogin = false

// 响应拦截：解包 Result，统一错误提示；401 跳登录页
http.interceptors.response.use(
  (resp) => {
    const body = resp.data as Result
    if (body && typeof body.code === 'number') {
      if (body.code === 401) {
        handleUnauthorized(body.message)
        return Promise.reject(new Error(body.message))
      }
      if (body.code !== 0) {
        ElMessage.error(body.message || '请求失败')
        return Promise.reject(new Error(body.message))
      }
      return body.data as any
    }
    return body
  },
  (err) => {
    if (err?.response?.status === 401) {
      handleUnauthorized(err?.response?.data?.message)
      return Promise.reject(err)
    }
    const msg = err?.response?.data?.message || err?.message || '网络异常，请稍后重试'
    ElMessage.error(msg)
    return Promise.reject(err)
  },
)

function handleUnauthorized(msg?: string) {
  authStore.clear()
  // 仅当不是已经在登录页时跳转
  if (!redirectingToLogin && !location.pathname.startsWith('/login')) {
    redirectingToLogin = true
    ElMessage.warning(msg || '登录已过期，请重新登录')
    const redirect = encodeURIComponent(location.pathname + location.search)
    location.replace(`/login?redirect=${redirect}`)
    setTimeout(() => { redirectingToLogin = false }, 1000)
  }
}

/** 便捷 GET：直接返回 data */
export async function get<T = any>(url: string, params?: Record<string, any>): Promise<T> {
  return (await http.get(url, { params })) as T
}

/** 便捷 POST */
export async function post<T = any>(url: string, body?: any): Promise<T> {
  return (await http.post(url, body)) as T
}

/** 便捷 PUT */
export async function put<T = any>(url: string, body?: any): Promise<T> {
  return (await http.put(url, body)) as T
}

/** 便捷 DELETE */
export async function del<T = any>(url: string): Promise<T> {
  return (await http.delete(url)) as T
}

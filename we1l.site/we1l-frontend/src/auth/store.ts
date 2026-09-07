import axios from 'axios'

/**
 * 鉴权状态：token + 用户信息，localStorage 持久化避免刷新失效。
 */
export interface AuthUser {
  id: number
  username: string
  displayName: string
  role: string
}

const STORAGE_KEY = 'we1l-auth'

interface AuthSnapshot {
  token: string
  expireAt: number // ms timestamp
  user: AuthUser
}

function loadSnapshot(): AuthSnapshot | null {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return null
    const snap = JSON.parse(raw) as AuthSnapshot
    if (!snap.token || !snap.user || !snap.expireAt || snap.expireAt <= Date.now()) {
      localStorage.removeItem(STORAGE_KEY)
      return null
    }
    return snap
  } catch {
    localStorage.removeItem(STORAGE_KEY)
    return null
  }
}

function saveSnapshot(snap: AuthSnapshot) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(snap))
}

export function clearSnapshot() {
  localStorage.removeItem(STORAGE_KEY)
}

/** 当前 token，供 axios 拦截器取用（不要直接从 component 里 get 出来用） */
export function getToken(): string | null {
  return loadSnapshot()?.token ?? null
}

export const authStore = {
  state: (): AuthSnapshot | null => loadSnapshot(),
  save(token: string, expireSeconds: number, user: AuthUser): AuthSnapshot {
    const snap: AuthSnapshot = {
      token,
      expireAt: Date.now() + expireSeconds * 1000,
      user,
    }
    saveSnapshot(snap)
    return snap
  },
  clear() {
    clearSnapshot()
  },
  isAuthenticated(): boolean {
    const s = loadSnapshot()
    return !!s && s.expireAt > Date.now()
  },
  user(): AuthUser | null {
    return loadSnapshot()?.user ?? null
  },
  /** 仅作为单例使用，所有页面共享同一个 token——避免组件每次去解析 localStorage */
  currentToken(): string | null {
    return loadSnapshot()?.token ?? null
  },
}

import { reactive } from 'vue'
import { request } from '@/api'

const SESSION_KEY = 'xvay-houtaixitong-session'

function readSession() {
  try {
    return JSON.parse(localStorage.getItem(SESSION_KEY) || 'null')
  } catch {
    return null
  }
}

export const session = reactive({
  user: readSession(),
})

export function token() {
  return session.user?.token || ''
}

function save(user) {
  session.user = user
  if (user) localStorage.setItem(SESSION_KEY, JSON.stringify(user))
  else localStorage.removeItem(SESSION_KEY)
}

export async function login(username, password) {
  const data = await request('/api/distributor/login', {
    method: 'POST',
    body: { username, password },
  })
  save({ ...data.user, token: data.token })
  return data
}

export async function register(form) {
  const data = await request('/api/agent/register', {
    method: 'POST',
    body: form,
  })
  save({ ...data.user, token: data.token })
  return data
}

export async function logout() {
  const current = token()
  save(null)
  if (!current) return
  try {
    await request('/api/agent/logout', { method: 'POST', token: current })
  } catch {
    // 本地会话已经清掉，后端失效不影响退出。
  }
}

export const LEVELS = {
  gold: { label: '金牌', type: 'warning' },
  silver: { label: '银牌', type: '' },
  bronze: { label: '铜牌', type: 'info' },
}

export const ORDER_STATUS = {
  pending: { label: '待结算', type: 'warning' },
  settled: { label: '已结算', type: 'success' },
  rejected: { label: '已驳回', type: 'info' },
}

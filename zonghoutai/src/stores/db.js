import { reactive, watch } from 'vue'
import { request } from '@/api'
import { API_BASE } from '@/config'

const SESSION_KEY = 'xvay-zonghoutai-session'

export const CORE_TYPES = ['v2ray', 'xray', 'sing-box', 'clash', 'hysteria2', 'naive']

export const GROUP_PROTOCOLS = [
  { value: 'anyportalRest', label: 'AnyPortal REST' },
  { value: 'file', label: '文件' },
  { value: 'generic', label: '通用订阅' },
]

export const NODE_STATUS = [
  { value: 'online', label: '在线', type: 'success' },
  { value: 'offline', label: '离线', type: 'info' },
  { value: 'maintain', label: '维护', type: 'warning' },
]

export const USER_STATUS = [
  { value: 'active', label: '正常', type: 'success' },
  { value: 'disabled', label: '停用', type: 'danger' },
  { value: 'expired', label: '到期', type: 'warning' },
]

export const AGENT_LEVELS = [
  { value: 'gold', label: '金牌', type: 'warning' },
  { value: 'silver', label: '银牌', type: '' },
  { value: 'bronze', label: '铜牌', type: 'info' },
]

export const COMMISSION_STATUS = [
  { value: 'pending', label: '待结算', type: 'warning' },
  { value: 'settled', label: '已结算', type: 'success' },
  { value: 'rejected', label: '已驳回', type: 'info' },
]

function emptyAppSettings() {
  return {
    appName: '',
    version: '',
    localeFollowSystem: true,
    locale: 'zh',
    autoUpdate: true,
    connectAtStartup: false,
    connectAtLaunch: false,
    brightnessFollowSystem: true,
    brightnessDark: false,
    serverAddress: '127.0.0.1',
    apiBase: API_BASE,
    socksPort: 15491,
    httpPort: 15492,
    defaultMode: 'fullSpeed',
    systemProxy: false,
    tun: false,
    pingUrl: 'http://www.gstatic.com/generate_204',
    pingMaxConcurrency: 8,
    announcement: '',
    supportUrl: '',
    aboutText: '',
    profileName: '',
  }
}

function emptyDb() {
  return {
    admins: [],
    groups: [],
    nodes: [],
    cores: [],
    assets: [],
    plans: [],
    appSettings: emptyAppSettings(),
    users: [],
    agents: [],
    commissionRules: [],
    commissions: [],
  }
}

function loadSession() {
  try {
    return JSON.parse(localStorage.getItem(SESSION_KEY) || 'null')
  } catch {
    return null
  }
}

export const db = reactive(emptyDb())

export const session = reactive({
  user: loadSession(),
})

watch(
  () => session.user,
  (user) => {
    if (user) localStorage.setItem(SESSION_KEY, JSON.stringify(user))
    else localStorage.removeItem(SESSION_KEY)
  },
)

export function labelOf(options, value) {
  return options.find((item) => item.value === value)?.label || '—'
}

export function tagOf(options, value) {
  return options.find((item) => item.value === value)?.type || 'info'
}

export function groupName(id) {
  return db.groups.find((item) => item.id === id)?.name || '—'
}

export function planName(id) {
  return db.plans.find((item) => item.id === id)?.name || '未开通'
}

export function agentName(id) {
  if (!id) return '直客'
  return db.agents.find((item) => item.id === id)?.name || '—'
}

export function userName(id) {
  return db.users.find((item) => item.id === id)?.username || '—'
}

export function agentUserCount(agentId) {
  return db.users.filter((user) => user.agentId === agentId).length
}

export function adminToken() {
  return session.user?.token || ''
}

export async function login(username, password) {
  const data = await request('/api/admin/login', {
    method: 'POST',
    body: { username: username.trim(), password },
  })
  session.user = { ...data.user, token: data.token }
  await refreshBackend()
}

export async function register({ username, password, nickname, phone }) {
  const data = await request('/api/admin/register', {
    method: 'POST',
    body: {
      username: username.trim(),
      password,
      nickname: nickname.trim(),
      phone: phone.trim(),
    },
  })
  session.user = { ...data.user, token: data.token }
  await refreshBackend()
}

export function logout() {
  session.user = null
}

export async function resetDb() {
  await request('/api/admin/demo/reset', { method: 'POST', token: adminToken() })
  session.user = null
  Object.assign(db, emptyDb())
}

export async function addItem(key, item) {
  const row = await request(`/api/admin/catalog/${key}`, {
    method: 'POST',
    token: adminToken(),
    body: item,
  })
  await refreshBackend()
  return row
}

export async function updateItem(key, id, patch) {
  const row = await request(`/api/admin/catalog/${key}/${id}`, {
    method: 'PATCH',
    token: adminToken(),
    body: patch,
  })
  await refreshBackend()
  return row
}

export async function removeItem(key, id) {
  await request(`/api/admin/catalog/${key}/${id}`, {
    method: 'DELETE',
    token: adminToken(),
  })
  await refreshBackend()
  return true
}

export async function saveAppSettings(patch) {
  await request('/api/admin/catalog/appSettings', {
    method: 'PUT',
    token: adminToken(),
    body: patch,
  })
  await refreshBackend()
}

function gb(bytes) {
  return Math.round(((Number(bytes) || 0) / 1024 / 1024 / 1024) * 10) / 10
}

export function mapRemoteUser(user) {
  return {
    id: user.id,
    username: user.displayName || user.email,
    email: user.email,
    phone: user.phone || '',
    status: user.status,
    planId: user.planId || null,
    agentId: user.agentId || null,
    trafficUsedGB: gb((user.upload || 0) + (user.download || 0)),
    trafficTotalGB: gb(user.total),
    device: user.device || '',
    platform: user.platform || '',
    region: user.region || '',
    expireAt: user.expireAt ? new Date(user.expireAt).toISOString() : '',
    registeredAt: user.createdAt ? new Date(user.createdAt).toISOString() : '',
    lastLoginAt: user.lastLoginAt ? new Date(user.lastLoginAt).toISOString() : '',
    subscriptionUrl: user.subscriptionUrl || '',
    deviceLimit: user.deviceLimit,
  }
}

export function mapRemoteNode(node) {
  const protocols = node.protocols || []
  return {
    id: node.id,
    name: node.name,
    key: node.key || `n-${node.id}`,
    groupId: node.groupId || db.groups[0]?.id || null,
    coreType: node.coreType || (protocols.includes('hysteria2') && !protocols.includes('reality') ? 'hysteria2' : 'xray'),
    type: node.lineType || 'remote',
    url: node.url || node.host || '',
    host: node.host,
    region: node.region || '',
    status: node.lineStatus || (node.online ? 'online' : 'offline'),
    latency: node.latency || 0,
    enabled: node.enabled,
    updatedAt: node.lastSeenAt ? new Date(node.lastSeenAt).toISOString() : '',
  }
}

export async function refreshBackend() {
  const token = adminToken()
  if (!token) return
  const data = await request('/api/admin/catalog', { token })
  db.admins = data.admins || []
  db.groups = data.groups || []
  db.cores = data.cores || []
  db.assets = data.assets || []
  db.plans = data.plans || []
  db.agents = data.agents || []
  db.commissionRules = data.commissionRules || []
  db.commissions = data.commissions || []
  db.users = (data.users || []).map(mapRemoteUser)
  db.nodes = (data.nodes || []).map(mapRemoteNode)
  db.appSettings = { ...emptyAppSettings(), ...(data.appSettings || {}), apiBase: API_BASE }
}

export async function saveBackendSettings(patch) {
  const token = adminToken()
  if (!token) return
  await request('/api/admin/settings', { method: 'PUT', token, body: patch })
  await refreshBackend()
}

export async function settleCommission(id) {
  await request(`/api/admin/catalog/commissions/${id}/settle`, {
    method: 'POST',
    token: adminToken(),
  })
  await refreshBackend()
  return true
}

export async function rejectCommission(id, remark) {
  await request(`/api/admin/catalog/commissions/${id}/reject`, {
    method: 'POST',
    token: adminToken(),
    body: { remark },
  })
  await refreshBackend()
  return true
}

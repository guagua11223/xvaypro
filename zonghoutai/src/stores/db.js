import { reactive, watch } from 'vue'
import { request } from '@/api'
import { API_BASE } from '@/config'
import { daysFromNow } from '@/utils/format'

const STORAGE_KEY = 'xvay-zonghoutai-db-v1'
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

function ago(days) {
  return daysFromNow(-days)
}

function seed() {
  return {
    admins: [
      {
        id: 1,
        username: 'admin',
        password: 'admin123',
        nickname: '超级管理员',
        role: 'super',
        phone: '13800000000',
        createdAt: ago(120),
      },
    ],
    groups: [
      {
        id: 1,
        name: '默认',
        type: 'local',
        protocol: '',
        coreType: 'xray',
        autoUpdateInterval: 0,
        url: '',
        status: 'enabled',
        updatedAt: ago(2),
      },
      {
        id: 2,
        name: '亚洲高速',
        type: 'remote',
        protocol: 'anyportalRest',
        coreType: 'sing-box',
        autoUpdateInterval: 60,
        url: 'https://api.xvay.example/groups/asia',
        status: 'enabled',
        updatedAt: ago(1),
      },
      {
        id: 3,
        name: '全球通用',
        type: 'remote',
        protocol: 'generic',
        coreType: 'clash',
        autoUpdateInterval: 360,
        url: 'https://sub.xvay.example/global.yaml',
        status: 'enabled',
        updatedAt: ago(3),
      },
    ],
    nodes: [
      {
        id: 1,
        name: '香港 01',
        key: 'hk-01',
        groupId: 2,
        coreType: 'xray',
        type: 'remote',
        url: 'vless://hk-01.xvay.example:443',
        region: '香港',
        status: 'online',
        latency: 38,
        updatedAt: ago(1),
      },
      {
        id: 2,
        name: '东京 01',
        key: 'jp-tyo-01',
        groupId: 2,
        coreType: 'sing-box',
        type: 'remote',
        url: 'vless://tyo-01.xvay.example:443',
        region: '日本东京',
        status: 'online',
        latency: 62,
        updatedAt: ago(1),
      },
      {
        id: 3,
        name: '新加坡 01',
        key: 'sg-01',
        groupId: 2,
        coreType: 'xray',
        type: 'remote',
        url: 'vless://sg-01.xvay.example:443',
        region: '新加坡',
        status: 'online',
        latency: 71,
        updatedAt: ago(2),
      },
      {
        id: 4,
        name: '洛杉矶 01',
        key: 'us-lax-01',
        groupId: 3,
        coreType: 'clash',
        type: 'remote',
        url: 'https://sub.xvay.example/nodes/lax',
        region: '美国洛杉矶',
        status: 'maintain',
        latency: 168,
        updatedAt: ago(4),
      },
      {
        id: 5,
        name: '首尔 01',
        key: 'kr-sel-01',
        groupId: 2,
        coreType: 'hysteria2',
        type: 'remote',
        url: 'hysteria2://sel-01.xvay.example:443',
        region: '韩国首尔',
        status: 'online',
        latency: 54,
        updatedAt: ago(1),
      },
      {
        id: 6,
        name: '本地调试',
        key: 'local-dev',
        groupId: 1,
        coreType: 'v2ray',
        type: 'local',
        url: '',
        region: '本地',
        status: 'offline',
        latency: 0,
        updatedAt: ago(8),
      },
    ],
    cores: [
      { id: 1, name: 'v2ray', version: '5.16.1', enabled: true, isExec: true, workingDir: '', updatedAt: ago(10) },
      { id: 2, name: 'xray', version: '1.8.24', enabled: true, isExec: true, workingDir: '', updatedAt: ago(4) },
      { id: 3, name: 'sing-box', version: '1.11.0', enabled: true, isExec: true, workingDir: '', updatedAt: ago(6) },
      { id: 4, name: 'clash', version: '1.18.0', enabled: true, isExec: true, workingDir: '', updatedAt: ago(20) },
      { id: 5, name: 'hysteria2', version: '2.6.0', enabled: false, isExec: true, workingDir: '', updatedAt: ago(15) },
      { id: 6, name: 'naive', version: '1.0.0', enabled: false, isExec: true, workingDir: '', updatedAt: ago(30) },
    ],
    assets: [
      {
        id: 1,
        name: 'geoip.dat',
        type: 'remote',
        path: 'assets/geoip.dat',
        url: 'github://v2fly/geoip/geoip.dat',
        autoUpdateInterval: 1440,
        updatedAt: ago(2),
      },
      {
        id: 2,
        name: 'geosite.dat',
        type: 'remote',
        path: 'assets/geosite.dat',
        url: 'github://v2fly/domain-list-community/dlc.dat',
        autoUpdateInterval: 1440,
        updatedAt: ago(2),
      },
      {
        id: 3,
        name: 'geoip.srs',
        type: 'remote',
        path: 'assets/geoip.srs',
        url: 'github://SagerNet/sing-geoip/geoip.srs',
        autoUpdateInterval: 1440,
        updatedAt: ago(5),
      },
      {
        id: 4,
        name: 'geosite.srs',
        type: 'remote',
        path: 'assets/geosite.srs',
        url: 'github://SagerNet/sing-geosite/geosite.srs',
        autoUpdateInterval: 1440,
        updatedAt: ago(5),
      },
    ],
    plans: [
      { id: 1, name: '月卡', price: 30, durationDays: 30, trafficGB: 100, deviceLimit: 2, status: 'on', updatedAt: ago(8) },
      { id: 2, name: '季卡', price: 78, durationDays: 90, trafficGB: 300, deviceLimit: 3, status: 'on', updatedAt: ago(8) },
      { id: 3, name: '年卡', price: 258, durationDays: 365, trafficGB: 1500, deviceLimit: 5, status: 'on', updatedAt: ago(8) },
    ],
    appSettings: {
      appName: 'AnyPortal',
      version: '0.6.31',
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
      announcement: '欢迎使用 飞连。线路、套餐与公告由总后台统一配置后下发到 App。',
      supportUrl: 'https://xvay.example/support',
      aboutText: 'AnyPortal 客户端，支持 V2Ray、Xray、sing-box、Clash、Hysteria2 与 Naive。',
    },
    users: [
      {
        id: 1,
        username: '林晓',
        email: 'linxiao@example.com',
        phone: '13811110001',
        status: 'active',
        planId: 1,
        agentId: 3,
        trafficUsedGB: 36.4,
        trafficTotalGB: 100,
        device: 'Pixel 8',
        platform: 'Android',
        region: '深圳',
        registeredAt: ago(20),
        lastLoginAt: ago(0.2),
        expireAt: daysFromNow(10),
      },
      {
        id: 2,
        username: '周宁',
        email: 'zhouning@example.com',
        phone: '13811110002',
        status: 'active',
        planId: 3,
        agentId: 1,
        trafficUsedGB: 420,
        trafficTotalGB: 1500,
        device: 'iPhone 15',
        platform: 'iOS',
        region: '广州',
        registeredAt: ago(80),
        lastLoginAt: ago(0.5),
        expireAt: daysFromNow(280),
      },
      {
        id: 3,
        username: '陈可',
        email: 'chenke@example.com',
        phone: '13811110003',
        status: 'active',
        planId: 2,
        agentId: 4,
        trafficUsedGB: 88,
        trafficTotalGB: 300,
        device: 'Windows PC',
        platform: 'Windows',
        region: '杭州',
        registeredAt: ago(40),
        lastLoginAt: ago(1),
        expireAt: daysFromNow(50),
      },
      {
        id: 4,
        username: '赵磊',
        email: 'zhaolei@example.com',
        phone: '13811110004',
        status: 'expired',
        planId: 1,
        agentId: 2,
        trafficUsedGB: 97,
        trafficTotalGB: 100,
        device: 'MacBook',
        platform: 'macOS',
        region: '上海',
        registeredAt: ago(60),
        lastLoginAt: ago(12),
        expireAt: ago(3),
      },
      {
        id: 5,
        username: '孙琪',
        email: 'sunqi@example.com',
        phone: '13811110005',
        status: 'disabled',
        planId: 3,
        agentId: 1,
        trafficUsedGB: 12,
        trafficTotalGB: 1500,
        device: 'iPad',
        platform: 'iOS',
        region: '广州',
        registeredAt: ago(15),
        lastLoginAt: ago(9),
        expireAt: daysFromNow(340),
      },
      {
        id: 6,
        username: '吴迪',
        email: 'wudi@example.com',
        phone: '13811110006',
        status: 'active',
        planId: 2,
        agentId: 3,
        trafficUsedGB: 140,
        trafficTotalGB: 300,
        device: 'Mac mini',
        platform: 'macOS',
        region: '东莞',
        registeredAt: ago(25),
        lastLoginAt: ago(0.1),
        expireAt: daysFromNow(65),
      },
      {
        id: 7,
        username: '郑爽',
        email: 'zhengshuang@example.com',
        phone: '13811110007',
        status: 'active',
        planId: 1,
        agentId: null,
        trafficUsedGB: 18,
        trafficTotalGB: 100,
        device: 'Xiaomi 14',
        platform: 'Android',
        region: '北京',
        registeredAt: ago(6),
        lastLoginAt: ago(0.4),
        expireAt: daysFromNow(24),
      },
      {
        id: 8,
        username: '何俊',
        email: 'hejun@example.com',
        phone: '13811110008',
        status: 'active',
        planId: 3,
        agentId: 2,
        trafficUsedGB: 260,
        trafficTotalGB: 1500,
        device: 'iPhone 16',
        platform: 'iOS',
        region: '南京',
        registeredAt: ago(100),
        lastLoginAt: ago(2),
        expireAt: daysFromNow(200),
      },
    ],
    agents: [
      {
        id: 1,
        name: '华南总代',
        username: 'agent-hn',
        phone: '13900001001',
        level: 'gold',
        inviteCode: '飞连-HN',
        parentId: null,
        balance: 154.8,
        totalCommission: 154.8,
        status: 'active',
        remark: '覆盖广东直营与下级站点',
        createdAt: ago(200),
      },
      {
        id: 2,
        name: '华东渠道',
        username: 'agent-hd',
        phone: '13900001002',
        level: 'gold',
        inviteCode: '飞连-HD',
        parentId: null,
        balance: 9,
        totalCommission: 9,
        status: 'active',
        remark: '上海、江苏渠道',
        createdAt: ago(180),
      },
      {
        id: 3,
        name: '深圳站',
        username: 'agent-sz',
        phone: '13900001003',
        level: 'silver',
        inviteCode: '飞连-SZ',
        parentId: 1,
        balance: 0,
        totalCommission: 0,
        status: 'active',
        remark: '华南总代下级',
        createdAt: ago(90),
      },
      {
        id: 4,
        name: '杭州站',
        username: 'agent-hz',
        phone: '13900001004',
        level: 'bronze',
        inviteCode: '飞连-HZ',
        parentId: 2,
        balance: 0,
        totalCommission: 0,
        status: 'frozen',
        remark: '结算资料待补充',
        createdAt: ago(40),
      },
    ],
    commissionRules: [
      { id: 1, level: 'gold', rate: 30, minOrder: 30, settleCycle: 'weekly', enabled: true },
      { id: 2, level: 'silver', rate: 20, minOrder: 30, settleCycle: 'weekly', enabled: true },
      { id: 3, level: 'bronze', rate: 12, minOrder: 30, settleCycle: 'monthly', enabled: true },
    ],
    commissions: [
      {
        id: 1,
        agentId: 3,
        userId: 1,
        orderNo: 'XV20261001001',
        orderAmount: 30,
        rate: 20,
        commission: 6,
        status: 'pending',
        createdAt: ago(2),
        settledAt: '',
        remark: '月卡续费',
      },
      {
        id: 2,
        agentId: 1,
        userId: 2,
        orderNo: 'XV20260912008',
        orderAmount: 258,
        rate: 30,
        commission: 77.4,
        status: 'settled',
        createdAt: ago(27),
        settledAt: ago(20),
        remark: '年卡',
      },
      {
        id: 3,
        agentId: 4,
        userId: 3,
        orderNo: 'XV20261003012',
        orderAmount: 78,
        rate: 12,
        commission: 9.36,
        status: 'pending',
        createdAt: ago(1),
        settledAt: '',
        remark: '季卡',
      },
      {
        id: 4,
        agentId: 2,
        userId: 4,
        orderNo: 'XV20260820003',
        orderAmount: 30,
        rate: 30,
        commission: 9,
        status: 'settled',
        createdAt: ago(50),
        settledAt: ago(43),
        remark: '月卡',
      },
      {
        id: 5,
        agentId: 1,
        userId: 5,
        orderNo: 'XV20260928019',
        orderAmount: 258,
        rate: 30,
        commission: 77.4,
        status: 'settled',
        createdAt: ago(11),
        settledAt: ago(7),
        remark: '年卡',
      },
      {
        id: 6,
        agentId: 3,
        userId: 6,
        orderNo: 'XV20261006021',
        orderAmount: 78,
        rate: 20,
        commission: 15.6,
        status: 'pending',
        createdAt: ago(0.6),
        settledAt: '',
        remark: '季卡',
      },
      {
        id: 7,
        agentId: 2,
        userId: 8,
        orderNo: 'XV20261007030',
        orderAmount: 258,
        rate: 30,
        commission: 77.4,
        status: 'pending',
        createdAt: ago(0.3),
        settledAt: '',
        remark: '年卡续费',
      },
    ],
  }
}

function loadDb() {
  const base = seed()
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return base
    const parsed = JSON.parse(raw)
    return {
      ...base,
      ...parsed,
      appSettings: { ...base.appSettings, ...(parsed.appSettings || {}) },
    }
  } catch {
    return base
  }
}

function loadSession() {
  try {
    return JSON.parse(localStorage.getItem(SESSION_KEY) || 'null')
  } catch {
    return null
  }
}

export const db = reactive(loadDb())

export const session = reactive({
  user: loadSession(),
})

watch(
  db,
  (value) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(value))
  },
  { deep: true },
)

watch(
  () => session.user,
  (user) => {
    if (user) localStorage.setItem(SESSION_KEY, JSON.stringify(user))
    else localStorage.removeItem(SESSION_KEY)
  },
)

function nextId(list) {
  return list.reduce((max, item) => Math.max(max, item.id || 0), 0) + 1
}

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

export function login(username, password) {
  const admin = db.admins.find((item) => item.username === username && item.password === password)
  if (!admin) return { ok: false, message: '账号或密码不正确' }
  session.user = {
    id: admin.id,
    username: admin.username,
    nickname: admin.nickname,
    role: admin.role,
  }
  return { ok: true }
}

export function register({ username, password, nickname, phone }) {
  const name = username.trim()
  if (db.admins.some((item) => item.username === name)) {
    return { ok: false, message: '用户名已存在' }
  }
  const admin = {
    id: nextId(db.admins),
    username: name,
    password,
    nickname: nickname.trim() || name,
    role: 'operator',
    phone: phone.trim(),
    createdAt: new Date().toISOString(),
  }
  db.admins.push(admin)
  session.user = {
    id: admin.id,
    username: admin.username,
    nickname: admin.nickname,
    role: admin.role,
  }
  return { ok: true }
}

export function logout() {
  session.user = null
}

export function resetDb() {
  const fresh = seed()
  Object.keys(db).forEach((key) => {
    delete db[key]
  })
  Object.assign(db, fresh)
  if (session.user && !db.admins.some((item) => item.id === session.user.id)) {
    session.user = null
  }
}

export function addItem(key, item) {
  const row = {
    ...item,
    id: nextId(db[key]),
    updatedAt: item.updatedAt || new Date().toISOString(),
  }
  db[key].unshift(row)
  return row
}

export function updateItem(key, id, patch) {
  const row = db[key].find((item) => item.id === id)
  if (!row) return null
  Object.assign(row, patch, { updatedAt: new Date().toISOString() })
  return row
}

export function removeItem(key, id) {
  const index = db[key].findIndex((item) => item.id === id)
  if (index < 0) return false
  db[key].splice(index, 1)
  return true
}

export function saveAppSettings(patch) {
  Object.assign(db.appSettings, patch)
}

function gb(bytes) {
  return Math.round(((Number(bytes) || 0) / 1024 / 1024 / 1024) * 10) / 10
}

export function adminToken() {
  return session.user?.token || ''
}

export function mapRemoteUser(user) {
  return {
    id: user.id,
    username: user.email,
    email: user.email,
    phone: '',
    status: user.status,
    planId: null,
    agentId: null,
    trafficUsedGB: gb((user.upload || 0) + (user.download || 0)),
    trafficTotalGB: gb(user.total),
    device: '',
    platform: '',
    region: '',
    expireAt: user.expireAt ? new Date(user.expireAt).toISOString() : '',
    registeredAt: user.createdAt ? new Date(user.createdAt).toISOString() : '',
    lastLoginAt: '',
    subscriptionUrl: user.subscriptionUrl || '',
    deviceLimit: user.deviceLimit,
  }
}

export function mapRemoteNode(node) {
  const protocols = node.protocols || []
  return {
    id: node.id,
    name: node.name,
    key: `n-${node.id}`,
    groupId: db.groups[0]?.id ?? 1,
    coreType: protocols.includes('hysteria2') && !protocols.includes('reality') ? 'hysteria2' : 'xray',
    type: 'remote',
    url: node.host,
    host: node.host,
    region: node.region || '',
    status: node.online ? 'online' : 'offline',
    latency: 0,
    enabled: node.enabled,
    updatedAt: node.lastSeenAt ? new Date(node.lastSeenAt).toISOString() : '',
  }
}

export async function refreshBackend() {
  const token = adminToken()
  if (!token) return
  const [users, nodes, announcements, settings] = await Promise.all([
    request('/api/admin/users', { token }),
    request('/api/admin/nodes', { token }),
    request('/api/admin/announcements', { token }),
    request('/api/admin/settings', { token }),
  ])
  db.users = (users.users || []).map(mapRemoteUser)
  db.nodes = (nodes.nodes || []).map(mapRemoteNode)
  const notice = (announcements.announcements || [])[0]
  if (notice) db.appSettings.announcement = `${notice.title}\n${notice.body}`
  db.appSettings.apiBase = API_BASE
  if (settings) {
    db.appSettings.supportUrl = settings.supportUrl || ''
    db.appSettings.profileName = settings.profileName || db.appSettings.profileName
  }
}

export async function saveBackendSettings(patch) {
  const token = adminToken()
  if (!token) return
  await request('/api/admin/settings', { method: 'PUT', token, body: patch })
  await refreshBackend()
}

export function settleCommission(id) {
  const record = db.commissions.find((item) => item.id === id)
  if (!record || record.status !== 'pending') return false
  record.status = 'settled'
  record.settledAt = new Date().toISOString()
  const agent = db.agents.find((item) => item.id === record.agentId)
  if (agent) {
    agent.balance = Number((agent.balance + record.commission).toFixed(2))
    agent.totalCommission = Number((agent.totalCommission + record.commission).toFixed(2))
  }
  return true
}

export function rejectCommission(id, remark) {
  const record = db.commissions.find((item) => item.id === id)
  if (!record || record.status !== 'pending') return false
  record.status = 'rejected'
  record.settledAt = new Date().toISOString()
  if (remark) record.remark = remark
  return true
}

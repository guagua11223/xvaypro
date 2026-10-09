<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { request } from '@/api'
import { adminToken, agentName, db, labelOf, planName, refreshBackend, tagOf, USER_STATUS } from '@/stores/db'
import { formatTime } from '@/utils/format'

const keyword = ref('')
const status = ref('')
const planId = ref()
const agentId = ref('')
const page = ref(1)
const drawer = ref(false)
const current = ref(null)
const dialogVisible = ref(false)
const editingId = ref(null)
const formRef = ref()
const form = reactive(emptyForm())

function emptyForm() {
  return {
    username: '',
    email: '',
    password: '',
    phone: '',
    status: 'active',
    planId: db.plans[0]?.id ?? null,
    agentId: null,
    trafficUsedGB: 0,
    trafficTotalGB: 100,
    device: '',
    platform: 'Android',
    region: '',
    expireAt: '',
  }
}

const rules = {
  email: [{ required: true, type: 'email', message: '请输入邮箱', trigger: 'blur' }],
  password: [{
    validator: (_rule, value, callback) => {
      if (!editingId.value && (!value || value.length < 8)) callback(new Error('密码至少 8 位'))
      else if (value && value.length < 8) callback(new Error('密码至少 8 位'))
      else callback()
    },
    trigger: 'blur',
  }],
}

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return db.users.filter((user) => {
    const hit =
      !kw ||
      [user.username, user.email, user.phone].some((field) => String(field).toLowerCase().includes(kw))
    const statusOk = !status.value || user.status === status.value
    const planOk = !planId.value || user.planId === planId.value
    const agentOk =
      agentId.value === '' ||
      agentId.value == null ||
      (agentId.value === 'direct' ? !user.agentId : user.agentId === agentId.value)
    return hit && statusOk && planOk && agentOk
  })
})

const paged = computed(() => filtered.value.slice((page.value - 1) * 8, page.value * 8))

function trafficPercent(user) {
  if (!user.trafficTotalGB) return 0
  return Math.min(100, Math.round((user.trafficUsedGB / user.trafficTotalGB) * 100))
}

function openDetail(row) {
  current.value = row
  drawer.value = true
}

function openCreate() {
  editingId.value = null
  Object.assign(form, emptyForm())
  dialogVisible.value = true
}

function openEdit(row) {
  editingId.value = row.id
  Object.assign(form, {
    ...row,
    password: '',
    expireAt: row.expireAt ? row.expireAt.slice(0, 19) : '',
  })
  dialogVisible.value = true
}

function userPayload() {
  const plan = db.plans.find((item) => item.id === form.planId)
  const body = {
    email: form.email.trim(),
    status: form.status,
    total: Math.round((Number(form.trafficTotalGB) || 0) * 1024 * 1024 * 1024),
    download: Math.round((Number(form.trafficUsedGB) || 0) * 1024 * 1024 * 1024),
    upload: 0,
    deviceLimit: plan?.deviceLimit || 3,
    displayName: form.username.trim(),
    phone: form.phone.trim(),
    planId: form.planId || 0,
    agentId: form.agentId || 0,
    device: form.device.trim(),
    platform: form.platform,
    region: form.region.trim(),
  }
  if (form.password) body.password = form.password
  if (form.expireAt) body.expireAt = new Date(form.expireAt).getTime()
  return body
}

async function submit() {
  await formRef.value.validate()
  try {
    if (editingId.value) {
      await request(`/api/admin/users/${editingId.value}`, {
        method: 'PATCH',
        token: adminToken(),
        body: userPayload(),
      })
    } else {
      await request('/api/admin/users', {
        method: 'POST',
        token: adminToken(),
        body: userPayload(),
      })
    }
    await refreshBackend()
    dialogVisible.value = false
    ElMessage.success('用户资料已保存')
  } catch (error) {
    ElMessage.error(error.message || '保存失败')
  }
}

async function toggleStatus(row) {
  const next = row.status === 'disabled' ? 'active' : 'disabled'
  try {
    await request(`/api/admin/users/${row.id}`, {
      method: 'PATCH',
      token: adminToken(),
      body: { status: next },
    })
    await refreshBackend()
    ElMessage.success(next === 'active' ? '已启用' : '已停用')
  } catch (error) {
    ElMessage.error(error.message || '更新失败')
  }
}

onMounted(() => {
  refreshBackend().catch((error) => ElMessage.error(error.message || '加载用户失败'))
})
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>用户查看</h2>
        <p>查看 AnyPortal 用户的套餐、流量、设备和所属代理。停用后客户端不可继续使用当前套餐。</p>
      </div>
      <el-button type="primary" @click="openCreate">新增用户</el-button>
    </div>
    <el-card shadow="never">
      <div class="filters">
        <el-input v-model="keyword" clearable placeholder="搜索用户、手机、邮箱" style="width: 240px" @input="page = 1" />
        <el-select v-model="status" clearable placeholder="状态" style="width: 140px" @change="page = 1">
          <el-option v-for="item in USER_STATUS" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
        <el-select v-model="planId" clearable placeholder="套餐" style="width: 140px" @change="page = 1">
          <el-option v-for="plan in db.plans" :key="plan.id" :label="plan.name" :value="plan.id" />
        </el-select>
        <el-select v-model="agentId" clearable placeholder="代理商" style="width: 160px" @change="page = 1">
          <el-option label="直客" value="direct" />
          <el-option v-for="agent in db.agents" :key="agent.id" :label="agent.name" :value="agent.id" />
        </el-select>
      </div>
      <el-table :data="paged" style="margin-top: 16px">
        <el-table-column prop="username" label="用户" width="100" />
        <el-table-column prop="phone" label="手机" width="130" />
        <el-table-column label="套餐" width="90">
          <template #default="{ row }">{{ planName(row.planId) }}</template>
        </el-table-column>
        <el-table-column label="流量" min-width="180">
          <template #default="{ row }">
            <div style="font-size: 12px; color: #6b7280">{{ row.trafficUsedGB }} / {{ row.trafficTotalGB }} GB</div>
            <el-progress :percentage="trafficPercent(row)" :show-text="false" :stroke-width="8" />
          </template>
        </el-table-column>
        <el-table-column label="代理" width="110">
          <template #default="{ row }">{{ agentName(row.agentId) }}</template>
        </el-table-column>
        <el-table-column prop="platform" label="平台" width="100" />
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="tagOf(USER_STATUS, row.status)" size="small">{{ labelOf(USER_STATUS, row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="到期" width="160">
          <template #default="{ row }">{{ formatTime(row.expireAt) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openDetail(row)">详情</el-button>
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link :type="row.status === 'disabled' ? 'success' : 'danger'" @click="toggleStatus(row)">
              {{ row.status === 'disabled' ? '启用' : '停用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <div style="margin-top: 16px; display: flex; justify-content: flex-end">
        <el-pagination v-model:current-page="page" layout="total, prev, pager, next" :total="filtered.length" :page-size="8" />
      </div>
    </el-card>

    <el-drawer v-model="drawer" title="用户详情" size="420px">
      <div v-if="current" class="detail-grid">
        <span>用户</span><strong>{{ current.username }}</strong>
        <span>邮箱</span><div>{{ current.email || '—' }}</div>
        <span>手机</span><div>{{ current.phone || '—' }}</div>
        <span>套餐</span><div>{{ planName(current.planId) }}</div>
        <span>代理</span><div>{{ agentName(current.agentId) }}</div>
        <span>状态</span><div>{{ labelOf(USER_STATUS, current.status) }}</div>
        <span>流量</span><div>{{ current.trafficUsedGB }} / {{ current.trafficTotalGB }} GB</div>
        <span>设备</span><div>{{ current.device || '—' }}</div>
        <span>平台</span><div>{{ current.platform }}</div>
        <span>地区</span><div>{{ current.region || '—' }}</div>
        <span>注册</span><div>{{ formatTime(current.registeredAt) }}</div>
        <span>最近登录</span><div>{{ formatTime(current.lastLoginAt) }}</div>
        <span>到期</span><div>{{ formatTime(current.expireAt) }}</div>
        <span>订阅</span><div>{{ current.subscriptionUrl || '—' }}</div>
      </div>
    </el-drawer>

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑用户' : '新增用户'" width="560px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="form.email" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" type="password" show-password placeholder="新建时必填，编辑时留空则不修改" />
        </el-form-item>
        <el-form-item label="手机" prop="phone">
          <el-input v-model="form.phone" maxlength="11" />
        </el-form-item>
        <el-form-item label="套餐" prop="planId">
          <el-select v-model="form.planId" style="width: 100%">
            <el-option v-for="plan in db.plans" :key="plan.id" :label="plan.name" :value="plan.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="代理商">
          <el-select v-model="form.agentId" clearable placeholder="直客" style="width: 100%">
            <el-option v-for="agent in db.agents" :key="agent.id" :label="agent.name" :value="agent.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="form.status" style="width: 100%">
            <el-option v-for="item in USER_STATUS" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="已用流量">
          <el-input-number v-model="form.trafficUsedGB" :min="0" :precision="1" />
          <span style="margin-left: 8px; color: #6b7280">GB</span>
        </el-form-item>
        <el-form-item label="总流量">
          <el-input-number v-model="form.trafficTotalGB" :min="1" />
          <span style="margin-left: 8px; color: #6b7280">GB</span>
        </el-form-item>
        <el-form-item label="平台">
          <el-select v-model="form.platform" style="width: 100%">
            <el-option v-for="item in ['Android', 'iOS', 'Windows', 'macOS', 'Linux']" :key="item" :label="item" :value="item" />
          </el-select>
        </el-form-item>
        <el-form-item label="设备">
          <el-input v-model="form.device" />
        </el-form-item>
        <el-form-item label="地区">
          <el-input v-model="form.region" />
        </el-form-item>
        <el-form-item label="到期时间">
          <el-date-picker v-model="form.expireAt" type="datetime" value-format="YYYY-MM-DDTHH:mm:ss" style="width: 100%" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

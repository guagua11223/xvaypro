<script setup>
import { computed, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  addItem,
  AGENT_LEVELS,
  agentName,
  agentUserCount,
  db,
  labelOf,
  removeItem,
  tagOf,
  updateItem,
  userName,
} from '@/stores/db'
import { formatMoney, formatTime } from '@/utils/format'

const keyword = ref('')
const level = ref('')
const status = ref('')
const drawer = ref(false)
const current = ref(null)
const dialogVisible = ref(false)
const editingId = ref(null)
const formRef = ref()
const form = reactive(emptyForm())

function emptyForm() {
  return {
    name: '',
    username: '',
    phone: '',
    level: 'bronze',
    inviteCode: '',
    parentId: null,
    status: 'active',
    remark: '',
  }
}

const rules = {
  name: [{ required: true, message: '请输入代理名称', trigger: 'blur' }],
  username: [{ required: true, message: '请输入登录名', trigger: 'blur' }],
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { pattern: /^1\d{10}$/, message: '请输入 11 位手机号', trigger: 'blur' },
  ],
  inviteCode: [{ required: true, message: '请输入邀请码', trigger: 'blur' }],
}

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return db.agents.filter((agent) => {
    const hit = !kw || [agent.name, agent.username, agent.inviteCode, agent.phone].some((field) => field.toLowerCase().includes(kw))
    const levelOk = !level.value || agent.level === level.value
    const statusOk = !status.value || agent.status === status.value
    return hit && levelOk && statusOk
  })
})

const downlineUsers = computed(() => (current.value ? db.users.filter((user) => user.agentId === current.value.id) : []))
const agentCommissions = computed(() =>
  current.value ? db.commissions.filter((item) => item.agentId === current.value.id) : [],
)

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
  Object.assign(form, row)
  dialogVisible.value = true
}

async function submit() {
  await formRef.value.validate()
  const code = form.inviteCode.trim().toUpperCase()
  const duplicated = db.agents.some((item) => item.inviteCode === code && item.id !== editingId.value)
  if (duplicated) {
    ElMessage.warning('邀请码已存在')
    return
  }
  if (form.parentId && form.parentId === editingId.value) {
    ElMessage.warning('不能将自己设为上级')
    return
  }
  const payload = {
    ...form,
    name: form.name.trim(),
    username: form.username.trim(),
    phone: form.phone.trim(),
    inviteCode: code,
    parentId: form.parentId || null,
    remark: form.remark.trim(),
  }
  if (editingId.value) updateItem('agents', editingId.value, payload)
  else {
    addItem('agents', {
      ...payload,
      balance: 0,
      totalCommission: 0,
      createdAt: new Date().toISOString(),
    })
  }
  dialogVisible.value = false
  ElMessage.success('代理商已保存')
}

function toggleFreeze(row) {
  const next = row.status === 'frozen' ? 'active' : 'frozen'
  updateItem('agents', row.id, { status: next })
  ElMessage.success(next === 'frozen' ? '已冻结' : '已恢复')
}

async function remove(row) {
  if (agentUserCount(row.id) > 0) {
    ElMessage.warning('该代理下还有用户，请先调整归属')
    return
  }
  if (db.agents.some((item) => item.parentId === row.id)) {
    ElMessage.warning('该代理还有下级，请先调整层级')
    return
  }
  await ElMessageBox.confirm(`删除代理商「${row.name}」？`, '删除代理商', { type: 'warning' })
  removeItem('agents', row.id)
  ElMessage.success('已删除')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>代理商查看</h2>
        <p>查看代理等级、邀请码、上下级、名下用户和可结算余额。冻结后不再产生新的分佣。</p>
      </div>
      <el-button type="primary" @click="openCreate">新增代理商</el-button>
    </div>
    <el-card shadow="never">
      <div class="filters">
        <el-input v-model="keyword" clearable placeholder="搜索名称、账号、邀请码" style="width: 240px" />
        <el-select v-model="level" clearable placeholder="等级" style="width: 140px">
          <el-option v-for="item in AGENT_LEVELS" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
        <el-select v-model="status" clearable placeholder="状态" style="width: 140px">
          <el-option label="在营" value="active" />
          <el-option label="冻结" value="frozen" />
        </el-select>
      </div>
      <el-table :data="filtered" style="margin-top: 16px">
        <el-table-column prop="name" label="名称" width="120" />
        <el-table-column prop="username" label="账号" width="120" />
        <el-table-column label="等级" width="90">
          <template #default="{ row }">
            <el-tag :type="tagOf(AGENT_LEVELS, row.level)" size="small">{{ labelOf(AGENT_LEVELS, row.level) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="inviteCode" label="邀请码" width="120" />
        <el-table-column label="上级" width="120">
          <template #default="{ row }">{{ agentName(row.parentId) === '直客' ? '—' : agentName(row.parentId) }}</template>
        </el-table-column>
        <el-table-column label="用户数" width="90">
          <template #default="{ row }">{{ agentUserCount(row.id) }}</template>
        </el-table-column>
        <el-table-column label="可提现" width="110">
          <template #default="{ row }">{{ formatMoney(row.balance) }}</template>
        </el-table-column>
        <el-table-column label="累计分佣" width="110">
          <template #default="{ row }">{{ formatMoney(row.totalCommission) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'success' : 'danger'" size="small">
              {{ row.status === 'active' ? '在营' : '冻结' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="210" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openDetail(row)">详情</el-button>
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link @click="toggleFreeze(row)">{{ row.status === 'frozen' ? '恢复' : '冻结' }}</el-button>
            <el-button link type="danger" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-drawer v-model="drawer" title="代理商详情" size="480px">
      <template v-if="current">
        <div class="detail-grid">
          <span>名称</span><strong>{{ current.name }}</strong>
          <span>账号</span><div>{{ current.username }}</div>
          <span>手机</span><div>{{ current.phone }}</div>
          <span>等级</span><div>{{ labelOf(AGENT_LEVELS, current.level) }}</div>
          <span>邀请码</span><div>{{ current.inviteCode }}</div>
          <span>上级</span><div>{{ current.parentId ? agentName(current.parentId) : '无' }}</div>
          <span>用户数</span><div>{{ agentUserCount(current.id) }}</div>
          <span>可提现</span><div>{{ formatMoney(current.balance) }}</div>
          <span>累计分佣</span><div>{{ formatMoney(current.totalCommission) }}</div>
          <span>入驻</span><div>{{ formatTime(current.createdAt) }}</div>
          <span>备注</span><div>{{ current.remark || '—' }}</div>
        </div>
        <h4>名下用户</h4>
        <el-table :data="downlineUsers" size="small">
          <el-table-column prop="username" label="用户" />
          <el-table-column prop="platform" label="平台" />
          <el-table-column label="状态" width="80">
            <template #default="{ row }">{{ row.status === 'active' ? '正常' : row.status === 'expired' ? '到期' : '停用' }}</template>
          </el-table-column>
        </el-table>
        <h4>分佣记录</h4>
        <el-table :data="agentCommissions" size="small">
          <el-table-column prop="orderNo" label="订单" />
          <el-table-column label="用户" width="80">
            <template #default="{ row }">{{ userName(row.userId) }}</template>
          </el-table-column>
          <el-table-column label="佣金" width="90">
            <template #default="{ row }">{{ formatMoney(row.commission) }}</template>
          </el-table-column>
        </el-table>
      </template>
    </el-drawer>

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑代理商' : '新增代理商'" width="520px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="账号" prop="username">
          <el-input v-model="form.username" />
        </el-form-item>
        <el-form-item label="手机" prop="phone">
          <el-input v-model="form.phone" maxlength="11" />
        </el-form-item>
        <el-form-item label="等级">
          <el-select v-model="form.level" style="width: 100%">
            <el-option v-for="item in AGENT_LEVELS" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="邀请码" prop="inviteCode">
          <el-input v-model="form.inviteCode" placeholder="例如 XVAY-SH" />
        </el-form-item>
        <el-form-item label="上级">
          <el-select v-model="form.parentId" clearable placeholder="无上级" style="width: 100%">
            <el-option
              v-for="agent in db.agents.filter((item) => item.id !== editingId)"
              :key="agent.id"
              :label="agent.name"
              :value="agent.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio value="active">在营</el-radio>
            <el-radio value="frozen">冻结</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

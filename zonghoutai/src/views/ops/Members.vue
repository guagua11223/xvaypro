<script setup>
import { computed, onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { adminRequest, COMMISSION_STATUS, EMAIL_STATUS, PAY_STATUS, WITHDRAW_STATUS, adminRole, label } from '@/ops'
import { formatMoney, formatTime } from '@/utils/format'

const loading = ref(false)
const keyword = ref('')
const typeFilter = ref('')
const statusFilter = ref('')
const rows = ref([])
const shown = computed(() => rows.value.filter((row) => {
  if (typeFilter.value && row.userType !== typeFilter.value) return false
  if (statusFilter.value === 'banned' && row.status !== 1) return false
  if (statusFilter.value === 'active' && row.status === 1) return false
  return true
}))
const canManage = computed(() => adminRole() === 'super' || adminRole() === 'operator')
const recordOpen = ref(false)
const recordTitle = ref('')
const recordWallet = ref(null)
const recordOrders = ref([])
const recordCommissions = ref([])
const recordWithdrawals = ref([])

onMounted(load)

async function load() {
  loading.value = true
  try {
    const data = await adminRequest('/api/admin/members?q=' + encodeURIComponent(keyword.value.trim()))
    rows.value = data.members || []
  } catch (error) {
    ElMessage.error(error.message)
  } finally {
    loading.value = false
  }
}

async function act(path, body, ok) {
  await adminRequest(path, { method: 'POST', body: body || {} })
  ElMessage.success(ok)
  await load()
}

async function promote(row) {
  const { value } = await ElMessageBox.prompt('留空则使用默认 55%', '设为经销商', { inputPlaceholder: '分佣比例' })
  await act(`/api/admin/members/${row.id}/distributor`, { rate: Number(value || 0) }, '已设为经销商')
}

async function parentOf(row) {
  const { value } = await ElMessageBox.prompt('填写上级会员 ID，0 表示清空', '调整上级', { inputValue: String(row.parentId || 0) })
  await act(`/api/admin/members/${row.id}/parent`, { parentId: Number(value || 0) }, '已调整上级')
}

async function ban(row) {
  const { value } = await ElMessageBox.prompt('封禁后节点立即停用，可以解封', '封禁', { inputPlaceholder: '原因' })
  await act(`/api/admin/members/${row.id}/ban`, { reason: value || '平台封禁' }, '已封禁')
}

async function setRate(row) {
  const { value } = await ElMessageBox.prompt('不能超过该会员所属经销商的比例', '设置返佣比例', {
    inputValue: String(row.customRate || 0),
  })
  await act(`/api/admin/members/${row.id}/rate`, { rate: Number(value) }, '已设置返佣比例')
}

async function records(row) {
  const data = await adminRequest(`/api/admin/members/${row.id}/records`)
  recordTitle.value = `${row.username} 的订单、佣金和钱包`
  recordWallet.value = data.wallet || null
  recordOrders.value = data.orders || []
  recordCommissions.value = data.commissions || []
  recordWithdrawals.value = data.withdrawals || []
  recordOpen.value = true
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>会员管理</h2>
        <p>普通会员、代理和经销商都在这里。经销商模式和系统三级分佣不能叠加。</p>
      </div>
      <div class="filters">
        <el-input v-model="keyword" clearable placeholder="用户名 / 邮箱 / 手机" style="width: 220px" @keyup.enter="load" />
        <el-select v-model="typeFilter" clearable placeholder="类型" style="width: 120px">
          <el-option label="普通用户" value="普通用户" />
          <el-option label="代理" value="代理" />
          <el-option label="经销商" value="经销商" />
        </el-select>
        <el-select v-model="statusFilter" clearable placeholder="状态" style="width: 110px">
          <el-option label="正常" value="active" />
          <el-option label="封禁" value="banned" />
        </el-select>
        <el-button type="primary" @click="load">查询</el-button>
      </div>
    </div>
    <el-table v-loading="loading" :data="shown" size="small">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="名称" min-width="120" />
      <el-table-column prop="phone" label="手机" width="120" />
      <el-table-column prop="email" label="邮箱" min-width="160" />
      <el-table-column label="邮箱状态" width="120">
        <template #default="{ row }">{{ label(EMAIL_STATUS, row.emailStatus) }}</template>
      </el-table-column>
      <el-table-column prop="userType" label="类型" width="90" />
      <el-table-column prop="inviteCode" label="邀请码" width="110" />
      <el-table-column prop="distributorName" label="上级经销商" min-width="120" />
      <el-table-column prop="parentName" label="推荐人" min-width="120" />
      <el-table-column label="分佣" width="90">
        <template #default="{ row }">{{ row.commissionMode === 1 ? '经销商' : '系统三级' }}</template>
      </el-table-column>
      <el-table-column label="钱包" width="70">
        <template #default="{ row }">{{ row.walletEnabled ? '开通' : '关闭' }}</template>
      </el-table-column>
      <el-table-column label="注册时间" width="150">
        <template #default="{ row }">{{ formatTime(row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="80">
        <template #default="{ row }">{{ row.status === 1 ? '封禁' : '正常' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="280" fixed="right">
        <template #default="{ row }">
          <template v-if="canManage">
            <el-button v-if="!row.isDistributor" link type="primary" @click="promote(row)">设为经销商</el-button>
            <el-button v-else link @click="act(`/api/admin/members/${row.id}/distributor/cancel`, {}, '已取消经销商')">取消经销商</el-button>
            <el-button v-if="!row.isAgent" link @click="act(`/api/admin/members/${row.id}/agent`, {}, '已授权代理')">授权代理</el-button>
            <el-button v-if="row.status !== 1" link type="danger" @click="ban(row)">封禁</el-button>
            <el-button v-else link type="success" @click="act(`/api/admin/members/${row.id}/unban`, {}, '已解封')">解封</el-button>
            <el-button link @click="parentOf(row)">调整上级</el-button>
            <el-button v-if="row.distributorId" link @click="setRate(row)">设置比例</el-button>
            <el-button v-if="row.email" link @click="act(`/api/admin/members/${row.id}/email/unbind`, {}, '已解绑邮箱')">解绑邮箱</el-button>
          </template>
          <el-button link @click="records(row)">记录</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-dialog v-model="recordOpen" :title="recordTitle" width="860px">
      <div v-if="recordWallet" class="stat-grid">
        <div class="stat-card"><span>钱包</span><strong>{{ recordWallet.enabled ? '开通' : '关闭' }}</strong></div>
        <div class="stat-card"><span>可提现</span><strong>{{ formatMoney(recordWallet.balance) }}</strong><em>冻结 {{ formatMoney(recordWallet.frozen) }}</em></div>
        <div class="stat-card"><span>推荐获利</span><strong>{{ formatMoney(recordWallet.totalIncome) }}</strong><em>已提现 {{ formatMoney(recordWallet.totalWithdraw) }}</em></div>
        <div class="stat-card"><span>负余额</span><strong>{{ formatMoney(recordWallet.negativeBalance) }}</strong></div>
      </div>
      <h3>订单</h3>
      <el-table :data="recordOrders" size="small">
        <el-table-column prop="orderNo" label="订单号" min-width="140" />
        <el-table-column prop="packageName" label="套餐" width="90" />
        <el-table-column label="金额" width="90"><template #default="{ row }">{{ formatMoney(row.amount) }}</template></el-table-column>
        <el-table-column label="支付" width="80"><template #default="{ row }">{{ label(PAY_STATUS, row.payStatus) }}</template></el-table-column>
        <el-table-column label="时间" width="150"><template #default="{ row }">{{ formatTime(row.createdAt) }}</template></el-table-column>
      </el-table>
      <h3>佣金</h3>
      <el-table :data="recordCommissions" size="small">
        <el-table-column prop="fromUsername" label="来源" min-width="100" />
        <el-table-column label="金额" width="90"><template #default="{ row }">{{ formatMoney(row.amount) }}</template></el-table-column>
        <el-table-column label="状态" width="90"><template #default="{ row }">{{ label(COMMISSION_STATUS, row.status) }}</template></el-table-column>
      </el-table>
      <h3>提现</h3>
      <el-table :data="recordWithdrawals" size="small">
        <el-table-column label="金额" width="90"><template #default="{ row }">{{ formatMoney(row.amount) }}</template></el-table-column>
        <el-table-column label="手续费" width="90"><template #default="{ row }">{{ formatMoney(row.fee) }}</template></el-table-column>
        <el-table-column label="状态" width="90"><template #default="{ row }">{{ label(WITHDRAW_STATUS, row.status) }}</template></el-table-column>
      </el-table>
    </el-dialog>
  </div>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { API_BASE } from '@/config'
import { session } from '@/stores/db'
import { adminRequest, COMMISSION_STATUS, PAY_STATUS, REFUND_STATUS, SERVICE_STATUS, label } from '@/ops'
import { formatMoney, formatTime } from '@/utils/format'

const loading = ref(false)
const range = ref([])
const summary = ref({ total: 0, paidAmount: 0, orders: [] })
const refundOpen = ref(false)
const refundBusy = ref(false)
const refundForm = reactive({
  orderId: 0,
  orderNo: '',
  username: '',
  maxAmount: 0,
  amount: 0,
  reason: '后台退款',
})

onMounted(load)

function queryString() {
  const params = new URLSearchParams()
  if (range.value?.length === 2) {
    params.set('from', String(range.value[0]))
    params.set('to', String(Number(range.value[1]) + 86400000 - 1))
  }
  return params.toString()
}

async function load() {
  loading.value = true
  try {
    const query = queryString()
    summary.value = await adminRequest('/api/admin/commerce/orders' + (query ? `?${query}` : ''))
  } catch (error) {
    ElMessage.error(error.message)
  } finally {
    loading.value = false
  }
}

async function download() {
  const query = queryString()
  const response = await fetch(`${API_BASE}/api/admin/commerce/orders?export=1${query ? `&${query}` : ''}`, {
    headers: { Authorization: `Bearer ${session.user?.token || ''}` },
  })
  const blob = await response.blob()
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = 'orders.csv'
  link.click()
  URL.revokeObjectURL(url)
}

function canRefund(row) {
  return Number(row.payStatus) === 1 && (Number(row.refundStatus) < 0 || Number(row.refundStatus) === 3)
}

function openRefund(row) {
  refundForm.orderId = row.id
  refundForm.orderNo = row.orderNo
  refundForm.username = row.username
  refundForm.maxAmount = Number(row.amount || 0)
  refundForm.amount = Number(row.amount || 0)
  refundForm.reason = '后台退款'
  refundOpen.value = true
}

async function submitRefund() {
  const amount = Number(refundForm.amount)
  if (!(amount > 0)) {
    ElMessage.warning('请填写退款金额')
    return
  }
  if (amount > refundForm.maxAmount) {
    ElMessage.warning('退款金额不能超过订单金额')
    return
  }
  refundBusy.value = true
  try {
    await adminRequest(`/api/admin/commerce/orders/${refundForm.orderId}/refund`, {
      method: 'POST',
      body: {
        amount,
        reason: refundForm.reason || '后台退款',
      },
    })
    ElMessage.success('已退款并封禁该账号')
    refundOpen.value = false
    await load()
  } catch (error) {
    ElMessage.error(error.message)
  } finally {
    refundBusy.value = false
  }
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>订单</h2>
        <p>共 {{ summary.total }} 笔，已支付 {{ formatMoney(summary.paidAmount) }}。退款成功会扣回佣金并封禁账号。</p>
      </div>
      <div class="filters">
        <el-date-picker v-model="range" type="daterange" value-format="x" start-placeholder="开始日期" end-placeholder="结束日期" />
        <el-button type="primary" @click="load">查询</el-button>
        <el-button @click="download">导出</el-button>
      </div>
    </div>
    <el-table v-loading="loading" :data="summary.orders || []" size="small">
      <el-table-column prop="orderNo" label="订单号" min-width="160" />
      <el-table-column prop="username" label="用户" min-width="120" />
      <el-table-column prop="packageName" label="套餐" width="90" />
      <el-table-column label="金额" width="100">
        <template #default="{ row }">{{ formatMoney(row.amount) }}</template>
      </el-table-column>
      <el-table-column label="手续费" width="90">
        <template #default="{ row }">{{ formatMoney(row.gatewayFee) }}</template>
      </el-table-column>
      <el-table-column label="分佣基数" width="100">
        <template #default="{ row }">{{ formatMoney(row.commissionBase) }}</template>
      </el-table-column>
      <el-table-column label="支付" width="90">
        <template #default="{ row }">{{ label(PAY_STATUS, row.payStatus) }}</template>
      </el-table-column>
      <el-table-column label="分佣" width="90">
        <template #default="{ row }">{{ label(COMMISSION_STATUS, row.commissionStatus) }}</template>
      </el-table-column>
      <el-table-column label="退款" width="90">
        <template #default="{ row }">{{ row.refundStatus < 0 ? '无' : label(REFUND_STATUS, row.refundStatus) }}</template>
      </el-table-column>
      <el-table-column label="节点" width="90">
        <template #default="{ row }">{{ label(SERVICE_STATUS, row.serviceStatus) }}</template>
      </el-table-column>
      <el-table-column label="下单时间" width="150">
        <template #default="{ row }">{{ formatTime(row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="支付时间" width="150">
        <template #default="{ row }">{{ formatTime(row.payTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="100" fixed="right">
        <template #default="{ row }">
          <el-button v-if="canRefund(row)" link type="danger" @click="openRefund(row)">退款</el-button>
          <span v-else class="muted">—</span>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="refundOpen" title="退款申请" width="420px" destroy-on-close>
      <p class="refund-tip">
        订单 {{ refundForm.orderNo }} / {{ refundForm.username }}。退款成功后会扣回佣金，并封禁此账号。
      </p>
      <el-form label-width="96px">
        <el-form-item label="订单金额">
          <span>{{ formatMoney(refundForm.maxAmount) }}</span>
        </el-form-item>
        <el-form-item label="退款金额" required>
          <el-input-number
            v-model="refundForm.amount"
            :min="0.01"
            :max="refundForm.maxAmount"
            :precision="2"
            :step="1"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="退款原因">
          <el-input v-model="refundForm.reason" maxlength="100" show-word-limit placeholder="后台退款" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="refundOpen = false">取消</el-button>
        <el-button type="danger" :loading="refundBusy" @click="submitRefund">确认退款并封禁</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.refund-tip {
  margin: 0 0 16px;
  color: #64748b;
  line-height: 1.5;
}
.muted {
  color: #94a3b8;
}
</style>

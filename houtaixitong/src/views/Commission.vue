<script setup>
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { request } from '@/api'
import { ORDER_STATUS, token } from '@/stores/session'
import { formatMoney, formatRate, formatTime } from '@/utils/format'

const loading = ref(false)
const status = ref('')
const summary = ref({ pending: 0, settled: 0, rejected: 0, balance: 0, totalCommission: 0, orders: [] })

const rows = computed(() => {
  const orders = summary.value.orders || []
  if (!status.value) return orders
  return orders.filter((item) => item.status === status.value)
})

onMounted(load)

async function load() {
  loading.value = true
  try {
    summary.value = await request('/api/agent/commissions', { token: token() })
  } catch (error) {
    ElMessage.error(error.message || '加载失败')
  } finally {
    loading.value = false
  }
}

function statusOf(value) {
  return ORDER_STATUS[value] || { label: value || '—', type: 'info' }
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>分佣订单</h2>
        <p>只显示当前代理自己的分佣，以及产生这笔分佣的订单。</p>
      </div>
      <el-select v-model="status" clearable placeholder="全部状态" style="width: 160px">
        <el-option label="待结算" value="pending" />
        <el-option label="已结算" value="settled" />
        <el-option label="已驳回" value="rejected" />
      </el-select>
    </div>
    <div class="stat-grid">
      <div class="stat-card">
        <span>账户余额</span>
        <strong>{{ formatMoney(summary.balance) }}</strong>
      </div>
      <div class="stat-card">
        <span>累计分佣</span>
        <strong>{{ formatMoney(summary.totalCommission) }}</strong>
      </div>
      <div class="stat-card">
        <span>待结算</span>
        <strong>{{ formatMoney(summary.pending) }}</strong>
      </div>
      <div class="stat-card">
        <span>已结算</span>
        <strong>{{ formatMoney(summary.settled) }}</strong>
        <em>已驳回 {{ formatMoney(summary.rejected) }}</em>
      </div>
    </div>
    <el-table v-loading="loading" :data="rows" empty-text="还没有分佣订单">
      <el-table-column prop="orderNo" label="订单号" min-width="160" />
      <el-table-column prop="userName" label="用户" min-width="140">
        <template #default="{ row }">{{ row.userName || '—' }}</template>
      </el-table-column>
      <el-table-column label="订单金额" width="120">
        <template #default="{ row }">{{ formatMoney(row.orderAmount) }}</template>
      </el-table-column>
      <el-table-column label="比例" width="90">
        <template #default="{ row }">{{ formatRate(row.rate) }}</template>
      </el-table-column>
      <el-table-column label="分佣" width="120">
        <template #default="{ row }">{{ formatMoney(row.commission) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-tag size="small" :type="statusOf(row.status).type">{{ statusOf(row.status).label }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="时间" min-width="160">
        <template #default="{ row }">{{ formatTime(row.createdAt) }}</template>
      </el-table-column>
      <el-table-column prop="remark" label="备注" min-width="160">
        <template #default="{ row }">{{ row.remark || '—' }}</template>
      </el-table-column>
    </el-table>
  </div>
</template>

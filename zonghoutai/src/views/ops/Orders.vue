<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { API_BASE } from '@/config'
import { session } from '@/stores/db'
import { adminRequest, COMMISSION_STATUS, PAY_STATUS, REFUND_STATUS, SERVICE_STATUS, label } from '@/ops'
import { formatMoney, formatTime } from '@/utils/format'

const loading = ref(false)
const range = ref([])
const summary = ref({ total: 0, paidAmount: 0, orders: [] })

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
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>订单</h2>
        <p>共 {{ summary.total }} 笔，已支付 {{ formatMoney(summary.paidAmount) }}。分佣基数 = 实付金额 - 四方手续费。</p>
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
    </el-table>
  </div>
</template>

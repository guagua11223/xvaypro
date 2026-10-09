<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { adminRequest, REFUND_STATUS, WITHDRAW_STATUS, label } from '@/ops'
import { formatMoney, formatTime } from '@/utils/format'

const rules = ref({ feeRate: 0, minAmount: 0, settleDay: 1 })
const withdrawals = ref([])
const refunds = ref([])

onMounted(load)

async function load() {
  const [cash, back] = await Promise.all([
    adminRequest('/api/admin/withdrawals'),
    adminRequest('/api/admin/refunds'),
  ])
  rules.value = { feeRate: cash.feeRate, minAmount: cash.minAmount, settleDay: cash.settleDay }
  withdrawals.value = cash.withdrawals || []
  refunds.value = back.refunds || []
}

async function saveRules() {
  await adminRequest('/api/admin/withdrawals/rules', { method: 'POST', body: rules.value })
  ElMessage.success('提现规则已保存')
}

async function audit(row, action) {
  await adminRequest(`/api/admin/withdrawals/${row.id}/audit`, { method: 'POST', body: { action } })
  ElMessage.success('已处理')
  await load()
}

async function refund(row, action) {
  await adminRequest(`/api/admin/refunds/${row.id}/handle`, { method: 'POST', body: { action } })
  ElMessage.success(action === 'approve' ? '已退款并封禁，可再解封' : '已拒绝')
  await load()
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>提现与退款</h2>
        <p>分佣按月结算，默认每月 1 日结算上月。退款成功会扣回佣金并封禁账号。</p>
      </div>
    </div>
    <div class="filters">
      <el-input-number v-model="rules.feeRate" :min="0" :max="100" />
      <span>提现手续费 %</span>
      <el-input-number v-model="rules.minAmount" :min="0" />
      <span>最低金额</span>
      <el-input-number v-model="rules.settleDay" :min="1" :max="28" />
      <span>结算日</span>
      <el-button type="primary" @click="saveRules">保存</el-button>
    </div>
    <h3>提现</h3>
    <el-table :data="withdrawals" size="small">
      <el-table-column prop="userId" label="会员ID" width="80" />
      <el-table-column prop="username" label="名称" min-width="120" />
      <el-table-column label="金额" width="100">
        <template #default="{ row }">{{ formatMoney(row.amount) }}</template>
      </el-table-column>
      <el-table-column label="手续费" width="90">
        <template #default="{ row }">{{ formatMoney(row.fee) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="100">
        <template #default="{ row }">{{ label(WITHDRAW_STATUS, row.status) }}</template>
      </el-table-column>
      <el-table-column prop="month" label="结算月份" width="100" />
      <el-table-column label="申请时间" width="150">
        <template #default="{ row }">{{ formatTime(row.applyTime) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="200">
        <template #default="{ row }">
          <el-button v-if="row.status === 0" link type="primary" @click="audit(row, 'approve')">通过</el-button>
          <el-button v-if="row.status === 0" link @click="audit(row, 'reject')">拒绝</el-button>
          <el-button v-if="row.status === 0 || row.status === 1" link type="success" @click="audit(row, 'pay')">打款</el-button>
        </template>
      </el-table-column>
    </el-table>
    <h3>退款</h3>
    <el-table :data="refunds" size="small">
      <el-table-column prop="orderNo" label="订单号" min-width="150" />
      <el-table-column prop="username" label="用户" width="120" />
      <el-table-column label="金额" width="100">
        <template #default="{ row }">{{ formatMoney(row.amount) }}</template>
      </el-table-column>
      <el-table-column prop="reason" label="原因" min-width="160" />
      <el-table-column label="状态" width="90">
        <template #default="{ row }">{{ label(REFUND_STATUS, row.status) }}</template>
      </el-table-column>
      <el-table-column label="操作" width="160">
        <template #default="{ row }">
          <template v-if="row.status === 0 || row.status === 1">
            <el-button link type="danger" @click="refund(row, 'approve')">同意并封禁</el-button>
            <el-button link @click="refund(row, 'reject')">拒绝</el-button>
          </template>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

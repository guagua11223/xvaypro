<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { request } from '@/api'
import { token } from '@/stores/session'
import { formatMoney, formatTime } from '@/utils/format'

const amount = ref(10)
const data = ref({ withdrawals: [] })
const names = ['待审核', '审核通过', '已打款', '已拒绝', '已取消']

onMounted(load)

async function load() {
  data.value = await request('/api/distributor/withdrawals', { token: token() })
}

async function submit() {
  await request('/api/distributor/withdrawals', { method: 'POST', token: token(), body: { amount: amount.value } })
  ElMessage.success('已提交提现')
  await load()
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>提现</h2>
        <p>可提现 {{ formatMoney(data.balance) }}，冻结 {{ formatMoney(data.frozen) }}，负余额 {{ formatMoney(data.negativeBalance) }}。手续费 {{ data.feeRate || 0 }}%，最低 {{ formatMoney(data.minAmount) }}。冻结金额要到结算日才进入可提现。</p>
      </div>
      <div class="filters">
        <el-input-number v-model="amount" :min="1" />
        <el-button type="primary" @click="submit">申请提现</el-button>
      </div>
    </div>
    <el-table :data="data.withdrawals || []">
      <el-table-column label="金额" width="120"><template #default="{ row }">{{ formatMoney(row.amount) }}</template></el-table-column>
      <el-table-column label="手续费" width="100"><template #default="{ row }">{{ formatMoney(row.fee) }}</template></el-table-column>
      <el-table-column label="状态" width="100"><template #default="{ row }">{{ names[row.status] }}</template></el-table-column>
      <el-table-column prop="month" label="月份" width="100" />
      <el-table-column label="申请时间" min-width="160"><template #default="{ row }">{{ formatTime(row.applyTime) }}</template></el-table-column>
    </el-table>
  </div>
</template>

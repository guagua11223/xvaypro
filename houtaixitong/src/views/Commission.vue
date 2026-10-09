<script setup>
import { onMounted, ref } from 'vue'
import { request } from '@/api'
import { token } from '@/stores/session'
import { formatMoney, formatTime } from '@/utils/format'

const orders = ref([])
const rows = ref([])
const statusName = ['待结算', '已结算', '已退回']

onMounted(async () => {
  orders.value = (await request('/api/distributor/orders', { token: token() })).orders || []
  rows.value = (await request('/api/distributor/commissions', { token: token() })).commissions || []
})
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>订单与佣金</h2>
        <p>只显示旗下会员的订单，以及自己拿到的佣金。经销商模式不向上再分三级。</p>
      </div>
    </div>
    <h3>旗下订单</h3>
    <el-table :data="orders" size="small">
      <el-table-column prop="orderNo" label="订单号" min-width="150" />
      <el-table-column prop="userId" label="会员" width="80" />
      <el-table-column label="金额" width="100"><template #default="{ row }">{{ formatMoney(row.amount) }}</template></el-table-column>
      <el-table-column label="手续费" width="90"><template #default="{ row }">{{ formatMoney(row.gatewayFee) }}</template></el-table-column>
      <el-table-column label="分佣基数" width="100"><template #default="{ row }">{{ formatMoney(row.commissionBase) }}</template></el-table-column>
      <el-table-column label="时间" width="150"><template #default="{ row }">{{ formatTime(row.createdAt) }}</template></el-table-column>
    </el-table>
    <h3>佣金明细</h3>
    <el-table :data="rows" size="small">
      <el-table-column prop="fromUserId" label="来源会员" width="100" />
      <el-table-column prop="level" label="层级" width="70" />
      <el-table-column label="比例" width="80"><template #default="{ row }">{{ row.rate }}%</template></el-table-column>
      <el-table-column label="基数" width="100"><template #default="{ row }">{{ formatMoney(row.baseAmount) }}</template></el-table-column>
      <el-table-column label="佣金" width="100"><template #default="{ row }">{{ formatMoney(row.amount) }}</template></el-table-column>
      <el-table-column label="状态" width="90"><template #default="{ row }">{{ statusName[row.status] || '—' }}</template></el-table-column>
      <el-table-column label="时间" width="150"><template #default="{ row }">{{ formatTime(row.createdAt) }}</template></el-table-column>
    </el-table>
  </div>
</template>

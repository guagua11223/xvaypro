<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { request } from '@/api'
import { session, token } from '@/stores/session'
import { formatMoney } from '@/utils/format'

const data = ref({})
onMounted(async () => {
  try {
    data.value = await request('/api/distributor/dashboard', { token: token() })
  } catch (error) {
    ElMessage.error(error.message)
  }
})
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>{{ session.user?.username || '经销商' }}</h2>
        <p>邀请码 {{ data.inviteCode || session.user?.inviteCode || '—' }}。只能看自己旗下的会员，不能封禁，也不能改系统分佣。</p>
      </div>
    </div>
    <div class="stat-grid">
      <div class="stat-card"><span>旗下人数</span><strong>{{ data.members || 0 }}</strong><em>今日新增 {{ data.todayMembers || 0 }}</em></div>
      <div class="stat-card"><span>今日订单</span><strong>{{ formatMoney(data.todayOrderAmount) }}</strong></div>
      <div class="stat-card"><span>今日佣金</span><strong>{{ formatMoney(data.todayCommission) }}</strong><em>累计 {{ formatMoney(data.totalCommission) }}</em></div>
      <div class="stat-card"><span>可提现</span><strong>{{ formatMoney(data.balance) }}</strong><em>冻结 {{ formatMoney(data.frozen) }} · 比例 {{ data.rate || 0 }}%</em></div>
    </div>
  </div>
</template>

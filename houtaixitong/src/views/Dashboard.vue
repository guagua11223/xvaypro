<script setup>
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { request } from '@/api'
import { session, token } from '@/stores/session'
import { formatMoney } from '@/utils/format'

const loading = ref(false)
const team = ref({ direct: [] })
const commission = ref({ pending: 0, settled: 0, orders: [] })

const directCount = computed(() => team.value.direct?.length || 0)
const secondCount = computed(() =>
  (team.value.direct || []).reduce((sum, item) => sum + (item.agents?.length || 0), 0),
)

onMounted(load)

async function load() {
  loading.value = true
  try {
    const auth = token()
    const [teamData, commissionData, me] = await Promise.all([
      request('/api/agent/team', { token: auth }),
      request('/api/agent/commissions', { token: auth }),
      request('/api/agent/me', { token: auth }),
    ])
    team.value = teamData
    commission.value = commissionData
    session.user = { ...session.user, ...me, token: auth }
    localStorage.setItem('xvay-houtaixitong-session', JSON.stringify(session.user))
  } catch (error) {
    ElMessage.error(error.message || '加载失败')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="page" v-loading="loading">
    <div class="page-head">
      <div>
        <h2>{{ session.user?.name || '概览' }}</h2>
        <p>
          邀请码
          <span class="invite-code">{{ session.user?.inviteCode || '—' }}</span>
          ，发给下级注册时填写。
        </p>
      </div>
    </div>
    <div class="stat-grid">
      <div class="stat-card">
        <span>账户余额</span>
        <strong>{{ formatMoney(session.user?.balance) }}</strong>
        <em>当前可结算余额</em>
      </div>
      <div class="stat-card">
        <span>累计分佣</span>
        <strong>{{ formatMoney(session.user?.totalCommission) }}</strong>
        <em>待结算 {{ formatMoney(commission.pending) }}</em>
      </div>
      <div class="stat-card">
        <span>我的代理</span>
        <strong>{{ directCount }}</strong>
        <em>直接发展的下级</em>
      </div>
      <div class="stat-card">
        <span>代理的代理</span>
        <strong>{{ secondCount }}</strong>
        <em>下级再发展的一级</em>
      </div>
    </div>
  </div>
</template>

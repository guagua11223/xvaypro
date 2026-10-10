<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { db, labelOf, NODE_STATUS, refreshBackend } from '@/stores/db'
import { COMMISSION_STATUS, PAY_STATUS, WITHDRAW_STATUS, adminRequest, label } from '@/ops'
import { formatMoney, formatTime } from '@/utils/format'

const router = useRouter()
const stats = ref({})
const recentMembers = computed(() => stats.value.recentMembers || [])
const recentOrders = computed(() => stats.value.recentOrders || [])
const recentCommissions = computed(() => stats.value.recentCommissions || [])
const recentWithdrawals = computed(() => stats.value.recentWithdrawals || [])

const onlineNodes = computed(() => db.nodes.filter((item) => item.status === 'online').length)

onMounted(() => {
  refreshBackend().catch((error) => ElMessage.error(error.message || '加载概览失败'))
  adminRequest('/api/admin/stats').then((data) => { stats.value = data }).catch(() => {})
})
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>概览</h2>
        <p>会员、订单、佣金和提现按讯连宝的分佣规则汇总。经销商模式和系统三级分佣不叠加。</p>
      </div>
    </div>
    <div class="stat-grid">
      <div class="stat-card"><span>总会员</span><strong>{{ stats.members || 0 }}</strong><em>今日新增 {{ stats.todayMembers || 0 }}</em></div>
      <div class="stat-card"><span>今日订单</span><strong>{{ formatMoney(stats.todayOrderAmount) }}</strong><em>累计 {{ formatMoney(stats.orderAmount) }}</em></div>
      <div class="stat-card"><span>今日佣金</span><strong>{{ formatMoney(stats.todayCommission) }}</strong><em>累计 {{ formatMoney(stats.commissionTotal) }}</em></div>
      <div class="stat-card"><span>待审核提现</span><strong>{{ stats.pendingWithdraw || 0 }}</strong><em>今日打款 {{ formatMoney(stats.todayWithdraw) }}</em></div>
    </div>
    <div class="stat-grid">
      <div class="stat-card">
        <span>待结算佣金</span>
        <strong>{{ formatMoney(stats.pendingCommission) }}</strong>
        <em>已结算 {{ formatMoney(stats.settledCommission) }}</em>
      </div>
      <div class="stat-card">
        <span>钱包可提现</span>
        <strong>{{ formatMoney(stats.walletBalance) }}</strong>
        <em>冻结 {{ formatMoney(stats.walletFrozen) }}</em>
      </div>
      <div class="stat-card">
        <span>负余额</span>
        <strong>{{ formatMoney(stats.negativeBalance) }}</strong>
        <em>退款扣回后不足的部分</em>
      </div>
      <div class="stat-card">
        <span>在线线路</span>
        <strong>{{ onlineNodes }} / {{ db.nodes.length }}</strong>
        <em>今日订单 {{ stats.todayOrderCount || 0 }} 笔 · 今日经销商 {{ stats.todayDistributors || 0 }}</em>
      </div>
    </div>
    <div class="two-col">
      <el-card shadow="never">
        <template #header>线路状态</template>
        <el-table :data="db.nodes" size="small">
          <el-table-column prop="name" label="线路" />
          <el-table-column prop="region" label="地区" width="120" />
          <el-table-column label="内核" width="110" prop="coreType" />
          <el-table-column label="状态" width="90">
            <template #default="{ row }">
              <el-tag :type="row.status === 'online' ? 'success' : row.status === 'maintain' ? 'warning' : 'info'" size="small">
                {{ labelOf(NODE_STATUS, row.status) }}
              </el-tag>
            </template>
          </el-table-column>
          <el-table-column label="延迟" width="80">
            <template #default="{ row }">{{ row.latency ? `${row.latency} ms` : '—' }}</template>
          </el-table-column>
        </el-table>
        <div style="margin-top: 12px; text-align: right">
          <el-button link type="primary" @click="router.push('/config/nodes')">管理线路</el-button>
        </div>
      </el-card>
      <el-card shadow="never">
        <template #header>最近会员</template>
        <el-table :data="recentMembers" size="small">
          <el-table-column prop="username" label="会员" />
          <el-table-column prop="userType" label="类型" width="90" />
          <el-table-column label="钱包" width="70">
            <template #default="{ row }">{{ row.walletEnabled ? '开通' : '关闭' }}</template>
          </el-table-column>
          <el-table-column label="注册时间" width="150">
            <template #default="{ row }">{{ formatTime(row.createdAt) }}</template>
          </el-table-column>
        </el-table>
      </el-card>
    </div>
    <div class="two-col">
      <el-card shadow="never">
        <template #header>最近订单</template>
        <el-table :data="recentOrders" size="small">
          <el-table-column prop="orderNo" label="订单号" min-width="140" />
          <el-table-column prop="username" label="会员" width="100" />
          <el-table-column label="金额" width="90">
            <template #default="{ row }">{{ formatMoney(row.amount) }}</template>
          </el-table-column>
          <el-table-column label="支付" width="80">
            <template #default="{ row }">{{ label(PAY_STATUS, row.payStatus) }}</template>
          </el-table-column>
        </el-table>
      </el-card>
      <el-card shadow="never">
        <template #header>最近提现</template>
        <el-table :data="recentWithdrawals" size="small">
          <el-table-column prop="username" label="会员" />
          <el-table-column label="金额" width="90">
            <template #default="{ row }">{{ formatMoney(row.amount) }}</template>
          </el-table-column>
          <el-table-column label="状态" width="90">
            <template #default="{ row }">{{ label(WITHDRAW_STATUS, row.status) }}</template>
          </el-table-column>
        </el-table>
      </el-card>
    </div>
    <el-card shadow="never">
      <template #header>最近佣金</template>
      <el-table :data="recentCommissions" size="small">
        <el-table-column prop="fromUsername" label="来源会员" min-width="120" />
        <el-table-column label="模式" width="100">
          <template #default="{ row }">{{ row.mode === 1 ? '经销商' : '系统三级' }}</template>
        </el-table-column>
        <el-table-column prop="level" label="层级" width="70" />
        <el-table-column label="佣金" width="120">
          <template #default="{ row }">{{ formatMoney(row.amount) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">{{ label(COMMISSION_STATUS, row.status) }}</template>
        </el-table-column>
        <el-table-column label="时间" width="150">
          <template #default="{ row }">{{ formatTime(row.createdAt) }}</template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

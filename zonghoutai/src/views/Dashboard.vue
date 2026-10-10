<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { agentName, db, labelOf, NODE_STATUS, refreshBackend, userName } from '@/stores/db'
import { adminRequest } from '@/ops'
import { formatMoney, formatTime } from '@/utils/format'

const router = useRouter()
const stats = ref({})

const onlineNodes = computed(() => db.nodes.filter((item) => item.status === 'online').length)
const activeUsers = computed(() => db.users.filter((item) => item.status === 'active').length)
const activeAgents = computed(() => db.agents.filter((item) => item.status === 'active').length)
const pending = computed(() => db.commissions.filter((item) => item.status === 'pending'))
const pendingAmount = computed(() => pending.value.reduce((sum, item) => sum + item.commission, 0))

const recentUsers = computed(() =>
  [...db.users].sort((a, b) => new Date(b.registeredAt) - new Date(a.registeredAt)).slice(0, 5),
)

const recentCommissions = computed(() =>
  [...db.commissions].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)).slice(0, 5),
)

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
      <div class="stat-card"><span>待审核提现</span><strong>{{ stats.pendingWithdraw || 0 }}</strong><em>今日新增经销商 {{ stats.todayDistributors || 0 }}</em></div>
    </div>
    <div class="stat-grid">
      <div class="stat-card">
        <span>在线线路</span>
        <strong>{{ onlineNodes }} / {{ db.nodes.length }}</strong>
        <em>对应 App 选线列表</em>
      </div>
      <div class="stat-card">
        <span>正常用户</span>
        <strong>{{ activeUsers }}</strong>
        <em>共 {{ db.users.length }} 个账号</em>
      </div>
      <div class="stat-card">
        <span>在营代理</span>
        <strong>{{ activeAgents }}</strong>
        <em>共 {{ db.agents.length }} 个代理商</em>
      </div>
      <div class="stat-card">
        <span>待结算佣金</span>
        <strong>{{ formatMoney(pendingAmount) }}</strong>
        <em>{{ pending.length }} 笔待处理</em>
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
        <template #header>最近注册用户</template>
        <el-table :data="recentUsers" size="small">
          <el-table-column prop="username" label="用户" />
          <el-table-column label="代理" width="110">
            <template #default="{ row }">{{ agentName(row.agentId) }}</template>
          </el-table-column>
          <el-table-column label="注册时间" width="150">
            <template #default="{ row }">{{ formatTime(row.registeredAt) }}</template>
          </el-table-column>
        </el-table>
      </el-card>
    </div>
    <el-card shadow="never">
      <template #header>最近分佣</template>
      <el-table :data="recentCommissions" size="small">
        <el-table-column prop="orderNo" label="订单号" width="160" />
        <el-table-column label="代理商">
          <template #default="{ row }">{{ agentName(row.agentId) }}</template>
        </el-table-column>
        <el-table-column label="用户">
          <template #default="{ row }">{{ userName(row.userId) }}</template>
        </el-table-column>
        <el-table-column label="佣金" width="120">
          <template #default="{ row }">{{ formatMoney(row.commission) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'settled' ? 'success' : row.status === 'pending' ? 'warning' : 'info'" size="small">
              {{ row.status === 'settled' ? '已结算' : row.status === 'pending' ? '待结算' : '已驳回' }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

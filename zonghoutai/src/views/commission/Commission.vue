<script setup>
import { computed, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  addItem,
  AGENT_LEVELS,
  agentName,
  COMMISSION_STATUS,
  db,
  labelOf,
  planName,
  rejectCommission,
  settleCommission,
  tagOf,
  userName,
} from '@/stores/db'
import { formatMoney, formatTime } from '@/utils/format'

const status = ref('')
const agentId = ref()
const page = ref(1)
const dialogVisible = ref(false)
const formRef = ref()
const form = reactive({
  agentId: null,
  userId: null,
  orderAmount: 30,
  remark: '',
})

const rules = {
  agentId: [{ required: true, message: '请选择代理商', trigger: 'change' }],
  userId: [{ required: true, message: '请选择用户', trigger: 'change' }],
  orderAmount: [{ required: true, message: '请输入订单金额', trigger: 'change' }],
}

const filtered = computed(() =>
  db.commissions.filter((item) => {
    const statusOk = !status.value || item.status === status.value
    const agentOk = !agentId.value || item.agentId === agentId.value
    return statusOk && agentOk
  }),
)

const paged = computed(() => filtered.value.slice((page.value - 1) * 8, page.value * 8))

const summary = computed(() => {
  const sum = (target) =>
    db.commissions.filter((item) => item.status === target).reduce((total, item) => total + item.commission, 0)
  return {
    pending: sum('pending'),
    settled: sum('settled'),
    rejected: sum('rejected'),
  }
})

const cycleLabel = {
  daily: '按日',
  weekly: '按周',
  monthly: '按月',
}

function rateOf(level) {
  return db.commissionRules.find((item) => item.level === level && item.enabled)
}

function openCreate() {
  form.agentId = db.agents.find((item) => item.status === 'active')?.id ?? null
  form.userId = null
  form.orderAmount = 30
  form.remark = ''
  dialogVisible.value = true
}

const preview = computed(() => {
  const agent = db.agents.find((item) => item.id === form.agentId)
  const rule = agent ? rateOf(agent.level) : null
  if (!agent || !rule) return null
  if (form.orderAmount < rule.minOrder) {
    return { text: `未达到最低订单 ${formatMoney(rule.minOrder)}`, commission: 0 }
  }
  const commission = Number(((form.orderAmount * rule.rate) / 100).toFixed(2))
  return { text: `${labelOf(AGENT_LEVELS, agent.level)} ${rule.rate}%`, commission }
})

async function submit() {
  await formRef.value.validate()
  const agent = db.agents.find((item) => item.id === form.agentId)
  if (!agent || agent.status !== 'active') {
    ElMessage.warning('代理商未在营，不能记佣')
    return
  }
  const rule = rateOf(agent.level)
  if (!rule) {
    ElMessage.warning('该等级分佣规则未启用')
    return
  }
  if (Number(form.orderAmount) < rule.minOrder) {
    ElMessage.warning(`订单金额需不低于 ${formatMoney(rule.minOrder)}`)
    return
  }
  const user = db.users.find((item) => item.id === form.userId)
  const commission = Number(((Number(form.orderAmount) * rule.rate) / 100).toFixed(2))
  const orderNo = `XV${new Date().toISOString().slice(0, 10).replace(/-/g, '')}${String(db.commissions.length + 1).padStart(3, '0')}`
  addItem('commissions', {
    agentId: agent.id,
    userId: user.id,
    orderNo,
    orderAmount: Number(form.orderAmount),
    rate: rule.rate,
    commission,
    status: 'pending',
    createdAt: new Date().toISOString(),
    settledAt: '',
    remark: form.remark.trim() || `${planName(user.planId)}成交`,
  })
  dialogVisible.value = false
  ElMessage.success('已生成待结算分佣')
}

async function settle(row) {
  await ElMessageBox.confirm(`确认结算 ${formatMoney(row.commission)} 给「${agentName(row.agentId)}」？`, '结算分佣', {
    type: 'warning',
  })
  settleCommission(row.id)
  ElMessage.success('已结算，金额计入代理可提现余额')
}

async function reject(row) {
  const { value } = await ElMessageBox.prompt('填写驳回原因', '驳回分佣', {
    inputPlaceholder: '例如订单已退款',
    inputValidator: (text) => (text && text.trim() ? true : '请填写原因'),
  })
  rejectCommission(row.id, value.trim())
  ElMessage.success('已驳回')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>代理分佣</h2>
        <p>按代理等级设置比例。用户成交后生成待结算记录，结算后计入代理可提现余额。</p>
      </div>
      <el-button type="primary" @click="openCreate">登记成交</el-button>
    </div>

    <div class="stat-grid" style="grid-template-columns: repeat(3, minmax(0, 1fr))">
      <div class="stat-card">
        <span>待结算</span>
        <strong>{{ formatMoney(summary.pending) }}</strong>
      </div>
      <div class="stat-card">
        <span>已结算</span>
        <strong>{{ formatMoney(summary.settled) }}</strong>
      </div>
      <div class="stat-card">
        <span>已驳回</span>
        <strong>{{ formatMoney(summary.rejected) }}</strong>
      </div>
    </div>

    <el-card shadow="never">
      <template #header>分佣规则</template>
      <el-table :data="db.commissionRules">
        <el-table-column label="等级" width="120">
          <template #default="{ row }">
            <el-tag :type="tagOf(AGENT_LEVELS, row.level)" size="small">{{ labelOf(AGENT_LEVELS, row.level) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="比例" width="180">
          <template #default="{ row }">
            <el-input-number v-model="row.rate" :min="0" :max="100" size="small" />
            <span style="margin-left: 6px">%</span>
          </template>
        </el-table-column>
        <el-table-column label="最低订单" width="180">
          <template #default="{ row }">
            <el-input-number v-model="row.minOrder" :min="0" :precision="2" size="small" />
          </template>
        </el-table-column>
        <el-table-column label="结算周期" width="160">
          <template #default="{ row }">
            <el-select v-model="row.settleCycle" size="small" style="width: 120px">
              <el-option label="按日" value="daily" />
              <el-option label="按周" value="weekly" />
              <el-option label="按月" value="monthly" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="启用" width="100">
          <template #default="{ row }">
            <el-switch v-model="row.enabled" />
          </template>
        </el-table-column>
        <el-table-column label="说明">
          <template #default="{ row }">
            {{ labelOf(AGENT_LEVELS, row.level) }}代理，{{ cycleLabel[row.settleCycle] }}结算，满 {{ formatMoney(row.minOrder) }} 按 {{ row.rate }}% 计佣。
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="never">
      <template #header>分佣记录</template>
      <div class="filters">
        <el-select v-model="agentId" clearable placeholder="代理商" style="width: 180px" @change="page = 1">
          <el-option v-for="agent in db.agents" :key="agent.id" :label="agent.name" :value="agent.id" />
        </el-select>
        <el-select v-model="status" clearable placeholder="状态" style="width: 140px" @change="page = 1">
          <el-option v-for="item in COMMISSION_STATUS" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
      </div>
      <el-table :data="paged" style="margin-top: 16px">
        <el-table-column prop="orderNo" label="订单号" width="160" />
        <el-table-column label="代理商" width="120">
          <template #default="{ row }">{{ agentName(row.agentId) }}</template>
        </el-table-column>
        <el-table-column label="用户" width="100">
          <template #default="{ row }">{{ userName(row.userId) }}</template>
        </el-table-column>
        <el-table-column label="订单金额" width="110">
          <template #default="{ row }">{{ formatMoney(row.orderAmount) }}</template>
        </el-table-column>
        <el-table-column label="比例" width="80">
          <template #default="{ row }">{{ row.rate }}%</template>
        </el-table-column>
        <el-table-column label="佣金" width="110">
          <template #default="{ row }">{{ formatMoney(row.commission) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="tagOf(COMMISSION_STATUS, row.status)" size="small">{{ labelOf(COMMISSION_STATUS, row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" min-width="120" />
        <el-table-column label="时间" width="160">
          <template #default="{ row }">{{ formatTime(row.settledAt || row.createdAt) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{ row }">
            <template v-if="row.status === 'pending'">
              <el-button link type="primary" @click="settle(row)">结算</el-button>
              <el-button link type="danger" @click="reject(row)">驳回</el-button>
            </template>
            <span v-else style="color: #9ca3af">已处理</span>
          </template>
        </el-table-column>
      </el-table>
      <div style="margin-top: 16px; display: flex; justify-content: flex-end">
        <el-pagination v-model:current-page="page" layout="total, prev, pager, next" :total="filtered.length" :page-size="8" />
      </div>
    </el-card>

    <el-dialog v-model="dialogVisible" title="登记成交" width="480px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="代理商" prop="agentId">
          <el-select v-model="form.agentId" style="width: 100%">
            <el-option v-for="agent in db.agents" :key="agent.id" :label="agent.name" :value="agent.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="用户" prop="userId">
          <el-select v-model="form.userId" style="width: 100%">
            <el-option v-for="user in db.users" :key="user.id" :label="user.username" :value="user.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="订单金额" prop="orderAmount">
          <el-input-number v-model="form.orderAmount" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="预计佣金">
          <span v-if="preview">{{ preview.text }} · {{ formatMoney(preview.commission) }}</span>
          <span v-else>—</span>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">生成待结算</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { request } from '@/api'
import { LEVELS, token } from '@/stores/session'
import { formatMoney, formatTime } from '@/utils/format'

const loading = ref(false)
const keyword = ref('')
const direct = ref([])

const rows = computed(() => {
  const text = keyword.value.trim().toLowerCase()
  if (!text) return direct.value
  return direct.value.filter((item) => {
    const self = `${item.name} ${item.username} ${item.inviteCode}`.toLowerCase().includes(text)
    const child = (item.agents || []).some((agent) =>
      `${agent.name} ${agent.username} ${agent.inviteCode}`.toLowerCase().includes(text),
    )
    return self || child
  })
})

onMounted(load)

async function load() {
  loading.value = true
  try {
    const data = await request('/api/agent/team', { token: token() })
    direct.value = data.direct || []
  } catch (error) {
    ElMessage.error(error.message || '加载失败')
  } finally {
    loading.value = false
  }
}

function levelOf(value) {
  return LEVELS[value] || { label: value || '—', type: 'info' }
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>我的代理</h2>
        <p>展开一行，可以看到这个代理名下再发展的代理。这里只显示两级。</p>
      </div>
      <el-input v-model="keyword" clearable placeholder="搜索名称、账号、邀请码" style="width: 240px" />
    </div>
    <el-table v-loading="loading" :data="rows" row-key="id" empty-text="还没有下级代理">
      <el-table-column type="expand">
        <template #default="{ row }">
          <div style="padding: 4px 12px 12px 48px">
            <p class="nested-title">{{ row.name }} 名下的代理</p>
            <el-table :data="row.agents || []" size="small" empty-text="还没有再发展的代理">
              <el-table-column prop="name" label="名称" min-width="120" />
              <el-table-column prop="username" label="账号" min-width="120" />
              <el-table-column label="等级" width="90">
                <template #default="{ row: agent }">
                  <el-tag size="small" :type="levelOf(agent.level).type">{{ levelOf(agent.level).label }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="inviteCode" label="邀请码" min-width="120" />
              <el-table-column label="状态" width="90">
                <template #default="{ row: agent }">
                  <el-tag size="small" :type="agent.status === 'frozen' ? 'info' : 'success'">
                    {{ agent.status === 'frozen' ? '冻结' : '正常' }}
                  </el-tag>
                </template>
              </el-table-column>
              <el-table-column label="累计分佣" width="120">
                <template #default="{ row: agent }">{{ formatMoney(agent.totalCommission) }}</template>
              </el-table-column>
            </el-table>
          </div>
        </template>
      </el-table-column>
      <el-table-column prop="name" label="名称" min-width="120" />
      <el-table-column prop="username" label="账号" min-width="120" />
      <el-table-column prop="phone" label="手机" min-width="120">
        <template #default="{ row }">{{ row.phone || '—' }}</template>
      </el-table-column>
      <el-table-column label="等级" width="90">
        <template #default="{ row }">
          <el-tag size="small" :type="levelOf(row.level).type">{{ levelOf(row.level).label }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="inviteCode" label="邀请码" min-width="130" />
      <el-table-column label="名下代理" width="100">
        <template #default="{ row }">{{ row.agents?.length || 0 }}</template>
      </el-table-column>
      <el-table-column label="状态" width="90">
        <template #default="{ row }">
          <el-tag size="small" :type="row.status === 'frozen' ? 'info' : 'success'">
            {{ row.status === 'frozen' ? '冻结' : '正常' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="累计分佣" width="120">
        <template #default="{ row }">{{ formatMoney(row.totalCommission) }}</template>
      </el-table-column>
      <el-table-column label="加入时间" min-width="150">
        <template #default="{ row }">{{ formatTime(row.createdAt) }}</template>
      </el-table-column>
    </el-table>
  </div>
</template>

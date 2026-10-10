<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { adminRequest } from '@/ops'
import { formatMoney } from '@/utils/format'

const rows = ref([])
const loading = ref(false)

onMounted(load)

async function load() {
  loading.value = true
  try {
    const data = await adminRequest('/api/admin/distributors')
    rows.value = data.distributors || []
  } catch (error) {
    ElMessage.error(error.message)
  } finally {
    loading.value = false
  }
}

async function ban(row) {
  const { value } = await ElMessageBox.prompt('封禁后已购节点立即停用，可以解封', '封禁经销商', { inputPlaceholder: '原因' })
  await adminRequest(`/api/admin/members/${row.id}/ban`, { method: 'POST', body: { reason: value || '平台封禁' } })
  ElMessage.success('已封禁')
  await load()
}

async function unban(row) {
  await adminRequest(`/api/admin/members/${row.id}/unban`, { method: 'POST', body: {} })
  ElMessage.success('已解封')
  await load()
}

async function setRate(row) {
  const { value } = await ElMessageBox.prompt('给会员设置的比例不能超过这个数', '经销商比例', {
    inputValue: String(row.rate),
  })
  await adminRequest(`/api/admin/distributors/${row.id}/rate`, { method: 'POST', body: { rate: Number(value) } })
  ElMessage.success('已更新')
  await load()
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>经销商</h2>
        <p>经销商可无限授权代理。代理不能再发展代理，也没有这个后台。</p>
      </div>
      <el-button @click="load">刷新</el-button>
    </div>
    <el-table v-loading="loading" :data="rows">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="名称" min-width="140" />
      <el-table-column prop="members" label="旗下人数" width="100" />
      <el-table-column prop="direct" label="直接" width="80" />
      <el-table-column prop="indirect" label="间接" width="80" />
      <el-table-column prop="rate" label="分佣比例" width="100">
        <template #default="{ row }">{{ row.rate }}%</template>
      </el-table-column>
      <el-table-column label="累计佣金" width="120">
        <template #default="{ row }">{{ formatMoney(row.totalCommission) }}</template>
      </el-table-column>
      <el-table-column label="可提现" width="120">
        <template #default="{ row }">{{ formatMoney(row.balance) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="80">
        <template #default="{ row }">{{ row.status === 0 ? '正常' : '禁用' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="280">
        <template #default="{ row }">
          <el-button link type="primary" @click="setRate(row)">设置比例</el-button>
          <el-button v-if="row.status !== 1" link type="danger" @click="ban(row)">封禁</el-button>
          <el-button v-else link type="success" @click="unban(row)">解封</el-button>
          <el-button link tag="a" href="/dealer/" target="_blank">经销商后台</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { request } from '@/api'
import { token } from '@/stores/session'

const rows = ref([])
const ownRate = ref(0)

onMounted(load)

async function load() {
  const data = await request('/api/distributor/members', { token: token() })
  rows.value = data.members || []
  ownRate.value = data.rate || 0
}

async function setRate(row) {
  const { value } = await ElMessageBox.prompt(`不能超过本人比例 ${ownRate.value}%`, '设置返佣比例', {
    inputValue: String(row.customRate || 0),
  })
  const rate = Number(value)
  if (rate > ownRate.value) {
    ElMessage.error('不能超过经销商本人比例')
    return
  }
  await request(`/api/distributor/members/${row.id}/rate`, { method: 'POST', token: token(), body: { rate } })
  ElMessage.success('已设置')
  await load()
}

async function makeAgent(row) {
  await request(`/api/distributor/members/${row.id}/agent`, { method: 'POST', token: token(), body: {} })
  ElMessage.success('已授权代理，对方不能再发展代理')
  await load()
}

async function askBan(row) {
  const { value } = await ElMessageBox.prompt('提交给平台处理，经销商不能直接封禁', '申请处理', { inputPlaceholder: '原因' })
  await request(`/api/distributor/members/${row.id}/ban-request`, { method: 'POST', token: token(), body: { reason: value } })
  ElMessage.success('已提交平台')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>旗下会员</h2>
        <p>可以设置返佣、无限授权代理。代理不能再授权下一级代理。</p>
      </div>
    </div>
    <el-table :data="rows">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="名称" min-width="120" />
      <el-table-column prop="userType" label="类型" width="90" />
      <el-table-column prop="parentName" label="推荐人" min-width="120" />
      <el-table-column label="返佣比例" width="100">
        <template #default="{ row }">{{ row.hasCustomRate ? row.customRate + '%' : '未设置' }}</template>
      </el-table-column>
      <el-table-column label="钱包" width="80">
        <template #default="{ row }">{{ row.walletEnabled ? '开通' : '关闭' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="240">
        <template #default="{ row }">
          <el-button link type="primary" @click="setRate(row)">设置比例</el-button>
          <el-button v-if="!row.isAgent" link @click="makeAgent(row)">授权代理</el-button>
          <el-button link @click="askBan(row)">申请处理</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

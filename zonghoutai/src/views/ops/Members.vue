<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { adminRequest, EMAIL_STATUS, label } from '@/ops'
import { formatTime } from '@/utils/format'

const loading = ref(false)
const keyword = ref('')
const rows = ref([])

onMounted(load)

async function load() {
  loading.value = true
  try {
    const data = await adminRequest('/api/admin/members?q=' + encodeURIComponent(keyword.value.trim()))
    rows.value = data.members || []
  } catch (error) {
    ElMessage.error(error.message)
  } finally {
    loading.value = false
  }
}

async function act(path, body, ok) {
  await adminRequest(path, { method: 'POST', body: body || {} })
  ElMessage.success(ok)
  await load()
}

async function promote(row) {
  const { value } = await ElMessageBox.prompt('留空则使用默认 55%', '设为经销商', { inputPlaceholder: '分佣比例' })
  await act(`/api/admin/members/${row.id}/distributor`, { rate: Number(value || 0) }, '已设为经销商')
}

async function parentOf(row) {
  const { value } = await ElMessageBox.prompt('填写上级会员 ID，0 表示清空', '调整上级', { inputValue: String(row.parentId || 0) })
  await act(`/api/admin/members/${row.id}/parent`, { parentId: Number(value || 0) }, '已调整上级')
}

async function ban(row) {
  const { value } = await ElMessageBox.prompt('封禁后节点立即停用，可以解封', '封禁', { inputPlaceholder: '原因' })
  await act(`/api/admin/members/${row.id}/ban`, { reason: value || '平台封禁' }, '已封禁')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>会员管理</h2>
        <p>普通会员、代理和经销商都在这里。经销商模式和系统三级分佣不能叠加。</p>
      </div>
      <div class="filters">
        <el-input v-model="keyword" clearable placeholder="用户名 / 邮箱 / 手机" style="width: 220px" @keyup.enter="load" />
        <el-button type="primary" @click="load">查询</el-button>
      </div>
    </div>
    <el-table v-loading="loading" :data="rows" size="small">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="名称" min-width="120" />
      <el-table-column prop="phone" label="手机" width="120" />
      <el-table-column prop="email" label="邮箱" min-width="160" />
      <el-table-column label="邮箱状态" width="120">
        <template #default="{ row }">{{ label(EMAIL_STATUS, row.emailStatus) }}</template>
      </el-table-column>
      <el-table-column prop="userType" label="类型" width="90" />
      <el-table-column prop="distributorName" label="上级经销商" min-width="120" />
      <el-table-column prop="parentName" label="推荐人" min-width="120" />
      <el-table-column label="分佣" width="90">
        <template #default="{ row }">{{ row.commissionMode === 1 ? '经销商' : '系统三级' }}</template>
      </el-table-column>
      <el-table-column label="钱包" width="70">
        <template #default="{ row }">{{ row.walletEnabled ? '开通' : '关闭' }}</template>
      </el-table-column>
      <el-table-column label="注册时间" width="150">
        <template #default="{ row }">{{ formatTime(row.createdAt) }}</template>
      </el-table-column>
      <el-table-column label="状态" width="80">
        <template #default="{ row }">{{ row.status === 1 ? '封禁' : '正常' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="280" fixed="right">
        <template #default="{ row }">
          <el-button v-if="!row.isDistributor" link type="primary" @click="promote(row)">设为经销商</el-button>
          <el-button v-else link @click="act(`/api/admin/members/${row.id}/distributor/cancel`, {}, '已取消经销商')">取消经销商</el-button>
          <el-button v-if="!row.isAgent" link @click="act(`/api/admin/members/${row.id}/agent`, {}, '已授权代理')">授权代理</el-button>
          <el-button v-if="row.status !== 1" link type="danger" @click="ban(row)">封禁</el-button>
          <el-button v-else link type="success" @click="act(`/api/admin/members/${row.id}/unban`, {}, '已解封')">解封</el-button>
          <el-button link @click="parentOf(row)">调整上级</el-button>
          <el-button v-if="row.email" link @click="act(`/api/admin/members/${row.id}/email/unbind`, {}, '已解绑邮箱')">解绑邮箱</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

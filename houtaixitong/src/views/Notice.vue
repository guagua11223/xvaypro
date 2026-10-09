<script setup>
import { onMounted, ref } from 'vue'
import { request } from '@/api'
import { token } from '@/stores/session'
import { formatTime } from '@/utils/format'

const notices = ref([])
const services = ref([])
onMounted(async () => {
  notices.value = (await request('/api/distributor/announcements', { token: token() })).announcements || []
  services.value = (await request('/api/distributor/customer-service', { token: token() })).services || []
})
</script>

<template>
  <div class="page">
    <div class="page-head"><div><h2>公告与客服</h2><p>平台公告和客服渠道，经销商不能修改。</p></div></div>
    <el-table :data="notices">
      <el-table-column prop="title" label="标题" min-width="160" />
      <el-table-column prop="body" label="内容" min-width="240" />
      <el-table-column label="时间" width="160"><template #default="{ row }">{{ formatTime(row.createdAt) }}</template></el-table-column>
    </el-table>
    <h3>客服</h3>
    <el-table :data="services">
      <el-table-column prop="channel" label="渠道" width="120" />
      <el-table-column prop="account" label="账号" min-width="180" />
    </el-table>
  </div>
</template>

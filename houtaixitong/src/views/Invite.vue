<script setup>
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { request } from '@/api'
import { API_BASE } from '@/config'
import { token } from '@/stores/session'

const data = ref({ rules: { example: {} } })
const qr = ref('')
const ads = ref([])
onMounted(async () => {
  data.value = await request('/api/distributor/invite', { token: token() })
  try {
    ads.value = ((await request('/api/ads', { token: token() })).ads || []).filter((item) => item.slot === 'invite')
  } catch (_) {}
  const response = await fetch(`${API_BASE}/api/app/invite/qr.png`, {
    headers: { Authorization: `Bearer ${token()}` },
  })
  if (response.ok) qr.value = URL.createObjectURL(await response.blob())
})

async function copy(text) {
  await navigator.clipboard.writeText(text)
  ElMessage.success('已复制')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>邀请</h2>
        <p>{{ data.mode }}</p>
      </div>
    </div>
    <div class="stat-grid">
      <div class="stat-card">
        <span>推荐码</span>
        <strong class="invite-code">{{ data.inviteCode }}</strong>
        <el-button link type="primary" @click="copy(data.inviteCode)">复制推荐码</el-button>
      </div>
      <div class="stat-card">
        <span>推荐链接</span>
        <strong style="font-size: 14px; word-break: break-all">{{ data.inviteUrl }}</strong>
        <el-button link type="primary" @click="copy(data.inviteUrl)">复制链接</el-button>
      </div>
    </div>
    <img v-if="qr" :src="qr" alt="邀请二维码" width="180" height="180" />
    <a v-for="ad in ads" :key="ad.id" :href="ad.linkUrl || undefined" target="_blank" rel="noreferrer">
      <img v-if="ad.imageUrl" :src="ad.imageUrl" :alt="ad.title" style="max-width: 360px; margin-top: 12px" />
      <p v-else>{{ ad.title }}</p>
    </a>
    <p>
      系统三级示例：购买 100 元时，一级 {{ data.rules?.example?.level1 ?? '—' }}，二级 {{ data.rules?.example?.level2 ?? '—' }}，三级 {{ data.rules?.example?.level3 ?? '—' }}。
      有经销商归属时不走这套三级。
    </p>
  </div>
</template>

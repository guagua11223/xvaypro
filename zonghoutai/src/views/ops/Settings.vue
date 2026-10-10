<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { adminRequest } from '@/ops'

const tab = ref('commission')
const commission = reactive({
  poolRate: 50, level1Rate: 60, level2Rate: 30, level3Rate: 10,
  threeLevel: true, commissionCap: 0, rateCap: 100, distributorRate: 55, settleDay: 1, example: {},
})
const pay = reactive({ fourth_mch_id: '', fourth_gateway: '', fourth_key: '', fourth_notify_secret: '' })
const mail = reactive({ email_host: '', email_port: '465', email_user: '', email_password: '', email_from: '' })
const notices = ref([])
const ads = ref([])
const services = ref([])
const tickets = ref([])
const staff = ref([])
const logs = ref([])
const notice = reactive({ title: '', body: '', noticeType: 'notice', startsAt: 0, endsAt: 0, status: '1' })
const ad = reactive({ slot: 'home_banner', title: '', imageUrl: '', linkUrl: '', sortOrder: 0, status: 1 })
const service = reactive({ channel: 'wechat', account: '', qrUrl: '', sortOrder: 0, enabled: 1 })

onMounted(async () => {
  Object.assign(commission, await adminRequest('/api/admin/commission-settings'))
  Object.assign(pay, await adminRequest('/api/admin/payment/fourth'))
  Object.assign(mail, await adminRequest('/api/admin/system/email-config'))
  notices.value = (await adminRequest('/api/admin/notices')).announcements || []
  ads.value = (await adminRequest('/api/admin/ads')).ads || []
  services.value = (await adminRequest('/api/admin/customer-services')).services || []
  tickets.value = (await adminRequest('/api/admin/tickets')).tickets || []
  staff.value = (await adminRequest('/api/admin/staff')).staff || []
  logs.value = (await adminRequest('/api/admin/system/logs')).logs || []
})

async function backup() {
  const data = await adminRequest('/api/admin/system/backup', { method: 'POST', body: {} })
  ElMessage.success(`已备份 ${data.file}`)
}

async function saveCommission() {
  Object.assign(commission, await adminRequest('/api/admin/commission-settings', { method: 'POST', body: { ...commission } }))
  ElMessage.success('分佣设置已保存，两种模式不可叠加')
}

async function savePay() {
  Object.assign(pay, await adminRequest('/api/admin/payment/fourth', { method: 'POST', body: { ...pay } }))
  ElMessage.success('四方支付已保存')
}

async function saveMail() {
  Object.assign(mail, await adminRequest('/api/admin/system/email-config', { method: 'POST', body: { ...mail } }))
  ElMessage.success('邮件配置已保存')
}

async function addNotice() {
  await adminRequest('/api/admin/notices', { method: 'POST', body: notice })
  notices.value = (await adminRequest('/api/admin/notices')).announcements || []
  ElMessage.success('公告已发布')
}

async function addAd() {
  await adminRequest('/api/admin/ads', { method: 'POST', body: ad })
  ads.value = (await adminRequest('/api/admin/ads')).ads || []
  ElMessage.success('广告已保存')
}

async function addService() {
  await adminRequest('/api/admin/customer-services', { method: 'POST', body: service })
  services.value = (await adminRequest('/api/admin/customer-services')).services || []
  ElMessage.success('客服已保存')
}

async function reply(row) {
  await adminRequest(`/api/admin/tickets/${row.id}/reply`, { method: 'POST', body: { reply: row.reply, close: false } })
  ElMessage.success('已回复')
}

async function setRole(row) {
  await adminRequest(`/api/admin/staff/${row.id}/role`, { method: 'POST', body: { role: row.role } })
  ElMessage.success('角色已更新')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>规则与系统</h2>
        <p>系统三级按分佣池分配。经销商自定义只发给直接推荐人。示例按 100 元、手续费 0 计算。</p>
      </div>
      <el-button @click="backup">备份数据库</el-button>
    </div>
    <el-tabs v-model="tab">
      <el-tab-pane label="分佣" name="commission">
        <div class="filters">
          <span>分佣池 %</span><el-input-number v-model="commission.poolRate" :min="0" :max="100" />
          <span>一级</span><el-input-number v-model="commission.level1Rate" :min="0" :max="100" />
          <span>二级</span><el-input-number v-model="commission.level2Rate" :min="0" :max="100" />
          <span>三级</span><el-input-number v-model="commission.level3Rate" :min="0" :max="100" />
        </div>
        <div class="filters">
          <span>封顶</span><el-input-number v-model="commission.commissionCap" :min="0" />
          <span>比例上限</span><el-input-number v-model="commission.rateCap" :min="0" :max="100" />
          <span>经销商默认 %</span><el-input-number v-model="commission.distributorRate" :min="0" :max="100" />
          <el-switch v-model="commission.threeLevel" active-text="开启三级" />
          <el-button type="primary" @click="saveCommission">保存</el-button>
        </div>
        <p>示例：一级 {{ commission.example?.level1 ?? '—' }}，二级 {{ commission.example?.level2 ?? '—' }}，三级 {{ commission.example?.level3 ?? '—' }}</p>
      </el-tab-pane>
      <el-tab-pane label="四方支付" name="pay">
        <el-form label-width="140px" style="max-width: 560px">
          <el-form-item label="商户号"><el-input v-model="pay.fourth_mch_id" /></el-form-item>
          <el-form-item label="网关"><el-input v-model="pay.fourth_gateway" /></el-form-item>
          <el-form-item label="密钥"><el-input v-model="pay.fourth_key" placeholder="已配置时显示为 ******" /></el-form-item>
          <el-form-item label="回调密钥"><el-input v-model="pay.fourth_notify_secret" placeholder="已配置时显示为 ******" /></el-form-item>
          <el-button type="primary" @click="savePay">保存</el-button>
        </el-form>
      </el-tab-pane>
      <el-tab-pane label="邮件" name="mail">
        <el-form label-width="140px" style="max-width: 560px">
          <el-form-item label="主机"><el-input v-model="mail.email_host" /></el-form-item>
          <el-form-item label="端口"><el-input v-model="mail.email_port" /></el-form-item>
          <el-form-item label="账号"><el-input v-model="mail.email_user" /></el-form-item>
          <el-form-item label="密码"><el-input v-model="mail.email_password" placeholder="已配置时显示为 ******" /></el-form-item>
          <el-form-item label="发件人"><el-input v-model="mail.email_from" /></el-form-item>
          <el-button type="primary" @click="saveMail">保存</el-button>
        </el-form>
      </el-tab-pane>
      <el-tab-pane label="公告广告" name="content">
        <div class="filters">
          <el-input v-model="notice.title" placeholder="公告标题" style="width: 180px" />
          <el-input v-model="notice.body" placeholder="内容" style="width: 260px" />
          <el-button @click="addNotice">发布公告</el-button>
        </div>
        <div class="filters">
          <el-select v-model="ad.slot" style="width: 140px">
            <el-option label="首页 Banner" value="home_banner" />
            <el-option label="弹窗" value="popup" />
            <el-option label="邀请页" value="invite" />
          </el-select>
          <el-input v-model="ad.title" placeholder="广告标题" style="width: 180px" />
          <el-input v-model="ad.imageUrl" placeholder="图片地址" style="width: 220px" />
          <el-button @click="addAd">发布广告</el-button>
        </div>
        <p>公告 {{ notices.length }} 条，广告 {{ ads.length }} 条。</p>
      </el-tab-pane>
      <el-tab-pane label="客服工单" name="support">
        <div class="filters">
          <el-select v-model="service.channel" style="width: 140px">
            <el-option label="微信" value="wechat" />
            <el-option label="QQ" value="qq" />
            <el-option label="Telegram" value="telegram" />
            <el-option label="在线客服" value="online" />
          </el-select>
          <el-input v-model="service.account" placeholder="账号" style="width: 180px" />
          <el-input v-model="service.qrUrl" placeholder="二维码地址" style="width: 220px" />
          <el-button @click="addService">保存客服</el-button>
        </div>
        <el-table :data="tickets" size="small">
          <el-table-column prop="username" label="用户" width="120" />
          <el-table-column prop="title" label="标题" min-width="140" />
          <el-table-column prop="body" label="内容" min-width="180" />
          <el-table-column label="回复" min-width="180">
            <template #default="{ row }"><el-input v-model="row.reply" /></template>
          </el-table-column>
          <el-table-column width="80">
            <template #default="{ row }"><el-button link type="primary" @click="reply(row)">回复</el-button></template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="权限日志" name="staff">
        <el-table :data="staff" size="small">
          <el-table-column prop="username" label="管理员" width="140" />
          <el-table-column label="角色" width="180">
            <template #default="{ row }">
              <el-select v-model="row.role" style="width: 140px">
                <el-option label="超级管理员" value="super" />
                <el-option label="运营" value="operator" />
                <el-option label="财务" value="finance" />
                <el-option label="客服" value="support" />
              </el-select>
            </template>
          </el-table-column>
          <el-table-column width="80">
            <template #default="{ row }"><el-button link @click="setRole(row)">保存</el-button></template>
          </el-table-column>
        </el-table>
        <el-table :data="logs" size="small">
          <el-table-column prop="actorType" label="来源" width="100" />
          <el-table-column prop="action" label="动作" width="160" />
          <el-table-column prop="detail" label="详情" min-width="180" />
          <el-table-column prop="ip" label="IP" width="140" />
        </el-table>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

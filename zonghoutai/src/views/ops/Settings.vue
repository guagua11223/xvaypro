<script setup>
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { ROLE_LABEL, adminRequest, adminRole } from '@/ops'

const role = adminRole()
const full = role === 'super' || role === 'operator'
const tab = ref(full ? 'commission' : 'content')
const commission = reactive({
  poolRate: 50, level1Rate: 60, level2Rate: 30, level3Rate: 10,
  threeLevel: true, commissionCap: 0, rateCap: 100, distributorRate: 55, settleDay: 1, example: {},
})
const pay = reactive({ fourth_mch_id: '', fourth_gateway: '', fourth_key: '', fourth_notify_secret: '' })
const epay = reactive({
  epay_account: '',
  epay_api_key: '',
  epay_api_base: 'https://api.epay.com/capi/openapi',
  epay_merchant_name: '飞连',
  epay_currency: 'CNY',
  epay_payment_currency: '',
  epay_payment_country: '',
  epay_language: 'CN',
  notifyUrl: '',
})
const mail = reactive({ email_host: '', email_port: '465', email_user: '', email_password: '', email_from: '' })
const notices = ref([])
const ads = ref([])
const services = ref([])
const tickets = ref([])
const staff = ref([])
const logs = ref([])
const notice = reactive({ id: 0, title: '', body: '', noticeType: 'notice', startsAt: '', endsAt: '', status: '1' })
const ad = reactive({ id: 0, slot: 'home_banner', title: '', imageUrl: '', linkUrl: '', sortOrder: 0, startsAt: '', endsAt: '', status: 1 })
const service = reactive({ channel: 'wechat', account: '', qrUrl: '', sortOrder: 0, enabled: 1 })
const staffForm = reactive({ username: '', password: '', role: 'support' })

onMounted(async () => {
  if (full) {
    Object.assign(commission, await adminRequest('/api/admin/commission-settings'))
    Object.assign(pay, await adminRequest('/api/admin/payment/fourth'))
    Object.assign(epay, await adminRequest('/api/admin/payment/epay'))
    Object.assign(mail, await adminRequest('/api/admin/system/email-config'))
    staff.value = (await adminRequest('/api/admin/staff')).staff || []
    logs.value = (await adminRequest('/api/admin/system/logs')).logs || []
  }
  notices.value = (await adminRequest('/api/admin/notices')).announcements || []
  ads.value = (await adminRequest('/api/admin/ads')).ads || []
  services.value = (await adminRequest('/api/admin/customer-services')).services || []
  tickets.value = (await adminRequest('/api/admin/tickets')).tickets || []
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

async function saveEpay() {
  Object.assign(epay, await adminRequest('/api/admin/payment/epay', { method: 'POST', body: { ...epay } }))
  ElMessage.success('EPAY 支付已保存')
}

async function saveMail() {
  Object.assign(mail, await adminRequest('/api/admin/system/email-config', { method: 'POST', body: { ...mail } }))
  ElMessage.success('邮件配置已保存')
}

function asMs(value) {
  if (value === '' || value == null) return 0
  const n = Number(value)
  return Number.isFinite(n) ? n : 0
}

function stamp(value) {
  const n = Number(value || 0)
  if (!n) return ''
  return new Date(n).toLocaleString()
}

async function addNotice() {
  await adminRequest('/api/admin/notices', {
    method: 'POST',
    body: { ...notice, startsAt: asMs(notice.startsAt), endsAt: asMs(notice.endsAt) },
  })
  notices.value = (await adminRequest('/api/admin/notices')).announcements || []
  notice.id = 0
  ElMessage.success('公告已保存')
}

function editNotice(row) {
  Object.assign(notice, {
    id: row.id, title: row.title, body: row.body, noticeType: row.noticeType || 'notice',
    startsAt: row.startsAt ? String(row.startsAt) : '',
    endsAt: row.endsAt ? String(row.endsAt) : '',
    status: String(row.enabled ?? 1),
  })
}

async function addAd() {
  await adminRequest('/api/admin/ads', {
    method: 'POST',
    body: { ...ad, startsAt: asMs(ad.startsAt), endsAt: asMs(ad.endsAt), status: Number(ad.status) },
  })
  ads.value = (await adminRequest('/api/admin/ads')).ads || []
  ad.id = 0
  ElMessage.success('广告已保存')
}

function editAd(row) {
  Object.assign(ad, {
    id: row.id, slot: row.slot, title: row.title, imageUrl: row.imageUrl, linkUrl: row.linkUrl,
    sortOrder: row.sortOrder || 0,
    startsAt: row.startsAt ? String(row.startsAt) : '',
    endsAt: row.endsAt ? String(row.endsAt) : '',
    status: row.status ?? 1,
  })
}

async function removeAd(row) {
  await adminRequest(`/api/admin/ads/${row.id}`, { method: 'DELETE' })
  ads.value = (await adminRequest('/api/admin/ads')).ads || []
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

async function createStaff() {
  await adminRequest('/api/admin/staff', { method: 'POST', body: { ...staffForm } })
  staff.value = (await adminRequest('/api/admin/staff')).staff || []
  staffForm.username = ''
  staffForm.password = ''
  ElMessage.success('账号已创建，可用该账号登录')
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
      <el-tab-pane v-if="full" label="分佣" name="commission">
        <div class="filters">
          <span>分佣池 %</span><el-input-number v-model="commission.poolRate" :min="0" :max="100" />
          <span>一级 60%</span>
          <span>二级 30%</span>
          <span>三级 10%</span>
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
      <el-tab-pane v-if="full" label="EPAY支付" name="epay">
        <el-form label-width="140px" style="max-width: 640px">
          <p style="margin: 0 0 12px; color: #64748b">
            对接
            <a href="https://www.epay.com/zh-CN" target="_blank" rel="noreferrer">epay.com</a>
            收银台代收。请在 EPAY 后台开通 API、配置 IP 白名单，并把下方回调地址填入商户通知。
          </p>
          <el-form-item label="EPAY账号"><el-input v-model="epay.epay_account" placeholder="登录邮箱账号" /></el-form-item>
          <el-form-item label="收款API Key"><el-input v-model="epay.epay_api_key" placeholder="已配置时显示为 ******" show-password /></el-form-item>
          <el-form-item label="API地址"><el-input v-model="epay.epay_api_base" placeholder="https://api.epay.com/capi/openapi" /></el-form-item>
          <el-form-item label="商户名称"><el-input v-model="epay.epay_merchant_name" /></el-form-item>
          <el-form-item label="订单币种"><el-input v-model="epay.epay_currency" placeholder="CNY" /></el-form-item>
          <el-form-item label="付款币种"><el-input v-model="epay.epay_payment_currency" placeholder="可选，如 USD" /></el-form-item>
          <el-form-item label="付款国家"><el-input v-model="epay.epay_payment_country" placeholder="可选，如 CN" /></el-form-item>
          <el-form-item label="语言"><el-input v-model="epay.epay_language" placeholder="CN" /></el-form-item>
          <el-form-item label="回调地址">
            <el-input :model-value="epay.notifyUrl" readonly />
          </el-form-item>
          <el-button type="primary" @click="saveEpay">保存</el-button>
        </el-form>
      </el-tab-pane>
      <el-tab-pane v-if="full" label="四方支付" name="pay">
        <el-form label-width="140px" style="max-width: 560px">
          <el-form-item label="商户号"><el-input v-model="pay.fourth_mch_id" /></el-form-item>
          <el-form-item label="网关"><el-input v-model="pay.fourth_gateway" /></el-form-item>
          <el-form-item label="密钥"><el-input v-model="pay.fourth_key" placeholder="已配置时显示为 ******" /></el-form-item>
          <el-form-item label="回调密钥"><el-input v-model="pay.fourth_notify_secret" placeholder="已配置时显示为 ******" /></el-form-item>
          <el-button type="primary" @click="savePay">保存</el-button>
        </el-form>
      </el-tab-pane>
      <el-tab-pane v-if="full" label="邮件" name="mail">
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
        <h3>公告</h3>
        <div class="filters">
          <el-input v-model="notice.title" placeholder="标题" style="width: 160px" />
          <el-input v-model="notice.body" placeholder="内容" style="width: 220px" />
          <el-select v-model="notice.noticeType" style="width: 120px">
            <el-option label="公告" value="notice" />
            <el-option label="活动" value="activity" />
            <el-option label="维护" value="maintenance" />
          </el-select>
          <el-date-picker v-model="notice.startsAt" type="datetime" value-format="x" placeholder="开始时间" />
          <el-date-picker v-model="notice.endsAt" type="datetime" value-format="x" placeholder="结束时间" />
          <el-select v-model="notice.status" style="width: 100px">
            <el-option label="上架" value="1" />
            <el-option label="下架" value="0" />
          </el-select>
          <el-button type="primary" @click="addNotice">保存公告</el-button>
        </div>
        <el-table :data="notices" size="small" @row-click="editNotice">
          <el-table-column prop="title" label="标题" min-width="140" />
          <el-table-column label="类型" width="90">
            <template #default="{ row }">{{ { notice: '公告', activity: '活动', maintenance: '维护' }[row.noticeType] || row.noticeType }}</template>
          </el-table-column>
          <el-table-column label="开始" width="160"><template #default="{ row }">{{ stamp(row.startsAt) }}</template></el-table-column>
          <el-table-column label="结束" width="160"><template #default="{ row }">{{ stamp(row.endsAt) }}</template></el-table-column>
          <el-table-column label="状态" width="80"><template #default="{ row }">{{ row.enabled ? '上架' : '下架' }}</template></el-table-column>
        </el-table>
        <h3>广告</h3>
        <div class="filters">
          <el-select v-model="ad.slot" style="width: 140px">
            <el-option label="首页 Banner" value="home_banner" />
            <el-option label="弹窗" value="popup" />
            <el-option label="邀请页" value="invite" />
          </el-select>
          <el-input v-model="ad.title" placeholder="标题" style="width: 140px" />
          <el-input v-model="ad.imageUrl" placeholder="图片地址" style="width: 180px" />
          <el-input v-model="ad.linkUrl" placeholder="链接" style="width: 160px" />
          <el-input-number v-model="ad.sortOrder" :min="0" />
          <el-date-picker v-model="ad.startsAt" type="datetime" value-format="x" placeholder="开始时间" />
          <el-date-picker v-model="ad.endsAt" type="datetime" value-format="x" placeholder="结束时间" />
          <el-select v-model="ad.status" style="width: 100px">
            <el-option label="上架" :value="1" />
            <el-option label="下架" :value="0" />
          </el-select>
          <el-button type="primary" @click="addAd">保存广告</el-button>
        </div>
        <el-table :data="ads" size="small" @row-click="editAd">
          <el-table-column prop="slot" label="位置" width="120" />
          <el-table-column prop="title" label="标题" min-width="120" />
          <el-table-column prop="sortOrder" label="排序" width="70" />
          <el-table-column label="状态" width="80"><template #default="{ row }">{{ row.status ? '上架' : '下架' }}</template></el-table-column>
          <el-table-column width="80">
            <template #default="{ row }"><el-button link type="danger" @click.stop="removeAd(row)">删除</el-button></template>
          </el-table-column>
        </el-table>
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
        <el-table :data="services" size="small">
          <el-table-column prop="channel" label="渠道" width="120" />
          <el-table-column prop="account" label="账号" min-width="160" />
          <el-table-column prop="qrUrl" label="二维码" min-width="180" />
          <el-table-column label="状态" width="80"><template #default="{ row }">{{ row.enabled ? '启用' : '停用' }}</template></el-table-column>
        </el-table>
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
      <el-tab-pane v-if="full" label="权限日志" name="staff">
        <div class="filters">
          <el-input v-model="staffForm.username" placeholder="新账号" style="width: 140px" />
          <el-input v-model="staffForm.password" placeholder="密码至少 6 位" show-password style="width: 160px" />
          <el-select v-model="staffForm.role" style="width: 140px">
            <el-option v-for="(name, key) in ROLE_LABEL" :key="key" :label="name" :value="key" :disabled="key === 'super' && role !== 'super'" />
          </el-select>
          <el-button type="primary" @click="createStaff">创建账号</el-button>
        </div>
        <el-table :data="staff" size="small">
          <el-table-column prop="username" label="管理员" width="140" />
          <el-table-column label="角色" width="180">
            <template #default="{ row }">
              <el-select v-model="row.role" style="width: 140px" :disabled="row.role === 'super' && role !== 'super'">
                <el-option v-for="(name, key) in ROLE_LABEL" :key="key" :label="name" :value="key" :disabled="key === 'super' && role !== 'super'" />
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

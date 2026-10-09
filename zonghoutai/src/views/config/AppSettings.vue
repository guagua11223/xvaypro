<script setup>
import { onMounted, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import { API_BASE } from '@/config'
import { db, refreshBackend, saveAppSettings, saveBackendSettings } from '@/stores/db'

const form = reactive({ ...db.appSettings })

const locales = [
  { value: 'zh', label: '简体中文' },
  { value: 'zh-TW', label: '繁体中文' },
  { value: 'en', label: 'English' },
  { value: 'ja', label: '日本語' },
  { value: 'ko', label: '한국어' },
]

async function save() {
  if (!form.appName.trim()) {
    ElMessage.warning('请填写应用名称')
    return
  }
  if (!form.serverAddress.trim()) {
    ElMessage.warning('请填写服务器地址')
    return
  }
  try {
    await saveBackendSettings({
      profileName: form.appName.trim(),
      supportUrl: form.supportUrl.trim(),
    })
  } catch (error) {
    ElMessage.error(error.message || '后端保存失败')
    return
  }
  saveAppSettings({
    ...form,
    appName: form.appName.trim(),
    version: form.version.trim(),
    serverAddress: form.serverAddress.trim(),
    pingUrl: form.pingUrl.trim(),
    announcement: form.announcement.trim(),
    supportUrl: form.supportUrl.trim(),
    aboutText: form.aboutText.trim(),
    socksPort: Number(form.socksPort) || 15491,
    httpPort: Number(form.httpPort) || 15492,
    pingMaxConcurrency: Number(form.pingMaxConcurrency) || 1,
    tun: form.defaultMode === 'fullMask',
  })
  ElMessage.success('App 配置已保存到后端')
}

onMounted(async () => {
  try {
    await refreshBackend()
    Object.assign(form, db.appSettings)
  } catch (error) {
    ElMessage.error(error.message || '加载配置失败')
  }
})
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>App 配置</h2>
        <p>接口地址 {{ API_BASE }}/api/ 。应用名称和支持链接会保存到后端，订阅配置按这里下发。</p>
      </div>
      <el-button type="primary" @click="save">保存配置</el-button>
    </div>
    <el-card shadow="never">
      <el-tabs>
        <el-tab-pane label="通用">
          <el-form :model="form" label-width="140px" style="max-width: 640px">
            <el-form-item label="应用名称">
              <el-input v-model="form.appName" />
            </el-form-item>
            <el-form-item label="版本">
              <el-input v-model="form.version" />
            </el-form-item>
            <el-form-item label="跟随系统语言">
              <el-switch v-model="form.localeFollowSystem" />
            </el-form-item>
            <el-form-item label="默认语言">
              <el-select v-model="form.locale" :disabled="form.localeFollowSystem" style="width: 220px">
                <el-option v-for="item in locales" :key="item.value" :label="item.label" :value="item.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="自动更新">
              <el-switch v-model="form.autoUpdate" />
            </el-form-item>
            <el-form-item label="开机自动连接">
              <el-switch v-model="form.connectAtStartup" />
            </el-form-item>
            <el-form-item label="启动后自动连接">
              <el-switch v-model="form.connectAtLaunch" />
            </el-form-item>
            <el-form-item label="跟随系统外观">
              <el-switch v-model="form.brightnessFollowSystem" />
            </el-form-item>
            <el-form-item label="深色模式">
              <el-switch v-model="form.brightnessDark" :disabled="form.brightnessFollowSystem" />
            </el-form-item>
          </el-form>
        </el-tab-pane>
        <el-tab-pane label="连接">
          <el-form :model="form" label-width="140px" style="max-width: 640px">
            <el-form-item label="服务器地址">
              <el-input v-model="form.serverAddress" />
            </el-form-item>
            <el-form-item label="SOCKS 端口">
              <el-input-number v-model="form.socksPort" :min="1" :max="65535" />
            </el-form-item>
            <el-form-item label="HTTP 端口">
              <el-input-number v-model="form.httpPort" :min="1" :max="65535" />
            </el-form-item>
            <el-form-item label="默认连接模式">
              <el-radio-group v-model="form.defaultMode">
                <el-radio value="fullSpeed">全速</el-radio>
                <el-radio value="fullMask">全掩</el-radio>
              </el-radio-group>
              <div style="color: #6b7280; font-size: 12px">全掩对应 App 选线页的 Tun 模式，全速关闭 Tun。</div>
            </el-form-item>
            <el-form-item label="测速地址">
              <el-input v-model="form.pingUrl" />
            </el-form-item>
            <el-form-item label="测速并发">
              <el-input-number v-model="form.pingMaxConcurrency" :min="1" :max="64" />
            </el-form-item>
          </el-form>
        </el-tab-pane>
        <el-tab-pane label="代理与 TUN">
          <el-form :model="form" label-width="140px" style="max-width: 640px">
            <el-form-item label="系统代理">
              <el-switch v-model="form.systemProxy" />
              <div style="color: #6b7280; font-size: 12px">对应客户端系统代理开关，由操作系统提供，并非所有应用都会遵守。</div>
            </el-form-item>
            <el-form-item label="Tun2socks">
              <el-switch :model-value="form.defaultMode === 'fullMask'" disabled />
              <div style="color: #6b7280; font-size: 12px">与默认连接模式联动：选择全掩即开启虚拟网卡。</div>
            </el-form-item>
          </el-form>
        </el-tab-pane>
        <el-tab-pane label="公告与关于">
          <el-form :model="form" label-width="140px" style="max-width: 720px">
            <el-form-item label="公告">
              <el-input v-model="form.announcement" type="textarea" :rows="3" />
            </el-form-item>
            <el-form-item label="客服链接">
              <el-input v-model="form.supportUrl" />
            </el-form-item>
            <el-form-item label="关于">
              <el-input v-model="form.aboutText" type="textarea" :rows="4" />
            </el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
    </el-card>
  </div>
</template>

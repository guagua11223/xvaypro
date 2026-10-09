<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { request } from '@/api'
import { API_BASE } from '@/config'
import { refreshBackend, session } from '@/stores/db'

const router = useRouter()
const formRef = ref()
const loading = ref(false)
const form = reactive({
  username: '',
  password: '',
})

const rules = {
  password: [{ required: true, message: '请输入管理令牌', trigger: 'blur' }],
}

async function submit() {
  await formRef.value.validate()
  loading.value = true
  const token = form.password.trim()
  try {
    await request('/api/admin/overview', { token })
    session.user = {
      id: 1,
      username: form.username.trim() || 'admin',
      nickname: '管理员',
      role: 'super',
      token,
    }
    await refreshBackend()
    ElMessage.success('已连接后端')
    router.push('/dashboard')
  } catch (error) {
    ElMessage.error(error.message || '无法连接后端')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="auth-page">
    <section class="auth-brand">
      <div>
        <div class="brand-mark">X</div>
        <h1>XVAY 总后台</h1>
        <p>面向 AnyPortal 客户端的运营中台。在这里配置线路、内核和 App 默认参数，并查看用户、代理商与分佣。</p>
        <div class="brand-points">
          <div>数据配置：线路节点、分组、内核、资源、套餐、App 下发</div>
          <div>用户查看：套餐、流量、设备与所属代理</div>
          <div>代理体系：代理商档案与按等级分佣结算</div>
        </div>
      </div>
      <div>AnyPortal · v0.6.31</div>
    </section>
    <section class="auth-panel">
      <div class="auth-card">
        <h2>登录</h2>
        <p class="hint">管理接口：{{ API_BASE }}/api/</p>
        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent="submit">
          <el-form-item label="显示名称">
            <el-input v-model="form.username" placeholder="可选，仅显示在后台" />
          </el-form-item>
          <el-form-item label="管理令牌" prop="password">
            <el-input v-model="form.password" type="password" show-password placeholder="服务器 ADMIN_TOKEN" />
          </el-form-item>
          <el-button native-type="submit" type="primary" style="width: 100%" :loading="loading">登录</el-button>
        </el-form>
        <p class="hint" style="margin-top: 16px">
          还没有账号？
          <router-link to="/register">注册运营账号</router-link>
        </p>
        <div class="demo-box">登录后，用户、线路和 App 配置从 {{ API_BASE }}/api/ 读取。</div>
      </div>
    </section>
  </div>
</template>

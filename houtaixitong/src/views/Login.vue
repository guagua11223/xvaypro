<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { API_BASE } from '@/config'
import { login } from '@/stores/session'

const router = useRouter()
const formRef = ref()
const loading = ref(false)
const form = reactive({
  username: '',
  password: '',
})

const rules = {
  username: [{ required: true, message: '请输入账号', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
}

async function submit() {
  await formRef.value.validate()
  loading.value = true
  try {
    await login(form.username, form.password)
    ElMessage.success('登录成功')
    router.push('/dashboard')
  } catch (error) {
    ElMessage.error(error.message || '登录失败')
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
        <h1>飞连 代理商后台</h1>
        <p>查看自己发展的代理，以及这些代理再发展的下一级。分佣和对应订单只显示当前账号。</p>
        <div class="brand-points">
          <div>我的代理：直属代理，以及他们名下的代理</div>
          <div>分佣订单：订单金额、比例、佣金和结算状态</div>
          <div>邀请码：注册时填写上级邀请码，加入对方团队</div>
        </div>
      </div>
      <div>飞连 · 代理商</div>
    </section>
    <section class="auth-panel">
      <div class="auth-card">
        <h2>登录</h2>
        <p class="hint">接口：{{ API_BASE }}/api/agent/</p>
        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent="submit">
          <el-form-item label="账号" prop="username">
            <el-input v-model="form.username" placeholder="用户名" />
          </el-form-item>
          <el-form-item label="密码" prop="password">
            <el-input v-model="form.password" type="password" show-password placeholder="至少 6 位" />
          </el-form-item>
          <el-button native-type="submit" type="primary" style="width: 100%" :loading="loading">登录</el-button>
        </el-form>
        <p class="hint" style="margin-top: 16px">
          还没有代理账号？
          <router-link to="/register">注册</router-link>
        </p>
      </div>
    </section>
  </div>
</template>

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
        <h1>飞连 经销商后台</h1>
        <p>管理旗下会员、授权代理、查看订单和佣金。代理不能登录这里，也不能再发展代理。</p>
        <div class="brand-points">
          <div>旗下会员：设置返佣，授权代理</div>
          <div>订单佣金：只看自己旗下的订单和佣金</div>
          <div>邀请码：会员注册时填写，加入你的团队</div>
        </div>
      </div>
      <div>飞连 · 经销商</div>
    </section>
    <section class="auth-panel">
      <div class="auth-card">
        <h2>登录</h2>
        <p class="hint">接口：{{ API_BASE }}/api/distributor/</p>
        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent="submit">
          <el-form-item label="账号" prop="username">
            <el-input v-model="form.username" placeholder="用户名" />
          </el-form-item>
          <el-form-item label="密码" prop="password">
            <el-input v-model="form.password" type="password" show-password placeholder="至少 8 位" />
          </el-form-item>
          <el-button native-type="submit" type="primary" style="width: 100%" :loading="loading">登录</el-button>
        </el-form>
        <p class="hint" style="margin-top: 16px">
          经销商账号由总后台开通，不在这里注册。
        </p>
      </div>
    </section>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { register } from '@/stores/db'

const router = useRouter()
const formRef = ref()
const loading = ref(false)
const form = reactive({
  username: '',
  nickname: '',
  phone: '',
  password: '',
  confirm: '',
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度为 3-20 位', trigger: 'blur' },
  ],
  nickname: [{ required: true, message: '请输入昵称', trigger: 'blur' }],
  phone: [{ pattern: /^$|^1\d{10}$/, message: '请输入 11 位手机号', trigger: 'blur' }],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少 6 位', trigger: 'blur' },
  ],
  confirm: [
    { required: true, message: '请再次输入密码', trigger: 'blur' },
    {
      validator: (_rule, value, callback) => {
        if (value !== form.password) callback(new Error('两次密码不一致'))
        else callback()
      },
      trigger: 'blur',
    },
  ],
}

async function submit() {
  await formRef.value.validate()
  loading.value = true
  const result = register(form)
  loading.value = false
  if (!result.ok) {
    ElMessage.error(result.message)
    return
  }
  ElMessage.success('注册成功，已自动登录')
  router.push('/dashboard')
}
</script>

<template>
  <div class="auth-page">
    <section class="auth-brand">
      <div>
        <div class="brand-mark">X</div>
        <h1>注册运营账号</h1>
        <p>新账号默认为运营角色，可配置 App 数据并查看用户与代理分佣。超级管理员账号随演示数据提供。</p>
      </div>
      <div>AnyPortal · 总后台</div>
    </section>
    <section class="auth-panel">
      <div class="auth-card">
        <h2>注册</h2>
        <p class="hint">创建后即可进入总后台。</p>
        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent="submit">
          <el-form-item label="用户名" prop="username">
            <el-input v-model="form.username" placeholder="3-20 位，用于登录" />
          </el-form-item>
          <el-form-item label="昵称" prop="nickname">
            <el-input v-model="form.nickname" placeholder="在后台中显示的名称" />
          </el-form-item>
          <el-form-item label="手机号" prop="phone">
            <el-input v-model="form.phone" maxlength="11" placeholder="选填" />
          </el-form-item>
          <el-form-item label="密码" prop="password">
            <el-input v-model="form.password" type="password" show-password placeholder="至少 6 位" />
          </el-form-item>
          <el-form-item label="确认密码" prop="confirm">
            <el-input v-model="form.confirm" type="password" show-password placeholder="再次输入密码" />
          </el-form-item>
          <el-button native-type="submit" type="primary" style="width: 100%" :loading="loading">注册并进入</el-button>
        </el-form>
        <p class="hint" style="margin-top: 16px">
          已有账号？
          <router-link to="/login">返回登录</router-link>
        </p>
      </div>
    </section>
  </div>
</template>

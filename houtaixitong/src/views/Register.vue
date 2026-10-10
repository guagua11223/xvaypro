<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { register } from '@/stores/session'

const router = useRouter()
const formRef = ref()
const loading = ref(false)
const form = reactive({
  username: '',
  password: '',
  confirm: '',
  name: '',
  phone: '',
  inviteCode: '',
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度为 3-20 位', trigger: 'blur' },
  ],
  name: [{ required: true, message: '请填写代理名称', trigger: 'blur' }],
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
  phone: [
    {
      validator: (_rule, value, callback) => {
        if (!value || /^1\d{10}$/.test(value)) callback()
        else callback(new Error('请输入 11 位手机号'))
      },
      trigger: 'blur',
    },
  ],
}

async function submit() {
  await formRef.value.validate()
  loading.value = true
  try {
    await register({
      username: form.username.trim(),
      password: form.password,
      name: form.name.trim(),
      phone: form.phone.trim(),
      inviteCode: form.inviteCode.trim(),
    })
    ElMessage.success('注册成功')
    router.push('/dashboard')
  } catch (error) {
    ElMessage.error(error.message || '注册失败')
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
        <h1>加入代理团队</h1>
        <p>填写上级邀请码后，账号会挂到对方名下。不填邀请码则作为独立代理注册。</p>
      </div>
      <div>讯连宝 · 代理商</div>
    </section>
    <section class="auth-panel">
      <div class="auth-card">
        <h2>注册</h2>
        <p class="hint">新账号默认为铜牌代理，注册后即可登录。</p>
        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent="submit">
          <el-form-item label="用户名" prop="username">
            <el-input v-model="form.username" maxlength="20" placeholder="3-20 位" />
          </el-form-item>
          <el-form-item label="代理名称" prop="name">
            <el-input v-model="form.name" maxlength="20" placeholder="对外显示的名称" />
          </el-form-item>
          <el-form-item label="手机号" prop="phone">
            <el-input v-model="form.phone" maxlength="11" placeholder="选填" />
          </el-form-item>
          <el-form-item label="上级邀请码" prop="inviteCode">
            <el-input v-model="form.inviteCode" placeholder="选填，加入对方团队" />
          </el-form-item>
          <el-form-item label="密码" prop="password">
            <el-input v-model="form.password" type="password" show-password />
          </el-form-item>
          <el-form-item label="确认密码" prop="confirm">
            <el-input v-model="form.confirm" type="password" show-password />
          </el-form-item>
          <el-button native-type="submit" type="primary" style="width: 100%" :loading="loading">注册并登录</el-button>
        </el-form>
        <p class="hint" style="margin-top: 16px">
          已有账号？
          <router-link to="/login">返回登录</router-link>
        </p>
      </div>
    </section>
  </div>
</template>

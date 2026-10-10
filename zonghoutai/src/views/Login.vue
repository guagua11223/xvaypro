<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { API_BASE } from '@/config'
import { login } from '@/stores/db'

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
        <h1>讯连宝 总后台</h1>
        <p>查看真实会员、订单、佣金和钱包。财务与客服只能进入自己负责的页面。</p>
        <div class="brand-points">
          <div>数据配置：线路节点、分组、内核、资源、套餐、App 下发</div>
          <div>用户查看：套餐、流量、设备与所属代理</div>
          <div>代理体系：代理商档案与按等级分佣结算</div>
        </div>
      </div>
      <div>讯连宝 · 总后台</div>
    </section>
    <section class="auth-panel">
      <div class="auth-card">
        <h2>登录</h2>
        <p class="hint">管理接口：{{ API_BASE }}/api/</p>
        <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @submit.prevent="submit">
          <el-form-item label="账号" prop="username">
            <el-input v-model="form.username" placeholder="admin" />
          </el-form-item>
          <el-form-item label="密码" prop="password">
            <el-input v-model="form.password" type="password" show-password placeholder="admin123" />
          </el-form-item>
          <el-button native-type="submit" type="primary" style="width: 100%" :loading="loading">登录</el-button>
        </el-form>
        <div class="demo-box">使用已分配的后台账号。财务、客服账号由超级管理员创建。数据来自 {{ API_BASE }}/api/。</div>
      </div>
    </section>
  </div>
</template>

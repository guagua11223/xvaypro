<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { logout, refreshBackend, resetDb, session } from '@/stores/db'

const route = useRoute()
const router = useRouter()
const collapsed = ref(false)

const title = computed(() => route.meta.title || '总后台')
const roleLabel = computed(() => (session.user?.role === 'super' ? '超级管理员' : '运营'))

function toggleCollapse() {
  collapsed.value = !collapsed.value
}

onMounted(() => {
  refreshBackend().catch((error) => ElMessage.error(error.message || '加载数据失败'))
})

async function onReset() {
  await ElMessageBox.confirm('演示数据会恢复到初始内容，已注册的运营账号也会被清除。', '重置演示数据', {
    type: 'warning',
    confirmButtonText: '重置',
    cancelButtonText: '取消',
  })
  try {
    await resetDb()
  } catch (error) {
    ElMessage.error(error.message || '重置失败')
    return
  }
  router.push('/login')
}

function onLogout() {
  logout()
  router.push('/login')
}
</script>

<template>
  <el-container class="admin-shell">
    <el-aside class="admin-aside" :width="collapsed ? '64px' : '220px'">
      <div class="logo">
        <i>X</i>
        <span v-show="!collapsed">飞连 总后台</span>
      </div>
      <el-menu
        :default-active="route.path"
        :collapse="collapsed"
        :default-openeds="['config', 'ops']"
        router
        background-color="#0e122d"
        text-color="#c9d0e0"
        active-text-color="#00b6f9"
      >
        <el-menu-item index="/dashboard">
          <el-icon><Odometer /></el-icon>
          <span>概览</span>
        </el-menu-item>
        <el-sub-menu index="config">
          <template #title>
            <el-icon><Setting /></el-icon>
            <span>数据配置</span>
          </template>
          <el-menu-item index="/config/nodes">线路节点</el-menu-item>
          <el-menu-item index="/config/groups">线路分组</el-menu-item>
          <el-menu-item index="/config/cores">内核</el-menu-item>
          <el-menu-item index="/config/assets">资源文件</el-menu-item>
          <el-menu-item index="/config/plans">套餐</el-menu-item>
          <el-menu-item index="/config/app">App 配置</el-menu-item>
        </el-sub-menu>
        <el-sub-menu index="ops">
          <template #title>
            <el-icon><User /></el-icon>
            <span>会员运营</span>
          </template>
          <el-menu-item index="/members">会员管理</el-menu-item>
          <el-menu-item index="/distributors">经销商</el-menu-item>
          <el-menu-item index="/orders">订单</el-menu-item>
          <el-menu-item index="/money">提现与退款</el-menu-item>
          <el-menu-item index="/rules">规则与系统</el-menu-item>
        </el-sub-menu>
        <el-menu-item index="/users">
          <el-icon><User /></el-icon>
          <span>用户查看</span>
        </el-menu-item>
        <el-menu-item index="/agents">
          <el-icon><Avatar /></el-icon>
          <span>代理商查看</span>
        </el-menu-item>
        <el-menu-item index="/commission">
          <el-icon><Money /></el-icon>
          <span>代理分佣</span>
        </el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header class="admin-header">
        <div style="display: flex; align-items: center; gap: 12px">
          <el-button text @click="toggleCollapse">
            <el-icon><Fold v-if="!collapsed" /><Expand v-else /></el-icon>
          </el-button>
          <div class="header-title">{{ title }}</div>
        </div>
        <el-dropdown>
          <span class="header-user">
            <el-avatar :size="32">{{ session.user?.nickname?.slice(0, 1) }}</el-avatar>
            <span>{{ session.user?.nickname }}</span>
            <el-tag size="small" effect="plain">{{ roleLabel }}</el-tag>
          </span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="onReset">重置演示数据</el-dropdown-item>
              <el-dropdown-item divided @click="onLogout">退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </el-header>
      <el-main class="admin-main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { LEVELS, logout, session } from '@/stores/session'

const route = useRoute()
const router = useRouter()
const collapsed = ref(false)

const title = computed(() => route.meta.title || '代理商后台')
const level = computed(() => LEVELS[session.user?.level] || { label: '代理', type: 'info' })

function toggleCollapse() {
  collapsed.value = !collapsed.value
}

async function onLogout() {
  await logout()
  router.push('/login')
}
</script>

<template>
  <el-container class="admin-shell">
    <el-aside class="admin-aside" :width="collapsed ? '64px' : '220px'">
      <div class="logo">
        <i>X</i>
        <span v-show="!collapsed">飞连 代理商</span>
      </div>
      <el-menu
        :default-active="route.path"
        :collapse="collapsed"
        router
        background-color="#0e122d"
        text-color="#c9d0e0"
        active-text-color="#00b6f9"
      >
        <el-menu-item index="/dashboard">
          <el-icon><Odometer /></el-icon>
          <span>概览</span>
        </el-menu-item>
        <el-menu-item index="/team">
          <el-icon><Avatar /></el-icon>
          <span>我的代理</span>
        </el-menu-item>
        <el-menu-item index="/commission">
          <el-icon><Money /></el-icon>
          <span>分佣订单</span>
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
            <el-avatar :size="32">{{ session.user?.name?.slice(0, 1) }}</el-avatar>
            <span>{{ session.user?.name }}</span>
            <el-tag size="small" :type="level.type" effect="plain">{{ level.label }}</el-tag>
          </span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item @click="onLogout">退出登录</el-dropdown-item>
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

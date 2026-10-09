<script setup>
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { LEVELS, logout, session } from '@/stores/session'

const route = useRoute()
const router = useRouter()
const collapsed = ref(false)

const title = computed(() => route.meta.title || '经销商后台')
const level = computed(() => LEVELS[session.user?.level] || { label: '经销商', type: 'warning' })

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
        <span v-show="!collapsed">飞连 经销商</span>
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
          <span>旗下会员</span>
        </el-menu-item>
        <el-menu-item index="/commission">
          <el-icon><Money /></el-icon>
          <span>订单佣金</span>
        </el-menu-item>
        <el-menu-item index="/withdraw">
          <el-icon><Wallet /></el-icon>
          <span>提现</span>
        </el-menu-item>
        <el-menu-item index="/invite">
          <el-icon><Share /></el-icon>
          <span>邀请</span>
        </el-menu-item>
        <el-menu-item index="/notice">
          <el-icon><Bell /></el-icon>
          <span>公告客服</span>
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
            <el-avatar :size="32">{{ (session.user?.username || session.user?.name || '经').slice(0, 1) }}</el-avatar>
            <span>{{ session.user?.username || session.user?.name }}</span>
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

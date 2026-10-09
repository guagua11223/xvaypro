import { createRouter, createWebHistory } from 'vue-router'
import { session } from '@/stores/session'

import AgentLayout from '@/layouts/AgentLayout.vue'
import Login from '@/views/Login.vue'
import Register from '@/views/Register.vue'
import Dashboard from '@/views/Dashboard.vue'
import Team from '@/views/Team.vue'
import Commission from '@/views/Commission.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: Login, meta: { public: true, title: '登录' } },
    { path: '/register', component: Register, meta: { public: true, title: '注册' } },
    {
      path: '/',
      component: AgentLayout,
      redirect: '/dashboard',
      children: [
        { path: 'dashboard', component: Dashboard, meta: { title: '概览' } },
        { path: 'team', component: Team, meta: { title: '我的代理' } },
        { path: 'commission', component: Commission, meta: { title: '分佣订单' } },
      ],
    },
  ],
})

router.beforeEach((to) => {
  const loggedIn = Boolean(session.user?.token)
  if (!to.meta.public && !loggedIn) return '/login'
  if (loggedIn && (to.path === '/login' || to.path === '/register')) return '/dashboard'
  return true
})

export default router

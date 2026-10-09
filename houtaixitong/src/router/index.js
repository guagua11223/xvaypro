import { createRouter, createWebHistory } from 'vue-router'
import { session } from '@/stores/session'

import AgentLayout from '@/layouts/AgentLayout.vue'
import Login from '@/views/Login.vue'
import Register from '@/views/Register.vue'
import Dashboard from '@/views/Dashboard.vue'
import Team from '@/views/Team.vue'
import Commission from '@/views/Commission.vue'
import Withdraw from '@/views/Withdraw.vue'
import Invite from '@/views/Invite.vue'
import Notice from '@/views/Notice.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/login', component: Login, meta: { public: true, title: '登录' } },
    { path: '/register', component: Register, meta: { public: true, title: '注册' } },
    {
      path: '/',
      component: AgentLayout,
      redirect: '/dashboard',
      children: [
        { path: 'dashboard', component: Dashboard, meta: { title: '概览' } },
        { path: 'team', component: Team, meta: { title: '旗下会员' } },
        { path: 'commission', component: Commission, meta: { title: '订单佣金' } },
        { path: 'withdraw', component: Withdraw, meta: { title: '提现' } },
        { path: 'invite', component: Invite, meta: { title: '邀请' } },
        { path: 'notice', component: Notice, meta: { title: '公告客服' } },
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

import { createRouter, createWebHistory } from 'vue-router'
import { session } from '@/stores/db'

import AdminLayout from '@/layouts/AdminLayout.vue'
import Login from '@/views/Login.vue'
import Register from '@/views/Register.vue'
import Dashboard from '@/views/Dashboard.vue'
import Nodes from '@/views/config/Nodes.vue'
import Groups from '@/views/config/Groups.vue'
import Cores from '@/views/config/Cores.vue'
import Assets from '@/views/config/Assets.vue'
import Plans from '@/views/config/Plans.vue'
import AppSettings from '@/views/config/AppSettings.vue'
import UserList from '@/views/users/UserList.vue'
import AgentList from '@/views/agents/AgentList.vue'
import Commission from '@/views/commission/Commission.vue'
import Members from '@/views/ops/Members.vue'
import Distributors from '@/views/ops/Distributors.vue'
import Orders from '@/views/ops/Orders.vue'
import Money from '@/views/ops/Money.vue'
import SettingsOps from '@/views/ops/Settings.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', component: Login, meta: { public: true, title: '登录' } },
    { path: '/register', component: Register, meta: { public: true, title: '注册' } },
    {
      path: '/',
      component: AdminLayout,
      redirect: '/dashboard',
      children: [
        { path: 'dashboard', component: Dashboard, meta: { title: '概览' } },
        { path: 'config/nodes', component: Nodes, meta: { title: '线路节点' } },
        { path: 'config/groups', component: Groups, meta: { title: '线路分组' } },
        { path: 'config/cores', component: Cores, meta: { title: '内核' } },
        { path: 'config/assets', component: Assets, meta: { title: '资源文件' } },
        { path: 'config/plans', component: Plans, meta: { title: '套餐' } },
        { path: 'config/app', component: AppSettings, meta: { title: 'App 配置' } },
        { path: 'members', component: Members, meta: { title: '会员管理' } },
        { path: 'distributors', component: Distributors, meta: { title: '经销商' } },
        { path: 'orders', component: Orders, meta: { title: '订单' } },
        { path: 'money', component: Money, meta: { title: '提现与退款' } },
        { path: 'rules', component: SettingsOps, meta: { title: '规则与系统' } },
        { path: 'users', component: UserList, meta: { title: '用户查看' } },
        { path: 'agents', component: AgentList, meta: { title: '代理商查看' } },
        { path: 'commission', component: Commission, meta: { title: '代理分佣' } },
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

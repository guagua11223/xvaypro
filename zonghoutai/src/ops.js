import { request } from './api'
import { session } from './stores/db'

export function adminRequest(path, options = {}) {
  return request(path, { ...options, token: session.user?.token || '' })
}

export const PAY_STATUS = ['待支付', '已支付', '已退款', '已关闭']
export const COMMISSION_STATUS = ['待结算', '已结算', '已退回']
export const REFUND_STATUS = ['申请中', '处理中', '成功', '已拒绝']
export const WITHDRAW_STATUS = ['待审核', '审核通过', '已打款', '已拒绝', '已取消']
export const EMAIL_STATUS = ['未绑定', '已绑定未验证', '已绑定已验证']
export const SERVICE_STATUS = ['未激活', '正常', '停用', '到期', '退款停用']

export function label(list, value) {
  return list[Number(value)] || '—'
}

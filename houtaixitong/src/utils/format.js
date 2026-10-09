export function formatTime(value) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return String(value)
  const pad = (n) => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export function formatMoney(value) {
  return `¥${Number(value || 0).toFixed(2)}`
}

export function formatRate(value) {
  const rate = Number(value || 0)
  if (rate <= 1) return `${Math.round(rate * 1000) / 10}%`
  return `${rate}%`
}

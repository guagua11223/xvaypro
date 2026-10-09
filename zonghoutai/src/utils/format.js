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

export function daysFromNow(days) {
  return new Date(Date.now() + days * 86400000).toISOString()
}

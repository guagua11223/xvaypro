<script setup>
import { reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { addItem, db, removeItem, updateItem } from '@/stores/db'
import { formatMoney, formatTime } from '@/utils/format'

const dialogVisible = ref(false)
const editingId = ref(null)
const formRef = ref()
const form = reactive(emptyForm())

function emptyForm() {
  return {
    name: '',
    price: 30,
    durationDays: 30,
    trafficGB: 100,
    deviceLimit: 2,
    status: 'on',
  }
}

const rules = {
  name: [{ required: true, message: '请输入套餐名称', trigger: 'blur' }],
}

function openCreate() {
  editingId.value = null
  Object.assign(form, emptyForm())
  dialogVisible.value = true
}

function openEdit(row) {
  editingId.value = row.id
  Object.assign(form, row)
  dialogVisible.value = true
}

async function submit() {
  await formRef.value.validate()
  const payload = {
    ...form,
    name: form.name.trim(),
    price: Number(form.price) || 0,
    durationDays: Number(form.durationDays) || 1,
    trafficGB: Number(form.trafficGB) || 0,
    deviceLimit: Number(form.deviceLimit) || 1,
  }
  if (editingId.value) updateItem('plans', editingId.value, payload)
  else addItem('plans', payload)
  dialogVisible.value = false
  ElMessage.success('套餐已保存')
}

async function remove(row) {
  if (db.users.some((user) => user.planId === row.id)) {
    ElMessage.warning('仍有用户使用该套餐')
    return
  }
  await ElMessageBox.confirm(`删除套餐「${row.name}」？`, '删除套餐', { type: 'warning' })
  removeItem('plans', row.id)
  ElMessage.success('已删除')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>套餐</h2>
        <p>用户流量、时长和设备数按套餐生效。代理分佣按套餐成交金额和代理等级计算。</p>
      </div>
      <el-button type="primary" @click="openCreate">新增套餐</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="db.plans">
        <el-table-column prop="name" label="名称" width="120" />
        <el-table-column label="价格" width="120">
          <template #default="{ row }">{{ formatMoney(row.price) }}</template>
        </el-table-column>
        <el-table-column label="时长" width="100">
          <template #default="{ row }">{{ row.durationDays }} 天</template>
        </el-table-column>
        <el-table-column label="流量" width="110">
          <template #default="{ row }">{{ row.trafficGB }} GB</template>
        </el-table-column>
        <el-table-column label="设备数" width="90" prop="deviceLimit" />
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="row.status === 'on' ? 'success' : 'info'" size="small">
              {{ row.status === 'on' ? '在售' : '下架' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="更新时间" width="160">
          <template #default="{ row }">{{ formatTime(row.updatedAt) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="140" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑套餐' : '新增套餐'" width="480px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="价格">
          <el-input-number v-model="form.price" :min="0" :precision="2" />
        </el-form-item>
        <el-form-item label="时长">
          <el-input-number v-model="form.durationDays" :min="1" />
          <span style="margin-left: 8px; color: #6b7280">天</span>
        </el-form-item>
        <el-form-item label="流量">
          <el-input-number v-model="form.trafficGB" :min="1" />
          <span style="margin-left: 8px; color: #6b7280">GB</span>
        </el-form-item>
        <el-form-item label="设备数">
          <el-input-number v-model="form.deviceLimit" :min="1" :max="20" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" active-value="on" inactive-value="off" active-text="在售" inactive-text="下架" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

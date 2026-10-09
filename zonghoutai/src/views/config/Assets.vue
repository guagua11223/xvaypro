<script setup>
import { reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { addItem, db, removeItem, updateItem } from '@/stores/db'
import { formatTime } from '@/utils/format'

const dialogVisible = ref(false)
const editingId = ref(null)
const formRef = ref()
const form = reactive(emptyForm())

function emptyForm() {
  return {
    name: '',
    type: 'remote',
    path: '',
    url: '',
    autoUpdateInterval: 1440,
  }
}

const rules = {
  name: [{ required: true, message: '请输入资源名称', trigger: 'blur' }],
  path: [{ required: true, message: '请输入本地路径', trigger: 'blur' }],
  url: [
    {
      validator: (_rule, value, callback) => {
        if (form.type === 'remote' && !value) callback(new Error('远程资源需要填写地址'))
        else callback()
      },
      trigger: 'blur',
    },
  ],
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
    path: form.path.trim(),
    url: form.type === 'local' ? '' : form.url.trim(),
    autoUpdateInterval: form.type === 'local' ? 0 : Number(form.autoUpdateInterval) || 0,
  }
  if (editingId.value) updateItem('assets', editingId.value, payload)
  else addItem('assets', payload)
  dialogVisible.value = false
  ElMessage.success('资源已保存')
}

async function remove(row) {
  await ElMessageBox.confirm(`删除资源「${row.name}」？`, '删除资源', { type: 'warning' })
  removeItem('assets', row.id)
  ElMessage.success('已删除')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>资源文件</h2>
        <p>对应 App 的 Asset。geoip、geosite 等规则文件可从 GitHub 远程更新，或指定本地路径。</p>
      </div>
      <el-button type="primary" @click="openCreate">新增资源</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="db.assets">
        <el-table-column prop="name" label="名称" width="140" />
        <el-table-column label="类型" width="90">
          <template #default="{ row }">{{ row.type === 'remote' ? '远程' : '本地' }}</template>
        </el-table-column>
        <el-table-column prop="path" label="路径" min-width="160" />
        <el-table-column prop="url" label="远程地址" min-width="220">
          <template #default="{ row }">{{ row.url || '—' }}</template>
        </el-table-column>
        <el-table-column label="更新间隔" width="120">
          <template #default="{ row }">{{ row.autoUpdateInterval ? `${row.autoUpdateInterval} 分钟` : '—' }}</template>
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

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑资源' : '新增资源'" width="560px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" placeholder="例如 geoip.dat" />
        </el-form-item>
        <el-form-item label="类型">
          <el-radio-group v-model="form.type">
            <el-radio value="remote">远程</el-radio>
            <el-radio value="local">本地</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="本地路径" prop="path">
          <el-input v-model="form.path" placeholder="assets/geoip.dat" />
        </el-form-item>
        <el-form-item v-if="form.type === 'remote'" label="远程地址" prop="url">
          <el-input v-model="form.url" placeholder="github://owner/repo/file" />
        </el-form-item>
        <el-form-item v-if="form.type === 'remote'" label="更新间隔">
          <el-input-number v-model="form.autoUpdateInterval" :min="0" :max="43200" />
          <span style="margin-left: 8px; color: #6b7280">分钟</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

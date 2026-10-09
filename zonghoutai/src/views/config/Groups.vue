<script setup>
import { computed, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { addItem, CORE_TYPES, db, GROUP_PROTOCOLS, labelOf, removeItem, updateItem } from '@/stores/db'
import { formatTime } from '@/utils/format'

const dialogVisible = ref(false)
const editingId = ref(null)
const formRef = ref()
const form = reactive(emptyForm())

function emptyForm() {
  return {
    name: '',
    type: 'remote',
    protocol: 'generic',
    coreType: 'xray',
    autoUpdateInterval: 60,
    url: '',
    status: 'enabled',
  }
}

const rules = {
  name: [{ required: true, message: '请输入分组名称', trigger: 'blur' }],
  coreType: [{ required: true, message: '请选择内核', trigger: 'change' }],
  url: [
    {
      validator: (_rule, value, callback) => {
        if (form.type === 'remote' && !value) callback(new Error('远程分组需要填写地址'))
        else callback()
      },
      trigger: 'blur',
    },
  ],
}

const rows = computed(() =>
  db.groups.map((group) => ({
    ...group,
    nodeCount: db.nodes.filter((node) => node.groupId === group.id).length,
  })),
)

function openCreate() {
  editingId.value = null
  Object.assign(form, emptyForm())
  dialogVisible.value = true
}

function openEdit(row) {
  editingId.value = row.id
  const { nodeCount, ...rest } = row
  Object.assign(form, rest)
  dialogVisible.value = true
}

async function submit() {
  await formRef.value.validate()
  const payload = {
    ...form,
    name: form.name.trim(),
    url: form.type === 'local' ? '' : form.url.trim(),
    protocol: form.type === 'local' ? '' : form.protocol,
    autoUpdateInterval: form.type === 'local' ? 0 : Number(form.autoUpdateInterval) || 0,
  }
  try {
    if (editingId.value) await updateItem('groups', editingId.value, payload)
    else await addItem('groups', payload)
    dialogVisible.value = false
    ElMessage.success('分组已保存')
  } catch (error) {
    ElMessage.error(error.message || '保存失败')
  }
}

async function remove(row) {
  if (db.nodes.some((node) => node.groupId === row.id)) {
    ElMessage.warning('该分组下还有线路，请先调整线路')
    return
  }
  await ElMessageBox.confirm(`删除分组「${row.name}」？`, '删除分组', { type: 'warning' })
  try {
    await removeItem('groups', row.id)
    ElMessage.success('已删除')
  } catch (error) {
    ElMessage.error(error.message || '删除失败')
  }
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>线路分组</h2>
        <p>对应 App 的 ProfileGroup。本地分组手工维护，远程分组按 AnyPortal REST、文件或通用订阅更新。</p>
      </div>
      <el-button type="primary" @click="openCreate">新增分组</el-button>
    </div>
    <el-card shadow="never">
      <el-table :data="rows">
        <el-table-column prop="name" label="名称" min-width="120" />
        <el-table-column label="类型" width="90">
          <template #default="{ row }">{{ row.type === 'remote' ? '远程' : '本地' }}</template>
        </el-table-column>
        <el-table-column label="协议" width="150">
          <template #default="{ row }">{{ row.type === 'remote' ? labelOf(GROUP_PROTOCOLS, row.protocol) : '—' }}</template>
        </el-table-column>
        <el-table-column prop="coreType" label="内核" width="110" />
        <el-table-column label="更新间隔" width="110">
          <template #default="{ row }">{{ row.autoUpdateInterval ? `${row.autoUpdateInterval} 分钟` : '—' }}</template>
        </el-table-column>
        <el-table-column prop="nodeCount" label="线路数" width="90" />
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="row.status === 'enabled' ? 'success' : 'info'" size="small">
              {{ row.status === 'enabled' ? '启用' : '停用' }}
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

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑分组' : '新增分组'" width="560px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="110px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="类型">
          <el-radio-group v-model="form.type">
            <el-radio value="local">本地</el-radio>
            <el-radio value="remote">远程</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.type === 'remote'" label="远程协议">
          <el-select v-model="form.protocol" style="width: 100%">
            <el-option v-for="item in GROUP_PROTOCOLS" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="默认内核" prop="coreType">
          <el-select v-model="form.coreType" style="width: 100%">
            <el-option v-for="core in CORE_TYPES" :key="core" :label="core" :value="core" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="form.type === 'remote'" label="订阅地址" prop="url">
          <el-input v-model="form.url" />
        </el-form-item>
        <el-form-item v-if="form.type === 'remote'" label="更新间隔">
          <el-input-number v-model="form.autoUpdateInterval" :min="0" :max="10080" />
          <span style="margin-left: 8px; color: #6b7280">分钟</span>
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" active-value="enabled" inactive-value="disabled" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

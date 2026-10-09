<script setup>
import { computed, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { addItem, CORE_TYPES, db, groupName, labelOf, NODE_STATUS, removeItem, updateItem } from '@/stores/db'
import { formatTime } from '@/utils/format'

const keyword = ref('')
const groupId = ref()
const status = ref('')
const page = ref(1)
const dialogVisible = ref(false)
const editingId = ref(null)
const formRef = ref()

const form = reactive(emptyForm())

function emptyForm() {
  return {
    name: '',
    key: '',
    groupId: db.groups[0]?.id ?? null,
    coreType: 'xray',
    type: 'remote',
    url: '',
    region: '',
    status: 'online',
    latency: 40,
  }
}

const rules = {
  name: [{ required: true, message: '请输入线路名称', trigger: 'blur' }],
  key: [{ required: true, message: '请输入线路标识', trigger: 'blur' }],
  groupId: [{ required: true, message: '请选择分组', trigger: 'change' }],
  coreType: [{ required: true, message: '请选择内核', trigger: 'change' }],
  region: [{ required: true, message: '请输入地区', trigger: 'blur' }],
  url: [
    {
      validator: (_rule, value, callback) => {
        if (form.type === 'remote' && !value) callback(new Error('远程线路需要填写地址'))
        else callback()
      },
      trigger: 'blur',
    },
  ],
}

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return db.nodes.filter((item) => {
    const hit = !kw || [item.name, item.key, item.region].some((field) => field.toLowerCase().includes(kw))
    const groupOk = !groupId.value || item.groupId === groupId.value
    const statusOk = !status.value || item.status === status.value
    return hit && groupOk && statusOk
  })
})

const paged = computed(() => filtered.value.slice((page.value - 1) * 8, page.value * 8))

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
  const duplicated = db.nodes.some((item) => item.key === form.key.trim() && item.id !== editingId.value)
  if (duplicated) {
    ElMessage.warning('线路标识已存在')
    return
  }
  const payload = {
    ...form,
    name: form.name.trim(),
    key: form.key.trim(),
    url: form.type === 'local' ? '' : form.url.trim(),
    latency: Number(form.latency) || 0,
  }
  if (editingId.value) updateItem('nodes', editingId.value, payload)
  else addItem('nodes', payload)
  dialogVisible.value = false
  ElMessage.success(editingId.value ? '线路已更新' : '线路已添加')
}

async function remove(row) {
  await ElMessageBox.confirm(`删除线路「${row.name}」后，App 选线列表将不再包含它。`, '删除线路', { type: 'warning' })
  removeItem('nodes', row.id)
  ElMessage.success('已删除')
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>线路节点</h2>
        <p>对应 App 的 Profile 与选线页。用户在客户端选择地区后，按这里的线路和内核建立连接。</p>
      </div>
      <el-button type="primary" @click="openCreate">新增线路</el-button>
    </div>
    <el-card shadow="never">
      <div class="filters">
        <el-input v-model="keyword" clearable placeholder="搜索名称、标识、地区" style="width: 240px" @input="page = 1" />
        <el-select v-model="groupId" clearable placeholder="分组" style="width: 160px" @change="page = 1">
          <el-option v-for="group in db.groups" :key="group.id" :label="group.name" :value="group.id" />
        </el-select>
        <el-select v-model="status" clearable placeholder="状态" style="width: 140px" @change="page = 1">
          <el-option v-for="item in NODE_STATUS" :key="item.value" :label="item.label" :value="item.value" />
        </el-select>
      </div>
      <el-table :data="paged" style="margin-top: 16px">
        <el-table-column prop="name" label="名称" min-width="120" />
        <el-table-column prop="region" label="地区" width="120" />
        <el-table-column label="分组" width="120">
          <template #default="{ row }">{{ groupName(row.groupId) }}</template>
        </el-table-column>
        <el-table-column prop="coreType" label="内核" width="110" />
        <el-table-column label="类型" width="90">
          <template #default="{ row }">{{ row.type === 'remote' ? '远程' : '本地' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="row.status === 'online' ? 'success' : row.status === 'maintain' ? 'warning' : 'info'" size="small">
              {{ labelOf(NODE_STATUS, row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="延迟" width="90">
          <template #default="{ row }">{{ row.latency ? `${row.latency} ms` : '—' }}</template>
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
      <div style="margin-top: 16px; display: flex; justify-content: flex-end">
        <el-pagination
          v-model:current-page="page"
          layout="total, prev, pager, next"
          :total="filtered.length"
          :page-size="8"
        />
      </div>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="editingId ? '编辑线路' : '新增线路'" width="560px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" placeholder="例如 香港 02" />
        </el-form-item>
        <el-form-item label="标识" prop="key">
          <el-input v-model="form.key" placeholder="唯一 key，例如 hk-02" />
        </el-form-item>
        <el-form-item label="分组" prop="groupId">
          <el-select v-model="form.groupId" style="width: 100%">
            <el-option v-for="group in db.groups" :key="group.id" :label="group.name" :value="group.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="内核" prop="coreType">
          <el-select v-model="form.coreType" style="width: 100%">
            <el-option v-for="core in CORE_TYPES" :key="core" :label="core" :value="core" />
          </el-select>
        </el-form-item>
        <el-form-item label="类型">
          <el-radio-group v-model="form.type">
            <el-radio value="remote">远程</el-radio>
            <el-radio value="local">本地</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.type === 'remote'" label="地址" prop="url">
          <el-input v-model="form.url" placeholder="节点链接或订阅地址" />
        </el-form-item>
        <el-form-item label="地区" prop="region">
          <el-input v-model="form.region" placeholder="展示在 App 选线页" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="form.status" style="width: 100%">
            <el-option v-for="item in NODE_STATUS" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="延迟">
          <el-input-number v-model="form.latency" :min="0" :max="9999" />
          <span style="margin-left: 8px; color: #6b7280">ms，对应 App 的 httping</span>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { db, updateItem } from '@/stores/db'
import { formatTime } from '@/utils/format'

const dialogVisible = ref(false)
const formRef = ref()
const form = reactive({
  id: null,
  name: '',
  version: '',
  enabled: true,
  isExec: true,
  workingDir: '',
})

const rules = {
  version: [{ required: true, message: '请输入版本号', trigger: 'blur' }],
}

function openEdit(row) {
  Object.assign(form, row)
  dialogVisible.value = true
}

async function submit() {
  await formRef.value.validate()
  try {
    await updateItem('cores', form.id, {
      version: form.version.trim(),
      enabled: form.enabled,
      isExec: form.isExec,
      workingDir: form.workingDir.trim(),
    })
    dialogVisible.value = false
    ElMessage.success('内核配置已保存')
  } catch (error) {
    ElMessage.error(error.message || '保存失败')
  }
}

async function toggle(row, enabled) {
  try {
    await updateItem('cores', row.id, { enabled })
  } catch (error) {
    ElMessage.error(error.message || '保存失败')
  }
}
</script>

<template>
  <div class="page">
    <div class="page-head">
      <div>
        <h2>内核</h2>
        <p>对应 App 设置中的 Cores。客户端按启用的内核加载可执行文件，线路节点会引用其中一种内核。</p>
      </div>
    </div>
    <el-card shadow="never">
      <el-table :data="db.cores">
        <el-table-column prop="name" label="内核" width="140" />
        <el-table-column prop="version" label="版本" width="140" />
        <el-table-column label="可执行" width="100">
          <template #default="{ row }">{{ row.isExec ? '是' : '库' }}</template>
        </el-table-column>
        <el-table-column label="启用" width="100">
          <template #default="{ row }">
            <el-switch :model-value="row.enabled" @change="toggle(row, $event)" />
          </template>
        </el-table-column>
        <el-table-column prop="workingDir" label="工作目录" min-width="180">
          <template #default="{ row }">{{ row.workingDir || '默认' }}</template>
        </el-table-column>
        <el-table-column label="更新时间" width="160">
          <template #default="{ row }">{{ formatTime(row.updatedAt) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="`编辑 ${form.name}`" width="480px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="96px">
        <el-form-item label="版本" prop="version">
          <el-input v-model="form.version" />
        </el-form-item>
        <el-form-item label="工作目录">
          <el-input v-model="form.workingDir" placeholder="留空使用客户端默认目录" />
        </el-form-item>
        <el-form-item label="可执行">
          <el-switch v-model="form.isExec" />
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="form.enabled" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="submit">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

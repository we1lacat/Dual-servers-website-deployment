<template>
  <div>
    <!-- 工具栏 + 标题区 -->
    <div class="admin-page-header">
      <div>
        <h2 class="admin-page-title">{{ title }}</h2>
        <p class="admin-page-desc">
          接口前缀 /api/admin/{{ base }} · 共 {{ total }} 条
        </p>
      </div>
      <div class="admin-toolbar">
        <slot name="filters" />
        <el-button type="primary" @click="openCreate">新增</el-button>
      </div>
    </div>

    <!-- 数据表格 -->
    <div class="admin-table-wrap">
      <el-table v-loading="loading" :data="rows" stripe>
        <el-table-column prop="id" label="ID" width="64" />
        <el-table-column
          v-for="f in tableFields"
          :key="f.prop"
          :prop="f.prop"
          :label="f.label"
          :width="f.width"
          show-overflow-tooltip
        >
          <template #default="{ row }">
            <span v-if="f.type === 'select'">{{ optionLabel(f, row[f.prop]) }}</span>
            <span v-else>{{ row[f.prop] }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="openEdit(row)">编辑</el-button>
            <el-button link type="danger" @click="remove(row)">删除</el-button>
          </template>
        </el-table-column>

        <template #empty>
          <div class="admin-empty">暂无数据，点击右上角「新增」开始添加</div>
        </template>
      </el-table>
    </div>

    <!-- 分页 -->
    <el-pagination
      v-model:current-page="current"
      v-model:page-size="size"
      :total="total"
      :page-sizes="[5, 10, 20, 50]"
      layout="total, sizes, prev, pager, next"
      class="admin-pagination"
      @size-change="load"
      @current-change="load"
    />

    <!-- 新增 / 编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="(form.id != null ? '编辑' : '新增') + ' · ' + title" width="560px" destroy-on-close>
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item v-for="f in fields" :key="f.prop" :label="f.label" :prop="f.prop">
          <el-input-number
            v-if="f.type === 'number'"
            v-model="form[f.prop]"
            :min="f.min ?? 0"
            :max="f.max ?? 9999999"
            class="admin-form-control"
            style="width: 200px"
          />
          <el-select
            v-else-if="f.type === 'select'"
            v-model="form[f.prop]"
            :placeholder="f.placeholder || '请选择'"
            class="admin-form-control"
            style="width: 220px"
          >
            <el-option v-for="o in f.options" :key="String(o.value)" :label="o.label" :value="o.value" />
          </el-select>
          <el-input
            v-else-if="f.type === 'textarea'"
            v-model="form[f.prop]"
            type="textarea"
            :rows="4"
            :placeholder="f.placeholder || ''"
          />
          <el-input v-else v-model="form[f.prop]" :placeholder="f.placeholder || ''" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import type { FormInstance, FormRules } from 'element-plus'
import { ElMessage, ElMessageBox } from 'element-plus'
import { adminPage, adminCreate, adminUpdate, adminDelete } from '@/api'

export interface FieldDef {
  prop: string
  label: string
  type?: 'text' | 'textarea' | 'number' | 'select'
  options?: { label: string; value: any }[]
  required?: boolean
  width?: string
  placeholder?: string
  hideInTable?: boolean
  min?: number
  max?: number
}

const props = defineProps<{
  title: string
  base: string
  fields: FieldDef[]
  /** 额外查询参数（如技能 type、笔记 keyword），变化时自动刷新 */
  extraQuery?: Record<string, any>
}>()

const rows = ref<any[]>([])
const total = ref(0)
const current = ref(1)
const size = ref(10)
const loading = ref(false)

const dialogVisible = ref(false)
const saving = ref(false)
const formRef = ref<FormInstance>()
const form = ref<Record<string, any>>({})

const tableFields = computed(() => props.fields.filter((f) => !f.hideInTable))

const rules = computed<FormRules>(() => {
  const r: FormRules = {}
  for (const f of props.fields) {
    if (f.required) r[f.prop] = [{ required: true, message: `请填写${f.label}`, trigger: 'blur' }]
  }
  return r
})

function optionLabel(f: FieldDef, value: any) {
  const hit = f.options?.find((o) => o.value === value)
  return hit ? hit.label : String(value ?? '')
}

async function load() {
  loading.value = true
  try {
    const page = await adminPage(props.base, {
      current: current.value,
      size: size.value,
      ...(props.extraQuery || {}),
    })
    rows.value = page.records || []
    total.value = Number(page.total || 0)
  } catch {
    /* 错误已由拦截器统一提示 */
  } finally {
    loading.value = false
  }
}

function emptyForm(): Record<string, any> {
  const f: Record<string, any> = {}
  for (const d of props.fields) f[d.prop] = d.type === 'number' ? (d.min ?? 0) : (d.type === 'select' ? d.options?.[0]?.value ?? '' : '')
  return f
}

function openCreate() {
  form.value = emptyForm()
  dialogVisible.value = true
}

function openEdit(row: any) {
  const f: Record<string, any> = { id: row.id }
  for (const d of props.fields) f[d.prop] = row[d.prop] ?? emptyForm()[d.prop]
  form.value = f
  dialogVisible.value = true
}

async function save() {
  try {
    await formRef.value?.validate()
  } catch {
    return
  }
  saving.value = true
  try {
    if (form.value.id != null) {
      await adminUpdate(props.base, form.value)
      ElMessage.success('已更新')
    } else {
      await adminCreate(props.base, form.value)
      ElMessage.success('已新增')
    }
    dialogVisible.value = false
    await load()
  } catch {
    /* 错误已由拦截器统一提示 */
  } finally {
    saving.value = false
  }
}

async function remove(row: any) {
  try {
    await ElMessageBox.confirm(`确认删除该条记录（ID=${row.id}）？删除后不可恢复。`, '删除确认', {
      type: 'warning',
      confirmButtonText: '删除',
      cancelButtonText: '取消',
    })
  } catch {
    return
  }
  try {
    await adminDelete(props.base, row.id)
    ElMessage.success('已删除')
    // 当前页删空后回退一页
    if (rows.value.length === 1 && current.value > 1) current.value -= 1
    await load()
  } catch {
    /* 错误已由拦截器统一提示 */
  }
}

watch(() => props.extraQuery, () => {
  current.value = 1
  load()
}, { deep: true })

onMounted(load)

defineExpose({ reload: load })
</script>

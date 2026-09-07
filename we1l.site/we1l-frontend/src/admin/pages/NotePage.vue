<template>
  <div class="admin-filter">
    <el-input
      v-model="query.keyword"
      placeholder="标题关键词"
      clearable
      class="admin-form-control"
      style="width: 180px"
      @keyup.enter="refresh"
      @clear="refresh"
    />
    <el-input
      v-model="query.category"
      placeholder="分类"
      clearable
      class="admin-form-control"
      style="width: 130px"
      @keyup.enter="refresh"
      @clear="refresh"
    />
    <el-button @click="refresh">查询</el-button>
  </div>
  <CrudTable ref="tableRef" title="学习笔记" base="notes" :fields="fields" :extra-query="query" />
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import CrudTable from '@/admin/components/CrudTable.vue'

// query 同时作为 extraQuery 传给后端分页接口
const query = reactive<{ keyword?: string; category?: string }>({})
const tableRef = ref<InstanceType<typeof CrudTable>>()

// 手动触发刷新：给 extraQuery 赋新引用以触发 watch（回车/按钮时）
function refresh() {
  // 触发 CrudTable 内部对 extraQuery 的 deep watch
  query.keyword = query.keyword ?? ''
}

const fields = [
  { prop: 'title', label: '标题', required: true },
  { prop: 'category', label: '分类', width: '110' },
  { prop: 'summary', label: '摘要', type: 'textarea' as const, hideInTable: true },
  { prop: 'content', label: '正文', type: 'textarea' as const, hideInTable: true },
  { prop: 'publishedAt', label: '发布月份', placeholder: '2026-08', width: '110' },
  { prop: 'views', label: '阅读量', type: 'number' as const, width: '90' },
  { prop: 'status', label: '状态', type: 'select' as const, options: [
    { label: '发布', value: 1 },
    { label: '草稿', value: 0 },
  ], width: '90' },
]
</script>

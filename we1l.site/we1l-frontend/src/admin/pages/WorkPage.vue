<template>
  <CrudTable
    title="作品展示"
    base="works"
    :fields="fields"
  />
</template>

<script setup lang="ts">
import CrudTable from '@/admin/components/CrudTable.vue'

const fields = [
  { prop: 'title', label: '作品名称', required: true },
  { prop: 'techMeta', label: '技术栈' },
  { prop: 'category', label: '分类', placeholder: '桌面应用 / Web / 工具…' },
  { prop: 'link', label: '链接', placeholder: 'https://... 留空则不可点击' },
  { prop: 'sortOrder', label: '排序', type: 'number' as const },
  { prop: 'status', label: '状态', type: 'select' as const, options: [
    { label: '上架', value: 1 },
    { label: '下架', value: 0 },
  ], width: '90' },
]
</script>

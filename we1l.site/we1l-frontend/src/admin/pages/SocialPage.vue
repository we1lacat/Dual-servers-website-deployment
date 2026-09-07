<template>
  <CrudTable
    title="社交矩阵"
    base="socials"
    :fields="fields"
  />
</template>

<script setup lang="ts">
import CrudTable from '@/admin/components/CrudTable.vue'

const fields = [
  { prop: 'platform', label: '平台', required: true },
  { prop: 'handle', label: '账号' },
  { prop: 'url', label: '链接', placeholder: 'https://... 留空则前台不可点击' },
  { prop: 'icon', label: '图标标识' },
  { prop: 'sortOrder', label: '排序', type: 'number' as const },
  { prop: 'status', label: '状态', type: 'select' as const, options: [
    { label: '显示', value: 1 },
    { label: '隐藏', value: 0 },
  ], width: '90' },
]
</script>

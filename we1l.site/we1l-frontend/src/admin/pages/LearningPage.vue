<template>
  <CrudTable
    title="正在学习"
    base="learnings"
    :fields="fields"
  />
</template>

<script setup lang="ts">
import CrudTable from '@/admin/components/CrudTable.vue'

const fields = [
  { prop: 'title', label: '学习方向', required: true },
  { prop: 'description', label: '描述' },
  { prop: 'icon', label: '图标标识' },
  { prop: 'sortOrder', label: '排序', type: 'number' as const, width: '90' },
  { prop: 'status', label: '状态', type: 'select' as const, options: [
    { label: '进行中', value: 1 },
    { label: '暂停', value: 0 },
  ], width: '100' },
]
</script>

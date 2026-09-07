<template>
  <CrudTable
    title="简历模板"
    base="resumes"
    :fields="fields"
  />
</template>

<script setup lang="ts">
import CrudTable from '@/admin/components/CrudTable.vue'

const fields = [
  { prop: 'title', label: '模板名称', required: true },
  { prop: 'fileType', label: '格式', type: 'select' as const, options: [
    { label: 'PDF', value: 'PDF' },
    { label: 'DOCX', value: 'DOCX' },
    { label: '其他', value: '其他' },
  ], width: '100' },
  { prop: 'fileSize', label: '大小', placeholder: '约 120KB / 可编辑', width: '120' },
  { prop: 'fileUrl', label: '下载链接', placeholder: 'https://... 留空则前台不显示下载' },
  { prop: 'sortOrder', label: '排序', type: 'number' as const },
  { prop: 'status', label: '状态', type: 'select' as const, options: [
    { label: '上架', value: 1 },
    { label: '下架', value: 0 },
  ], width: '90' },
]
</script>

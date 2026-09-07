<template>
  <CrudTable
    title="站点趋势"
    base="trend"
    :fields="fields"
  />
</template>

<script setup lang="ts">
import CrudTable from '@/admin/components/CrudTable.vue'

const fields = [
  { prop: 'statLabel', label: '月份标签', required: true, placeholder: '例：9月', width: '120' },
  { prop: 'statValue', label: '数值', type: 'number' as const },
  { prop: 'remark', label: '备注', placeholder: '如：峰值 / 站点上线' },
  { prop: 'sortOrder', label: '排序', type: 'number' as const, width: '90' },
]
</script>

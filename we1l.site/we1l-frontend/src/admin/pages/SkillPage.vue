<template>
  <div class="admin-filter">
    <el-select v-model="type" class="admin-form-control" style="width: 150px">
      <el-option label="进度条（BAR）" value="BAR" />
      <el-option label="雷达图（RADAR）" value="RADAR" />
    </el-select>
  </div>
  <CrudTable title="技能管理" base="skills" :fields="fields" :extra-query="{ type }" />
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import CrudTable from '@/admin/components/CrudTable.vue'

// 切换类型时由 CrudTable 的 extraQuery watch 自动刷新
const type = ref<'BAR' | 'RADAR'>('BAR')

const fields = [
  { prop: 'skillName', label: '技能名称', required: true },
  { prop: 'skillType', label: '类型', type: 'select' as const, options: [
    { label: '进度条', value: 'BAR' },
    { label: '雷达图', value: 'RADAR' },
  ], width: '110' },
  { prop: 'percentValue', label: '分值（0-100）', type: 'number' as const, min: 0, max: 100, width: '130' },
  { prop: 'colorKey', label: '配色', type: 'select' as const, options: [
    { label: '蓝色', value: 'blue' },
    { label: '绿色', value: 'green' },
    { label: '橙色', value: 'orange' },
    { label: '紫色', value: 'purple' },
  ], width: '100' },
  { prop: 'sortOrder', label: '排序', type: 'number' as const, width: '90' },
  { prop: 'status', label: '状态', type: 'select' as const, options: [
    { label: '显示', value: 1 },
    { label: '隐藏', value: 0 },
  ], width: '90' },
]
</script>

<template>
  <div ref="el" class="chart-wrap"></div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import * as echarts from 'echarts/core'
import { LineChart } from 'echarts/charts'
import { GridComponent, TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import type { SiteTrend } from '@/api'

echarts.use([LineChart, GridComponent, TooltipComponent, CanvasRenderer])

const props = defineProps<{ data: SiteTrend[] }>()

const el = ref<HTMLElement | null>(null)
let chart: echarts.ECharts | null = null

function render() {
  if (!chart) return
  chart.setOption({
    grid: { left: 40, right: 20, top: 24, bottom: 28 },
    tooltip: {
      trigger: 'axis',
      backgroundColor: '#151515',
      borderWidth: 0,
      textStyle: { color: '#fff', fontSize: 12 },
      formatter: (params: any) => {
        const p = Array.isArray(params) ? params[0] : params
        const item = props.data[p.dataIndex]
        const remark = item?.remark ? `<br/>${item.remark}` : ''
        return `${p.name}<br/><b>${p.value}</b>${remark}`
      },
    },
    xAxis: {
      type: 'category',
      data: props.data.map((d) => d.statLabel),
      axisLine: { lineStyle: { color: '#d9d8d6' } },
      axisTick: { show: false },
      axisLabel: { color: '#787774', fontSize: 12 },
    },
    yAxis: {
      type: 'value',
      splitLine: { lineStyle: { color: '#ececea' } },
      axisLabel: { color: '#9b9a97', fontSize: 12 },
    },
    series: [
      {
        type: 'line',
        data: props.data.map((d) => d.statValue),
        smooth: 0.35,
        symbol: 'circle',
        symbolSize: 7,
        lineStyle: { color: '#37352f', width: 2 },
        itemStyle: { color: '#37352f' },
        areaStyle: {
          color: 'rgba(55, 53, 47, 0.05)',
        },
      },
    ],
  })
}

function onResize() {
  chart?.resize()
}

onMounted(() => {
  if (el.value) {
    chart = echarts.init(el.value)
    render()
    window.addEventListener('resize', onResize)
  }
})

watch(() => props.data, render, { deep: true })

onBeforeUnmount(() => {
  window.removeEventListener('resize', onResize)
  chart?.dispose()
  chart = null
})
</script>

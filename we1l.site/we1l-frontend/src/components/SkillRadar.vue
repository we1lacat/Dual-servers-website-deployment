<template>
  <div ref="el" class="radar-canvas"></div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import * as echarts from 'echarts/core'
import { RadarChart } from 'echarts/charts'
import { TooltipComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import type { Skill } from '@/api'

echarts.use([RadarChart, TooltipComponent, CanvasRenderer])

const props = defineProps<{ skills: Skill[] }>()

const el = ref<HTMLElement | null>(null)
let chart: echarts.ECharts | null = null

function render() {
  if (!chart) return
  chart.setOption({
    tooltip: {
      backgroundColor: '#151515',
      borderWidth: 0,
      textStyle: { color: '#fff', fontSize: 12 },
    },
    radar: {
      indicator: props.skills.map((s) => ({ name: s.skillName, max: 100 })),
      radius: '68%',
      center: ['50%', '52%'],
      axisName: { color: '#787774', fontSize: 12 },
      splitLine: { lineStyle: { color: '#ececea' } },
      splitArea: { areaStyle: { color: ['#ffffff', '#fafaf8'] } },
      axisLine: { lineStyle: { color: '#ececea' } },
    },
    series: [
      {
        type: 'radar',
        data: [
          {
            value: props.skills.map((s) => s.percentValue),
            name: '能力评估',
            symbol: 'circle',
            symbolSize: 5,
            lineStyle: { color: '#2383e2', width: 2 },
            itemStyle: { color: '#2383e2' },
            areaStyle: { color: 'rgba(35, 131, 226, 0.14)' },
          },
        ],
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

watch(() => props.skills, render, { deep: true })

onBeforeUnmount(() => {
  window.removeEventListener('resize', onResize)
  chart?.dispose()
  chart = null
})
</script>

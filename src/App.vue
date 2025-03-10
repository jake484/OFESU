<template>

  <n-layout>
    <n-layout-content>
      <n-form>
        <n-form-item label="参数1">
          <n-input v-model:value="param1" />
        </n-form-item>
        <n-form-item label="参数2">
          <n-input v-model:value="param2" />
        </n-form-item>
      </n-form>
      <div style="display: flex; justify-content: space-between;">
        <div ref="chart1Ref" style="width: 45%; height: 300px;"></div>
        <div ref="chart2Ref" style="width: 45%; height: 300px;"></div>
      </div>
      <n-button type="primary" @click="calculate">计算</n-button>
      <div ref="outputChartRef" style="width: 100%; height: 300px;"></div>
      <p>输出数据1: {{ outputData1 }}</p>
      <p>输出数据2: {{ outputData2 }}</p>
    </n-layout-content>
  </n-layout>
</template>

<script setup lang="ts">
import { ref } from 'vue'

import * as echarts from 'echarts'

const msg = ref('XXX')
const param1 = ref('')
const param2 = ref('')
const chart1Data = ref<number[]>(Array.from({ length: 48 }, () => Math.random() * 10))
const chart2Data = ref<number[]>(Array.from({ length: 48 }, () => Math.random() * 10))
const outputData1 = ref<number>(0)
const outputData2 = ref<number>(0)
const outputChartData = ref<number[]>([])

const chart1Ref = ref<HTMLDivElement | null>(null)
const chart2Ref = ref<HTMLDivElement | null>(null)
const outputChartRef = ref<HTMLDivElement | null>(null)

const initCharts = () => {
  if (chart1Ref.value) {
    const chart1 = echarts.init(chart1Ref.value)
    chart1.setOption({
      title: { text: '0-24小时每半小时电价' },
      tooltip: {},
      xAxis: {
        data: Array.from({ length: 48 }, (_, i) => `${Math.floor(i / 2)}:${i % 2 === 0 ? '00' : '30'}`)
      },
      yAxis: {},
      series: [{
        name: '电价',
        type: 'line',
        data: chart1Data.value
      }]
    })
  }

  if (chart2Ref.value) {
    const chart2 = echarts.init(chart2Ref.value)
    chart2.setOption({
      title: { text: '0-24小时每半小时负荷' },
      tooltip: {},
      xAxis: {
        data: Array.from({ length: 48 }, (_, i) => `${Math.floor(i / 2)}:${i % 2 === 0 ? '00' : '30'}`)
      },
      yAxis: {},
      series: [{
        name: '负荷',
        type: 'line',
        data: chart2Data.value
      }]
    })
  }

  if (outputChartRef.value) {
    const outputChart = echarts.init(outputChartRef.value)
    outputChart.setOption({
      title: { text: '输出曲线图' },
      tooltip: {},
      xAxis: {
        data: Array.from({ length: 48 }, (_, i) => `${Math.floor(i / 2)}:${i % 2 === 0 ? '00' : '30'}`)
      },
      yAxis: {},
      series: [{
        name: '输出',
        type: 'line',
        data: outputChartData.value
      }]
    })
  }
}

const calculate = () => {
  // 这里可以添加你的计算逻辑
  // 示例：将输入数据简单相加
  outputChartData.value = chart1Data.value.map((value, index) => value + chart2Data.value[index])
  outputData1.value = outputChartData.value.reduce((sum, value) => sum + value, 0)
  outputData2.value = outputChartData.value.reduce((sum, value) => sum + value * value, 0)

  // 更新图表
  initCharts()
}

// 初始化图表
initCharts()
</script>

<style scoped>
.read-the-docs {
  color: #888;
}
</style>
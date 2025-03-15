<template>
      <n-card hoverable title="储能单元优化调度系统" class="center-title"></n-card>
      <n-card hoverable style="display: flex; flex-direction: column; height: 100%;">
        <n-space justify="center" style="flex-grow: 1; width: 100%;" item-style="width: 48%;">
          <!-- 第一个输入框 -->
          <n-input-number v-model:value="capacity" :default-value="1000" :format="format" :parse="parse">
            <template #prefix>储能单元容量：</template>
            <template #suffix>kW</template>
          </n-input-number>
          <!-- 第二个输入框 -->
          <n-input-number v-model:value="rate" :default-value="1000" :format="format" :parse="parse">
            <template #prefix>充放电倍率：</template>
            <template #suffix>C </template>
          </n-input-number>
        </n-space>
      </n-card>
      <n-card hoverable title="电价输入" class="center-title-small">
        <n-data-table :columns="columns" :data="priceData" />
      </n-card>
      <n-card hoverable>
        <n-button type="primary" style="width: 100%;" @click="calculateAndUpdateChart">点击计算</n-button>
      </n-card>
      <n-grid cols="4" item-responsive>
        <n-grid-item span="3" style="padding: 0.2rem;">
          <n-card hoverable title="储能单元优化调度曲线" class="center-title-small" style="height: 500px;">
            <div ref="chartRef" style="width: 100%; height: 400px;"></div>
          </n-card>
        </n-grid-item>
        <n-grid-item span="1" style="padding: 0.2rem;">
          <n-card hoverable title="优化调度数据" class="center-title-small" style="height: 500px;">
            <p style="text-align: left; font-size: 28px;">
              收益：￥{{ totalRevenue.toFixed(2) }}
            </p>
            <p style="text-align: left; font-size: 28px;">
              充放电量：{{ totalCap.toFixed(2) }} kWh
            </p>
          </n-card>
        </n-grid-item>
      </n-grid>
  </template>
  
  <script setup lang="ts">
  import { ref, onMounted, h } from 'vue'
  import type { DataTableColumns } from 'naive-ui'
  import { NInput, useMessage } from 'naive-ui'
  import * as echarts from 'echarts'
  const message = useMessage()
  const capacity = ref(1000) // 储能单元容量，双向绑定
  const rate = ref(0.5)  // 充放电倍率，双向绑定
  
  function format(value: number | null) {
    if (value === null)
      return ''
    return value.toLocaleString('en-US')
  }
  
  function parse(input: string) {
    const nums = input.replace(/,/g, '').trim()
    if (/^\d+(\.(\d+)?)?$/.test(nums))
      return Number(nums)
    return nums === '' ? null : Number.NaN
  }
  
  interface RowData {
    key: number
    name: string
    price: string
    timespan: string
  }
  
  // 陕西一般工商业用户电价表，35千伏段
  const priceData = ref([
    {
      key: 0,
      name: '尖峰',
      price: "1.095285",
      timespan: '夏季7、8月19:30-21:30，冬季12、1月18:30-20:30'
    },
    {
      key: 1,
      name: '高峰',
      price: "0.921225",
      timespan: '8:00-11:30，18:30-23:00'
    },
    {
      key: 2,
      name: '平段',
      price: '0.631125',
      timespan: '7:00-8:00,11:30-18:30'
    },
    {
      key: 3,
      name: '低谷',
      price: '0.341025',
      timespan: '23:00-次日7:00'
    }
  ] as RowData[])
  
  // 构造RowData[]
  const createColumns = (): DataTableColumns<RowData> => [
    {
      title: '区间',
      key: 'name',
      render(row, index) {
        return h(NInput, {
          value: row.name,
          disabled: true,
          onUpdateValue(v) {
            priceData.value[index].name = v
          }
        })
      }
    },
    {
      title: '价格',
      key: 'price',
      render(row, index) {
        return h(NInput, {
          value: row.price,
          onUpdateValue(v) {
            priceData.value[index].price = v
          }
        }, {
          suffix: () => h('span', '￥')
        })
      }
    },
    {
      title: '时段',
      key: 'timespan',
      render(row, index) {
        return h(NInput, {
          value: row.timespan,
          disabled: true,
          onUpdateValue(v) {
            priceData.value[index].timespan = v
          }
        })
      }
    }
  ]
  const columns = createColumns()
  
  const chartRef = ref<HTMLElement | null>(null)
  let chart: echarts.ECharts | null = null
  
  const generateRandomData = (length: number): number[] => {
    return Array.from({ length }, () => Math.random() * 1000) // 生成0到1000之间的随机数
  }
  
  const chargeData = ref(generateRandomData(48))
  const dischargeData = ref(generateRandomData(48).map(value => -value)) // 放电数据乘以 -1
  
  const timeLabels = Array.from({ length: 48 }, (_, i) => {
    const hour = Math.floor(i / 2)
    const minute = (i % 2) === 0 ? '00' : '30'
    return `${hour.toString().padStart(2, '0')}:${minute}`
  })
  
  const totalRevenue = ref(0)
  const totalCap = ref(0)
  
  onMounted(() => {
    if (chartRef.value) {
      chart = echarts.init(chartRef.value)
      updateChart()
    }
  })
  
  const updateChart = () => {
    if (chart) {
      const option = {
        tooltip: {
          trigger: 'axis'
        },
        legend: {
          data: ['充电', '放电']
        },
        xAxis: {
          type: 'category',
          data: timeLabels
        },
        yAxis: {
          type: 'value',
          name: '功率 (kW)'
        },
        series: [
          {
            name: '充电',
            type: 'line',
            step: 'start',
            symbol: 'none',
            data: chargeData.value
          },
          {
            name: '放电',
            type: 'line',
            step: 'start',
            symbol: 'none',
            data: dischargeData.value
          }
        ]
      }
      chart.setOption(option)
    }
  }
  
  const calculateAndUpdateChart = async () => {
    try {

      const priceObject = priceData.value.reduce((acc, item) => {
        acc[item.name] = parseFloat(item.price)
        return acc
      }, {} as { [key: string]: number })
  
      const response = await fetch('/api/calculate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          capacity: capacity.value,
          rate: rate.value,
          priceData: priceObject
        })
      })
  
      if (!response.ok) {
        message.error('计算失败！')
        throw new Error(`HTTP error! status: ${response.status}`)
      }
  
      const data = await response.json()
      message.success('计算成功！')
      chargeData.value = data.chargeData
      dischargeData.value = data.dischargeData
      totalRevenue.value = data.totalRevenue
      totalCap.value = data.totalCap
  
      updateChart()
    } catch (error) {
      console.error('Error fetching data:', error)
    }
  }
  
  </script>
  
  <style scoped>
  .n-card {
    padding: 2px;
    margin-bottom: 0.5rem;
    border-radius: 12px;
    /* 添加圆角 */
  }
  
  .center-title :deep(.n-card-header__main) {
    text-align: center;
    font-size: 30px;
  }
  
  .center-title-small :deep(.n-card-header__main) {
    text-align: center;
    font-size: 20px;
  }
  </style>
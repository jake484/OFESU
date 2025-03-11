<template>
  <n-card hoverable title="储能单元优化调度系统" class="center-title"></n-card>
  <n-card hoverable style="display: flex; flex-direction: column; height: 100%;">
    <n-space justify="center" style="flex-grow: 1; width: 100%;" item-style="width: 48%;">

      <!-- 第一个输入框 -->
      <n-input-number v-model:value="value1" :default-value="1000" :format="format" :parse="parse">
        <template #prefix>
          储能单元容量：
        </template>
        <template #suffix>
          kW
        </template>
      </n-input-number>

      <!-- 第二个输入框 -->
      <n-input-number v-model:value="value2" :default-value="1000" :format="format" :parse="parse">
        <template #prefix>
          放电倍率：
        </template>
        <template #suffix>
          C
        </template>
      </n-input-number>

    </n-space>
  </n-card>
  <n-card hoverable>
    <n-button type="primary" style="width: 100%;">点击计算</n-button>
  </n-card>
</template>


<script setup lang="ts">

import { ref } from 'vue'

const value = ref(1000)

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


</script>

<style scoped>
.n-card {
  padding: 2px;
  margin-bottom: 0.5rem;
}

.center-title::v-deep .n-card-header__main {
  text-align: center;
  font-size: 30px;
}
</style>
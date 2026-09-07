<template>
  <div>
    <div class="admin-page-header">
      <div>
        <h2 class="admin-page-title">站点档案</h2>
        <p class="admin-page-desc">
          单记录表单 · 读取 GET /api/profile · 保存 PUT /api/admin/profile
        </p>
      </div>
    </div>

    <div v-if="loading" class="skeleton-block">
      <div class="skeleton-line" style="width: 70%"></div>
      <div class="skeleton-line" style="width: 85%"></div>
      <div class="skeleton-line" style="width: 60%"></div>
    </div>

    <el-form v-else :model="form" label-width="110px" class="admin-form-card">
      <el-form-item label="站点名称" required>
        <el-input v-model="form.siteName" />
      </el-form-item>
      <el-form-item label="站点标语">
        <el-input v-model="form.siteSlogan" />
      </el-form-item>
      <el-form-item label="站长昵称" required>
        <el-input v-model="form.ownerName" />
      </el-form-item>
      <el-form-item label="头衔 / 方向">
        <el-input v-model="form.ownerTitle" />
      </el-form-item>
      <el-form-item label="邮箱">
        <el-input v-model="form.email" />
      </el-form-item>
      <el-form-item label="ICP 备案号">
        <el-input v-model="form.icpNo" placeholder="例：赣ICP备2026021347号-1" />
      </el-form-item>
      <el-form-item label="备案链接">
        <el-input v-model="form.icpUrl" placeholder="https://beian.miit.gov.cn/" />
      </el-form-item>
      <el-form-item label="页脚备注">
        <el-input v-model="form.footerNote" />
      </el-form-item>
      <el-form-item>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { fetchProfile, updateProfile, type SiteProfile } from '@/api'

const form = ref<SiteProfile>({} as SiteProfile)
const loading = ref(true)
const saving = ref(false)

onMounted(async () => {
  try {
    form.value = await fetchProfile()
  } catch {
    /* 错误已由拦截器统一提示 */
  } finally {
    loading.value = false
  }
})

async function save() {
  if (!form.value.siteName || !form.value.ownerName) {
    ElMessage.warning('站点名称与站长昵称为必填项')
    return
  }
  saving.value = true
  try {
    form.value = await updateProfile(form.value)
    ElMessage.success('站点档案已保存，前台立即生效')
  } catch {
    /* 错误已由拦截器统一提示 */
  } finally {
    saving.value = false
  }
}
</script>

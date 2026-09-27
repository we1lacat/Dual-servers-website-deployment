<template>
  <div class="login-page">
    <div class="login-bg" />
    <div class="login-card">
      <div class="brand-row">
        <span class="brand">we1l<span class="dot">.</span>site</span>
        <span class="badge">Admin</span>
      </div>
      <h1>登录后台</h1>
      <p class="lead">站点内容管理</p>

      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        size="large"
        @keyup.enter="onSubmit"
      >
        <el-form-item prop="username">
          <el-input v-model="form.username" placeholder="账号" :prefix-icon="User" autocomplete="username" />
        </el-form-item>
        <el-form-item prop="password">
          <el-input
            v-model="form.password"
            type="password"
            show-password
            placeholder="密码"
            :prefix-icon="Lock"
            autocomplete="current-password"
          />
        </el-form-item>
        <el-button
          type="primary"
          class="submit"
          :loading="loading"
          @click="onSubmit"
        >
          登 录
        </el-button>
      </el-form>

      <p class="hint">
        忘记密码？暂未提供自服务重置，请在
        <code>application.yml</code> 的
        <code>we1l.auth.admin.password</code> 修改后重启。
      </p>

      <router-link to="/" class="back-link">← 回到站点</router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, FormInstance, FormRules } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { post } from '@/api/request'
import { authStore, AuthUser } from '@/auth/store'

const router = useRouter()
const route = useRoute()
const formRef = ref<FormInstance>()
const loading = ref(false)

const form = reactive({ username: '', password: '' })
const rules: FormRules = {
  username: [{ required: true, message: '请输入账号', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
}

async function onSubmit() {
  if (!formRef.value) return
  try {
    await formRef.value.validate()
  } catch {
    return
  }
  loading.value = true
  try {
    const resp = await post<{
      token: string
      expireSeconds: number
      user: AuthUser
    }>('/auth/login', form)
    authStore.save(resp.token, resp.expireSeconds, resp.user)
    ElMessage.success(`欢迎回来，${resp.user.displayName || resp.user.username}`)
    const redirect = (route.query.redirect as string) || '/admin'
    router.replace(redirect)
  } catch (err) {
    // 错误已由拦截器 toast，不再重复
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
/* 与前台 token 一致：白底极简，仅以微弱的色斑做点缀，不做夸张阴影 */
.login-page {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--bg-gray, #f7f7f5);
  padding: 24px;
  overflow: hidden;
}
.login-bg {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 25% 20%, rgba(107, 213, 160, 0.08), transparent 45%),
    radial-gradient(circle at 80% 80%, rgba(35, 131, 226, 0.06), transparent 45%);
  pointer-events: none;
}
.login-card {
  position: relative;
  width: 100%;
  max-width: 420px;
  background: #fff;
  border: 1px solid var(--border);
  border-radius: 8px;
  padding: 32px 28px 28px;
  box-shadow: 0 1px 0 rgba(15, 15, 15, 0.02);
}
.brand-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}
.brand-row .brand {
  font-size: 18px;
  font-weight: 800;
  letter-spacing: -0.4px;
  color: var(--text);
}
.brand-row .brand .dot {
  color: #6bd5a0;
}
.brand-row .badge {
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 1px;
  padding: 3px 9px;
  border-radius: 99px;
  background: rgba(35, 131, 226, 0.1);
  color: var(--blue);
}
.login-card h1 {
  font-size: 22px;
  font-weight: 700;
  margin: 0 0 6px;
  color: var(--text);
}
.lead {
  color: var(--text-secondary);
  font-size: 13.5px;
  margin: 0 0 24px;
}
.submit {
  width: 100%;
  margin-top: 4px;
}
.hint {
  margin-top: 22px;
  font-size: 12px;
  color: var(--text-faint);
  line-height: 1.75;
}
.hint code {
  font-size: 11.5px;
}
.back-link {
  display: inline-block;
  margin-top: 20px;
  font-size: 13px;
  color: var(--text-secondary);
}
.back-link:hover {
  color: var(--blue);
}

/* login 表单进一步贴近主区风格（去掉 el-input 自带的粗边框） */
.login-card :deep(.el-input__wrapper) {
  box-shadow: 0 0 0 1px var(--border) inset;
  border-radius: var(--radius);
}
.login-card :deep(.el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px var(--border-strong) inset;
}
.login-card :deep(.el-input__wrapper.is-focus) {
  box-shadow: 0 0 0 1px var(--blue) inset !important;
}

/* ---------- 移动端适配 ----------
   用 dvh 替代 vh：手机浏览器地址栏收起/展开时不会导致页面高度跳动 */
@media (max-width: 768px) {
  .login-page {
    min-height: 100dvh;
    padding: 18px 14px calc(24px + env(safe-area-inset-bottom));
    align-items: flex-start;
  }
  .login-card {
    padding: 24px 18px 22px;
    border-radius: 10px;
    margin-top: 6vh;
  }
  .login-card h1 { font-size: 20px; }
  .lead { font-size: 13px; margin: 0 0 20px; }
  .submit { height: 42px; }
  .hint { margin-top: 18px; font-size: 11.5px; }
}
</style>

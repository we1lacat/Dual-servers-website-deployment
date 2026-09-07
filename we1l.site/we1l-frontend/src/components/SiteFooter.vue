<template>
  <footer class="site-footer">
    <div v-if="profile">
      <div>{{ profile.siteName }} · {{ profile.siteSlogan }}</div>
      <div>
        © 2026 {{ profile.ownerName }} ·
        <a :href="mailto">{{ profile.email }}</a>
      </div>
      <div>
        <a v-if="profile.icpNo" :href="profile.icpUrl || '#'" target="_blank" rel="noopener">{{ profile.icpNo }}</a>
        <span v-if="profile.icpNo && profile.footerNote"> · </span>
        <span v-if="profile.footerNote">{{ profile.footerNote }}</span>
      </div>
    </div>
    <div v-else>© 2026 we1l.site · Powered by Spring Boot + Vue 3</div>
    <div class="beian-row">
      <a
        class="beian-item"
        href="https://beian.mps.gov.cn/#/query/webSearch?code=36070302361481"
        target="_blank"
        rel="noopener noreferrer"
      >
        <img class="beian-icon" src="/beian.png" alt="公安备案图标" />
        <span>赣公网安备36070302361481号</span>
      </a>
    </div>
  </footer>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { fetchProfile, type SiteProfile } from '@/api'

const profile = ref<SiteProfile | null>(null)
const mailto = computed(() => (profile.value?.email ? `mailto:${profile.value.email}` : '#'))

fetchProfile().then((p) => { profile.value = p }).catch(() => {})
</script>

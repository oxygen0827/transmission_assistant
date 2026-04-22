<template>
  <div class="page">
    <div class="detail-bg"></div>
    <header class="app-hdr">
      <button class="app-back" @click="$router.back()">‹</button>
      <span class="app-hdr-ttl">文件详情</span>
      <button class="app-hdr-act" @click="confirmDelete" title="删除">🗑</button>
    </header>

    <div class="app-body">
      <div v-if="loading" class="center-tip">加载中...</div>
      <div v-else-if="!file" class="center-tip">文件不存在</div>

      <template v-else>
        <!-- Hero -->
        <div class="hero gc">
          <div class="hero-glow"></div>
          <div class="hero-icon">{{ typeIcon }}</div>
          <div class="hero-name">{{ file.original_filename }}</div>
          <div class="hero-badges">
            <span class="type-chip" :class="file.type">{{ typeLabel }}</span>
            <span class="status-chip" :class="file.status">{{ statusLabel }}</span>
          </div>
          <div class="hero-time">{{ timeStr }}</div>
        </div>

        <!-- AI Summary -->
        <div class="info-card gc">
          <div class="card-label">AI 简介</div>
          <div v-if="file.status === 'pending'" class="state-row">
            <div class="mini-orb"></div>
            <span>AI 分析中，请稍候...</span>
            <button class="action-link" @click="triggerAnalyze" :disabled="analyzing">立即分析</button>
          </div>
          <div v-else-if="file.status === 'failed'" class="state-row failed">
            <span>✕ {{ file.error || '分析失败' }}</span>
            <button class="action-link" @click="triggerAnalyze" :disabled="analyzing">重试</button>
          </div>
          <template v-else>
            <div class="summary-text">{{ file.summary || '暂无简介' }}</div>
            <div v-if="file.description" class="desc-text">{{ file.description }}</div>
          </template>
        </div>

        <!-- Keywords -->
        <div v-if="file.keywords?.length" class="info-card gc">
          <div class="card-label">关键词</div>
          <div class="kw-row">
            <span v-for="kw in file.keywords" :key="kw" class="kw-tag">{{ kw }}</span>
          </div>
        </div>

        <!-- Highlights -->
        <div v-if="file.highlights?.length" class="info-card gc">
          <div class="card-label">亮点</div>
          <ul class="highlight-list">
            <li v-for="h in file.highlights" :key="h">{{ h }}</li>
          </ul>
        </div>

        <!-- Link -->
        <div v-if="file.url" class="info-card gc">
          <div class="card-label">原始链接</div>
          <a :href="file.url" target="_blank" class="link-url">{{ file.url }}</a>
        </div>

        <!-- Actions -->
        <div class="actions">
          <a v-if="file.type !== 'link'"
            :href="`/api/files/${file.id}/download`"
            class="btn-primary" download>
            ⬇ 下载文件
          </a>
          <a v-if="file.url" :href="file.url" target="_blank" class="btn-primary">
            🔗 打开链接
          </a>
          <button v-if="file.status !== 'ready'"
            class="btn-secondary" @click="triggerAnalyze" :disabled="analyzing">
            {{ analyzing ? '分析中...' : '🤖 AI 分析' }}
          </button>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getFile, analyzeFile, deleteFile } from '../api/files'

const route = useRoute()
const router = useRouter()
const file = ref(null)
const loading = ref(true)
const analyzing = ref(false)

const ICONS  = { image:'🖼', video:'🎬', document:'📄', audio:'🎵', link:'🔗', other:'📦' }
const LABELS = { image:'图片', video:'视频', document:'文档', audio:'音频', link:'链接', other:'其他' }
const SLABELS = { pending:'分析中', ready:'已完成', failed:'分析失败' }

const typeIcon   = computed(() => ICONS[file.value?.type]   || '📦')
const typeLabel  = computed(() => LABELS[file.value?.type]  || '其他')
const statusLabel = computed(() => SLABELS[file.value?.status] || '')

const timeStr = computed(() => {
  if (!file.value?.created_at) return ''
  return new Date(file.value.created_at)
    .toLocaleString('zh-CN', { year:'numeric', month:'2-digit', day:'2-digit', hour:'2-digit', minute:'2-digit' })
})

async function load() {
  loading.value = true
  try { file.value = await getFile(route.params.id) }
  finally { loading.value = false }
}

async function triggerAnalyze() {
  analyzing.value = true
  try { await analyzeFile(file.value.id); await load() }
  finally { analyzing.value = false }
}

async function confirmDelete() {
  if (!confirm(`删除「${file.value?.original_filename}」？`)) return
  await deleteFile(file.value.id)
  router.back()
}

onMounted(load)
</script>

<style scoped>
.page { position: relative; height: 100%; background: var(--bg); display: flex; flex-direction: column; overflow: hidden; }
.detail-bg {
  position: absolute; inset: 0; pointer-events: none;
  background: radial-gradient(ellipse 300px 240px at 50% 0%, rgba(139,114,255,.1) 0%, transparent 65%), var(--bg);
}

.app-hdr {
  position: relative; z-index: 10; height: 90px;
  display: flex; align-items: flex-end; padding: 0 16px 14px; gap: 8px;
  background: var(--bg-blur); backdrop-filter: blur(20px);
  border-bottom: 1px solid var(--border); flex-shrink: 0;
}
.app-back {
  width: 32px; height: 32px; border: none; background: none;
  color: var(--accent); font-size: 26px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}
.app-hdr-ttl { font-size: 17px; font-weight: 700; color: var(--text); flex: 1; }
.app-hdr-act {
  width: 32px; height: 32px; border-radius: 50%;
  background: var(--s2); border: 1px solid var(--border);
  color: var(--text2); font-size: 16px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: background .15s;
}
.app-hdr-act:hover { background: rgba(255,110,122,.15); color: var(--red); }

.app-body {
  flex: 1; overflow-y: auto;
  padding: 14px 16px 32px;
  display: flex; flex-direction: column; gap: 10px;
  position: relative; z-index: 1;
}

.center-tip { text-align: center; color: var(--text3); font-size: 13px; padding: 40px; }

/* Hero card */
.hero {
  padding: 24px 18px; text-align: center;
  border-radius: var(--radius);
  background: var(--s2); border: 1px solid var(--border2);
}
.hero-glow {
  position: absolute; top: -40px; right: -40px;
  width: 140px; height: 140px;
  background: radial-gradient(circle, var(--accent-g) 0%, transparent 70%);
  pointer-events: none;
}
.hero-icon { font-size: 52px; margin-bottom: 10px; }
.hero-name {
  font-size: 15px; font-weight: 700; color: var(--text);
  word-break: break-all; margin-bottom: 10px;
}
.hero-badges { display: flex; gap: 8px; justify-content: center; margin-bottom: 8px; }
.hero-time { font-size: 11px; color: var(--text3); }

.type-chip {
  font-size: 11px; font-weight: 600; padding: 3px 9px; border-radius: 8px;
}
.type-chip.image    { background: rgba(139,114,255,.15); color: var(--accent); }
.type-chip.video    { background: rgba(255,110,122,.15); color: var(--red); }
.type-chip.document { background: rgba(94,234,181,.15);  color: var(--teal); }
.type-chip.audio    { background: rgba(255,170,92,.15);  color: var(--orange); }
.type-chip.link     { background: rgba(100,170,255,.15); color: #64AAFF; }
.type-chip.other    { background: var(--s3);             color: var(--text3); }

.status-chip { font-size: 11px; padding: 3px 9px; border-radius: 8px; }
.status-chip.pending { background: rgba(255,170,92,.15); color: var(--orange); }
.status-chip.ready   { background: rgba(94,234,181,.15); color: var(--teal); }
.status-chip.failed  { background: rgba(255,110,122,.15); color: var(--red); }

/* Info cards */
.info-card {
  padding: 14px 16px; border-radius: var(--radius);
  background: var(--s2); border: 1px solid var(--border);
}
.card-label {
  font-size: 10px; font-weight: 600; color: var(--text3);
  letter-spacing: .08em; text-transform: uppercase; margin-bottom: 9px;
}

.state-row {
  display: flex; align-items: center; gap: 8px;
  font-size: 13px; color: var(--text2);
}
.state-row.failed { color: var(--red); }
.mini-orb {
  width: 14px; height: 14px; border-radius: 50%;
  border: 2px solid rgba(139,114,255,.3);
  border-top-color: var(--accent);
  animation: spin .8s linear infinite; flex-shrink: 0;
}
@keyframes spin { to { transform: rotate(360deg); } }
.action-link {
  margin-left: auto; background: none; border: none;
  color: var(--accent); font-size: 12px; font-weight: 600;
  cursor: pointer; padding: 4px 10px;
  border: 1px solid rgba(139,114,255,.3); border-radius: 10px;
}
.action-link:disabled { opacity: .4; cursor: not-allowed; }

.summary-text { font-size: 15px; font-weight: 600; color: var(--text); line-height: 1.5; }
.desc-text { font-size: 13px; color: var(--text2); margin-top: 6px; line-height: 1.65; }

.kw-row { display: flex; flex-wrap: wrap; gap: 6px; }
.kw-tag {
  padding: 4px 11px; border-radius: 20px;
  background: var(--s1); border: 1px solid var(--border2);
  font-size: 12px; color: var(--text2);
}

.highlight-list { list-style: none; display: flex; flex-direction: column; gap: 7px; }
.highlight-list li {
  font-size: 13px; color: var(--text2); line-height: 1.6;
  padding-left: 16px; position: relative;
}
.highlight-list li::before {
  content: '✓'; position: absolute; left: 0;
  color: var(--teal); font-weight: 700;
}

.link-url {
  font-size: 13px; color: var(--accent); word-break: break-all; text-decoration: none;
}
.link-url:hover { text-decoration: underline; }

/* Actions */
.actions { display: flex; flex-direction: column; gap: 8px; padding-top: 4px; }
.btn-primary {
  display: flex; align-items: center; justify-content: center;
  height: 48px; border-radius: 14px; border: none;
  background: var(--accent); color: #fff;
  font-size: 15px; font-weight: 700; font-family: inherit;
  cursor: pointer; text-decoration: none;
  box-shadow: 0 4px 18px var(--accent-g);
  transition: transform .15s, box-shadow .15s;
}
.btn-primary:active { transform: scale(.97); }

.btn-secondary {
  height: 48px; border-radius: 14px;
  background: var(--accent-s); border: 1.5px solid rgba(139,114,255,.25);
  color: var(--accent); font-size: 15px; font-weight: 700;
  font-family: inherit; cursor: pointer;
  transition: transform .15s;
}
.btn-secondary:active { transform: scale(.97); }
.btn-secondary:disabled { opacity: .4; cursor: not-allowed; }
</style>

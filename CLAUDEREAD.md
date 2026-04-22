# Claude 项目速览 — 文件传输助手

> 供下次 Claude 会话直接读取，了解项目全貌与当前状态。
> 最后更新：2026-04-22

## 项目概述

**文件传输助手** — 个人用途的仿微信传输助手风格文件收集管理工具。
- 运行在本地，手机框样式 UI（390×844px，自适应缩放）
- 用户：单用户，无登录，无鉴权
- 存储：本地文件系统 + JSON 元数据，无数据库

## 技术架构

```
FastAPI (port 8000)  ←→  Vue3+Vite (port 5173, 开发时 proxy 到后端)
```

- **前端框架**：Vue 3 Composition API + Vue Router，无状态管理库
- **构建工具**：Vite，proxy `/api` → `http://localhost:8000`
- **后端框架**：FastAPI + Uvicorn，BackgroundTasks 处理异步分析
- **AI 服务**：智谱 ZhipuAI GLM-4-Flash（文本）+ GLM-4V-Flash（图像视觉）
- **实时推送**：SSE（Server-Sent Events），`/api/files/events` 端点

## 关键文件地图

### 后端

| 文件 | 职责 |
|---|---|
| `backend/main.py` | FastAPI app，CORS，静态文件挂载 |
| `backend/models/file.py` | `FileSummary`（完整模型）、`FileListItem`（列表响应）、枚举类 |
| `backend/routers/files.py` | 所有 API 路由，含 `/events` SSE 端点 |
| `backend/services/storage.py` | 文件读写，JSON 元数据，按 `data/files/日期/类型/` 层级存储 |
| `backend/services/analyzer.py` | AI 分析入口，各类型分发，分析完毕 emit SSE 事件；含 `search_files` |
| `backend/services/url_classifier.py` | 链接分类（微信/B站/通用），BeautifulSoup 抓取，LinkBox API 预留 |
| `backend/services/events.py` | SSE 事件总线（asyncio.Queue），subscribe/emit/stream |
| `backend/utils/config.py` | 读取 .env，定义 DATA_DIR、GLM 配置、LINKBOX 占位 |

### 前端

| 文件 | 职责 |
|---|---|
| `frontend/src/App.vue` | 手机框容器，JS 计算 `--phone-scale` CSS 变量，路由出口 |
| `frontend/src/views/Home.vue` | 主页：微信聊天风格气泡，右对齐，按日期升序分组，加载后滚到底部 |
| `frontend/src/views/Category.vue` | 分类磁贴网格（3列），点击展开时间线（年→月→日），底部 AI 搜索栏 |
| `frontend/src/views/DayFiles.vue` | 某天文件页：显示指定日期+类型的所有文件，底部 AI 搜索栏 |
| `frontend/src/views/Search.vue` | AI 搜索页，支持 `?date=` / `?type=` / `?q=` 参数 |
| `frontend/src/views/FileDetail.vue` | 文件详情：AI 摘要、关键词、亮点、下载/删除 |
| `frontend/src/components/FileCard.vue` | 文件卡片：含左滑删除手势 |
| `frontend/src/components/ChatBox.vue` | AI 聊天框，打字机效果（响应式修复），人格化话术，支持 date/fileType/initialQ props |
| `frontend/src/api/files.js` | axios 封装所有接口，`searchFiles(q, date, type)` |

## 路由表

| 路径 | 组件 | 说明 |
|---|---|---|
| `/` | Home.vue | 主页（微信聊天风格） |
| `/category` | Category.vue | 文件分类 + 时间线 |
| `/day?date=&type=` | DayFiles.vue | 某天某类型的所有文件 |
| `/search?q=&date=&type=` | Search.vue | AI 语义搜索 |
| `/file/:id` | FileDetail.vue | 文件详情 |

## 数据模型（`FileSummary`）

```python
id, filename, original_filename, type(image/video/document/audio/link/other),
url, file_path, file_size, mime_type,
summary, description, keywords[], highlights[],
og_image, favicon_url,          # 链接类型专用，OG 抓取填充
created_at, analyzed_at, status(pending/ready/failed), error
```

## 核心逻辑

### 上传流程
1. 前端 POST `/api/files/upload`（FormData）
2. 后端 `storage.save_file / save_link` 写入磁盘 + JSON 元数据
3. `BackgroundTasks.add_task(analyzer.analyze_file, meta)` 异步分析
4. 分析完毕 → `save_meta` 更新 JSON → `events.emit` 推送 SSE
5. 前端 `EventSource` 收到事件，原地更新 `files.value[idx]`

### 主页展示逻辑（`Home.vue`）
- 文件按 `created_at` **升序**分组（最旧在上，最新在下）
- 页面加载后自动 `scrollTo(scrollHeight)`，用户看到的是最新文件
- 左滑屏幕（drag > 60px）或手指左滑 → `router.push('/category')`
- 鼠标拖拽也支持：`onMouseDown/Move/Up`
- 上传成功后同样滚动到底部

### 分类时间线（`Category.vue`）
- 点击磁贴展开，不再显示文件列表，而是时间线树
- 时间线按 **年 → 月 → 日** 分组，显示每天文件数
- 点击某天 → `router.push('/day?date=YYYY-MM-DD&type=xxx')`
- 底部常驻 AI 搜索栏 → `router.push('/search?q=&type=')`

### DayFiles 页面（`DayFiles.vue`）
- 读取 `?date=` 和 `?type=` query 参数
- 获取全部文件后客户端过滤，按时间升序排列
- 卡片显示图片缩略图 / 链接封面 / 文件图标 + 摘要
- 底部搜索框 → `router.push('/search?q=&date=&type=')`（限定日期+类型范围）

### ChatBox.vue 响应式修复
- **Bug**：`msg` push 进 `messages.value` 后 Vue 包成 proxy，但 `typewrite(msg, ...)` 持有原始对象引用，修改 `msg.display` 不触发重渲染
- **Fix**：push 后立即 `const msg = messages.value[messages.value.length - 1]` 取响应式版本

### AI 话术人格化（`ChatBox.vue`）
- `pick(arr)` 随机取数组元素
- `replyText(results)` 按结果数（0/1/2-3/4+）返回不同风格文案（每种 5-6 条）
- 包含引导语如"可以继续描述更多信息，我帮你缩小范围~"

### 链接 OG 抓取（`url_classifier.py`）
- 微信公众号：BeautifulSoup 解析 HTML，提取标题/正文/封面，GLM 生成摘要
- LinkBox API：预留通道，`.env` 填入 `LINKBOX_API_URL/KEY` 后自动接管
- B站：官方 API 获取封面/标题/UP主
- 通用：httpx 抓取 og:title / og:image / favicon

### 手机框缩放（`App.vue`）
```js
const s = Math.min(1, (window.innerHeight - 40) / 844, (window.innerWidth - 40) / 390)
document.documentElement.style.setProperty('--phone-scale', s)
```

## CSS 设计系统

所有颜色通过 CSS 自定义属性，在 `App.vue` 的 `:root[data-theme]` 定义：
- `--bg`, `--bg-blur`, `--card`, `--s1/s2/s3`（层次背景）
- `--text`, `--text2`, `--text3`
- `--accent`（紫色 #8B72FF），`--teal`（青绿），`--red`，`--orange`
- `--accent-g`（accent 的 glow 色），`--accent-s`（accent 的淡背景）
- `--border`, `--border2`, `--radius`
- 动效曲线：`cubic-bezier(.32,.72,0,1)`

## 当前功能清单

- [x] 文件上传（多选、粘贴、拖拽）
- [x] 链接保存（含公众号、B站、通用）
- [x] 语音输入（Web Speech API，仅 Chrome）
- [x] AI 分析（图片视觉/文档文本/链接OG/视频音频基础）
- [x] SSE 实时分析状态推送
- [x] AI 语义搜索（GLM，score≥0.6，宁少勿滥）
- [x] 主页微信聊天风格，日期分组气泡，最新在底部
- [x] 左滑屏幕跳转分类页（触摸 + 鼠标拖拽均支持）
- [x] 分类页时间线（年→月→日），点某天跳 DayFiles 页
- [x] DayFiles 页：某天某类型全部文件 + 底部限定范围 AI 搜索
- [x] ChatBox 人格化话术（随机多变，打字机效果响应式修复）
- [x] 文件详情页（摘要/关键词/亮点/下载）
- [x] 深色/浅色主题切换
- [x] 手机框自适应缩放
- [x] LinkBox API 预留通道（填 .env 即生效）

## 已知限制

- 无分页，最多加载 200 条
- 视频/音频 AI 分析为基础元信息（无转录）
- 无多用户，无权限控制
- 数据存本地 `data/files/`，无备份机制

## 环境配置（.env）

```env
GLM_API_KEY=your_key
GLM_MODEL=glm-4-flash
GLM_VISION_MODEL=glm-4v-flash
MAX_FILE_SIZE_MB=50
CORS_ORIGINS=http://localhost:5173,http://localhost:3000

# 拿到后填入，自动接管公众号/通用链接解析
LINKBOX_API_URL=
LINKBOX_API_KEY=
```

## 启动命令

```bash
# 后端（项目根目录）
$env:PYTHONPATH = $PWD
uvicorn backend.main:app --reload --port 8000

# 前端
cd frontend && npm run dev

# 或一键启动（Windows）
start_dev.bat
```

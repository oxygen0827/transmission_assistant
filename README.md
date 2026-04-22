# 文件传输助手

> 一个仿微信传输助手风格的个人文件管理工具，支持文件上传、链接收藏、AI 内容理解与智能搜索。

## 功能特性

- **微信风格主页** — 文件以聊天气泡形式展示，右对齐，最新文件在底部，往上滚查看历史
- **多格式收集** — 图片、视频、文档、音频、链接，粘贴/拖拽/点击 `+` 均可上传
- **AI 自动分析** — 上传后自动调用智谱 GLM，生成摘要、关键词、亮点
- **公众号链接解析** — BeautifulSoup 抓取微信文章正文，GLM 生成摘要；支持接入 LinkBox API
- **链接富预览** — 自动抓取 OG 封面图、favicon；B站链接走官方 API 获取封面与简介
- **实时状态推送** — 后端分析完成即通过 SSE 推送到前端，无需手动刷新
- **AI 智能搜索** — 自然语言搜索文件内容，支持按日期、类型过滤
- **分类时间线** — 左滑进入分类页，点击分类后显示年→月→日时间线，点某天查看当天所有文件
- **范围限定搜索** — DayFiles 页底部 AI 搜索框自动限定日期+类型范围，快速定位文件
- **左滑删除** — iOS 原生交互风格，滑动卡片显示删除按钮
- **深色 / 浅色主题** — 系统级切换，持久化到 localStorage
- **手机框缩放** — 在桌面端也以手机比例呈现，自适应窗口大小

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Vue 3 + Vite + Vue Router |
| 后端 | FastAPI + Uvicorn |
| AI | 智谱 ZhipuAI GLM-4-Flash / GLM-4V-Flash |
| 链接解析 | BeautifulSoup4 + httpx（LinkBox API 预留） |
| 存储 | 本地文件系统 + JSON 元数据 |
| 实时推送 | Server-Sent Events (SSE) |

## 快速开始

### 1. 配置环境变量

在 `file-assistant/` 目录创建 `.env` 文件：

```env
GLM_API_KEY=your_zhipuai_api_key
GLM_MODEL=glm-4-flash
GLM_VISION_MODEL=glm-4v-flash
MAX_FILE_SIZE_MB=50

# 可选：LinkBox API（填入后自动接管公众号/通用链接解析）
LINKBOX_API_URL=
LINKBOX_API_KEY=
```

> 前往 [智谱 AI 开放平台](https://open.bigmodel.cn/) 注册获取 API Key。

### 2. 安装后端依赖

```bash
pip install -r requirements.txt
```

### 3. 一键启动（Windows）

```bat
start_dev.bat
```

或手动启动：

```bash
# 后端（file-assistant/ 目录）
$env:PYTHONPATH = $PWD
uvicorn backend.main:app --reload --port 8000

# 前端（新窗口）
cd frontend && npm run dev
```

### 4. 打开应用

浏览器访问 `http://localhost:5173`

---

## 界面导航

| 操作 | 效果 |
|---|---|
| 主页左滑 | 进入文件分类页 |
| 点击分类磁贴 | 展开该类型时间线（年/月/日） |
| 点击时间线某天 | 查看当天该类型全部文件 |
| 底部 AI 搜索框 | 自然语言搜索，自动限定当前日期/类型范围 |
| 点击日期分隔线 | 进入 AI 搜索页（按日期过滤） |
| 左滑文件卡片 | 显示删除按钮 |

---

## 目录结构

```
file-assistant/
├── backend/
│   ├── main.py                # FastAPI 入口
│   ├── models/file.py         # Pydantic 数据模型
│   ├── routers/files.py       # API 路由（含 SSE 端点）
│   ├── services/
│   │   ├── analyzer.py        # AI 分析逻辑 + 语义搜索
│   │   ├── storage.py         # 文件存储与元数据
│   │   ├── url_classifier.py  # 链接分类、OG 抓取、LinkBox API
│   │   └── events.py          # SSE 事件总线
│   └── utils/config.py        # 环境配置
├── frontend/src/
│   ├── views/
│   │   ├── Home.vue           # 主页（微信聊天风格，右对齐气泡）
│   │   ├── Category.vue       # 分类磁贴 + 时间线
│   │   ├── DayFiles.vue       # 某天某类型的全部文件
│   │   ├── Search.vue         # AI 语义搜索页
│   │   └── FileDetail.vue     # 文件详情
│   ├── components/
│   │   ├── ChatBox.vue        # AI 对话组件（打字机效果 + 人格化话术）
│   │   └── FileCard.vue       # 文件卡片（左滑删除）
│   └── api/files.js           # API 封装
├── data/files/                # 文件存储目录（自动创建）
├── requirements.txt
├── start_dev.bat              # Windows 一键启动
└── 启动说明.md
```

## API 概览

| 方法 | 路径 | 说明 |
|---|---|---|
| POST | `/api/files/upload` | 上传文件或链接 |
| GET | `/api/files` | 文件列表 |
| GET | `/api/files/search?q=` | AI 语义搜索 |
| GET | `/api/files/events` | SSE 实时推送端点 |
| GET | `/api/files/stats` | 统计信息（含 by_type） |
| GET | `/api/files/{id}` | 文件详情 |
| DELETE | `/api/files/{id}` | 删除文件 |
| GET | `/api/files/{id}/download` | 下载文件 |
| POST | `/api/files/{id}/analyze` | 手动触发 AI 分析 |

## 许可证

MIT

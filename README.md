# 用户快速上手指南

> 本指南面向**普通用户**，从零开始完成 Worker 子服务和油猴脚本的安装配置。
> 你不需要了解代码，只需按步骤操作即可。

---

## 一、你会得到什么

通过脚本可以下载到以下三个文件：

| 文件 | 说明 |
|------|------|
| `music-worker.js` | Worker 子服务，运行在你的本地电脑或海外服务器上，负责从 Qobuz 下载音乐 |
| `.env` | Worker 配置文件，填写服务器地址和本地下载目录 |
| `music-upload-tampermonkey.user.js` | 油猴脚本安装文件，安装后在浏览器中使用 |

> **提示**：`.env` 可能不可见（以 `.` 开头的隐藏文件），需要开启系统显示隐藏文件。

---

## 二、安装 Node.js 运行环境

Worker 需要 Node.js 22 或更高版本才能运行。

### Linux (Ubuntu/Debian, 默认使用root账号)

```bash
apt install build-essential libssl-dev && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

nvm install v24.12.0
npm install -g pm2
```

---

## 三、安装系统依赖工具

Worker 下载专辑后会自动生成频谱图和种子文件，需要以下工具：

| 工具 | 用途 |
|------|------|
| `sox` | 生成频谱图（spectrogram） |
| `mktorrent` | 生成 .torrent 种子文件 |
| `flac` | FLAC 无损压缩处理 |
| `ffmpeg` | FLAC 转 MP3 V0 格式 |

### Linux (Ubuntu/Debian)

```bash
apt install -y sox mktorrent flac ffmpeg
```

---

## 四、一键下载 Worker 文件并启动服务（推荐）

在 Linux 服务器终端中，首次执行以下命令即可自动下载最新版本的全部文件，并在用户目录下生成 `music-worker` 文件夹，启动worker服务：

```bash
cd ~/ && rm -rf ~/music-worker && bash <(curl -fsSL https://raw.githubusercontent.com/oj8kr/music_upload/main/start.sh) && cd ~/music-worker && pm2 start music-worker.js --name music-upload-worker && pm2 logs music-upload-worker
```

下载完成后，进入目录编辑配置文件（非必要无需编辑修改）：

```bash
nano ./music-worker/.env
```


如需手动下载文件，请参考下一节。

---

## 五、手动配置 Worker

### 1. 整理文件

将解压后的三个文件放入同一目录，例如：

```
~/music-worker/
├── music-worker.js
└── .env
```

### 2. 编辑 `.env` 配置文件

用任意文本编辑器打开 `.env`（macOS 可用 TextEdit，Windows 用记事本），按实际情况填写：

```dotenv
# 主服务地址
MAIN_SERVICE_URL=https://admin.hostmails.de

# 专辑下载保存目录（使用你本地电脑的绝对路径）
DOWNLOAD_DIR=/home/downloads

# RED MP3 补全专用种子下载目录（与 DOWNLOAD_DIR 独立，可自定义）
RED_FILL_DOWNLOAD_DIR=/home/downloads/red-fill

# qBittorrent 保存目录：点击下载时推送种子到 qBittorrent 所使用的 savepath
QBITTORRENT_DOWNLOAD_DIR=/home/downloads/red-fill

# Worker 本地监听端口（默认 36501，一般不需要修改）
PORT=36501

# 调度间隔，单位毫秒（默认 10000 = 10秒，一般不需要修改）
SCHEDULER_INTERVAL_MS=10000
```

**注意事项：**
- `MAIN_SERVICE_URL` 末尾**不要加斜杠**
- `DOWNLOAD_DIR` 使用绝对路径，目录需要存在（若不存在请先创建）
- `RED_FILL_DOWNLOAD_DIR` 控制 RED MP3 补全的种子下载与 FLAC→MP3 扫描根目录，仅 Worker 使用
- `QBITTORRENT_DOWNLOAD_DIR` 是点击「下载」时推送种子到 qBittorrent 的保存路径（`savepath`），无论单个专辑还是批量下载均使用此目录；通常与 `RED_FILL_DOWNLOAD_DIR` 保持一致，如果你的 qBittorrent 挂载路径与 Worker 不同时才需要单独设置
- Windows 路径示例：`DOWNLOAD_DIR=C:/Users/yourname/Music/downloads`

创建下载目录（若不存在）：
```bash
# Linux
mkdir -p /home/download
```

---

## 六、手动启动 Worker

### 基本启动方式

在终端（macOS / Linux）或命令提示符（Windows）中进入 Worker 目录，运行：

```bash
cd ~/music-worker
node music-worker.js
```

启动成功后，你会看到类似输出：

```
[WorkerScheduler] 调度器已启动，间隔 10000ms
Server listening at http://0.0.0.0:36501
```

> 保持此终端窗口**不要关闭**，关闭窗口会停止 Worker。

### 后台常驻运行（推荐）

如果不希望一直开着终端窗口，可以使用 PM2 在后台运行：

```bash
# 安装 PM2（全局安装，只需一次）
npm install -g pm2

# 进入 Worker 目录，后台启动
cd ~/music-worker
pm2 start music-worker.js --name music-upload-worker

# 设置开机自启（按提示执行输出的命令）
pm2 save
pm2 startup
```

常用 PM2 命令：

```bash
pm2 status                           # 查看运行状态
pm2 logs music-upload-worker         # 查看实时日志
pm2 restart music-upload-worker      # 重启
pm2 stop music-upload-worker         # 停止
```

---

## 七、安装油猴脚本

### 1. 安装 Tampermonkey 浏览器扩展

| 浏览器 | 安装地址 |
|--------|---------|
| Chrome | Chrome 应用商店搜索「Tampermonkey」 |
| Firefox | Firefox 附加组件搜索「Tampermonkey」 |
| Edge | Edge 应用商店搜索「Tampermonkey」 |
| Safari | App Store 搜索「Tampermonkey」 |

### 2. 安装脚本

**方式一（推荐）：直接拖拽安装**

将 `music-upload-tampermonkey.user.js` 文件拖拽到浏览器窗口中，Tampermonkey 会弹出安装确认页面，点击「安装」即可。

**方式二：通过 Release 链接安装**

管理员提供的 Release 链接示例：
```
https://github.com/oj8kr/music_upload/releases/latest/download/music-upload-XXXX.zip
```

解压后同样拖拽 `.user.js` 文件安装。

### 3. 确认安装成功

点击浏览器右上角的 Tampermonkey 图标，在「已安装脚本」列表中能看到「Music Upload Helper」，即为安装成功。

---

## 八、配置油猴脚本

安装脚本后，访问 [qobuz.com](https://play.qobuz.com/) 的专辑页面，右上角会出现一个浮动面板。

### 1. 基本连接配置

点击面板中的**设置**（齿轮图标），填写以下信息：

| 字段 | 说明 | 示例 |
|------|------|------|
| Worker URL | 你本地 Worker 的地址 | `http://localhost:36501` |
| API Key | 向管理员申请的 API Key | `9f0f88xxxxxxxx` |

填写完成后点击「保存」。

> **API Key** 是你在系统中的身份标识，由管理员在注册你的账号时分配。如果忘记，请联系管理员重置。

### 2. 从服务器同步配置

首次使用时，点击「从服务器同步」按钮，脚本会从主服务拉取以下配置（无需手动填写）：

- Qobuz 账号（邮箱 + 密码）
- PT 站 API Key（Red、Ops、GGN 等）

> 上述配置由管理员在主服务后台统一管理，你只需同步即可。

### 3. 验证连接

配置保存后，脚本会自动向 Worker 发起注册请求。注册成功后，面板状态变为「已连接」。

如连接失败，请检查：
1. Worker 是否已启动（终端中是否有运行的 `node music-worker.js` 进程）
2. Worker URL 是否正确（默认 `http://localhost:36501`）
3. API Key 是否正确

---

## 九、首次使用流程

完成以上配置后，按如下流程开始使用：

1. **进入指定站点发布页** — 在 发布页，右上角面板展示专辑列表
2. **查看专辑列表** — 可按 HiRes、已下载、上传状态等条件筛选
3. **单张下载** — 在专辑列表中点击「下载」按钮，将该专辑加入下载队列
4. **批量下载** — 按照当前筛选条件批量加入队列

Worker 会按顺序**逐张下载**，下载完成后自动生成频谱图和种子文件，保存到 `.env` 中配置的 `DOWNLOAD_DIR` 目录。

---

## 十、RED MP3 补全（Red Fill）使用指南

**RED MP3 补全**是一种补种玩法：首先抓取 RED 上**同一 group 缺少 V0/320 MP3 编码**的专辑，管理端将这些专辑分配给你；你下载对应种子、触发 FLAC→MP3 转码，最终补种到 RED。

相关交互位于油猴脚本面板的两个 tab：**📋 Actions** 与 **🎯 Red Fill Albums**。

### 1. 前置配置

- `.env` 中的 `RED_FILL_DOWNLOAD_DIR` 必须指向一个独立目录：Worker 会把 RED 补种的种子下载到这里，并以此为根做 FLAC 扫描与 MP3 转码
- `.env` 中的 `QBITTORRENT_DOWNLOAD_DIR` 是推送种子到 qBittorrent 时使用的 savepath，单个专辑下载和批量下载均使用此目录；通常与 `RED_FILL_DOWNLOAD_DIR` 相同，若 qBittorrent 的挂载路径与 Worker 不同则需单独设置
- 在「⚙ Settings → 从服务器同步」已拉取到有效的 RED API Key

### 2. 「📋 Actions」tab：发起/维护任务

此 tab 下部有「Red MP3 补全操作」区块，包含四个异步按钮。按钮执行期间会显示 ⏳ 状态，同一时刻只能有一个任务在执行。

| 按钮 | 作用 | 常见反馈 |
|------|------|---------|
| **获取 Red 可补全专辑** | 扫描本地 FLAC 目录，为每张专辑到 RED 查询缺失的 MP3 编码，匹配成功的专辑自动分配给你 | 「扫描已启动，session #N（共 X 个任务）」；已有进行中扫描会自动合流 |
| **Red 可补全专辑复查** | 对已分配给你、但 7 天内未复查的 assignment 重新拉最新状态 | 「已创建 N 条复查，跳过 M 条」 |
| **可补专辑全量查重** | 加入本 ISO 自然周全局共享的全量查重，每次领取 20 个 groupId | 「已发起/加入本周全量复查，本次领取 N 个，剩余 M 个」；本周已完成则提示「感谢支持，本周内已经复查完毕，请下周再来」 |
| **转码** | 对已下载种子触发 FLAC→MP3 转码任务 | 「转码任务已启动，taskId=N」 |

> 以上都是**异步任务**，提交完毕后请到「🎯 Red Fill Albums」tab 查看结果。

### 3. 「🎯 Red Fill Albums」tab：查看与操作认领专辑

此 tab 展示分配给你的所有 RED 补全专辑，按分配时间倒序排列，每页 20 条。

**顶部工具栏**

- **下载状态**（下拉）：全部 / 已下载 / 未下载，切换后自动按新条件刷新
- **刷新**：按当前下拉条件重新拉取最新数据；由于下载/重查是异步的，完成后需要手动点刷新查看结果

**每行展示**

| 区域 | 内容 |
|------|------|
| 专辑名称 | 固定 300px 宽，格式 `艺术家 - 专辑名 (年份) [介质] [Remaster 标题]`；超长显示省略号，鼠标悬浮可看全文 |
| 下载状态 | 「已下载」/「未下载」，以 `downloadedTorrentPath` 是否存在为准 |
| 操作 | **打开**（新标签访问 RED group 页面）、**下载**、**重查** |

**按钮语义**

- **下载**：向 Worker 提交下载任务
  - 若该行种子已下载过，立即提示「已下载」
  - 否则创建下载任务并提示「下载任务已创建，请稍后点"刷新"查看最新状态」
- **重查**：向 RED 再查一次该专辑当前缺失的编码，更新 assignment 状态；失败会在消息区显示错误原因

**分页**：总条数超过 20 时，底部出现页码按钮，点击按当前下拉条件跳转。

### 4. 典型使用流程

1. 「📋 Actions」→ **获取 Red 可补全专辑**：扫描本地库并分配专辑
2. 「🎯 Red Fill Albums」→ 下拉筛选「未下载」→ 逐条点 **下载**
3. 稍等 Worker 调度完成（每 10 秒一轮），顶部 **刷新** 查看状态变化
4. 所有专辑都 **已下载** 后，回到「📋 Actions」→ **转码**，触发 FLAC→MP3 发布流程
5. 怀疑某条状态已过期时单行点 **重查**；批量更新可用 **Red 可补全专辑复查**
6. 有空闲时点 **可补专辑全量查重**，协助社区完成每周全量查重

---

## 十一、更新 Worker

管理员发布新版本后，在 `music-worker` 目录的**上级目录**重新执行一键命令，会自动覆盖 `music-worker.js` 和 `.env`（你对 `.env` 的自定义修改会被覆盖，请提前备份），完成重启服务：

```bash
pm2 delete music-upload-worker 2>/dev/null || true && cd ~/ && rm -rf ~/music-worker && bash <(curl -fsSL https://raw.githubusercontent.com/oj8kr/music_upload/main/start.sh) && cd ~/music-worker && pm2 start music-worker.js --name music-upload-worker && pm2 logs music-upload-worker
```

查看服务日志：

```bash
pm2 logs music-upload-worker
```

> 如需保留 `.env` 自定义配置，更新前先备份：`cp music-worker/.env music-worker/.env.bak`，更新后将自定义项补回。

---

## 十二、常见问题

### Worker 启动后提示「EADDRINUSE」端口被占用

默认端口 `36501` 已被其他程序占用。在 `.env` 中修改 `PORT` 为其他值（如 `36502`），同时在油猴脚本设置中更新 Worker URL 为对应端口。

### 油猴脚本面板不出现

确认：
- Tampermonkey 扩展已安装且已启用
- 脚本状态为「已启用」（在 Tampermonkey 图标 → 已安装脚本中确认）
- 当前页面是 qobuz.com 或支持的 PT 站（非 qobuz.com 页面需访问上传/种子列表页）

### 下载任务一直「待处理」没有开始

确认 Worker 正在运行（终端窗口未关闭，或 `pm2 status` 显示 `online`）。Worker 每 10 秒调度一次，稍等片刻即可。

### 下载目录没有生成文件

检查 `.env` 中 `DOWNLOAD_DIR` 目录是否存在，以及当前用户是否有写权限：

```bash
ls -la /home/yourname/downloads   # 确认目录存在
touch /home/yourname/downloads/test.txt && rm /home/yourname/downloads/test.txt  # 确认有写权限
```

### API Key 不正确 / 401 错误

联系管理员确认你的 API Key，或请管理员在后台重置。

---

## 附录：支持的 PT 站页面

油猴脚本会在以下页面自动注入面板：

| 站点 | 页面 |
|------|------|
| Qobuz | 专辑页面 |
| Redacted (RED) | upload.php |
| Orpheus (OPS) | upload.php |
| DicMusic | upload.php |
| GazelleGames (GGN) | upload.php |
| PterClub | upload.php |
| Open.cd | upload.php |
| TJUPT | upload.php |

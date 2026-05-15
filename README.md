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
pm2 delete music-upload-worker 2>/dev/null || true && cd ~/ && rm -rf ~/music-worker && bash <(curl -fsSL https://raw.githubusercontent.com/oj8kr/music_upload/main/start.sh) && cd ~/music-worker && pm2 start music-worker.js --name music-upload-worker && pm2 logs music-upload-worker
```

安装完成后，会在打印日志界面，可以ctrl+c退出，进入目录编辑配置文件（非必要无需编辑修改，qBittorrent下载地址需要配置）：

```bash
nano ./music-worker/.env
```

---

## 五、安装油猴脚本

### 1. 安装 Tampermonkey 浏览器扩展

| 浏览器 | 安装地址 |
|--------|---------|
| Chrome | Chrome 应用商店搜索「Tampermonkey」 |
| Edge | Edge 应用商店搜索「Tampermonkey」 |

### 2. 安装脚本

将 `music-upload-tampermonkey.user.js` 文件拖拽到浏览器窗口中，Tampermonkey 会弹出安装确认页面，点击「安装」即可。

### 3. 确认安装成功

点击浏览器右上角的 Tampermonkey 图标，在「已安装脚本」列表中能看到「Music Upload Helper」，即为安装成功。

---

## 六、配置后管系统（Qobuz 信息与授权）

管理员为你创建账号后，需要登录后管系统填写 Qobuz 账号信息并完成 OAuth 授权，Worker 才能代你从 Qobuz 下载音乐。

**后管地址**：[https://admin.hostmails.de/admin/dashboard](https://admin.hostmails.de/admin/dashboard)

使用管理员分配的用户名和密码登录。

### 1. 填写 Qobuz 账号信息

登录后点击页面中的「**我的配置**」，进入配置页面填写：

| 字段 | 说明 |
|------|------|
| Qobuz 邮箱 | 你的 Qobuz 账号邮箱地址 |
| Qobuz 密码 | 你的 Qobuz 账号密码（留空则不修改已保存的密码） |

填写完成后点击「**保存配置**」。

> **安全说明**：密码在提交前已加密，服务器端也以加密形式存储，不会明文保留。

### 2. 完成 Qobuz OAuth 授权

Qobuz 下载还需要一个 OAuth 授权码（与账号密码独立，系统自动获取无需手动填写），请按如下步骤操作：

1. 回到**仪表板**（Dashboard）
2. 点击「**Qobuz 授权**」按钮 — 浏览器新标签页会打开 Qobuz 的授权页面
3. 在 Qobuz 页面登录你的账号并点击同意授权
4. Qobuz 授权完成后会将你重定向回本系统的登录页，页面出现绿色提示：
   > **「Qobuz 授权码已捕获，登录后将自动保存。」**
5. 输入用户名和密码登录
6. 登录后自动跳转到仪表板，页面弹出成功提示：
   > **「Qobuz 授权码已保存」**

至此 Qobuz 配置全部完成。可在「我的配置」页面的「**Qobuz OAuth 授权码**」字段确认授权码已填入（该字段只读，自动维护）。

> **注意**：OAuth 授权码有有效期。若 Worker 下载时报认证失败，请重新执行本节第 2 步完成授权。

---

## 七、配置油猴脚本

安装脚本后，访问 [qobuz.com](https://play.qobuz.com/) 的专辑页面，右上角会出现一个浮动面板。

### 1. 基本连接配置

点击面板中的**设置**（齿轮图标），填写以下信息：

| 字段 | 说明 | 示例 |
|------|------|------|
| Worker URL | 你本地 Worker 的地址（可联系管理员配置域名访问） | `http://localhost:36501` |
| API Key | 向管理员申请的 API Key（后管系统首页点击“复制API Key”） | `9f0f88xxxxxxxx` |
| PTpimg Key | ptpimg.me 图床 API Key，用于上传封面和频谱图（若发布Qobuz专辑则必填） | `xxxxxxxx-xxxx-…` |

填写完成后点击「保存」。

> **API Key** 是你在系统中的身份标识，由管理员在注册你的账号时分配。后管系统首页点击“复制API Key”可获取，若泄露可联系管理员进行重置。
>
> **PTpimg Key** 不配置时可正常触发下载。但在 PT 上传页点击「加载」时，若该专辑的封面或频谱图尚未转换为 ptpimg 格式，脚本会弹出提示阻止操作——此时需要先填写 PTpimg Key 再重试。一旦某张专辑完成转换后，后续加载该专辑无需再提供 Key。

> **工作模式**（Settings 顶部下拉，持久化到浏览器）决定油猴面板打开后默认进入哪个 tab：
> - **Qobuz Albums 模式**（默认）：油猴脚本启动后默认进入 **Albums** tab（即 Qobuz 专辑列表），适合日常下载 Qobuz
> - **补充专辑模式**：脚本在 RED 发布页（`redacted.sh/upload.php`）加载时默认进入 **Red Fill Albums** tab；非 RED 发布页因该 tab 不存在自动回退到 **Albums** tab

### 2. 从服务器同步配置

首次使用时，点击「从服务器同步」按钮，脚本会从主服务拉取以下配置（无需手动填写）：

- Qobuz 账号（邮箱 + 密码）— 即在后管系统中填写的信息

> 请确保已完成Qobuz 配置再点击「从服务器同步」，否则同步到的账号信息会为空。
>
> PT 站 API Key（Red、Ops、GGN 等）等敏感信息只在油猴脚本设置页手动填写并保存到浏览器缓存。

### 3. 验证连接

在Settings页配置同步到服务器或从服务器加载后，脚本会自动向 Worker 发起请求。请求成功后，油猴脚本面板最下方会有相应的提示，vps服务中的pm2服务日志信息也会有相应的提示。

如连接失败，请检查：
1. Worker 是否已启动（vps中是否有运行的 `node music-worker.js` 进程）
2. Worker URL 是否正确（默认 `http://localhost:36501`，或管理员帮助配置的域名地址）
3. API Key 是否正确

---

## 八、首次使用流程

完成以上配置后，按如下流程开始使用：

1. **打开油猴面板** — 在 Qobuz 网站任意专辑页（或在 RED 发布页若使用「补充专辑模式」），右上角浮动面板自动出现，默认进入 **Albums** tab 展示 Qobuz 专辑列表
2. **查看/筛选专辑列表** — 可按 HiRes、已下载、上传状态等条件筛选
3. **单张下载** — 在专辑行点击「**下载**」（或对已下载过的专辑点「**强制下载**」清状态后重下）将该专辑加入下载队列
4. **批量下载** — 顶部「**批量下载**」按当前筛选条件一次入队多张

Worker 会按顺序**逐张下载**，下载完成后自动生成频谱图和种子文件，保存到 `.env` 中配置的 `DOWNLOAD_DIR` 目录。下载完成后专辑行内的「**加载 FLAC-16/24 / MP3-320 / V0 种子**」按钮可一键把对应种子注入到 RED 发布页的文件输入框（仅在 RED 发布页有效）。

---

## 九、RED MP3 补全（Red Fill）使用指南

**RED MP3 补全**是一种补种玩法：首先抓取 RED 上**同一 group 缺少 V0/320 MP3 编码**的专辑，管理端将这些专辑分配给你；你下载对应种子、触发 FLAC→MP3 转码，最终补种到 RED。

相关交互位于油猴脚本面板的两个 tab：**📋 Actions** 与 **🎯 Red Fill Albums**。

### 1. 前置配置

- `.env` 中的 `RED_FILL_DOWNLOAD_DIR` 必须指向一个独立目录：Worker 会把 RED 补种的种子下载到这里，并以此为根做 FLAC 扫描与 MP3 转码
- `.env` 中的 `QBITTORRENT_DOWNLOAD_RED_DIR` 是推送种子到 qBittorrent 时使用的保存目录（即 qBittorrent 将文件存放到的路径）。若 qBittorrent 与 Worker 在同一台机器，可直接与 `RED_FILL_DOWNLOAD_DIR` 保持相同路径；若使用 Docker 安装的 qBittorrent，需注意容器内的路径映射
- 在「⚙ Settings → 从服务器同步」已拉取到有效的 RED API Key

### 2. 「📋 Actions」tab：发起/维护任务

> **「Red MP3 补全操作」区块仅在 RED 发布页（`redacted.sh/upload.php`）显示**；其它页面打开 Actions tab 时该区块整体隐藏。

此区块包含四个异步按钮 + 一个 **RED API 间隔** 输入框（默认 2000ms，范围 500–10000ms，超出则回退默认值）。按钮执行期间会显示 ⏳ 状态，四个按钮各自独立、可同时运行；同一按钮在当前轮次未结束前重复点击会被拒绝，再次点击即可继续。达到单次上限后会自动停止释放，再次点击同一按钮可继续处理剩余任务。

| 按钮 | 作用 | 单次上限 | 常见反馈 |
|------|------|---------|---------|
| **获取 Red 可补全专辑** | 扫描本地 FLAC 目录，为每张专辑到 RED 查询缺失的 MP3 编码，匹配成功的专辑自动分配给你 | 100 轮（≈100 个 RED browse 页，单次足够覆盖全量扫描） | 「扫描已启动，session #N（共 X 个任务）」；已有进行中扫描会自动合流 |
| **Red 可补全专辑复查** | 对已分配给你的活跃 assignment 重新向 RED API 核实是否仍可补；已在队列中的 group 跳过 | 1000 轮（1 轮 = 1 个 group） | 「已创建 N 条复查，跳过 M 条」 |
| **可补专辑全量复查** | 加入本 ISO 自然周全局共享的全量复查，多 Worker 协同处理 | 1000 轮（1 轮 = 1 个 group） | 「已发起/加入本周全量复查，本次领取 N 个，剩余 M 个」；本周已完成则提示「感谢支持，本周内已经复查完毕，请下周再来」 |
| **补充 FilePath** | 后台补全 RED 种子库中缺失 filePath 的记录；全局共享队列，首次触发快照全量缺失项入队，后续点击认领后续批次 | 1000 轮（1 轮 = 1 个 torrent） | 「已加入/创建本次会话，本次领取 N 个，剩余 M 个」 |

> 以上都是**异步任务**，提交完毕后请到「🎯 Red Fill Albums」tab 查看结果。Actions tab 底部「最近一次任务」卡片每 5 秒轮询，分别展示 scan / recheck / transcode 最近一次任务的进度与结果。

### 3. 「🎯 Red Fill Albums」tab：查看与操作认领专辑

此 tab **仅在 RED 发布页（`redacted.sh/upload.php`）显示**，列出分配给你的所有 RED 补全专辑，按分配时间倒序排列，每页 20 条。

**顶部工具栏**

- **下载状态**（下拉）：全部 / 已下载 / 未下载，切换后自动按新条件刷新
- **刷新**：按当前下拉条件重新拉取最新数据；由于下载/转码/重查是异步的，完成后需要手动点刷新查看结果
- **批量下载**：将当前筛选条件下未下载的 assignment 一次入队
- **批量转码**：对所有 `DOWNLOADED` 状态的 assignment 启动转码任务（曾经失败的不会被重新自动入队，需在该行单独点「转码」手动重试）

**每行展示**

| 区域 | 内容 |
|------|------|
| 专辑名称 | 固定 300px 宽，格式 `艺术家 - 专辑名 (年份) [介质] [Remaster 标题]`；超长显示省略号，鼠标悬浮可看全文 |
| 版本信息 | 按 `Year / Title / Label / CatalogueNumber` 顺序拼接，缺字段保留 ` / ` 占位（与 RED 发布页 Edition 下拉对齐）；四字段全空时整行不显示 |
| 下载状态 | 「已下载」/「未下载」，以 `downloadedTorrentPath` 是否存在为准 |
| 操作 | **打开**（新标签访问 RED group 页面）、**下载**、**重查**、**转码**；当 `format=MP3` 时额外显示 **加载 320** / **加载 V0** |

**按钮语义**

- **下载**：向 Worker 提交下载任务
  - 若该行种子已下载过，立即提示「已下载」
  - 否则创建下载任务并提示「下载任务已创建，请稍后点"刷新"查看最新状态」
- **重查**：向 RED 再查一次该专辑当前缺失的编码，更新 assignment 状态；失败会在消息区显示错误原因
- **转码**：对该 assignment 启动 FLAC→MP3 转码任务；任务完成后该行的「加载 320」「加载 V0」按钮可用
- **加载 320 / 加载 V0**：把转码产物对应的 `.torrent` 注入当前 RED 发布页的文件输入框，并自动选中 `media=WEB` / `format=MP3` / `bitrate=320|V0 (VBR)`，省去手动选择

**分页**：总条数超过 20 时，底部出现页码按钮，点击按当前下拉条件跳转。

### 4. 典型使用流程

1. 「📋 Actions」（在 RED 发布页打开）→ **获取 Red 可补全专辑**：扫描本地库并分配专辑
2. 「🎯 Red Fill Albums」→ 下拉筛选「未下载」→ 逐条点 **下载**，或顶部 **批量下载** 一次入队
3. 稍等 Worker 处理完成（按 RED API 间隔节流），顶部 **刷新** 查看下载状态变化
4. 所有专辑都 **已下载** 后，顶部 **批量转码** 触发 FLAC→MP3 转码（或在某行单独点 **转码** 重试失败的）
5. 转码完成后，在 RED 发布页填好基础信息，回到该行点 **加载 320** 或 **加载 V0** 把种子和媒介/格式/比特率一键填入，提交发布
6. 怀疑某条状态已过期时单行点 **重查**；批量更新可用 **Red 可补全专辑复查**
7. 有空闲时点 **可补专辑全量复查** / **补充 FilePath**，协助社区完成每周全量复查与种子库元数据补全

---

## 十、OPS MP3 补全（Ops Fill）使用指南

**OPS MP3 补全**与 RED MP3 补全类似：首先抓取 Orpheus（OPS）上**同一 group 缺少 V0/320 MP3 编码**的专辑，管理端将这些专辑分配给你；你下载对应种子、触发 FLAC→MP3 转码，最终补种到 OPS。

相关交互位于油猴脚本面板的两个位置：**📋 Actions tab** 的「Ops MP3 补全操作」区块 与 **🎯 Ops Fill Albums tab**。

> 这两者**仅在 OPS 发布页（`orpheus.network/upload.php`）显示**，其他页面不可见。

### 1. 前置配置

- `.env` 中的 `OPS_FILL_DOWNLOAD_DIR` 必须指向一个独立目录：Worker 会把 OPS 补种的种子下载到这里，并以此为根做 FLAC 扫描与 MP3 转码
- `.env` 中的 `QBITTORRENT_DOWNLOAD_OPS_DIR` 是推送种子到 qBittorrent 时使用的保存目录（即 qBittorrent 将文件存放到的路径）。若 qBittorrent 与 Worker 在同一台机器，可直接与 `OPS_FILL_DOWNLOAD_DIR` 保持相同路径；若使用 Docker 安装的 qBittorrent，需注意容器内的路径映射
- 在「⚙ Settings → 从服务器同步」已拉取到有效的 OPS API Key

### 2. 「📋 Actions tab」：Ops MP3 补全操作区块

> **仅在 OPS 发布页（`orpheus.network/upload.php`）显示**。

此区块包含四个异步按钮 + 一个 **OPS API 间隔** 输入框（默认 3000ms，范围 1000–10000ms，超出则回退默认值，比 RED 更保守以遵循 OPS 限速）。

| 按钮 | 作用 | 单次上限 |
|------|------|---------|
| **获取 Ops 可补全专辑** | 扫描 OPS browse 接口，识别缺失 V0/320 的专辑并分配给你 | 100 轮（≈100 个 OPS browse 页） |
| **Ops 可补全专辑复查** | 对最近 7 天内未发布的分配批量重查状态；已在队列中的 group 跳过 | 1000 轮（1 轮 = 1 个 group） |
| **可补专辑全量复查** | 每 ISO 自然周全局共享，多 Worker 协同复查全部已入库 group | 1000 轮（1 轮 = 1 个 group） |
| **补充 FilePath** | 补全已扫描 release 缺失的 filePath（通过 OPS API 拉取种子文件列表） | 1000 轮（1 轮 = 1 个 torrent） |

### 3. 「🎯 Ops Fill Albums tab」：查看与操作认领专辑

仅在 OPS 发布页显示，列出分配给你的所有 OPS 补全专辑，按分配时间倒序，每页 20 条。

**顶部工具栏**：下载状态（全部 / 已下载 / 未下载）+ **刷新** + **批量下载** + **批量转码**

**每行按钮**：

| 按钮 | 作用 |
|------|------|
| **打开** | 新标签打开 OPS group 页面 |
| **发布** | 跳转到 OPS 发布页（需先完成下载和转码后才可用） |
| **下载** | 下载 OPS 种子并推送到 qBittorrent（`QBITTORRENT_DOWNLOAD_OPS_DIR`） |
| **重查** | 向 OPS API 重新确认该专辑当前缺失的编码 |
| **转码** | 启动 FLAC→MP3 转码任务（需先完成下载） |

### 4. 典型使用流程

1. 「📋 Actions」（在 OPS 发布页打开）→ **获取 Ops 可补全专辑**
2. 「🎯 Ops Fill Albums」→ 筛选「未下载」→ 逐条点 **下载**，或顶部 **批量下载** 一次入队
3. 稍等 Worker 处理，点 **刷新** 查看状态变化
4. 所有专辑都 **已下载** 后，点 **批量转码** 触发 FLAC→MP3 转码
5. 转码完成后，在 OPS 发布页填好基础信息，回到该行点 **发布** 跳转发布页提交

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

### Worker 下载时报 Qobuz 认证失败 / 401

OAuth 授权码已过期。重新登录后管系统（https://admin.hostmails.de/admin/dashboard），在仪表板点击「Qobuz 授权」，完成第八节第 2 步的授权流程即可。

### 点击「加载」时提示「未配置 PTpimg Key」

该专辑的封面或频谱图尚未转换为 ptpimg 格式，转换时需要 PTpimg Key。

解决方法：在设置中填写 PTpimg Key 后，重新点击「加载」即可。转换完成后结果会写入数据库，之后加载同一张专辑无需再提供 Key。

### API Key 不正确 / 401 错误

联系管理员确认你的 API Key，或请管理员在后台重置。

---

## 十三、附录：支持的 PT 站页面

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

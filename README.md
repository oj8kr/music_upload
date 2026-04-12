# 用户快速上手指南

> 本指南面向**普通用户**，从零开始完成 Worker 子服务和油猴脚本的安装配置。
> 你不需要了解代码，只需按步骤操作即可。

---

## 一、你会得到什么

管理员会向你提供 Release 压缩包，解压后包含以下三个文件：

| 文件 | 说明 |
|------|------|
| `music-worker.js` | Worker 子服务，运行在你的本地电脑或海外服务器上，负责从 Qobuz 下载音乐 |
| `.env` | Worker 配置文件，填写服务器地址和本地下载目录 |
| `music-upload-tampermonkey.user.js` | 油猴脚本安装文件，安装后在浏览器中使用 |

> **提示**：解压后 `.env` 可能不可见（以 `.` 开头的隐藏文件），需要开启系统显示隐藏文件。
> - macOS：Finder 中按 `Cmd + Shift + .`
> - Windows：文件资源管理器 → 查看 → 勾选「隐藏项目」

---

## 二、安装 Node.js 运行环境

Worker 需要 Node.js 22 或更高版本才能运行。

### macOS

推荐使用 Homebrew 安装（如已安装可跳过）：

```bash
# 安装 Homebrew（如已安装可跳过）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 Node.js
brew install node
```

验证安装：
```bash
node --version   # 应显示 v22.x.x 或更高
```

### Linux (Ubuntu/Debian)

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

node --version
```

### Windows

1. 访问 [nodejs.org](https://nodejs.org/) 下载 LTS 安装包（.msi 文件）
2. 双击安装，全程默认下一步
3. 打开命令提示符（Win + R，输入 `cmd`），运行 `node --version` 验证

---

## 三、安装系统依赖工具

Worker 下载专辑后会自动生成频谱图和种子文件，需要以下工具：

| 工具 | 用途 |
|------|------|
| `sox` | 生成频谱图（spectrogram） |
| `mktorrent` | 生成 .torrent 种子文件 |
| `flac` | FLAC 无损压缩处理 |
| `ffmpeg` | FLAC 转 MP3 V0 格式 |

### macOS

```bash
brew install sox mktorrent flac ffmpeg
```

### Linux (Ubuntu/Debian)

```bash
sudo apt install -y sox mktorrent flac ffmpeg
```

### Windows

Windows 暂不推荐用于生产下载（文件路径格式差异较大）。如需使用，请联系管理员获取 WSL（Windows Subsystem for Linux）配置方案。

---

## 四、一键下载 Worker 文件（推荐）

在 Linux 服务器或 macOS 终端中，执行以下命令即可自动下载最新版本的全部文件，并在当前目录下生成 `music-worker` 文件夹：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/oj8kr/music_upload/main/start.sh)
```

下载完成后，进入目录编辑配置文件：

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

# Worker 本地监听端口（默认 36501，一般不需要修改）
PORT=36501

# 调度间隔，单位毫秒（默认 10000 = 10秒，一般不需要修改）
SCHEDULER_INTERVAL_MS=10000
```

**注意事项：**
- `MAIN_SERVICE_URL` 末尾**不要加斜杠**
- `DOWNLOAD_DIR` 使用绝对路径，目录需要存在（若不存在请先创建）
- Windows 路径示例：`DOWNLOAD_DIR=C:/Users/yourname/Music/downloads`

创建下载目录（若不存在）：
```bash
# macOS / Linux
mkdir -p /home/yourname/downloads

# Windows（命令提示符）
mkdir C:\Users\yourname\Music\downloads
```

---

## 六、启动 Worker

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

1. **进入 Qobuz** — 在 qobuz.com 浏览专辑，右上角面板展示专辑列表
2. **查看专辑列表** — 可按 HiRes、已下载、上传状态等条件筛选
3. **单张下载** — 在专辑列表中点击「下载」按钮，将该专辑加入下载队列
4. **批量下载** — 按照当前筛选条件批量加入队列
5. **查看下载状态** — 面板底部显示当前队列状态（待处理 / 处理中）

Worker 会按顺序**逐张下载**，下载完成后自动生成频谱图和种子文件，保存到 `.env` 中配置的 `DOWNLOAD_DIR` 目录。

---

## 十、更新 Worker

管理员发布新版本后，在 `music-worker` 目录的**上级目录**重新执行一键脚本，会自动覆盖 `music-worker.js` 和 `.env`（你对 `.env` 的自定义修改会被覆盖，请提前备份）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/oj8kr/music_upload/main/start.sh)
```

更新完成后重启 Worker：

```bash
# 如果使用 PM2
pm2 restart music-upload-worker

# 如果直接 node 运行，先 Ctrl+C 停止，再重新运行
cd music-worker && node music-worker.js
```

> 如需保留 `.env` 自定义配置，更新前先备份：`cp music-worker/.env music-worker/.env.bak`，更新后将自定义项补回。

---

## 十一、常见问题

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

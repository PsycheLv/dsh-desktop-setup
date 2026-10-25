# DSH Desktop 新机配置 · 交付包

一套「新 Mac 上把 DeepSeek Harness 配好」的可执行交付物。两种用法，**推荐第一种**。

> 仓库：<https://github.com/PsycheLv/dsh-desktop-setup> · 文档与脚本 **MIT** · 上游署名见 [ATTRIBUTION.md](ATTRIBUTION.md)

## 快速开始

```sh
git clone https://github.com/PsycheLv/dsh-desktop-setup.git
cd dsh-desktop-setup
./setup-dsh-desktop.sh --check     # 先体检
```

或者直接把 [`AI-执行版.md`](AI-执行版.md) 整份丢给你的 AI。

## 文件说明

| 文件 | 给谁用 | 说明 |
|---|---|---|
| **`AI-执行版.md`** | **AI** | **自包含**：把整份文件发给你的 AI，它就能自检、执行、验证、回滚。也含完整人工步骤 |
| `setup-dsh-desktop.sh` | 人 / AI | 可执行脚本，四种模式：`--check` / `--apply`（默认）/ `--verify` / `--rollback` |
| `README.md` | 人 | 本文件：用法、分享、踩坑索引 |

## 用法一：交给 AI（推荐）

1. 把 `AI-执行版.md` 整份内容发给你的 AI（Claude Code / Cursor / Codex / DSH 都行）
2. 附一句话：

   > 按这个文件里「给 AI 的执行契约」帮我配置，遇到必须人工确认的点就停下来告诉我。

3. AI 会自检 → 执行 → 自检 → 在**两个必须人工的点**停下来：
   - 去「系统设置 → 隐私与安全性 → 辅助功能」勾选 DeepSeek Harness
   - `Cmd+Q` 完全退出再打开 App

> 为什么不能全自动：macOS 的辅助功能授权（TCC）只能人点；客户端插件是 immutable 缓存，必须换进程才加载。这两步任何插件/脚本都绕不过。

## 用法二：自己跑脚本

```sh
chmod +x setup-dsh-desktop.sh
./setup-dsh-desktop.sh --check     # 先体检，不改任何东西
./setup-dsh-desktop.sh             # 执行
./setup-dsh-desktop.sh --verify    # 重启后自检
./setup-dsh-desktop.sh --rollback  # 全部撤销
```

选项：`--profile <name>`（默认 `desktop`）、`--yes`（不交互，给 AI/CI 用）。

## 用法三：纯手动

见 `AI-执行版.md` 的 **B 节「人工步骤」**，命令可逐条复制。

## 分享给别人

对方需要的是**一份文件**：`AI-执行版.md`。它不依赖其他文件、不依赖网络仓库，命令全部内嵌。

上传到知识库（如 ima / Notion / 飞书）后，对方把文档内容喂给自己的 AI 即可。

## 这套配置会做什么

1. 启用 DSH 自带的 3 个可选插件：持久终端、自动会话标题、思维链翻译
2. 安装 3 个第三方插件：开机动画、壁纸引擎、启动自动最大化
3. 下载「深夜大肥鱼」动态壁纸并预置选择（暗化 0.25）
4. 自检 + 回滚

全部改动只在 `~/.dsh/` 下，不碰 App 本体。

## 三条最容易踩的坑

1. 装完没效果 → 客户端插件要 `Cmd+Q` 换进程，刷新页面没用。
2. 背景一片黑 → macOS 没有 Wallpaper Engine（不带壁纸）+ 暗化默认 0.5 太暗 + 没选中壁纸，三者叠加。
3. 壁纸文件放进去扫不到 → 文件名必须匹配 `up-[a-z0-9-]+.(mp4|png|jpg|jpeg)`。

完整坑表、组件清单、许可证见 `AI-执行版.md` 的 C 节。

## 致谢与出处

本仓库只是「安装编排 + 说明」，真正的功能都来自这些作者，**请给他们点 Star**：

| 组件 | 作者 | 出处 | 许可证 |
|---|---|---|---|
| 开机动画 | NativeDog1 | [NativeDog1/dsh-boot-animation](https://github.com/NativeDog1/dsh-boot-animation) | BSD-3-Clause |
| 壁纸引擎 | elysia395 | [elysia395/dsh-wallpaper-engine](https://github.com/elysia395/dsh-wallpaper-engine) | MIT |
| 启动自动最大化 | FideFei | [Gitee 主仓](https://gitee.com/FideFei/dsh-auto-maximize) · [GitHub 镜像](https://github.com/FideFeiPlane/dsh-auto-maximize) | MIT |
| 动态壁纸素材 | QWEQ-CELL-DEL | [QWEQ-CELL-DEL/dsh-whale-girl-wallpaper](https://github.com/QWEQ-CELL-DEL/dsh-whale-girl-wallpaper) | MIT |
| 宿主 | DeepSeek | [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness) | 见官方仓库 |

**角色形象**：「蓝色大肥鱼 / 鲸鱼娘」是社区同人形象（原创「溟月」— 上善无形；「女仆鲸鱼娘」定型 — ZipZipPipe），
以 **CC BY-NC-SA 4.0** 授权：**需署名、禁止商用**。本仓库不转载任何图片/视频，
素材由安装脚本在运行时从上游下载并做 SHA-256 校验。

完整署名、备选方案、免责声明见 **[ATTRIBUTION.md](ATTRIBUTION.md)**。

## 免责声明

本仓库与深度求索官方无隶属关系。脚本会修改 `~/.dsh/` 下的配置，执行前请先阅读；
第三方插件的行为与安全由各自作者负责。

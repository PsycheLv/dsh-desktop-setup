# 致谢与出处 / Credits & Attributions

本仓库**不包含**任何第三方图片、视频或二进制包，只包含文档与 shell 脚本。
安装时由脚本或用户从下列上游下载。**所有版权归各自作者**。

本仓库（文档与脚本）以 [MIT](LICENSE) 发布。

---

## 1. 宿主：DeepSeek Harness

| 项 | 内容 |
|---|---|
| 项目 | DeepSeek Harness（DSH） |
| 官方仓库 | <https://github.com/deepseek-ai/deepseek-harness> |
| 用途 | 本手册配置的宿主应用 |
| 关系 | 本仓库为社区实践整理，**与深度求索官方无隶属或背书关系** |

文档中关于 profile 组合、bundle 分层、`dsh plugin` 行为的技术结论，来自对已安装 DSH（0.2.1-rc.3）实现代码的阅读与实测。

## 2. 开机动画 / Boot animation

| 项 | 内容 |
|---|---|
| 项目 | dsh-boot-animation |
| 作者 | NativeDog1 |
| 仓库 | <https://github.com/NativeDog1/dsh-boot-animation> |
| 版本 | 0.4.4 |
| 许可证 | BSD-3-Clause（见其 `package.json` 与 `LICENSE`） |
| 用途 | 安装为「片头动画」插件 |
| 分发方式 | 本仓库**不转载**其代码或素材，安装时由 `dsh plugin add github:...` 从上游拉取 |

**备选方案（文档中提及）**：

| 项目 | 作者 | 仓库 | 许可证 | 说明 |
|---|---|---|---|---|
| dsh-boot-animation-pro | Yiheng-guo | <https://github.com/Yiheng-guo/dsh-boot-animation-pro> | BSD-3-Clause | 上述项目的二次开发 fork，补了路由守卫 |
| dsh-boot-animation（独立实现） | lxj5820 | <https://github.com/lxj5820/dsh-boot-animation> | 见仓库 | 替换 kernel 启动页的实现 |
| dsh-550c-boot | yannicksong0106 | <https://github.com/yannicksong0106/dsh-550c-boot> | MIT | 550C 终端风格启动画面 |

## 3. 壁纸引擎 / Wallpaper engine

| 项 | 内容 |
|---|---|
| 项目 | dsh-plugin-wallpaper-engine |
| 作者 | elysia395 |
| 仓库 | <https://github.com/elysia395/dsh-wallpaper-engine> |
| 版本 | 1.4.0（npm: `dsh-plugin-wallpaper-engine`） |
| 许可证 | MIT |
| 用途 | 安装为「壁纸引擎」插件 |
| 内嵌依赖 | `webwallgl`、`x11` 及其 7 个子包（均随 npm 包分发） |

**提及的社区分支**：ruijiaang-lab/dsh-wallpaper-engine（macOS 扩展分支，<https://github.com/ruijiaang-lab/dsh-wallpaper-engine>）。

## 4. 启动自动最大化 / Auto maximize

| 项 | 内容 |
|---|---|
| 项目 | dsh-auto-maximize |
| 作者 | FideFei |
| 主仓库（Gitee） | <https://gitee.com/FideFei/dsh-auto-maximize> |
| GitHub 镜像 | <https://github.com/FideFeiPlane/dsh-auto-maximize> |
| 版本 | 1.2.0 |
| 许可证 | MIT |
| 用途 | 安装为「启动自动最大化」host 插件 |

## 5. 动态壁纸素材 / Wallpaper asset

| 项 | 内容 |
|---|---|
| 项目 | dsh-whale-girl-wallpaper |
| 作者 | QWEQ-CELL-DEL |
| 仓库 | <https://github.com/QWEQ-CELL-DEL/dsh-whale-girl-wallpaper> |
| 许可证 | MIT（代码与素材） |
| 用途 | 提供 `assets/wallpaper.mp4`（1008×576 / 30fps / 2:05） |
| 分发方式 | 本仓库不转载该视频；脚本运行时下载，并用内嵌 SHA-256 校验 |

**上游素材链**（该仓库自述）：壁纸素材衍生自 <https://github.com/Sutera-Diffusus/dsh-whale-musume>（MIT）。

另参考了场景壁纸合集 <https://github.com/Iphsiibl/deepseek-whale-girl-gallery>（整理与页面代码 CC BY-NC-SA 4.0），用于筛选素材；最终采用的视频来自上一行的项目。

## 6. 角色形象 / Character rights（重要）

「蓝色大肥鱼 / 鲸鱼娘 / DeepSeek娘」是中文社区的**同人二创形象**，非官方发布：

- 原创角色「溟月」——作者 **上善无形**（B 站）
- 「女仆鲸鱼娘」定型——作者 **ZipZipPipe**
- 形象整体以 **CC BY-NC-SA 4.0** 授权：**需署名、禁止商业用途、衍生作品须以相同协议共享**

因此：本仓库及其安装的壁纸素材**仅适用于个人非商业用途**。若需商用，请自行联系原作者取得授权。

素材索引与梗科普参考：

- 梗鲸 GengJing（蓝色大肥鱼表情包图库）：<https://aigengtu.com/>
- 萌娘百科「DeepSeek娘」条目：<https://mzh.moegirl.org.cn/DeepSeek%E5%A8%98>

## 7. 工具与生态

| 项 | 内容 |
|---|---|
| Cordis | DSH 使用的插件框架（`@deepseek-ai/cordis`），本仓库的插件机制说明基于它 |
| DSH 插件开发规范 | DSH 内置 `cordis-plugin-development` skill 与 bundle 规范 |
| 社区插件索引 | <https://dsh-plugin.org>、<https://dshbase.com>、<https://www.dsh.so>（仅作调研参考，本仓库未使用其市场/索引） |

---

## 免责声明

- 本仓库提供的脚本会修改 `~/.dsh/` 下的 profile 与插件配置，**请自行阅读后再执行**；执行前建议备份 `~/.dsh/profiles/`。
- 第三方插件的行为与安全性由各自作者负责，本仓库仅做安装编排与说明。
- 因执行本仓库脚本造成的任何问题，由使用者自行承担。

如需更正署名或有版权异议，请提 Issue，我们会尽快处理。

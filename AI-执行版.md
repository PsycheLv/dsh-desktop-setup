# DSH Desktop 新机配置（AI 可直接执行）

> **怎么用**
> - **交给 AI**：把本文件整份发给你的 AI（Claude Code / Cursor / Codex / DSH 都行），说一句
>   「按这个文件里的『给 AI 的执行契约』帮我配好」。它会自检、执行、验证，只在两个必须人工的点停下来找你。
> - **自己动手**：直接看下面的「人工步骤」，命令可以逐条复制。
>
> 适用：macOS + 刚装好的 DeepSeek Harness Desktop。执行完得到：开机动画 + 动态壁纸 + 启动自动最大化 + 持久终端 / 自动标题 / CoT 翻译。
> 来源：<https://github.com/PsycheLv/dsh-desktop-setup> · 文档与脚本 MIT · 上游署名见 [ATTRIBUTION.md](ATTRIBUTION.md)

---

# A. 给 AI 的执行契约

## A1. 目标

在这台 Mac 上完成 DeepSeek Harness Desktop 的下列配置，全部改动只发生在 `~/.dsh/` 下：

1. 启用 3 个随包可选插件：持久终端、自动会话标题、思维链翻译
2. 安装 3 个第三方插件：开机动画、壁纸引擎、启动自动最大化
3. 下载动态壁纸到壁纸引擎的上传目录（文件名必须符合其规则）
4. 预置壁纸选择（`up-midnight-live`，暗化 `0.25`）
5. 自检并报告结果

## A2. 硬边界（违反会损坏用户环境）

- **不要修改 `/Applications/DeepSeek Harness.app` 本体**（不要动 app.asar、不要重新签名）。
- **不要通过编辑 `cordis.patch.yml` 来"安装"插件**；安装只有 `dsh plugin --profile <name> add` 一条路。
- **不要同时启用两个壁纸插件或两个片头插件**（会抢同一层，导致双层背景/白屏）。检测到已存在同类插件时先停下来问人。
- **不要尝试自动授予 macOS「辅助功能」权限**（TCC 只能用户在系统设置里点，脚本/插件都做不到）。
- **不要 `sudo`**。
- 执行 `apply` 前如果 App 在运行，先让用户 `Cmd+Q` 退出；不要在 App 运行时强杀。

## A3. 前置自检（任何一条不满足就停下来报告，不要猜）

```bash
APP="/Applications/DeepSeek Harness.app"
CLI="$APP/Contents/Resources/runtime/cli/bin/dsh"

test -d "$APP" || echo "MISSING: DSH app"
test -x "$CLI" || echo "MISSING: dsh CLI"
test -f "$HOME/.dsh/profiles/desktop/package.json" || echo "MISSING: profile（需要先启动一次 App）"
```

- 如果 profile 不存在：让用户**先打开一次 DeepSeek Harness**，然后再继续。
- 如果 App 正在运行（`pgrep -f "DeepSeek Harness"`）：请用户 `Cmd+Q` 后继续。
- 记录 DSH 版本：`cat "$APP/Contents/Resources/app.asar/../package.json" 2>/dev/null`（读不到不影响，跳过）。

## A4. 执行（一条命令跑完）

把下面整段存成 `setup.sh`，然后 `bash setup.sh`。**不要改动里面的值**；它已按实测环境校准。

```bash
#!/usr/bin/env bash
set -euo pipefail

APP="/Applications/DeepSeek Harness.app"
CLI="$APP/Contents/Resources/runtime/cli/bin/dsh"
ELECTRON="$APP/Contents/MacOS/DeepSeek Harness"
PROFILE="${DSH_PROFILE_NAME:-desktop}"
PKG="$HOME/.dsh/profiles/$PROFILE/package.json"
UPLOAD_DIR="$HOME/.dsh-wallpaper-engine/uploads"
UPLOAD_NAME="up-midnight-live.mp4"
WP_URL="https://raw.githubusercontent.com/QWEQ-CELL-DEL/dsh-whale-girl-wallpaper/main/assets/wallpaper.mp4"
WP_SHA256="03bdcb30599062b3e2603a664f33652782304faa8dab16512586879f6215eeea"

say() { printf "\n==> %s\n" "$*"; }
die() { printf "ERROR: %s\n" "$*" >&2; exit 1; }

[ -d "$APP" ] || die "没装 DeepSeek Harness"
[ -x "$CLI" ] || die "找不到 dsh CLI"
[ -f "$PKG" ] || die "profile \"$PROFILE\" 不存在：请先启动一次 App"

# 用 App 自带 Node（无需系统装 Node）
node_eval() { ELECTRON_RUN_AS_NODE=1 "$ELECTRON" -e "$1"; }

say "1/4 启用随包可选插件"
PKG="$PKG" node_eval '
  const fs=require("fs"), p=process.env.PKG;
  const d=JSON.parse(fs.readFileSync(p,"utf8"));
  d.dsh=d.dsh||{}; d.dsh.profile=d.dsh.profile||{};
  const list=d.dsh.profile.bundles=d.dsh.profile.bundles||[];
  for (const n of ["@deepseek-ai/dsh-base","@deepseek-ai/dsh-web-app",
    "@deepseek-ai/dsh-experimental-terminal-bundle",
    "@deepseek-ai/dsh-experimental-session-titles-bundle",
    "@deepseek-ai/dsh-experimental-cot-translation-bundle"])
    if (!list.includes(n)) list.push(n);
  fs.writeFileSync(p, JSON.stringify(d,null,2)+"\n");
  console.log("bundles:", list.length);
'

say "2/4 安装第三方插件（git 源慢，几分钟正常）"
for spec in \
  "github:NativeDog1/dsh-boot-animation" \
  "dsh-plugin-wallpaper-engine@1.4.0" \
  "github:FideFeiPlane/dsh-auto-maximize"
do
  printf "  → %s\n" "$spec"
  "$CLI" plugin --profile "$PROFILE" add "$spec"
done

say "3/4 下载动态壁纸"
mkdir -p "$UPLOAD_DIR"
if [ -f "$UPLOAD_DIR/$UPLOAD_NAME" ]; then
  echo "  已存在，校验后跳过"
else
  curl -fL --connect-timeout 20 --max-time 600 -o "$UPLOAD_DIR/$UPLOAD_NAME" "$WP_URL"
fi
echo "$WP_SHA256  $UPLOAD_DIR/$UPLOAD_NAME" | shasum -a 256 -c - \
  || die "壁纸文件校验失败（可能被篡改或不完整），已停止"

say "4/4 预置壁纸选择"
node_eval '
  const fs=require("fs"), dir=process.env.HOME+"/.dsh-wallpaper-engine", f=dir+"/config.json";
  fs.mkdirSync(dir,{recursive:true});
  let d={}; try{d=JSON.parse(fs.readFileSync(f,"utf8"))}catch{}
  if (typeof d!=="object"||d===null||Array.isArray(d)) d={};
  d.settings=Object.assign({},d.settings,{id:"up-midnight-live",scrim:0.25});
  fs.writeFileSync(f, JSON.stringify(d,null,2));
  console.log("settings.id =", d.settings.id, "scrim =", d.settings.scrim);
'

cat <<'EOS'

完成。以下两步必须由人完成（无法自动化）：
1) 系统设置 → 隐私与安全性 → 辅助功能 → 勾选 DeepSeek Harness
   （若 ~/.dsh/auto-maximize.log 仍报 perm:，再把 /usr/bin/osascript 加进去）
2) Cmd+Q 完全退出 App，再重新打开
EOS
```

## A5. 必须停下来问人的两个点

1. **辅助功能授权**：执行完 `apply` 后告诉用户：「需要你手动去 系统设置 → 隐私与安全性 → 辅助功能 勾选 DeepSeek Harness」。
2. **重启**：「请 Cmd+Q 完全退出再打开」——不重启的话客户端插件不会加载（immutable 缓存），自动最大化也不会生效（TCC 对新进程生效）。

除此以外不要停下来问；遇到单个插件安装失败，继续装其余两个，最后在报告里列出失败项。

## A6. 验证（重启之后再跑）

```bash
# 1) 清单与启用状态
ELECTRON_RUN_AS_NODE=1 "/Applications/DeepSeek Harness.app/Contents/MacOS/DeepSeek Harness" -e '
const fs=require("fs"),p=process.env.HOME+"/.dsh/profiles/desktop/package.json";
const d=JSON.parse(fs.readFileSync(p,"utf8"));
const deps=d.dependencies||{},b=d.dsh.profile.bundles||[];
const need=["dsh-boot-animation","dsh-plugin-wallpaper-engine","dsh-auto-maximize"];
console.log("deps+bundles:", need.every(n=>deps[n]&&b.includes(n))?"OK":"FAIL");
const dirs=need.map(n=>process.env.HOME+"/.dsh/profiles/desktop/node_modules/"+n);
console.log("node_modules:", dirs.every(fs.existsSync)?"OK":"FAIL");
'

# 2) 壁纸素材
ls -lh ~/.dsh-wallpaper-engine/uploads/up-midnight-live.mp4

# 3) 自动最大化：期望出现 maximized-bounds 或 "maximized (zoom click)"
grep -E "maximized|PERMISSION" ~/.dsh/auto-maximize.log | tail -5

# 4) 运行时接口（端口从 DSH 的 GUI 地址取；在 DSH 自己的终端里可直接用 $DSH_WEB_URL）
curl -s "${DSH_WEB_URL:-http://127.0.0.1:PORT}/wallpaper-engine/inventory" | head -c 300
curl -s "${DSH_WEB_URL:-http://127.0.0.1:PORT}/dsh-boot-animation/status.json" | head -c 300
```

判定标准：

| 检查项 | 通过标准 |
|---|---|
| profile 清单 | 3 个第三方包同时在 `dependencies` 和 `bundles` 里 |
| node_modules | 3 个包目录都存在 |
| 壁纸 | 文件存在（约 8.3MB）且 sha256 匹配 |
| 自动最大化 | 日志出现 `maximized-bounds` 或 `maximized (zoom click)`；若只有 `perm:` 说明授权没做 |
| 壁纸接口 | `total: 1`，`id = up-midnight-live`，`type: video` |
| 片头接口 | `count: 4`（内置 4 段） |

## A7. 失败处理与回滚

| 现象 | 处理 |
|---|---|
| `profile "desktop" is managed exclusively by the Electron application` | 这是正常的：desktop profile 归 App 独占，**不要**用 `--dump-config`；安装类操作走 `dsh plugin` 即可 |
| `dsh plugin add` 卡住几分钟 | 正常（git 源拉取慢），超时给 600s，不要中断重试 |
| 壁纸校验失败 | 停止，不要写上传目录；报告并让用户自己放素材 |
| 装完看不到片头/壁纸 | 99% 是没 `Cmd+Q`；先确认是完整退出再打开 |
| 自动最大化 `perm:` | 辅助功能授权没做或没覆盖 osascript；授权后必须重启 App |
| 想全部撤销 | 见下 |

回滚（全部撤销）：

```bash
CLI="/Applications/DeepSeek Harness.app/Contents/Resources/runtime/cli/bin/dsh"
for p in dsh-boot-animation dsh-plugin-wallpaper-engine dsh-auto-maximize; do
  "$CLI" plugin --profile desktop remove "$p" || true
done
# 再编辑 ~/.dsh/profiles/desktop/package.json，从 dsh.profile.bundles 里删掉：
#   "@deepseek-ai/dsh-experimental-terminal-bundle"
#   "@deepseek-ai/dsh-experimental-session-titles-bundle"
#   "@deepseek-ai/dsh-experimental-cot-translation-bundle"
```

---

# B. 人工步骤（等价，便于自己动手或排查）

## B1. 准备

1. 安装并**启动一次** DeepSeek Harness Desktop（生成 profile）
2. 完全退出（`Cmd+Q`）

## B2. 启用随包可选插件

编辑 `~/.dsh/profiles/desktop/package.json`，在 `dsh.profile.bundles` 末尾追加三行：

```json
"@deepseek-ai/dsh-experimental-terminal-bundle",
"@deepseek-ai/dsh-experimental-session-titles-bundle",
"@deepseek-ai/dsh-experimental-cot-translation-bundle"
```

## B3. 安装三个插件

```sh
DSH="/Applications/DeepSeek Harness.app/Contents/Resources/runtime/cli/bin/dsh"
"$DSH" plugin --profile desktop add github:NativeDog1/dsh-boot-animation
"$DSH" plugin --profile desktop add dsh-plugin-wallpaper-engine@1.4.0
"$DSH" plugin --profile desktop add github:FideFeiPlane/dsh-auto-maximize
```

## B4. 放动态壁纸

```sh
mkdir -p ~/.dsh-wallpaper-engine/uploads
curl -fL -o ~/.dsh-wallpaper-engine/uploads/up-midnight-live.mp4 \
  https://raw.githubusercontent.com/QWEQ-CELL-DEL/dsh-whale-girl-wallpaper/main/assets/wallpaper.mp4
```

文件名必须匹配 `up-[a-z0-9-]+.(mp4|png|jpg|jpeg)`，否则壁纸库里看不到。

## B5. 选中壁纸

打开 App → 设置 → 背景/壁纸库 → 选中 `up-midnight-live`；
把「暗化」调到 `0.25`（默认 0.5 会让壁纸看起来像一块黑背景）。

## B6. 授权 + 重启

1. 系统设置 → 隐私与安全性 → **辅助功能** → 勾选 **DeepSeek Harness**（日志仍报 `perm:` 就再加 `/usr/bin/osascript`）
2. `Cmd+Q` 完全退出，重新打开

## B7. 验证

```sh
head -40 ~/.dsh/auto-maximize.log     # 期望 maximized-bounds / SUCCESS
ls -lh ~/.dsh-wallpaper-engine/uploads/
cat ~/.dsh/profiles/desktop/package.json
```

界面确认：片头会播；侧栏左下出现 `🎞` / `🎛`；壁纸在动；窗口启动即最大化。

---

# C. 附录

## C1. 装了什么

| 组件 | 来源 / 版本 | 体积 | 备注 |
|---|---|---|---|
| 开机动画 | `github:NativeDog1/dsh-boot-animation` 0.4.4 | ~9.5MB | 334★ 原版；无路由守卫（`/select` 可被网页 POST，仅影响播哪段） |
| 壁纸引擎 | npm `dsh-plugin-wallpaper-engine@1.4.0` | ~28MB | 2609★；**必须走 npm**，git 装会缺 7 个子包 |
| 自动最大化 | `github:FideFeiPlane/dsh-auto-maximize` 1.2.0 | ~100KB | 纯 host、零依赖；需辅助功能权限 |
| 动态壁纸 | `QWEQ-CELL-DEL/dsh-whale-girl-wallpaper`（MIT） | 8.3MB | 1008×576 / 30fps / 2:05，sha256 已内嵌校验 |
| 持久终端 / 自动标题 / CoT 翻译 | DSH 自带 bundle | 0 | 加进 bundles 即启用 |

## C2. 已知坑

| 坑 | 表现 | 处理 |
|---|---|---|
| 客户端插件不生效 | 刷新页面无变化 | 必须 `Cmd+Q` 换进程 |
| 背景一片黑 | 以为插件坏了 | macOS 没有 Wallpaper Engine + `scrim` 默认 0.5 + 未选壁纸 |
| 壁纸文件扫不到 | 库里没有 | 文件名必须是 `up-<小写字母数字>.<ext>` |
| HTTP 改设置无效 | `200 OK` 但没变化 | body 要扁平，不能包 `{"settings":{...}}` |
| 自动最大化无反应 | 日志 `perm:` | 授辅助功能；必要时加 osascript；重启 |
| 第一次 `nowindow` | 窗口还没出来 | 正常，1 秒后重试 |
| `--dump-config` 报错 | "managed exclusively" | desktop profile 归 App 独占，属正常 |
| 两个壁纸/片头插件同装 | 双层背景/白屏 | 只能留一个 |

## C3. 许可

- **本配置文档与脚本**：MIT，可自由转发与修改。
- **各插件按其自身许可证**：
  - `dsh-boot-animation`（NativeDog1）— **BSD-3-Clause**
  - `dsh-plugin-wallpaper-engine`（elysia395）— MIT
  - `dsh-auto-maximize`（FideFei）— MIT
- **动态壁纸素材**（QWEQ-CELL-DEL/dsh-whale-girl-wallpaper）— MIT；素材衍生自 `Sutera-Diffusus/dsh-whale-musume`（MIT）。
- **角色形象**：「蓝色大肥鱼 / 鲸鱼娘」为社区同人（原创「溟月」— 上善无形；「女仆鲸鱼娘」定型 — ZipZipPipe），**CC BY-NC-SA 4.0**：署名 + **禁止商用** + 相同方式共享。

## C4. 致谢与出处

真正的功劳在这些作者身上，请给上游点 Star：

| 组件 | 作者 | 出处 | 许可证 |
|---|---|---|---|
| 宿主 DeepSeek Harness | DeepSeek | <https://github.com/deepseek-ai/deepseek-harness> | 见官方仓库 |
| 开机动画 | NativeDog1 | <https://github.com/NativeDog1/dsh-boot-animation> | BSD-3-Clause |
| 壁纸引擎 | elysia395 | <https://github.com/elysia395/dsh-wallpaper-engine> | MIT |
| 自动最大化 | FideFei | <https://gitee.com/FideFei/dsh-auto-maximize> · <https://github.com/FideFeiPlane/dsh-auto-maximize> | MIT |
| 动态壁纸素材 | QWEQ-CELL-DEL | <https://github.com/QWEQ-CELL-DEL/dsh-whale-girl-wallpaper> | MIT |

文档中提及的备选方案与参考来源：

- `dsh-boot-animation-pro`（Yiheng-guo，BSD-3-Clause，原版 fork，补了路由守卫）：<https://github.com/Yiheng-guo/dsh-boot-animation-pro>
- `dsh-550c-boot`（yannicksong0106，MIT）：<https://github.com/yannicksong0106/dsh-550c-boot>
- 场景壁纸合集（整理 CC BY-NC-SA 4.0）：<https://github.com/Iphsiibl/deepseek-whale-girl-gallery>
- 梗科普与素材索引：梗鲸 <https://aigengtu.com/>、萌娘百科「DeepSeek娘」<https://mzh.moegirl.org.cn/DeepSeek%E5%A8%98>

**本仓库不转载任何图片/视频/第三方二进制**：素材在安装时从上游下载，并做 SHA-256 校验（见 A4 脚本）。
完整署名与免责声明见仓库根目录 `ATTRIBUTION.md`。

---

*对应实测环境：macOS + DSH 0.2.1-rc.3，profile `desktop`。*

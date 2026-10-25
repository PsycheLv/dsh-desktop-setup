#!/usr/bin/env bash
#
# DSH Desktop 新机器配置器
# ---------------------------------------------------------------------------
# 用法：
#   ./setup-dsh-desktop.sh --check       # 只体检，不改任何东西
#   ./setup-dsh-desktop.sh               # 执行配置（幂等，可重复跑）
#   ./setup-dsh-desktop.sh --verify      # 安装后自检
#   ./setup-dsh-desktop.sh --rollback    # 回滚（卸载 3 个第三方插件 + 关掉 3 个可选包）
#
# 选项：
#   --profile <name>   默认 desktop
#   --yes, -y          不交互确认（给 AI / CI 用）
#
# 前置：DeepSeek Harness.app 已安装，且**至少启动过一次**（profile 才会生成）。
# 建议：执行前 Cmd+Q 完全退出 App。
# ---------------------------------------------------------------------------
set -euo pipefail

APP="/Applications/DeepSeek Harness.app"
CLI="$APP/Contents/Resources/runtime/cli/bin/dsh"
ELECTRON="$APP/Contents/MacOS/DeepSeek Harness"
PROFILE="desktop"
MODE="apply"
ASSUME_YES=0

WALLPAPER_URL="https://raw.githubusercontent.com/QWEQ-CELL-DEL/dsh-whale-girl-wallpaper/main/assets/wallpaper.mp4"
UPLOAD_DIR="$HOME/.dsh-wallpaper-engine/uploads"
UPLOAD_NAME="up-midnight-live.mp4"           # 必须匹配 ^up-[a-z0-9-]+\.(mp4|png|jpg|jpeg)$

OPTIONAL_BUNDLES=(
  "@deepseek-ai/dsh-experimental-terminal-bundle"
  "@deepseek-ai/dsh-experimental-session-titles-bundle"
  "@deepseek-ai/dsh-experimental-cot-translation-bundle"
)
PLUGIN_SPECS=(
  "github:NativeDog1/dsh-boot-animation"
  "dsh-plugin-wallpaper-engine@1.4.0"
  "github:FideFeiPlane/dsh-auto-maximize"
)
PLUGIN_NAMES=(dsh-boot-animation dsh-plugin-wallpaper-engine dsh-auto-maximize)

say()  { printf "\n\033[1m==> %s\033[0m\n" "$*"; }
ok()   { printf "  \033[32m✓\033[0m %s\n" "$*"; }
bad()  { printf "  \033[31m✗\033[0m %s\n" "$*"; }
warn() { printf "  \033[33m!\033[0m %s\n" "$*"; }
die()  { printf "\033[31mERROR:\033[0m %s\n" "$*" >&2; exit 1; }

usage() { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --check)    MODE="check"; shift ;;
    --apply)    MODE="apply"; shift ;;
    --verify)   MODE="verify"; shift ;;
    --rollback) MODE="rollback"; shift ;;
    --profile)  PROFILE="${2:-}"; [ -n "$PROFILE" ] || die "--profile 需要一个名字"; shift 2 ;;
    --yes|-y)   ASSUME_YES=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) die "未知参数：$1（--help 看用法）" ;;
  esac
done

PROFILE_DIR="$HOME/.dsh/profiles/$PROFILE"
PKG="$PROFILE_DIR/package.json"

require_env() {
  [ -d "$APP" ] || die "没找到 $APP（请先安装 DeepSeek Harness）"
  [ -x "$CLI" ] || die "没找到 dsh CLI：$CLI"
  [ -f "$PKG" ] || die "profile \"$PROFILE\" 不存在：请先启动一次 App 生成 ~/.dsh/profiles/$PROFILE，再运行本脚本"
}

# 用 App 自带的 Node 执行 JS（不需要系统装 Node）
node_eval() { ELECTRON_RUN_AS_NODE=1 "$ELECTRON" -e "$1"; }

app_running() { pgrep -f "DeepSeek Harness" >/dev/null 2>&1; }

# ============================================================ check
do_check() {
  require_env
  say "体检（不修改任何东西）"

  PKG="$PKG" node_eval '
    const fs=require("fs"), p=process.env.PKG;
    const d=JSON.parse(fs.readFileSync(p,"utf8"));
    const deps=d.dependencies||{}, bundles=(d.dsh&&d.dsh.profile&&d.dsh.profile.bundles)||[];
    console.log("  profile :", p);
    console.log("  依赖     :", Object.keys(deps).join(", ")||"(空)");
    console.log("  bundles :", bundles.length, "条");
    for (const n of ["dsh-boot-animation","dsh-plugin-wallpaper-engine","dsh-auto-maximize"]) {
      console.log("   -", n, deps[n] ? "["+deps[n]+"]" : "(未安装)", bundles.includes(n)?"(已启用)":"(未启用)");
    }
    for (const n of ["@deepseek-ai/dsh-experimental-terminal-bundle","@deepseek-ai/dsh-experimental-session-titles-bundle","@deepseek-ai/dsh-experimental-cot-translation-bundle"]) {
      console.log("  可选包", n.replace("@deepseek-ai/",""), bundles.includes(n)?"(已启用)":"(未启用)");
    }
  '

  if [ -f "$UPLOAD_DIR/$UPLOAD_NAME" ]; then ok "壁纸素材已就位（$(du -h "$UPLOAD_DIR/$UPLOAD_NAME" | cut -f1)）"; else warn "壁纸素材缺失：$UPLOAD_DIR/$UPLOAD_NAME"; fi

  if [ -f "$HOME/.dsh/auto-maximize.log" ]; then
    if grep -q "maximized-bounds\|maximized (zoom click)" "$HOME/.dsh/auto-maximize.log"; then ok "自动最大化：日志里有成功记录"
    elif grep -q "PERMISSION MISSING" "$HOME/.dsh/auto-maximize.log"; then warn "自动最大化：缺「辅助功能」授权"
    else warn "自动最大化：日志存在但无成功记录"; fi
  else warn "自动最大化：还没有日志（装好后尚未启动过 App）"; fi

  if app_running; then warn "App 正在运行：执行 apply 前建议 Cmd+Q 退出"; else ok "App 未运行"; fi
}

# ============================================================ apply
do_apply() {
  require_env
  if app_running && [ "$ASSUME_YES" -eq 0 ]; then
    warn "检测到 App 正在运行，改动会在重启后才完全生效"
    read -r -p "  继续？[y/N] " a || true
    case "${a:-}" in y|Y) ;; *) die "已取消（可先 Cmd+Q 再跑）" ;; esac
  fi

  say "1/4 启用随包可选插件（持久终端 / 自动会话标题 / 思维链翻译）"
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
    console.log("  bundles 共 "+list.length+" 条");
  '

  say "2/4 安装第三方插件（git 源首次拉取较慢，几分钟属正常）"
  for spec in "${PLUGIN_SPECS[@]}"; do
    printf "  → %s\n" "$spec"
    "$CLI" plugin --profile "$PROFILE" add "$spec"
  done

  say "3/4 下载动态壁纸"
  mkdir -p "$UPLOAD_DIR"
  if [ -f "$UPLOAD_DIR/$UPLOAD_NAME" ]; then
    ok "已存在，跳过：$UPLOAD_DIR/$UPLOAD_NAME"
  else
    curl -fL --connect-timeout 20 --max-time 600 -o "$UPLOAD_DIR/$UPLOAD_NAME" "$WALLPAPER_URL"
    ok "已下载 $(du -h "$UPLOAD_DIR/$UPLOAD_NAME" | cut -f1)"
  fi

  say "4/4 预置壁纸选择（id=up-midnight-live, scrim=0.25）"
  node_eval '
    const fs=require("fs"), dir=process.env.HOME+"/.dsh-wallpaper-engine", file=dir+"/config.json";
    fs.mkdirSync(dir,{recursive:true});
    let d={}; try{d=JSON.parse(fs.readFileSync(file,"utf8"))}catch{}
    if (typeof d!=="object"||d===null||Array.isArray(d)) d={};
    d.settings=Object.assign({},d.settings,{id:"up-midnight-live",scrim:0.25});
    fs.writeFileSync(file, JSON.stringify(d,null,2));
    console.log("  settings.id = "+d.settings.id+" , scrim = "+d.settings.scrim);
  '

  cat <<'EOS'

--------------------------------------------------------------------
安装完成。剩下两步只能人工做（系统限制，无法脚本化）：

1) 系统设置 → 隐私与安全性 → 辅助功能 → 勾选 DeepSeek Harness
   （若日志仍报 perm:，再把 /usr/bin/osascript 加进去）
2) Cmd+Q 完全退出 App，再打开（客户端插件 + TCC 都需要新进程）

验证：./setup-dsh-desktop.sh --verify
--------------------------------------------------------------------
EOS
}

# ============================================================ verify
do_verify() {
  require_env
  local fail=0 out line
  say "自检"

  out=$(PKG="$PKG" PROFILE="$PROFILE" node_eval '
    const fs=require("fs"), p=process.env.PKG;
    const d=JSON.parse(fs.readFileSync(p,"utf8"));
    const deps=d.dependencies||{}, bundles=(d.dsh&&d.dsh.profile&&d.dsh.profile.bundles)||[];
    const need=["dsh-boot-animation","dsh-plugin-wallpaper-engine","dsh-auto-maximize"];
    const opt=["@deepseek-ai/dsh-experimental-terminal-bundle","@deepseek-ai/dsh-experimental-session-titles-bundle","@deepseek-ai/dsh-experimental-cot-translation-bundle"];
    console.log(need.every(n=>deps[n]&&bundles.includes(n))?"OK 依赖与 bundles":"BAD 依赖与 bundles");
    console.log(opt.every(n=>bundles.includes(n))?"OK 可选包已启用":"BAD 可选包未启用");
    const dirs=need.map(n=>process.env.HOME+"/.dsh/profiles/"+process.env.PROFILE+"/node_modules/"+n);
    console.log(dirs.every(x=>fs.existsSync(x))?"OK node_modules":"BAD node_modules");
  ')
  while IFS= read -r line; do
    case "$line" in
      OK\ *)  ok "${line#OK }" ;;
      BAD\ *) bad "${line#BAD }"; fail=1 ;;
    esac
  done <<< "$out"

  if [ -f "$UPLOAD_DIR/$UPLOAD_NAME" ]; then ok "壁纸素材存在"; else bad "壁纸素材缺失"; fail=1; fi

  if [ -f "$HOME/.dsh/auto-maximize.log" ]; then
    if grep -q "maximized-bounds\|maximized (zoom click)" "$HOME/.dsh/auto-maximize.log"; then ok "自动最大化已成功过"
    elif grep -q "PERMISSION MISSING" "$HOME/.dsh/auto-maximize.log"; then bad "自动最大化缺辅助功能授权"; fail=1
    else warn "自动最大化暂无成功记录"; fi
  else bad "没有 auto-maximize 日志（装好后未启动过？）"; fail=1; fi

  if [ -n "${DSH_WEB_URL:-}" ]; then
    say "运行时接口（$DSH_WEB_URL）"
    curl -sS --max-time 10 "$DSH_WEB_URL/wallpaper-engine/inventory" 2>/dev/null | head -c 200; echo
    curl -sS --max-time 10 "$DSH_WEB_URL/dsh-boot-animation/status.json" 2>/dev/null | head -c 200; echo
  else
    warn "未设置 DSH_WEB_URL，跳过运行时接口检查（在 DSH 终端里跑才有）"
  fi

  if [ "$fail" -eq 0 ]; then say "结果：全部通过"; else say "结果：有失败项，见上"; fi
  return "$fail"
}

# ============================================================ rollback
do_rollback() {
  require_env
  say "回滚"
  for spec in "${PLUGIN_NAMES[@]}"; do
    printf "  → remove %s\n" "$spec"
    "$CLI" plugin --profile "$PROFILE" remove "$spec" || warn "移除失败（可能本来就没装）：$spec"
  done

  say "关掉随包可选插件"
  PKG="$PKG" node_eval '
    const fs=require("fs"), p=process.env.PKG;
    const d=JSON.parse(fs.readFileSync(p,"utf8"));
    const drop=new Set(["@deepseek-ai/dsh-experimental-terminal-bundle",
      "@deepseek-ai/dsh-experimental-session-titles-bundle",
      "@deepseek-ai/dsh-experimental-cot-translation-bundle"]);
    d.dsh=d.dsh||{}; d.dsh.profile=d.dsh.profile||{};
    d.dsh.profile.bundles=(d.dsh.profile.bundles||[]).filter(n=>!drop.has(n));
    fs.writeFileSync(p, JSON.stringify(d,null,2)+"\n");
    console.log("  剩余 bundles："+d.dsh.profile.bundles.length+" 条");
  '

  warn "壁纸素材保留在 $UPLOAD_DIR（手动删除即可）"
  say "回滚完成；Cmd+Q 重开 App 生效"
}

case "$MODE" in
  check)    do_check ;;
  apply)    do_apply ;;
  verify)   do_verify ;;
  rollback) do_rollback ;;
esac

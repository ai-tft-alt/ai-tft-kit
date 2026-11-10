<#
AI-TFT 스타터 키트 설치 (Windows PowerShell 5.1 이상)

  .\install.ps1                                   키트 설치 (스킬 · CLI · 레이아웃)
  .\install.ps1 -Project C:\ai_tft\kit51          + 그 폴더에 CLAUDE.md 템플릿
  .\install.ps1 -Project C:\ai_tft\kit51 -Learning   + 그 폴더에만 학습 모드 훅 켜기
  .\install.ps1 -VSCode                           VS Code 터미널 설정 3줄 + Zellij 중복 실행 방지 (단축키 · ESC 문제 해결)
  .\install.ps1 -Force                            같은 이름 스킬이 있어도 덮어쓰기
  .\install.ps1 -Uninstall                        키트 스킬과 파일 지우기

전역 설정(%USERPROFILE%\.claude\settings.json)은 건드리지 않습니다. 훅은 -Project 폴더에만 켭니다.
#>
param([string]$Project = "", [switch]$Learning, [switch]$VSCode, [switch]$Force, [switch]$Uninstall)
$ErrorActionPreference = "Stop"
$Kit = Split-Path -Parent $MyInvocation.MyCommand.Path
$Home2 = Join-Path $env:USERPROFILE ".ai-tft-kit"
$SkillDir = Join-Path $env:USERPROFILE ".claude\skills"
function Say($m, $c = "Gray") { Write-Host $m -ForegroundColor $c }

if ($Uninstall) {
  Get-ChildItem (Join-Path $Kit "skills") -Directory | ForEach-Object {
    $t = Join-Path $SkillDir $_.Name; if (Test-Path $t) { Remove-Item $t -Recurse -Force; Say "삭제: 스킬 $($_.Name)" }
  }
  if (Test-Path $Home2) { Remove-Item $Home2 -Recurse -Force; Say "삭제: $Home2" }
  $pf = $PROFILE.CurrentUserAllHosts
  if (Test-Path $pf) {
    $old = Get-Content $pf -Raw
    $new = [regex]::Replace($old, '(?s)\r?\n?# >>> ai-tft zellij guard >>>.*?# <<< ai-tft zellij guard <<<\r?\n?', '')
    if ($new -ne $old) { [IO.File]::WriteAllText($pf, $new, (New-Object Text.UTF8Encoding $true)); Say "삭제: Zellij 중복 실행 방지 ($pf)" }
  }
  Say "제거 완료 (프로젝트 폴더의 .claude\settings.json 훅은 직접 지우세요)" Green; return
}

Say "== AI-TFT 스타터 키트 설치 ==" Cyan
# 1) 필요한 프로그램 확인
foreach ($p in "git", "node", "python", "claude", "zellij") {
  $ok = [bool](Get-Command $p -ErrorAction SilentlyContinue)
  Say ("  {0,-7} {1}" -f $p, $(if ($ok) { "OK" } else { "없음 → 설치 가이드 1장 참고" })) $(if ($ok) { "Gray" } else { "Yellow" })
}

# 2) CLI · 훅 · 레이아웃 · 템플릿 → %USERPROFILE%\.ai-tft-kit
New-Item -ItemType Directory -Force $Home2 | Out-Null
foreach ($d in "cli", "hooks", "layouts", "templates") {
  Copy-Item (Join-Path $Kit $d) $Home2 -Recurse -Force
}
Say "  파일 복사: $Home2" Green

# 3) 스킬 → %USERPROFILE%\.claude\skills (사용자 범위: 모든 폴더에서 사용)
New-Item -ItemType Directory -Force $SkillDir | Out-Null
Get-ChildItem (Join-Path $Kit "skills") -Directory | ForEach-Object {
  $t = Join-Path $SkillDir $_.Name
  if ((Test-Path $t) -and -not $Force) { Say "  건너뜀: $($_.Name) (이미 있음, -Force 로 덮어쓰기)" Yellow }
  else { Copy-Item $_.FullName $SkillDir -Recurse -Force; Say "  스킬 설치: $($_.Name)" Green }
}

# 4) 프로젝트 폴더 준비 (선택)
if ($Project) {
  New-Item -ItemType Directory -Force $Project | Out-Null
  $cm = Join-Path $Project "CLAUDE.md"
  if (-not (Test-Path $cm)) { Copy-Item (Join-Path $Kit "templates\CLAUDE.md") $cm; Say "  CLAUDE.md 템플릿 → $cm" Green }
  if ($Learning) {
    $cd = Join-Path $Project ".claude"; New-Item -ItemType Directory -Force $cd | Out-Null
    $sf = Join-Path $cd "settings.json"
    $hookPath = (Join-Path $Home2 "hooks\learning-mode.mjs") -replace '\\', '/'
    $cmd = "node `"$hookPath`""
    $s = if (Test-Path $sf) { Get-Content $sf -Raw -Encoding UTF8 | ConvertFrom-Json } else { New-Object PSObject }
    if (-not $s.PSObject.Properties["hooks"]) { $s | Add-Member hooks (New-Object PSObject) }
    $entry = [pscustomobject]@{ hooks = @([pscustomobject]@{ type = "command"; command = $cmd; timeout = 10 }) }
    $exists = $false
    if ($s.hooks.PSObject.Properties["UserPromptSubmit"]) {
      foreach ($e in $s.hooks.UserPromptSubmit) { foreach ($h in $e.hooks) { if ($h.command -like "*learning-mode.mjs*") { $exists = $true } } }
      if (-not $exists) { $s.hooks.UserPromptSubmit = @($s.hooks.UserPromptSubmit) + $entry }
    } else { $s.hooks | Add-Member UserPromptSubmit @($entry) }
    $json = $s | ConvertTo-Json -Depth 10
    [IO.File]::WriteAllText($sf, $json, (New-Object Text.UTF8Encoding $false))
    Say "  학습 모드 훅 켬 → $sf  (Claude를 다시 실행하면 적용)" Green
  }
}

# 5) VS Code 터미널 설정 (선택, -VSCode)
#    sendKeybindingsToShell : Zellij 단축키(Ctrl+p 등)를 VS Code가 가로채지 않게
#    defaultProfile         : 터미널을 PowerShell로 통일
#    windowsUseConptyDll    : Windows 10에서 VS Code 안 Zellij의 ESC가 안 먹는 문제 해결
if ($VSCode) {
  $vs = Join-Path $env:APPDATA "Code\User\settings.json"
  New-Item -ItemType Directory -Force (Split-Path $vs) | Out-Null
  $want = [ordered]@{
    "terminal.integrated.sendKeybindingsToShell" = "true"
    "terminal.integrated.defaultProfile.windows" = '"PowerShell"'
    "terminal.integrated.windowsUseConptyDll"    = "true"
  }
  $txt = if (Test-Path $vs) { Get-Content $vs -Raw -Encoding UTF8 } else { "{`n}" }
  if (-not $txt.Trim()) { $txt = "{`n}" }
  $add = @($want.Keys | Where-Object { $txt -notmatch [regex]::Escape("`"$_`"") })
  if ($add.Count -eq 0) { Say "  VS Code 설정: 이미 있음" Gray }
  else {
    if (Test-Path $vs) { Copy-Item $vs "$vs.bak" -Force }
    $lines = ($add | ForEach-Object { "    `"$_`": $($want[$_])" }) -join ",`n"
    $i = $txt.LastIndexOf("}")
    $head = $txt.Substring(0, $i).TrimEnd()
    if (-not ($head.EndsWith("{") -or $head.EndsWith(","))) { $head += "," }
    $txt = $head + "`n" + $lines + "`n}" + $txt.Substring($i + 1)
    [IO.File]::WriteAllText($vs, $txt, (New-Object Text.UTF8Encoding $false))
    Say "  VS Code 설정 추가: $($add -join ', ')  (백업: settings.json.bak, 터미널을 새로 열면 적용)" Green
  }

  # Zellij 중복 실행 방지: Zellij 칸 안(ZELLIJ 환경변수가 있음)에서 zellij 를 또 켜면 막고 안내
  #   (두 겹이 되면 ESC 가 안 먹고 탭 줄·단축키 줄이 2줄씩 보임)
  #   action · list-sessions · kill-session 같은 관리 명령은 그대로 통과
  $pf = $PROFILE.CurrentUserAllHosts
  New-Item -ItemType Directory -Force (Split-Path $pf) | Out-Null
  $guard = @'
# >>> ai-tft zellij guard >>>
function zellij {
  $ok = 'action','list-sessions','ls','kill-session','k','kill-all-sessions','ka','delete-session','d',
        'delete-all-sessions','da','run','r','edit','e','plugin','pipe','setup','-h','--help','-V','--version'
  if ($env:ZELLIJ -and -not ($args.Count -gt 0 -and $ok -contains $args[0])) {
    Write-Host "이미 Zellij 안입니다 (세션: $env:ZELLIJ_SESSION_NAME)." -ForegroundColor Yellow
    Write-Host "  zellij 를 또 켜면 두 겹이 되어 ESC 가 안 먹습니다. 새 칸은 Alt + n 을 쓰세요." -ForegroundColor Yellow
    Write-Host "  다른 레이아웃을 쓰려면 Ctrl + q 로 나간 뒤 다시 실행하세요." -ForegroundColor Yellow
    return
  }
  zellij.exe @args
}
# <<< ai-tft zellij guard <<<
'@
  $old = if (Test-Path $pf) { Get-Content $pf -Raw } else { "" }
  if ($null -eq $old) { $old = "" }
  $new = [regex]::Replace($old, '(?s)# >>> ai-tft zellij guard >>>.*?# <<< ai-tft zellij guard <<<\r?\n?', '')
  $new = $new.TrimEnd() + $(if ($new.Trim()) { "`r`n`r`n" } else { "" }) + ($guard -replace "`r?`n", "`r`n") + "`r`n"
  if ($new -ne $old) {
    if (Test-Path $pf) { Copy-Item $pf "$pf.bak" -Force }
    [IO.File]::WriteAllText($pf, $new, (New-Object Text.UTF8Encoding $true))   # BOM: PowerShell 5.1 한글 깨짐 방지
    Say "  Zellij 중복 실행 방지 추가 → $pf  (PowerShell 을 새로 열면 적용)" Green
  } else { Say "  Zellij 중복 실행 방지: 이미 있음" Gray }
}

# 6) 점검
python (Join-Path $Home2 "cli\hwp.py") check
Say "== 설치 완료. Claude를 새로 실행한 뒤 /skills 또는 '설치된 tft 스킬 보여줘' 로 확인하세요 ==" Cyan

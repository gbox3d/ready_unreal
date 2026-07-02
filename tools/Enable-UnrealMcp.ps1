#Requires -Version 5.1
<#
.SYNOPSIS
    UE 5.8 프로젝트에 Unreal MCP(서버) 셋업을 멱등하게 적용한다.

.DESCRIPTION
    새 프로젝트마다 반복되는 "에디터 측" 준비를 명령 한 줄로 끝낸다:
      1) .uproject 의 Plugins 배열에 다음을 추가(이미 있으면 건너뜀):
           - ModelContextProtocol  (FriendlyName "Unreal MCP" = MCP HTTP 서버 본체)
           - AllToolsets           (실제 조작 Tool 묶음; 없으면 "연결되나 Tool 0개")
      2) (기본) Config/DefaultEditorPerProjectUserSettings.ini 에 자동시작 설정 기록:
           [/Script/ModelContextProtocolEngine.ModelContextProtocolSettings]
           bAutoStartServer=True / ServerPortNumber=<Port> / ServerUrlPath=/mcp
         -> 다음부터 그 프로젝트를 "열기만" 하면 :Port 에 MCP 서버가 자동 기동.

    클라이언트(Claude Code) 등록은 전역(user 스코프)이라 1회면 끝이며 이 스크립트 대상이
    아니다(readme.md 부록 A 참조). 이 스크립트는 "프로젝트별 에디터 준비"만 자동화한다.

    엔진 내장 플러그인이라 프로젝트 재컴파일은 없고 에디터 재시작만 필요하다.
    원본 .uproject 는 변경 시 타임스탬프 백업(*.uproject.bak_YYYYMMDD_HHmmss)을 남긴다.

.PARAMETER Project
    .uproject 파일 경로, 또는 .uproject 가 하나 들어있는 프로젝트 폴더 경로.

.PARAMETER Port
    MCP 서버 포트(기본 8000). 자동시작 config 의 ServerPortNumber 에 반영.

.PARAMETER NoAutoStart
    지정 시 자동시작 config(ini)는 건드리지 않고 .uproject 플러그인만 추가.

.PARAMETER DryRun
    실제 파일을 쓰지 않고 어떤 변경이 일어날지 출력만.

.EXAMPLE
    .\tools\Enable-UnrealMcp.ps1 -Project "C:\works\ue_prjs\MyNewProject"

.EXAMPLE
    .\tools\Enable-UnrealMcp.ps1 -Project "C:\works\ue_prjs\MyNewProject" -DryRun

.EXAMPLE
    .\tools\Enable-UnrealMcp.ps1 -Project ".\MyGame\MyGame.uproject" -Port 8123
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string] $Project,
    [int]    $Port = 8000,
    [switch] $NoAutoStart,
    [switch] $DryRun
)

$ErrorActionPreference = 'Stop'

# UTF-8 (BOM 없이) 로 파일 저장 — UE 설정/프로젝트 파일 관례.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-TextNoBom {
    param([string] $Path, [string] $Content)
    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

# ---- 1) .uproject 경로 해석 -------------------------------------------------
function Resolve-UProject {
    param([string] $InputPath)
    if (-not (Test-Path -LiteralPath $InputPath)) {
        throw "경로를 찾을 수 없음: $InputPath"
    }
    $item = Get-Item -LiteralPath $InputPath
    if ($item.PSIsContainer) {
        $found = @(Get-ChildItem -LiteralPath $item.FullName -Filter *.uproject -File)
        if ($found.Count -eq 0) { throw "폴더에 .uproject 가 없음: $($item.FullName)" }
        if ($found.Count -gt 1) { throw ".uproject 가 여러 개라 특정 불가($($found.Count)개). 파일 경로를 직접 지정." }
        return $found[0].FullName
    }
    if ($item.Extension -ne '.uproject') { throw ".uproject 파일이 아님: $($item.FullName)" }
    return $item.FullName
}

# ---- INI 섹션 병합(다른 섹션/키 보존, 대상 키만 갱신, 없으면 추가) ----------
function Merge-IniSection {
    param(
        [string]                        $Path,
        [string]                        $Section,   # 예: [/Script/....Settings]
        [System.Collections.Specialized.OrderedDictionary] $Values
    )
    $lines = @()
    if (Test-Path -LiteralPath $Path) { $lines = @(Get-Content -LiteralPath $Path) }

    $out         = New-Object System.Collections.Generic.List[string]
    $inSection   = $false
    $sectionSeen = $false
    $written     = @{}

    foreach ($line in $lines) {
        if ($line -match '^\s*\[.+\]\s*$') {
            # 섹션 경계: 직전이 대상 섹션이었다면 누락 키를 flush
            if ($inSection) {
                foreach ($k in $Values.Keys) { if (-not $written[$k]) { $out.Add("$k=$($Values[$k])") } }
            }
            $inSection = ($line.Trim() -eq $Section)
            if ($inSection) { $sectionSeen = $true; $written = @{} }
            $out.Add($line)
            continue
        }
        if ($inSection -and ($line -match '^\s*([^=;#\[]+?)\s*=')) {
            $key = $Matches[1].Trim()
            if ($Values.Contains($key)) {
                $out.Add("$key=$($Values[$key])")
                $written[$key] = $true
                continue
            }
        }
        $out.Add($line)
    }
    if ($inSection) {
        foreach ($k in $Values.Keys) { if (-not $written[$k]) { $out.Add("$k=$($Values[$k])") } }
    }
    if (-not $sectionSeen) {
        if ($out.Count -gt 0 -and $out[$out.Count - 1].Trim() -ne '') { $out.Add('') }
        $out.Add($Section)
        foreach ($k in $Values.Keys) { $out.Add("$k=$($Values[$k])") }
    }
    return (($out -join "`r`n").TrimEnd() + "`r`n")
}

# ---------------------------------------------------------------------------
$uproj   = Resolve-UProject -InputPath $Project
$projDir = Split-Path -Parent $uproj

Write-Host ""
Write-Host "== Unreal MCP 셋업 ==" -ForegroundColor Cyan
Write-Host "프로젝트: $uproj"
if ($DryRun) { Write-Host "(DryRun — 파일을 쓰지 않음)" -ForegroundColor Yellow }
Write-Host ""

# ---- 2) .uproject 플러그인 주입 --------------------------------------------
$doc = (Get-Content -LiteralPath $uproj -Raw) | ConvertFrom-Json

$plugins = New-Object System.Collections.Generic.List[object]
if (($doc.PSObject.Properties.Name -contains 'Plugins') -and $doc.Plugins) {
    foreach ($p in $doc.Plugins) { $plugins.Add($p) }
}

$required   = 'ModelContextProtocol', 'AllToolsets'
$uprojDirty = $false

Write-Host "[Plugins]" -ForegroundColor Cyan
foreach ($name in $required) {
    $existing = $plugins | Where-Object { $_.Name -eq $name } | Select-Object -First 1
    if ($null -ne $existing) {
        $enabled = ($existing.PSObject.Properties.Name -contains 'Enabled') -and $existing.Enabled
        if (-not $enabled) {
            $existing | Add-Member -NotePropertyName Enabled -NotePropertyValue $true -Force
            $uprojDirty = $true
            Write-Host "  [~] $name  이미 있음 → Enabled=true" -ForegroundColor Yellow
        }
        else {
            Write-Host "  [=] $name  이미 활성 (건너뜀)" -ForegroundColor DarkGray
        }
    }
    else {
        $plugins.Add([pscustomobject]@{ Name = $name; Enabled = $true })
        $uprojDirty = $true
        Write-Host "  [+] $name  추가" -ForegroundColor Green
    }
}

if ($uprojDirty) {
    $doc | Add-Member -NotePropertyName Plugins -NotePropertyValue ($plugins.ToArray()) -Force
    $json = $doc | ConvertTo-Json -Depth 100
    if ($DryRun) {
        Write-Host "  -> (DryRun) .uproject 갱신 예정" -ForegroundColor Yellow
    }
    else {
        $bak = "$uproj.bak_" + (Get-Date -Format 'yyyyMMdd_HHmmss')
        Copy-Item -LiteralPath $uproj -Destination $bak
        Write-TextNoBom -Path $uproj -Content $json
        Write-Host "  -> .uproject 갱신 완료 (백업: $(Split-Path -Leaf $bak))" -ForegroundColor Green
    }
}
else {
    Write-Host "  -> 변경 없음 (두 플러그인 모두 이미 활성)" -ForegroundColor DarkGray
}

# ---- 3) 자동시작 config -----------------------------------------------------
if (-not $NoAutoStart) {
    Write-Host ""
    Write-Host "[Auto Start Server]" -ForegroundColor Cyan
    $iniDir  = Join-Path $projDir 'Config'
    $iniPath = Join-Path $iniDir  'DefaultEditorPerProjectUserSettings.ini'
    $section = '[/Script/ModelContextProtocolEngine.ModelContextProtocolSettings]'
    $values  = [ordered]@{
        'bAutoStartServer' = 'True'
        'ServerPortNumber' = "$Port"
        'ServerUrlPath'    = '/mcp'
    }
    $newContent = Merge-IniSection -Path $iniPath -Section $section -Values $values
    $oldContent = if (Test-Path -LiteralPath $iniPath) { Get-Content -LiteralPath $iniPath -Raw } else { '' }

    if ($newContent -eq $oldContent) {
        Write-Host "  [=] 자동시작 이미 설정됨 (건너뜀)" -ForegroundColor DarkGray
    }
    elseif ($DryRun) {
        Write-Host "  -> (DryRun) $iniPath 에 bAutoStartServer=True, ServerPortNumber=$Port 기록 예정" -ForegroundColor Yellow
    }
    else {
        if (-not (Test-Path -LiteralPath $iniDir)) { New-Item -ItemType Directory -Force -Path $iniDir | Out-Null }
        Write-TextNoBom -Path $iniPath -Content $newContent
        Write-Host "  [+] 자동시작 켬 → $(Split-Path -Leaf $iniPath) (bAutoStartServer=True, port=$Port)" -ForegroundColor Green
    }
}
else {
    Write-Host ""
    Write-Host "[Auto Start Server] -NoAutoStart 지정 → 건너뜀 (콘솔 'ModelContextProtocol.StartServer $Port' 로 수동 기동)" -ForegroundColor DarkGray
}

# ---- 4) 다음 단계 안내 ------------------------------------------------------
Write-Host ""
Write-Host "== 다음 단계 ==" -ForegroundColor Cyan
Write-Host "  1) 이 프로젝트 에디터를 재시작(플러그인 모듈 로드). 자동시작을 켰으면 :$Port 자동 기동."
Write-Host "     (또는 실행 인자에 -ModelContextProtocolStartServer 를 붙여도 즉시 기동)"
Write-Host "  2) Claude 쪽은 손댈 것 없음(전역 등록됨). 세션에서 /mcp → 리커넥트."
Write-Host "  3) 검증:  Test-NetConnection 127.0.0.1 -Port $Port -InformationLevel Quiet   (True면 서버 생존)"
Write-Host ""

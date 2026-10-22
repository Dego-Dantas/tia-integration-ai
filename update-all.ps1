<#
.SYNOPSIS
  [EM TESTE - PODE QUEBRAR]
  Atualizador automatico do OpenCode Portable (OpenCode v2 + Magic Context + TIA-PORTAL MCP).
  Preserva todas as configuracoes (opencode.json, magic-context.jsonc, tiaolder-version.txt, proxy, dados)
  e remove versoes antigas / arquivos temporarios (zero leftovers).

.PARAMETER Component
  Componente para atualizar: 'all' (padrao), 'opencode', 'magic-context' ou 'tia-mcp'.

.PARAMETER CheckOnly
  Apenas verifica se ha novas versoes disponiveis, sem baixar ou alterar arquivos.

.PARAMETER Force
  Forca a reinstalacao do(s) componente(s) mesmo que ja estejam na ultima versao.
#>
param(
  [ValidateSet('all', 'opencode', 'magic-context', 'tia-mcp')]
  [string]$Component = 'all',
  [switch]$CheckOnly,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
Set-Location $Root

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Step([string]$Msg) { Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Ok([string]$Msg)   { Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-Info([string]$Msg) { Write-Host "  [..] $Msg" -ForegroundColor Gray }
function Write-Warn([string]$Msg) { Write-Host "  [!!] $Msg" -ForegroundColor Yellow }

Write-Warn "AVISO: Atualizador automatico em fase de testes (pode quebrar)."

# Garantir arquivos de configuracao caso seja um clone novo do repositorio
$ocConfigPath = Join-Path $Root "config\opencode\opencode.json"
if (-not (Test-Path $ocConfigPath) -and (Test-Path (Join-Path $Root "opencode.example.json"))) {
  New-Item -ItemType Directory -Force -Path (Split-Path $ocConfigPath) | Out-Null
  Copy-Item (Join-Path $Root "opencode.example.json") $ocConfigPath -Force
}
$mcConfigPath = Join-Path $Root "config\cortexkit\magic-context.jsonc"
if (-not (Test-Path $mcConfigPath) -and (Test-Path (Join-Path $Root "magic-context.example.jsonc"))) {
  New-Item -ItemType Directory -Force -Path (Split-Path $mcConfigPath) | Out-Null
  Copy-Item (Join-Path $Root "magic-context.example.jsonc") $mcConfigPath -Force
}

# ---------------------------------------------------------------------------
# 1. Detectar conectividade (Direta no Host vs Proxy 192.168.79.1:3128 na VM)
# ---------------------------------------------------------------------------
Write-Step "Verificando conectividade de rede..."
$ProxyUrl = "http://192.168.79.1:3128"
$UseProxy = $false

try {
  $null = Invoke-RestMethod -Uri "https://registry.npmjs.org/-/ping" -TimeoutSec 4 -ErrorAction Stop
  Write-Ok "Conexao direta com a internet ativa."
} catch {
  try {
    $null = Invoke-RestMethod -Uri "https://registry.npmjs.org/-/ping" -Proxy $ProxyUrl -TimeoutSec 6 -ErrorAction Stop
    $UseProxy = $true
    $env:HTTP_PROXY  = $ProxyUrl
    $env:HTTPS_PROXY = $ProxyUrl
    $env:NO_PROXY    = "localhost,127.0.0.1,192.168.79.1"
    Write-Ok "Conexao via proxy do Host ativa ($ProxyUrl)."
  } catch {
    throw "Sem acesso a internet (direto ou via proxy $ProxyUrl). Verifique se o proxy.js esta rodando no Host."
  }
}

function Invoke-Api([string]$Uri) {
  $headers = @{ 'User-Agent' = 'opencode-portable-updater' }
  if ($UseProxy) {
    return Invoke-RestMethod -Uri $Uri -Headers $headers -Proxy $ProxyUrl
  } else {
    return Invoke-RestMethod -Uri $Uri -Headers $headers
  }
}

function Download-File([string]$Uri, [string]$OutFile) {
  if ($UseProxy) {
    & curl.exe -fL -x $ProxyUrl "$Uri" -o "$OutFile"
  } else {
    & curl.exe -fL "$Uri" -o "$OutFile"
  }
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $OutFile)) {
    throw "Falha ao baixar: $Uri"
  }
}

# ---------------------------------------------------------------------------
# 2. Ler versions.json atual
# ---------------------------------------------------------------------------
$VersionsPath = Join-Path $Root "versions.json"
if (Test-Path $VersionsPath) {
  $Versions = Get-Content $VersionsPath -Raw | ConvertFrom-Json
} else {
  $Versions = [pscustomobject]@{
    updatedAt  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    components = [pscustomobject]@{
      'TIA-PORTAL'    = [pscustomobject]@{ version = "0.0.0" }
      'plugin'        = [pscustomobject]@{ version = "0.0.0" }
      'magic-context' = [pscustomobject]@{ version = "0.0.0" }
      'proxy'         = [pscustomobject]@{ version = "FE01DD29" }
      'opencode'      = [pscustomobject]@{ version = "0.0.0" }
    }
  }
}

# Configurar ambiente XDG portatil para comandos do OpenCode
$env:XDG_CONFIG_HOME = Join-Path $Root "config"
$env:XDG_STATE_HOME  = Join-Path $Root "state"
$env:XDG_DATA_HOME   = Join-Path $Root "data"
$env:XDG_CACHE_HOME  = Join-Path $Root "cache"
$env:MAGIC_CONTEXT_STORAGE_DIR = Join-Path $Root "data\cortexkit-magic-context"
$env:MAGIC_CONTEXT_LOG_PATH    = Join-Path $Root "state\magic-context.log"
$env:OPENCODE_DISABLE_AUTOCOMPACT = "1"

function Stop-PortableProcesses {
  Get-Process | Where-Object { $_.Path -like "$Root*" } | Stop-Process -Force -ErrorAction SilentlyContinue
  Remove-Item (Join-Path $Root "config\opencode\service.json") -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# 3. Atualizar OpenCode (opencode.exe v2 via @opencode/cli-windows-x64)
# ---------------------------------------------------------------------------
if ($Component -in @('all', 'opencode')) {
  Write-Step "Verificando OpenCode (v2 standalone)..."
  $ocMeta   = Invoke-Api "https://registry.npmjs.org/@opencode/cli-windows-x64/latest"
  $latestOc = $ocMeta.version
  $currOc   = if (Test-Path "$Root\opencode.exe") { ((& "$Root\opencode.exe" --version 2>$null) -replace '^opencode\s+v?','').Trim() } else { "ausente" }

  Write-Info "Instalado: $currOc | Ultima versao: $latestOc"
  if ($CheckOnly) {
    if ($currOc -ne $latestOc) { Write-Warn "Atualizacao disponivel para OpenCode: $latestOc" }
    else { Write-Ok "OpenCode ja esta na ultima versao." }
  } elseif ($Force -or $currOc -ne $latestOc) {
    Write-Info "Baixando OpenCode v$latestOc..."
    Stop-PortableProcesses
    $tmpDir = Join-Path $Root "temp\oc_update"
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

    $tgzPath = Join-Path $tmpDir "opencode.tgz"
    Download-File $ocMeta.dist.tarball $tgzPath
    & tar.exe -xzf $tgzPath -C $tmpDir
    $newExe = Join-Path $tmpDir "package\bin\opencode.exe"
    if (-not (Test-Path $newExe)) { throw "opencode.exe nao encontrado no pacote baixado." }

    Copy-Item $newExe (Join-Path $Root "opencode.exe") -Force
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

    $Versions.components.opencode.version = $latestOc
    $Versions.components.plugin.version   = $latestOc
    Write-Ok "OpenCode atualizado para v$latestOc (sem leftovers)."
  } else {
    Write-Ok "OpenCode ja esta na ultima versao ($currOc)."
  }
}

# ---------------------------------------------------------------------------
# 4. Atualizar Magic Context (@cortexkit/opencode-magic-context)
# ---------------------------------------------------------------------------
if ($Component -in @('all', 'magic-context')) {
  Write-Step "Verificando Magic Context (@cortexkit/opencode-magic-context)..."
  $mcMeta   = Invoke-Api "https://registry.npmjs.org/@cortexkit/opencode-magic-context/latest"
  $latestMc = $mcMeta.version
  $currMc   = $Versions.components.'magic-context'.version
  $mcCacheParent = Join-Path $Root "cache\opencode\npm\@cortexkit"
  $expectedCacheDir = Join-Path $mcCacheParent "opencode-magic-context@$latestMc"

  Write-Info "Instalado: $currMc | Ultima versao: $latestMc"
  if ($CheckOnly) {
    if ($currMc -ne $latestMc -or -not (Test-Path $expectedCacheDir)) {
      Write-Warn "Atualizacao disponivel para Magic Context: $latestMc"
    } else {
      Write-Ok "Magic Context ja esta na ultima versao."
    }
  } elseif ($Force -or $currMc -ne $latestMc -or -not (Test-Path $expectedCacheDir)) {
    Write-Info "Atualizando Magic Context para v$latestMc..."
    Stop-PortableProcesses

    $ocConfigPath = Join-Path $Root "config\opencode\opencode.json"
    if (-not (Test-Path $ocConfigPath) -and (Test-Path (Join-Path $Root "opencode.json"))) {
      $ocConfigPath = Join-Path $Root "opencode.json"
    }
    $cfgObj = Get-Content $ocConfigPath -Raw | ConvertFrom-Json
    if ($cfgObj.PSObject.Properties['plugins']) {
      $cfgObj.PSObject.Properties.Remove('plugins')
    }
    [System.IO.File]::WriteAllText($ocConfigPath, ($cfgObj | ConvertTo-Json -Depth 10), $Utf8NoBom)

    if (Test-Path $mcCacheParent) {
      Get-ChildItem $mcCacheParent -Directory -Force | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    & "$Root\opencode.exe" plugin add "@cortexkit/opencode-magic-context@$latestMc"
    Stop-PortableProcesses

    $cfgText = [System.IO.File]::ReadAllText($ocConfigPath)
    [System.IO.File]::WriteAllText($ocConfigPath, $cfgText, $Utf8NoBom)

    $agenteTxtPath = Join-Path $Root "Guias\MAGIC_CONTEXT_AGENTE.txt"
    if (-not (Test-Path $agenteTxtPath) -and (Test-Path (Join-Path $Root "MAGIC_CONTEXT_AGENTE.txt"))) {
      $agenteTxtPath = Join-Path $Root "MAGIC_CONTEXT_AGENTE.txt"
    }
    if (Test-Path $agenteTxtPath) {
      $txt = [System.IO.File]::ReadAllText($agenteTxtPath)
      $txt = $txt -replace '@cortexkit/opencode-magic-context@[0-9]+\.[0-9]+\.[0-9]+', "@cortexkit/opencode-magic-context@$latestMc"
      [System.IO.File]::WriteAllText($agenteTxtPath, $txt, $Utf8NoBom)
    }

    $mcSource = Join-Path $Root "config\cortexkit\magic-context.jsonc"
    if (-not (Test-Path $mcSource)) { $mcSource = Join-Path $Root "magic-context.jsonc" }
    if (Test-Path $mcSource) {
      $userMcDir = Join-Path $HOME ".config\cortexkit"
      New-Item -ItemType Directory -Force -Path $userMcDir | Out-Null
      Copy-Item $mcSource (Join-Path $userMcDir "magic-context.jsonc") -Force
    }

    $Versions.components.'magic-context'.version = $latestMc
    Write-Ok "Magic Context atualizado para v$latestMc e caches antigos removidos."
  } else {
    if (Test-Path $mcCacheParent) {
      Get-ChildItem $mcCacheParent -Directory -Force |
        Where-Object { $_.Name -ne "opencode-magic-context@$latestMc" } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Ok "Magic Context ja esta na ultima versao ($currMc)."
  }
}

# ---------------------------------------------------------------------------
# 5. Atualizar MCP TIA Portal (bulaofen0036-coder/TIA_Portal_Openness_MCP)
# ---------------------------------------------------------------------------
if ($Component -in @('all', 'tia-mcp')) {
  Write-Step "Verificando MCP TIA-PORTAL (bulaofen0036-coder/TIA_Portal_Openness_MCP)..."
  $tiaRel    = Invoke-Api "https://api.github.com/repos/bulaofen0036-coder/TIA_Portal_Openness_MCP/releases/latest"
  $latestTia = ($tiaRel.tag_name -replace '^v','').Trim()
  $asset     = $tiaRel.assets | Where-Object { $_.name -like "TIA_MCP_Delivery_*.zip" } | Select-Object -First 1
  if (-not $asset) { throw "Asset TIA_MCP_Delivery_*.zip nao encontrado na release $($tiaRel.tag_name)." }

  $expectedFolder = [System.IO.Path]::GetFileNameWithoutExtension($asset.name)
  $tiaMcpRoot     = Join-Path $Root "tia-openness-mcp"
  $expectedPath   = Join-Path $tiaMcpRoot $expectedFolder
  $currTia        = $Versions.components.'TIA-PORTAL'.version

  Write-Info "Instalado: $currTia | Ultima versao: $latestTia ($expectedFolder)"
  if ($CheckOnly) {
    if ($currTia -ne $latestTia -or -not (Test-Path $expectedPath)) {
      Write-Warn "Atualizacao disponivel para MCP TIA-PORTAL: $latestTia"
    } else {
      Write-Ok "MCP TIA-PORTAL ja esta na ultima versao."
    }
  } elseif ($Force -or $currTia -ne $latestTia -or -not (Test-Path $expectedPath)) {
    Write-Info "Baixando $($asset.name)..."
    Stop-PortableProcesses

    $tmpDir = Join-Path $Root "temp\tia_update"
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

    $zipPath = Join-Path $tmpDir $asset.name
    Download-File $asset.browser_download_url $zipPath

    New-Item -ItemType Directory -Force -Path $tiaMcpRoot | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $tiaMcpRoot -Force
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

    if (-not (Test-Path $expectedPath)) {
      $extracted = Get-ChildItem $tiaMcpRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
      if (-not $extracted) { throw "Falha ao extrair o pacote do MCP TIA-PORTAL." }
      $expectedFolder = $extracted.Name
      $expectedPath   = $extracted.FullName
    }

    Get-ChildItem $tiaMcpRoot -Directory |
      Where-Object { $_.Name -ne $expectedFolder } |
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    $cmdContent = @(
      '@echo off',
      'set /p TIA_VER=<"%~dp0tiaolder-version.txt"',
      'if "%TIA_VER%"=="20" (',
      "    set `"BIN_PATH=%~dp0tia-openness-mcp\$expectedFolder\runtime\v20\TiaMcpServer.exe`"",
      ') else (',
      "    set `"BIN_PATH=%~dp0tia-openness-mcp\$expectedFolder\runtime\v21\TiaMcpServer.exe`"",
      '    set "TiaPortalLocation=C:\Program Files\Siemens\Automation\Portal V21\"',
      ')',
      '"%BIN_PATH%" --tia-major-version %TIA_VER% --profile full %*'
    ) -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path $Root "tia-openness.cmd"), $cmdContent, $Utf8NoBom)

    foreach ($mdRel in @(".opencode\agents\tiaolder.md", ".opencode\skills\tia-portal-scl\SKILL.md")) {
      $mdPath = Join-Path $Root $mdRel
      if (Test-Path $mdPath) {
        $mdText = [System.IO.File]::ReadAllText($mdPath)
        $mdText = $mdText -replace 'TIA_MCP_Delivery_v[0-9A-Za-z._-]+', $expectedFolder
        $mdText = $mdText -replace '(bulaofen0036[^\r\n]*?v)[0-9]+\.[0-9]+\.[0-9]+', "`${1}$latestTia"
        [System.IO.File]::WriteAllText($mdPath, $mdText, $Utf8NoBom)
      }
    }

    $Versions.components.'TIA-PORTAL'.version = $latestTia
    Write-Ok "MCP TIA-PORTAL atualizado para v$latestTia ($expectedFolder) e versoes antigas removidas."
  } else {
    Get-ChildItem $tiaMcpRoot -Directory |
      Where-Object { $_.Name -ne $expectedFolder } |
      Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-Ok "MCP TIA-PORTAL ja esta na ultima versao ($currTia)."
  }
}

# ---------------------------------------------------------------------------
# 6. Limpeza final de temporarios e gravacao do versions.json
# ---------------------------------------------------------------------------
if (-not $CheckOnly) {
  Get-ChildItem (Join-Path $Root "temp") -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
  $Versions.updatedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
  [System.IO.File]::WriteAllText($VersionsPath, ($Versions | ConvertTo-Json -Depth 5), $Utf8NoBom)
  Write-Step "Atualizacao concluida com sucesso! Configuracoes preservadas e zero leftovers."
}

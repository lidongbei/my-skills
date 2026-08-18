param(
  [switch]$WhatIf,
  [ValidateSet('user', 'project', 'local')]
  [string]$Scope = 'user'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$PluginManifest = Join-Path $Root '.claude-plugin\plugin.json'
$MarketplaceManifest = Join-Path $Root '.claude-plugin\marketplace.json'
$Validate = Join-Path $PSScriptRoot 'validate.ps1'

function Read-JsonFile {
  param([string]$Path)
  try {
    return Get-Content -Path $Path -Raw | ConvertFrom-Json
  } catch {
    throw "Invalid JSON manifest: $Path. $($_.Exception.Message)"
  }
}

function Invoke-Claude {
  param([string[]]$Arguments)
  & claude @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Claude Code command failed with exit code ${LASTEXITCODE}: claude $($Arguments -join ' ')"
  }
}

if (!(Test-Path $Validate)) {
  throw "Validation script not found: $Validate"
}
if (!(Test-Path $PluginManifest)) {
  throw "Plugin manifest not found: $PluginManifest"
}
if (!(Test-Path $MarketplaceManifest)) {
  throw "Marketplace manifest not found: $MarketplaceManifest"
}

& $Validate
$plugin = Read-JsonFile -Path $PluginManifest
$marketplace = Read-JsonFile -Path $MarketplaceManifest

if ([string]::IsNullOrWhiteSpace($plugin.name)) {
  throw "Plugin manifest has no name: $PluginManifest"
}
if ([string]::IsNullOrWhiteSpace($marketplace.name)) {
  throw "Marketplace manifest has no name: $MarketplaceManifest"
}

$marketplacePlugin = @($marketplace.plugins | Where-Object { $_.name -eq $plugin.name }) | Select-Object -First 1
if ($null -eq $marketplacePlugin) {
  throw "Marketplace '$($marketplace.name)' does not contain plugin '$($plugin.name)'."
}
if ($marketplacePlugin.source -ne './') {
  throw "Plugin '$($plugin.name)' must use source './' for this repository-root marketplace."
}

$repoPath = (Resolve-Path $Root).Path
$pluginReference = "$($plugin.name)@$($marketplace.name)"

Write-Host "Validated plugin '$($plugin.name)' from $repoPath"
Write-Host "Target scope: $Scope"

if ($WhatIf) {
  Write-Host "[WhatIf] Would register marketplace '$($marketplace.name)' from $repoPath with scope '$Scope'"
  Write-Host "[WhatIf] Would install plugin '$pluginReference' with scope '$Scope'"
  Write-Host "[WhatIf] No Claude Code configuration was changed."
  exit 0
}

$marketplaces = @(Invoke-Claude -Arguments @('plugin', 'marketplace', 'list', '--json') | ConvertFrom-Json)
$registered = @($marketplaces | Where-Object { $_.name -eq $marketplace.name }) | Select-Object -First 1

if ($null -eq $registered) {
  Write-Host "Registering marketplace '$($marketplace.name)' from $repoPath"
  Invoke-Claude -Arguments @('plugin', 'marketplace', 'add', $repoPath, '--scope', $Scope)
} elseif ($registered.source -eq 'directory' -and (Resolve-Path $registered.path).Path -eq $repoPath) {
  Write-Host "Marketplace '$($marketplace.name)' already points to $repoPath"
} else {
  throw "Marketplace '$($marketplace.name)' is already registered from another source: $($registered.installLocation)"
}

Write-Host "Installing plugin '$pluginReference' with scope '$Scope'"
Invoke-Claude -Arguments @('plugin', 'install', $pluginReference, '--scope', $Scope)
Write-Host "Plugin '$pluginReference' is persistently installed for scope '$Scope'."
Write-Host "For a current-session development load instead, use: claude --plugin-dir `"$repoPath`""

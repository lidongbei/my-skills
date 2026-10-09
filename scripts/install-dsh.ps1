<#
.SYNOPSIS
  Install this plugin's skills into the current DSH (DeepSeek Harness) agent environment using directory links.

.DESCRIPTION
  DSH discovers filesystem skills from these roots, highest rank first:

    <project>/.dsh/skills       project-dsh
    <project>/.agents/skills    project-agents
    <DSH_HOME>/skills           user-dsh
    ~/.agents/skills            user-agents

  See @deepseek-ai/dsh-skill-filesystem: it follows a directory link (NTFS junction or
  symbolic link) when discovering a skill entry, and it reads SKILL.md through the link.

  This script links skills/<name>/ into one of those roots instead of copying files.
  Because the installed skill is the repository directory itself, every later change in
  this repository - edited SKILL.md, new supporting files, and newly added skills - is
  picked up without reinstalling.

.PARAMETER Scope
  user    (default) Links into a user-level root, available in every DSH project.
  project           Links into a project-level root under -Target.

.PARAMETER RootKind
  dsh    (default) Uses the DSH-specific root: <DSH_HOME>/skills or <Target>/.dsh/skills.
  agents           Uses the shared agent root: ~/.agents/skills or <Target>/.agents/skills.

.PARAMETER Target
  The project directory whose project-level root receives the links.
  Required for -Scope project.

.PARAMETER DshHome
  Overrides the DSH home used by -Scope user -RootKind dsh.
  Default: $env:DSH_HOME, then $HOME/.dsh.

.PARAMETER LinkType
  auto     (default) Tries a directory junction first, then a symbolic link.
  junction Forces a directory junction (needs no special privilege on Windows).
  symbolic Forces a symbolic link (on Windows this needs Developer Mode or an elevated shell).

.PARAMETER Skills
  Skill names to link. Default: every directory with a SKILL.md under ./skills.

.PARAMETER Uninstall
  Removes the linked skills from the target root instead of creating them.

.PARAMETER WhatIf
  Prints the planned actions without changing anything.

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-dsh.ps1 -WhatIf

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-dsh.ps1

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-dsh.ps1 -Scope project -Target D:\work\my-app

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-dsh.ps1 -Uninstall
#>
param(
  [ValidateSet('user', 'project')]
  [string]$Scope = 'user',

  [ValidateSet('dsh', 'agents')]
  [string]$RootKind = 'dsh',

  [string]$Target,

  [string]$DshHome,

  [ValidateSet('auto', 'junction', 'symbolic')]
  [string]$LinkType = 'auto',

  [string[]]$Skills,

  [switch]$Uninstall,

  [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$Root       = Split-Path -Parent $PSScriptRoot
$SkillsRoot = Join-Path $Root 'skills'
$Validate   = Join-Path $PSScriptRoot 'validate.ps1'

function Write-Step {
  param([string]$Message)
  if ($WhatIf) { Write-Host "[WhatIf] $Message" } else { Write-Host $Message }
}

function Get-NormalizedPath {
  param([string]$Path)
  return ([System.IO.Path]::GetFullPath($Path)).TrimEnd('\', '/')
}

# Returns the recorded link target, $null for a real directory/file, or '' when the
# reparse point exists but exposes no readable target.
function Get-LinkTarget {
  param([string]$Path)
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
  if (-not ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) { return $null }
  $recorded = $item.Target
  if ($recorded -is [array]) { $recorded = $recorded[0] }
  if ([string]::IsNullOrWhiteSpace($recorded)) { return '' }
  return (Get-NormalizedPath $recorded)
}

# Windows PowerShell 5.1 can fail with a NullReferenceException when Remove-Item
# recurses into a directory reparse point, so delete the link through .NET first.
function Remove-SkillLink {
  param([string]$Path)
  try {
    [System.IO.Directory]::Delete($Path, $false)
  } catch {
    Remove-Item -LiteralPath $Path -Force -Recurse:$false -ErrorAction Stop
  }
}

function New-SkillLink {
  param([string]$LinkPath, [string]$SourcePath)

  $kinds = switch ($LinkType) {
    'junction' { @('junction') }
    'symbolic' { @('symbolic') }
    default { @('junction', 'symbolic') }
  }

  $failures = @()
  foreach ($kind in $kinds) {
    $itemType = if ($kind -eq 'junction') { 'Junction' } else { 'SymbolicLink' }
    try {
      New-Item -ItemType $itemType -Path $LinkPath -Target $SourcePath -ErrorAction Stop | Out-Null
      return $kind
    } catch {
      $failures += "$kind failed: $($_.Exception.Message)"
      if (Test-Path -LiteralPath $LinkPath) {
        try { Remove-SkillLink -Path $LinkPath } catch { }
      }
    }
  }

  throw ("Failed to link {0} -> {1}. {2} A symbolic link on Windows needs Developer Mode or an elevated shell; a directory junction normally needs neither, so check the target volume and permissions." -f $LinkPath, $SourcePath, ($failures -join ' | '))
}

# Get-FileHash is unavailable in some launch contexts (for example Windows PowerShell 5.1
# started from a PowerShell 7 shell or from cmd, where the inherited PSModulePath breaks
# cmdlet autoloading), so hash through .NET instead.
function Get-FileHashText {
  param([string]$FilePath)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $stream = [System.IO.File]::OpenRead($FilePath)
    try { return [System.BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
    finally { $stream.Dispose() }
  } finally { $sha.Dispose() }
}

# Compares every file of the source skill with the file reached through the link.
# Returns $null when the link follows the repository, else a failure description.
function Test-LinkFollows {
  param([string]$LinkPath, [string]$SourcePath)

  $sourceBase = Get-NormalizedPath $SourcePath
  foreach ($file in Get-ChildItem -LiteralPath $sourceBase -Recurse -File) {
    $relative = $file.FullName.Substring($sourceBase.Length).TrimStart('\', '/')
    $linked = Join-Path $LinkPath $relative
    if (!(Test-Path -LiteralPath $linked -PathType Leaf)) { return "missing file through link: $relative" }
    if ((Get-FileHashText -FilePath $file.FullName) -ne (Get-FileHashText -FilePath $linked)) { return "content mismatch through link: $relative" }
  }
  return $null
}

# 1. Resolve the target root that DSH scans.
if ($Scope -eq 'project') {
  if ([string]::IsNullOrWhiteSpace($Target)) {
    throw "-Scope project requires -Target <project directory>."
  }
  if (!(Test-Path -LiteralPath $Target -PathType Container)) {
    throw "Target project directory not found: $Target"
  }
  $TargetProject = (Resolve-Path -LiteralPath $Target).Path
  $targetFolder = if ($RootKind -eq 'dsh') { '.dsh' } else { '.agents' }
  $TargetRoot = Get-NormalizedPath (Join-Path $TargetProject "$targetFolder\skills")
  $GitignoreLine = "$targetFolder/"
} else {
  if ($RootKind -eq 'dsh') {
    $resolvedHome = if (![string]::IsNullOrWhiteSpace($DshHome)) { $DshHome }
      elseif (![string]::IsNullOrWhiteSpace($env:DSH_HOME)) { $env:DSH_HOME }
      else { Join-Path $HOME '.dsh' }
  } else {
    $resolvedHome = if (![string]::IsNullOrWhiteSpace($DshHome)) { $DshHome } else { Join-Path $HOME '.agents' }
  }
  $TargetRoot = Get-NormalizedPath (Join-Path $resolvedHome 'skills')
  $GitignoreLine = $null
}

Write-Step "Runtime: DSH (DeepSeek Harness)"
Write-Step "Repository: $Root"
Write-Step "Target skill root: $TargetRoot"

# 2. Resolve the source skills: every skill directory, or the explicit -Skills list.
if ($Skills) {
  $SkillNames = @($Skills)
} else {
  $SkillNames = @(
    Get-ChildItem -LiteralPath $SkillsRoot -Directory |
      Sort-Object Name |
      Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } |
      ForEach-Object { $_.Name }
  )
}
if ($SkillNames.Count -eq 0) {
  throw "No skill directories with SKILL.md found under $SkillsRoot"
}

# 3. Validate the source plugin shape before touching the environment.
if (!(Test-Path -LiteralPath $Validate)) {
  throw "Source validation script not found: $Validate"
}
Write-Step "Validating source plugin: $Validate"
if (!$WhatIf) { & $Validate | Out-Null }

if (!(Test-Path -LiteralPath $SkillsRoot)) {
  throw "Source skills directory not found: $SkillsRoot"
}

# 4. Remove the linked skills.
if ($Uninstall) {
  if (!(Test-Path -LiteralPath $TargetRoot)) {
    Write-Step "Nothing to remove; target root does not exist: $TargetRoot"
    Write-Step "Done."
    return
  }
  foreach ($skillName in $SkillNames) {
    $linkPath = Join-Path $TargetRoot $skillName
    if (!(Test-Path -LiteralPath $linkPath)) {
      Write-Step "Not installed, skipping: $linkPath"
      continue
    }
    $recorded = Get-LinkTarget -Path $linkPath
    if ($null -eq $recorded) {
      Write-Step "Skipped real directory (not a link): $linkPath"
      continue
    }
    Write-Step "Would remove link: $linkPath -> $recorded"
    if (!$WhatIf) {
      Remove-SkillLink -Path $linkPath
      Write-Step "Removed $skillName"
    }
  }
  Write-Step "Done."
  return
}

# 5. Ensure the target root exists.
if (!(Test-Path -LiteralPath $TargetRoot)) {
  Write-Step "Would create $TargetRoot"
  if (!$WhatIf) { New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null }
} else {
  Write-Step "Directory exists: $TargetRoot"
}

# 6. Link every skill so the installed copy follows the repository.
$linked = 0
foreach ($skillName in $SkillNames) {
  $sourceSkill = Join-Path $SkillsRoot $skillName
  $linkPath = Join-Path $TargetRoot $skillName

  if (!(Test-Path -LiteralPath $sourceSkill -PathType Container)) {
    throw "Skill is missing in source: $sourceSkill"
  }
  $sourceResolved = (Resolve-Path -LiteralPath $sourceSkill).Path

  if (Test-Path -LiteralPath $linkPath) {
    $recorded = Get-LinkTarget -Path $linkPath
    if ($null -eq $recorded) {
      throw "Existing real directory at $linkPath is not a link; move or remove it manually before installing."
    }
    if ($recorded -ne '' -and $recorded -eq (Get-NormalizedPath $sourceResolved)) {
      Write-Step "Link already in place: $linkPath"
      $linked++
      continue
    }
    Write-Step "Would remove stale link: $linkPath -> $(if ($recorded -eq '') { '<unreadable target>' } else { $recorded })"
    if (!$WhatIf) { Remove-SkillLink -Path $linkPath }
  }

  Write-Step "Would link $linkPath -> $sourceResolved"
  if (!$WhatIf) {
    $kind = New-SkillLink -LinkPath $linkPath -SourcePath $sourceResolved
    Write-Step "Linked $skillName ($kind)"
  }
  $linked++
}

# 7. Verify that each link really resolves to the repository content.
if (!$WhatIf) {
  $failures = @()
  foreach ($skillName in $SkillNames) {
    $linkPath = Join-Path $TargetRoot $skillName
    $sourceSkill = Join-Path $SkillsRoot $skillName
    $problem = Test-LinkFollows -LinkPath $linkPath -SourcePath $sourceSkill
    if ($problem) { $failures += "$skillName : $problem" }
  }
  if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    throw "Link verification failed; the installed skills do not follow the repository."
  }
  Write-Step "Verified $($SkillNames.Count) link(s): installed skills read the repository directly."
}

# 8. Keep a project-level root out of version control.
if ($GitignoreLine) {
  $gitignorePath = Join-Path $TargetProject '.gitignore'
  $existing = ''
  if (Test-Path -LiteralPath $gitignorePath) { $existing = Get-Content -LiteralPath $gitignorePath -Raw }
  $pattern = "(?m)^\s*$([regex]::Escape($GitignoreLine.TrimEnd('/')))/?\s*$"
  if ($existing -match $pattern) {
    Write-Step ".gitignore already ignores $GitignoreLine"
  } else {
    Write-Step "Would append '$GitignoreLine' to $gitignorePath"
    if (!$WhatIf) {
      if ($existing.Length -gt 0 -and -not $existing.EndsWith([Environment]::NewLine)) {
        Add-Content -Path $gitignorePath -Value ''
      }
      Add-Content -Path $gitignorePath -Value $GitignoreLine
      Write-Step "Updated $gitignorePath"
    }
  }
}

Write-Step "Installed $linked skill(s) for DSH via directory links; later repository changes apply without reinstalling."
Write-Step "Note: DSH watches the skill root itself. A newly linked skill is detected, but edits inside the repository are read through the link without a watcher event; restart the session if the skill catalog description looks stale."
Write-Step "Done."

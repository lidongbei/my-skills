param(
  [switch]$WhatIf,
  [Parameter(Mandatory = $true)]
  [string]$Source,
  [Parameter(Mandatory = $true)]
  [string]$Target
)

$ErrorActionPreference = 'Stop'

$Skills        = Join-Path $Source 'skills'
$Validate      = Join-Path $Source 'scripts\validate.ps1'
$TargetTrae    = Join-Path $Target '.trae'
$TargetSkills  = Join-Path $TargetTrae 'skills'
$Gitignore     = Join-Path $Target '.gitignore'
$GitignoreLine = '.trae/'

# Mirror PROJECT_SPEC.md / validate.ps1: install all eight skills.
$ApprovedSkills = @(
  'coding-workflow',
  'generating-reqable-docs',
  'idea-shaping',
  'team-memory',
  'using-tool',
  'writing-skills',
  'session-handoff-save',
  'session-handoff-load'
)

function Write-Step {
  param([string]$Message)
  if ($WhatIf) { Write-Host "[WhatIf] $Message" } else { Write-Host $Message }
}

# 1. Validate the source plugin shape.
if (!(Test-Path $Validate)) {
  throw "Source validation script not found: $Validate"
}
Write-Step "Validating source plugin: $Validate"
if (!$WhatIf) { & $Validate | Out-Null }

# 2. Sanity-check source and target.
if (!(Test-Path $Skills)) {
  throw "Source skills directory not found: $Skills"
}
if (!(Test-Path $Target)) {
  throw "Target project directory not found: $Target"
}

# 3. Ensure .trae/skills exists.
if (!(Test-Path $TargetSkills)) {
  Write-Step "Would create $TargetSkills"
  if (!$WhatIf) { New-Item -ItemType Directory -Path $TargetSkills -Force | Out-Null }
} else {
  Write-Step "Directory exists: $TargetSkills"
}

# 4. Link each approved skill as a symbolic link.
foreach ($skillName in $ApprovedSkills) {
  $sourceSkill = Join-Path $Skills $skillName
  $linkPath    = Join-Path $TargetSkills $skillName

  if (!(Test-Path $sourceSkill)) {
    throw "Approved skill is missing in source: $sourceSkill"
  }

  if (Test-Path $linkPath) {
    $item = Get-Item $linkPath -Force -ErrorAction Stop
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
      $targetResolved = (Resolve-Path $sourceSkill).Path
      if ($item.Target -eq $sourceSkill -or $item.Target -eq $targetResolved) {
        Write-Step "Link already in place: $linkPath"
        continue
      }
      Write-Step "Would remove stale link: $linkPath -> $($item.Target)"
      if (!$WhatIf) { Remove-Item $linkPath -Force }
    } else {
      throw "Existing non-link at $linkPath; remove it manually before reinstalling."
    }
  }

  Write-Step "Would link $sourceSkill -> $linkPath"
  if (!$WhatIf) {
    try {
      New-Item -ItemType Junction -Path $linkPath -Target $sourceSkill -ErrorAction Stop | Out-Null
    } catch {
      throw "Failed to create directory junction at $linkPath. Ensure source and target are on the same NTFS volume. Original error: $($_.Exception.Message)"
    }
    Write-Step "Linked $skillName"
  }
}

# 5. Add .trae/ to the target project's .gitignore if missing.
$existingGitignore = ''
if (Test-Path $Gitignore) {
  $existingGitignore = Get-Content $Gitignore -Raw
}
if ($existingGitignore -match "(?m)^\s*\.trae/?\s*$") {
  Write-Step ".gitignore already ignores .trae/"
} else {
  Write-Step "Would append '$GitignoreLine' to $Gitignore"
  if (!$WhatIf) {
    if ($existingGitignore.Length -gt 0 -and -not $existingGitignore.EndsWith([Environment]::NewLine)) {
      Add-Content -Path $Gitignore -Value ''
    }
    Add-Content -Path $Gitignore -Value $GitignoreLine
    Write-Step "Updated $Gitignore"
  }
}

Write-Step "Done."

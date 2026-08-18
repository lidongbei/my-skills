param(
  [switch]$WhatIf,
  [Parameter(Mandatory = $true)]
  [string]$Target
)

$ErrorActionPreference = 'Stop'

$Root            = Split-Path -Parent $PSScriptRoot
$Skills          = Join-Path $Root 'skills'
$Validate        = Join-Path $PSScriptRoot 'validate.ps1'
$TargetCodeArts  = Join-Path $Target '.codeartsdoer'
$TargetSkills    = Join-Path $TargetCodeArts 'skills'
$StatusFile      = Join-Path $TargetSkills 'ProjectSkillStatus.txt'
$Gitignore       = Join-Path $Target '.gitignore'
$GitignoreLine   = '.codeartsdoer/'

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

# 3. Ensure .codeartsdoer/skills exists.
if (!(Test-Path $TargetSkills)) {
  Write-Step "Would create $TargetSkills"
  if (!$WhatIf) { New-Item -ItemType Directory -Path $TargetSkills -Force | Out-Null }
} else {
  Write-Step "Directory exists: $TargetSkills"
}

# 4. Copy each approved skill as real files.
#    CodeArts does not follow directory junctions/symlinks when discovering
#    skills, so we copy real files instead of linking. Re-running the script
#    overwrites stale copies with the latest source content.
foreach ($skillName in $ApprovedSkills) {
  $sourceSkill = Join-Path $Skills $skillName
  $targetSkill = Join-Path $TargetSkills $skillName

  if (!(Test-Path $sourceSkill)) {
    throw "Approved skill is missing in source: $sourceSkill"
  }

  if (Test-Path $targetSkill) {
    $item = Get-Item $targetSkill -Force -ErrorAction Stop
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
      Write-Step "Would remove stale link at $targetSkill (junctions are not recognized by CodeArts)"
      if (!$WhatIf) { Remove-Item $targetSkill -Force }
    } else {
      Write-Step "Would replace existing copy at $targetSkill"
      if (!$WhatIf) { Remove-Item $targetSkill -Recurse -Force }
    }
  }

  Write-Step "Would copy $sourceSkill -> $targetSkill"
  if (!$WhatIf) {
    Copy-Item -Path $sourceSkill -Destination $targetSkill -Recurse -Force
    Write-Step "Copied $skillName"
  }
}

# 5. Write ProjectSkillStatus.txt so CodeArts registers each skill as enabled.
#    Format mirrors SystemSkillStatus.txt: one "<skill-name>=true" line per skill.
Write-Step "Would write $StatusFile"
if (!$WhatIf) {
  $statusLines = $ApprovedSkills | ForEach-Object { "$_=true" }
  $statusContent = $statusLines -join "`r`n"
  Set-Content -Path $StatusFile -Value $statusContent -Encoding UTF8 -NoNewline
  Write-Step "Wrote ProjectSkillStatus.txt with $($ApprovedSkills.Count) entries"
}

# 6. Add .codeartsdoer/ to the target project's .gitignore if missing.
$existingGitignore = ''
if (Test-Path $Gitignore) {
  $existingGitignore = Get-Content $Gitignore -Raw
}
if ($existingGitignore -match "(?m)^\s*\.codeartsdoer/?\s*$") {
  Write-Step ".gitignore already ignores .codeartsdoer/"
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

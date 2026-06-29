param(
  [switch]$WhatIf,
  [string[]]$Skill = @('idea-shaping', 'team-memory')
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $env:USERPROFILE '.claude\skills'
$Dest = Join-Path $Root 'skills'
$ApprovedSkills = @('idea-shaping', 'team-memory')
$Validate = Join-Path $PSScriptRoot 'validate.ps1'

foreach ($skillName in $Skill) {
  if ($ApprovedSkills -notcontains $skillName) {
    throw "Refusing to sync unapproved skill '$skillName'. Approved skills: $($ApprovedSkills -join ', ')"
  }
}

if (!(Test-Path $Source)) {
  throw "Source skills directory not found: $Source"
}

if (!(Test-Path $Dest)) {
  if ($WhatIf) {
    Write-Host "Would create $Dest"
  } else {
    New-Item -ItemType Directory -Path $Dest | Out-Null
  }
}

foreach ($skillName in $Skill) {
  $sourceSkill = Join-Path $Source $skillName
  $target = Join-Path $Dest $skillName

  if (!(Test-Path $sourceSkill)) {
    if ($WhatIf) {
      Write-Host "Would skip missing source skill: $sourceSkill"
      continue
    }
    throw "Source skill directory not found: $sourceSkill"
  }

  if ($WhatIf) {
    Write-Host "Would sync $sourceSkill -> $target"
  } else {
    if (Test-Path $target) { Remove-Item -Recurse -Force $target }
    Copy-Item -Recurse -Force $sourceSkill $target
    Write-Host "Synced $skillName"
  }
}

if (!$WhatIf) {
  & $Validate
}

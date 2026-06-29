param(
  [switch]$WhatIf,
  [string]$Target = "$env:USERPROFILE\.claude\skills"
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Source = Join-Path $Root 'skills'
$Validate = Join-Path $PSScriptRoot 'validate.ps1'
$ApprovedSkills = @('idea-shaping', 'team-memory')

& $Validate

if (!(Test-Path $Source)) {
  throw "Plugin skills directory not found: $Source"
}

if (!(Test-Path $Target)) {
  if ($WhatIf) {
    Write-Host "Would create $Target"
  } else {
    New-Item -ItemType Directory -Path $Target | Out-Null
  }
}

foreach ($skillName in $ApprovedSkills) {
  $sourceSkill = Join-Path $Source $skillName
  $targetSkill = Join-Path $Target $skillName

  if (!(Test-Path $sourceSkill)) {
    throw "Approved skill is missing: $sourceSkill"
  }

  if ($WhatIf) {
    Write-Host "Would install $sourceSkill -> $targetSkill"
  } else {
    if (Test-Path $targetSkill) { Remove-Item -Recurse -Force $targetSkill }
    Copy-Item -Recurse -Force $sourceSkill $targetSkill
    Write-Host "Installed $skillName"
  }
}

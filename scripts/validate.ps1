param()

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Skills = Join-Path $Root 'skills'
$PluginManifest = Join-Path $Root '.claude-plugin\plugin.json'
$SkillsIndex = Join-Path $Root 'skills-index.md'
$UserOnlySkills = @('coding-workflow', 'idea-shaping', 'team-memory', 'writing-skills')
$ModelInvocableSkills = @('using-tool')
$AllowedSkills = @($UserOnlySkills + $ModelInvocableSkills)
$errors = @()

function Add-ValidationError {
  param([string]$Message)
  $script:errors += $Message
}

function Get-FrontmatterValue {
  param(
    [string]$Content,
    [string]$Key
  )

  $pattern = "(?m)^$([regex]::Escape($Key)):\s*(.+?)\s*$"
  $match = [regex]::Match($Content, $pattern)
  if ($match.Success) {
    return $match.Groups[1].Value.Trim().Trim('"').Trim("'")
  }
  return $null
}

function Test-BroadTriggerPhrases {
  param([string]$Description)

  $broadTriggerPhrases = @(
    'Use when implementing',
    'fixing bugs',
    'refactoring',
    'resolving test/build/type failures',
    'changing multiple files',
    'continuing an approved development plan',
    'handling any non-trivial coding task',
    'wants to curate',
    'Trigger phrases include',
    'creating, editing, reviewing',
    'diagnosing skipped skill workflows',
    'deployment readiness before changing'
  )

  foreach ($phrase in $broadTriggerPhrases) {
    if ($Description -like "*$phrase*") {
      return "description contains broad auto-trigger phrase: $phrase"
    }
  }

  return $null
}

function Test-ExplicitInvocationDescription {
  param(
    [string]$Description,
    [string]$SkillName
  )

  if ($Description -notlike 'Use only when*') {
    return "description must start with 'Use only when'"
  }

  $namespacedCommand = "/my-skills:$SkillName"
  $plainCommand = "/$SkillName"
  if (($Description -notmatch [regex]::Escape($namespacedCommand)) -and ($Description -notmatch [regex]::Escape($plainCommand)) -and ($Description -notmatch [regex]::Escape($SkillName))) {
    return "description must name the explicit skill invocation for '$SkillName'"
  }

  if (($Description -notmatch 'explicitly invokes') -and ($Description -notmatch 'explicitly instructs')) {
    return "description must require explicit invocation or instruction"
  }

  return Test-BroadTriggerPhrases -Description $Description
}

function Test-ModelInvocableDescription {
  param([string]$Description)

  if ($Description -notlike 'Use when*') {
    return "model-invocable description must start with 'Use when'"
  }

  if ($Description -like 'Use only when*') {
    return "model-invocable description must not require explicit user invocation"
  }

  return Test-BroadTriggerPhrases -Description $Description
}

if (!(Test-Path $PluginManifest)) {
  Add-ValidationError "Missing plugin manifest: $PluginManifest"
} else {
  try {
    Get-Content $PluginManifest -Raw | ConvertFrom-Json | Out-Null
  } catch {
    Add-ValidationError "Plugin manifest is not valid JSON: $($_.Exception.Message)"
  }
}

if (!(Test-Path $Skills)) {
  Add-ValidationError "Missing skills directory: $Skills"
} else {
  $legacyPlugins = Join-Path $Skills 'plugins'
  if (Test-Path $legacyPlugins) {
    Add-ValidationError "Legacy nested plugin directory is not allowed: $legacyPlugins"
  }

  $skillDirs = @(Get-ChildItem -Path $Skills -Directory | Sort-Object Name)
  $actualNames = @($skillDirs | ForEach-Object { $_.Name })

  foreach ($name in $actualNames) {
    if ($AllowedSkills -notcontains $name) {
      Add-ValidationError "Unexpected skill directory: $name"
    }
  }

  foreach ($name in $AllowedSkills) {
    if ($actualNames -notcontains $name) {
      Add-ValidationError "Missing required skill directory: $name"
    }
  }

  foreach ($skillDir in $skillDirs) {
    $skillFile = Join-Path $skillDir.FullName 'SKILL.md'
    if (!(Test-Path $skillFile)) {
      Add-ValidationError "Missing SKILL.md in $($skillDir.FullName)"
      continue
    }

    $content = Get-Content $skillFile -Raw
    if ($content -notmatch '^---\s*\r?\n') {
      Add-ValidationError "Missing YAML frontmatter start in $skillFile"
      continue
    }

    $frontmatterName = Get-FrontmatterValue -Content $content -Key 'name'
    $frontmatterDescription = Get-FrontmatterValue -Content $content -Key 'description'
    $disableModelInvocation = Get-FrontmatterValue -Content $content -Key 'disable-model-invocation'

    if ([string]::IsNullOrWhiteSpace($frontmatterName)) {
      Add-ValidationError "Missing frontmatter name in $skillFile"
    } elseif ($frontmatterName -ne $skillDir.Name) {
      Add-ValidationError "Frontmatter name mismatch in $skillFile; expected '$($skillDir.Name)', got '$frontmatterName'"
    }

    if ([string]::IsNullOrWhiteSpace($frontmatterDescription)) {
      Add-ValidationError "Missing frontmatter description in $skillFile"
    } elseif ($UserOnlySkills -contains $skillDir.Name) {
      if ($disableModelInvocation -ne 'true') {
        Add-ValidationError "User-only skill must include disable-model-invocation: true in $skillFile"
      }

      $descriptionError = Test-ExplicitInvocationDescription -Description $frontmatterDescription -SkillName $skillDir.Name
      if ($descriptionError) {
        Add-ValidationError "Invalid frontmatter description in $skillFile; $descriptionError"
      }
    } elseif ($ModelInvocableSkills -contains $skillDir.Name) {
      if (![string]::IsNullOrWhiteSpace($disableModelInvocation)) {
        Add-ValidationError "Model-invocable skill must not include disable-model-invocation in $skillFile"
      }

      $descriptionError = Test-ModelInvocableDescription -Description $frontmatterDescription
      if ($descriptionError) {
        Add-ValidationError "Invalid frontmatter description in $skillFile; $descriptionError"
      }
    }

    if ($skillDir.Name -eq 'using-tool') {
      foreach ($runtimeFile in @('runtimes\claude-code.md', 'runtimes\codex.md')) {
        $runtimePath = Join-Path $skillDir.FullName $runtimeFile
        if (!(Test-Path $runtimePath)) {
          Add-ValidationError "Missing using-tool runtime mapping: $runtimePath"
        }
      }
    }
  }
}

if (!(Test-Path $SkillsIndex)) {
  Add-ValidationError "Missing skills index: $SkillsIndex"
} else {
  $indexContent = Get-Content $SkillsIndex -Raw
  foreach ($name in $AllowedSkills) {
    $expectedLink = "skills/$name/SKILL.md"
    if ($indexContent -notmatch [regex]::Escape($expectedLink)) {
      Add-ValidationError "skills-index.md missing link: $expectedLink"
    }
  }

  $unexpectedIndexLinks = [regex]::Matches($indexContent, 'skills/([^/]+)/SKILL\.md') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $AllowedSkills -notcontains $_ }
  foreach ($name in $unexpectedIndexLinks) {
    Add-ValidationError "skills-index.md references unexpected skill: $name"
  }
}

if ($errors.Count -gt 0) {
  $errors | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Host "Validation passed for one plugin with user-only skills: $($UserOnlySkills -join ', '); model-invocable skills: $($ModelInvocableSkills -join ', ')."

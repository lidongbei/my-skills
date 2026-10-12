<#
.SYNOPSIS
  Universal installer: choose the agent tools, choose the skills, choose link or copy.

.DESCRIPTION
  This is the repository's single install entry point. It installs any subset of this
  repository's skills into any subset of supported tool locations, either by directory link
  (so the installed skills follow this repository) or by copying real files.

  The script is self-contained: it reads this repository's `skills/` directory and never
  calls another script, so it works on its own.

  Supported tools and their skill roots, in this order:

    claude     user: ~/.claude/skills                  project: <project>/.claude/skills
    dsh        user: <DSH_HOME>/skills                 project: <project>/.dsh/skills
    codex      user: ~/.codex/skills                   project: <project>/.codex/skills
    agents     user: ~/.agents/skills                  project: <project>/.agents/skills

  Run without -Tools to get an interactive selection. Supplying -Tools makes the run
  non-interactive, which is what automation should use.

  Skill plan:

    The installer works with groups, and a group is installed as a whole. The plan is:

      core          coding-workflow, subagent-takeover, configuring-plugin, using-tool   (default)
      documents     generating-reqable-docs
      ideas-memory  idea-shaping

    Skills that are not listed in the plan are ignored by this script, both for installation
    and for removal. -Groups selects groups; -Skills selects exact skill names; an install
    with neither uses the default group, while an uninstall with neither removes every group.

  Local detection: each tool reports whether it is present on this machine (its state
  directory), whether its command is on PATH, or whether the -Target project already contains
  its folder. Detected tools are pre-selected in the wizard; every tool stays selectable.

.PARAMETER Tools
  Tool keys to install for: claude, dsh, codex, agents.
  Aliases: claude-code -> claude, deepseek -> dsh, shared -> agents.

.PARAMETER Skills
  Skill names to install, for exact control. A group is normally installed as a whole, so
  prefer -Groups; -Skills and -Groups cannot be combined.

.PARAMETER Groups
  Group keys from the skill plan: core, documents, ideas-memory, or "all". The
  interactive wizard offers exactly these groups.

.PARAMETER LinkType
  auto     (default) Directory link: tries an NTFS junction, then a symbolic link.
  junction Directory link: junction only (needs no special privilege on Windows).
  symbolic Directory link: symbolic link only (on Windows needs Developer Mode or an elevated shell).
  copy     Copies real files; the installed skills stop following this repository.

.PARAMETER Scope
  auto    (default) User-level root for user-capable tools, project-level root for the rest.
  user    User-level roots only; tools without one are skipped.
  project Project-level roots only, under -Target.

.PARAMETER Target
  Project directory for project-level roots. Required by -Scope project.

.PARAMETER Uninstall
  Removes the selected skills from the selected tool roots instead of installing them.
  Directory links are removed; a real directory is removed only when it mirrors the
  repository or when -Force is given.

.PARAMETER Force
  Overwrites (or deletes) a real directory that does not mirror the repository skills.

.PARAMETER Action
  install, reinstall, or uninstall. The interactive wizard asks for this first, before the
  skill and tool selection. On the command line it is the equivalent of the -Reinstall and
  -Uninstall switches, which still work.

.PARAMETER Reinstall
  Removes the selected skills from the selected roots and installs them again, even when an
  entry already points at this repository or already mirrors it. Without this switch a re-run
  is idempotent: valid entries are reported as "already in place" and left untouched.

.PARAMETER List
  Prints the skill plan (groups, skills and their one-line intros) and the tool roots with
  their local detection result, then exits.

.PARAMETER PlainSelect
  Forces the typed selection prompt (numbers, names, "a", 0 to cancel) instead of the
  arrow-key selector. The arrow-key selector is also skipped automatically when the console
  cannot deliver raw keys (redirected input or output, CI, ISE), because reading a key would
  block forever there.

.PARAMETER WhatIf
  Prints the planned actions without changing anything.

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -List

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools claude,dsh -Groups core

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools codex,agents -Scope project -Target D:\work\my-app

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/install-agent-skills.ps1 -Tools claude -LinkType copy
#>
param(
  [string[]]$Tools,

  [string[]]$Skills,

  [string[]]$Groups,

  [ValidateSet('install', 'reinstall', 'uninstall')]
  [string]$Action,

  [ValidateSet('auto', 'junction', 'symbolic', 'copy')]
  [string]$LinkType = 'auto',

  [ValidateSet('auto', 'user', 'project')]
  [string]$Scope = 'auto',

  [string]$Target,

  [switch]$Uninstall,

  [switch]$Reinstall,

  [switch]$Force,

  [switch]$List,

  [switch]$PlainSelect,

  [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# `powershell.exe -File script.ps1 -Skills a,b` passes one literal string, not an array,
# so split every supplied value on commas before use.
$Tools = @($Tools | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
$Skills = @($Skills | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
$Groups = @($Groups | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
if ($Tools.Count -eq 0) { $Tools = $null }
if ($Skills.Count -eq 0) { $Skills = $null }
if ($Groups.Count -eq 0) { $Groups = $null }

$Root       = Split-Path -Parent $PSScriptRoot
$SkillsRoot = Join-Path $Root 'skills'
$HomeDir    = $HOME

# ---- Skill plan ----------------------------------------------------------------
# The installer offers groups, not loose skills: a group is always installed as a whole.
# Every skill listed here gets its one-line intro shown in the wizard. Skills that are not
# listed in this plan are ignored by this script, both for installation and for removal.
$SkillPlan = @(
  [pscustomobject]@{
    Key = 'core'; Label = 'Core workflow'; Default = $true
    Note = 'Plan, delegate and adapt - the everyday coding set'
    Skills = @(
      [pscustomobject]@{ Name = 'coding-workflow'; Intro = 'Plan, approve, implement and validate non-trivial coding work' }
      [pscustomobject]@{ Name = 'subagent-takeover'; Intro = 'Split an approved plan into human-reviewed subtasks' }
      [pscustomobject]@{ Name = 'configuring-plugin'; Intro = 'Configure this plugin per project and repair its configuration blocks' }
      [pscustomobject]@{ Name = 'using-tool'; Intro = 'Load first: map portable tool actions to the current runtime' }
    )
  }
  [pscustomobject]@{
    Key = 'documents'; Label = 'Documents'; Default = $false
    Note = 'Produce interface documents from an API definition'
    Skills = @(
      [pscustomobject]@{ Name = 'generating-reqable-docs'; Intro = 'Generate a Reqable Collection 3.0 JSON interface document' }
    )
  }
  [pscustomobject]@{
    Key = 'ideas-memory'; Label = 'Ideas'; Default = $false
    Note = 'Turn ideas into actionable artifacts'
    Skills = @(
      [pscustomobject]@{ Name = 'idea-shaping'; Intro = 'Shape a product, feature or project idea into an actionable plan' }
    )
  }
)

$ToolAliases = @{
  'deepseek'     = 'dsh'
  'harness'      = 'dsh'
  'shared'       = 'agents'
  'agent'        = 'agents'
  'claude-code'  = 'claude'
  'claudecode'   = 'claude'
  'codeartsdoer' = 'codearts'
  'code-arts'    = 'codearts'
}

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
  param([string]$LinkPath, [string]$SourcePath, [string]$Kind)

  $kinds = switch ($Kind) {
    'junction' { @('junction') }
    'symbolic' { @('symbolic') }
    default { @('junction', 'symbolic') }
  }

  $failures = @()
  foreach ($candidate in $kinds) {
    $itemType = if ($candidate -eq 'junction') { 'Junction' } else { 'SymbolicLink' }
    try {
      New-Item -ItemType $itemType -Path $LinkPath -Target $SourcePath -ErrorAction Stop | Out-Null
      return $candidate
    } catch {
      $failures += "$candidate failed: $($_.Exception.Message)"
      if (Test-Path -LiteralPath $LinkPath) {
        try { Remove-SkillLink -Path $LinkPath } catch { }
      }
    }
  }

  throw ("Failed to link {0} -> {1}. {2} A symbolic link on Windows needs Developer Mode or an elevated shell; a directory junction normally needs neither." -f $LinkPath, $SourcePath, ($failures -join ' | '))
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

# True when the directory holds exactly the source skill's files with identical content.
function Test-DirectoryMirrors {
  param([string]$Path, [string]$Source)

  $sourceBase = Get-NormalizedPath $Source
  $sourceFiles = @(Get-ChildItem -LiteralPath $sourceBase -Recurse -File)
  $destFiles = @(Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction Stop)
  if ($sourceFiles.Count -ne $destFiles.Count) { return $false }
  foreach ($file in $sourceFiles) {
    $relative = $file.FullName.Substring($sourceBase.Length).TrimStart('\', '/')
    $mirror = Join-Path $Path $relative
    if (!(Test-Path -LiteralPath $mirror -PathType Leaf)) { return $false }
    if ((Get-FileHashText -FilePath $file.FullName) -ne (Get-FileHashText -FilePath $mirror)) { return $false }
  }
  return $true
}

function Add-GitignoreEntry {
  param([string]$ProjectDir, [string]$Entry)
  if ([string]::IsNullOrWhiteSpace($Entry)) { return }

  $gitignorePath = Join-Path $ProjectDir '.gitignore'
  $existing = ''
  if (Test-Path -LiteralPath $gitignorePath) { $existing = Get-Content -LiteralPath $gitignorePath -Raw }
  $pattern = "(?m)^\s*$([regex]::Escape($Entry.TrimEnd('/')))/?\s*$"
  if ($existing -match $pattern) {
    Write-Step ".gitignore already ignores $Entry"
    return
  }
  Write-Step "Would append '$Entry' to $gitignorePath"
  if (!$WhatIf) {
    if ($existing.Length -gt 0 -and -not $existing.EndsWith([Environment]::NewLine)) {
      Add-Content -Path $gitignorePath -Value ''
    }
    Add-Content -Path $gitignorePath -Value $Entry
    Write-Step "Updated $gitignorePath"
  }
}

# CodeArts registers a skill only when ProjectSkillStatus.txt lists it as enabled.
# The file mirrors the skills that are actually present in the root as
# "<skill-name>=true" lines, which is also the format CodeArts' own
# SystemSkillStatus.txt uses. Remove the file when nothing is left.
function Update-CodeArtsStatus {
  param([string]$ToolRoot)

  $statusFile = Join-Path $ToolRoot 'ProjectSkillStatus.txt'
  $installed = @()

  if (Test-Path -LiteralPath $ToolRoot) {
    $installed = @(
      Get-ChildItem -LiteralPath $ToolRoot -Directory |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } |
        ForEach-Object { $_.Name } |
        Sort-Object
    )
  }

  if ($installed.Count -eq 0) {
    if (Test-Path -LiteralPath $statusFile) {
      Write-Step "Would remove $statusFile (no skills left in $ToolRoot)"
      if (!$WhatIf) { Remove-Item -LiteralPath $statusFile -Force }
    }
    return
  }

  Write-Step "Would write $statusFile with $($installed.Count) entries"
  if ($WhatIf) { return }

  $statusLines = $installed | ForEach-Object { "$_=true" }
  Set-Content -LiteralPath $statusFile -Value ($statusLines -join "`r`n") -Encoding UTF8 -NoNewline
  Write-Step "Wrote ProjectSkillStatus.txt with $($installed.Count) entries"
}

function Read-Selection {
  param(
    [string]$Title,
    [string[]]$Items,
    [string[]]$Details,
    [string[]]$Info,
    [int[]]$Default
  )

  Write-Host ''
  Write-Host $Title
  for ($i = 0; $i -lt $Items.Count; $i++) {
    $detail = if ($Details -and $i -lt $Details.Count -and ![string]::IsNullOrWhiteSpace($Details[$i])) { "  $($Details[$i])" } else { '' }
    Write-Host ("  [{0,2}] {1}{2}" -f ($i + 1), $Items[$i], $detail)
    if ($Info -and $i -lt $Info.Count -and ![string]::IsNullOrWhiteSpace($Info[$i])) {
      foreach ($infoLine in ($Info[$i] -split "`n")) {
        if (![string]::IsNullOrWhiteSpace($infoLine)) { Write-Host "        $infoLine" }
      }
    }
  }
  $defaultText = if ($Default.Count -gt 0) { (($Default | ForEach-Object { $_ + 1 }) -join ',') } else { 'none' }

  while ($true) {
    $answer = Read-Host "(Enter=$defaultText, a=all, numbers/names comma-separated, 0=cancel)"
    if ([string]::IsNullOrWhiteSpace($answer)) { return @($Default) }
    $trimmed = $answer.Trim()
    if ($trimmed -eq '0') { return @() }
    if ($trimmed -in @('a', 'all', '*')) { return @(0..($Items.Count - 1)) }

    $picked = New-Object System.Collections.Generic.List[int]
    $valid = $true
    foreach ($token in ($trimmed -split '[,;\s]+' | Where-Object { $_ -ne '' })) {
      if ($token -match '^(\d+)-(\d+)$') {
        $from = [int]$Matches[1]
        $to = [int]$Matches[2]
        if ($from -lt 1 -or $to -gt $Items.Count -or $from -gt $to) { $valid = $false; Write-Host "Out of range: $token"; continue }
        foreach ($n in $from..$to) { if (!$picked.Contains($n - 1)) { $picked.Add($n - 1) } }
        continue
      }
      if ($token -match '^\d+$') {
        $n = [int]$token
        if ($n -lt 1 -or $n -gt $Items.Count) { $valid = $false; Write-Host "Out of range: $token"; continue }
        if (!$picked.Contains($n - 1)) { $picked.Add($n - 1) }
        continue
      }
      $matches = @(0..($Items.Count - 1) | Where-Object { $Items[$_] -like "$token*" })
      if ($matches.Count -eq 1) { if (!$picked.Contains($matches[0])) { $picked.Add($matches[0]) } }
      elseif ($matches.Count -gt 1) { $valid = $false; Write-Host "Ambiguous name: $token" }
      else { $valid = $false; Write-Host "Unknown entry: $token" }
    }

    if ($valid -and $picked.Count -gt 0) { return @($picked | Sort-Object) }
    Write-Host 'Nothing selected; try again.'
  }
}

# Console selectors driven by arrow keys. They are self-contained on purpose: the script
# passes every value in, and the -Keys / -NoRender parameters exist so the selection logic
# can be exercised without a console (tests feed a key sequence and skip drawing).
#
# Key codes used: 13 Enter, 27 Escape, 32 Space, 37 Left, 38 Up, 39 Right, 40 Down,
# 49-57 the digits 1-9, 65 A, 73 I, 78 N, 89 Y.

function Get-ConsoleWidth {
  try {
    $width = $Host.UI.RawUI.WindowSize.Width
    if ($width -lt 40) { return 40 }
    return $width - 1
  } catch {
    return 100
  }
}

function Write-SelectionLines {
  param([string[]]$Lines, [int]$ClearLines)

  $width = Get-ConsoleWidth
  $total = if ($Lines.Count -gt $ClearLines) { $Lines.Count } else { $ClearLines }
  for ($i = 0; $i -lt $total; $i++) {
    $text = if ($i -lt $Lines.Count) { $Lines[$i] } else { '' }
    if ($text.Length -gt $width) { $text = $text.Substring(0, $width) }
    Write-Host $text.PadRight($width)
  }
}

# Moves the cursor back to the first line of the block that was just drawn.
function Set-CursorToBlockStart {
  param([int]$LineCount)
  try {
    $position = $Host.UI.RawUI.CursorPosition
    $top = $position.Y - $LineCount
    if ($top -lt 0) { $top = 0 }
    $position.X = 0
    $position.Y = $top
    $Host.UI.RawUI.CursorPosition = $position
    return $true
  } catch {
    return $false
  }
}

# Reads one key. With -Keys the sequence is consumed instead of the console.
function Read-UiKey {
  param([object[]]$Keys, [ref]$Index)

  if ($null -ne $Keys) {
    if ($Index.Value -ge $Keys.Count) { return $null }
    $key = $Keys[$Index.Value]
    $Index.Value = $Index.Value + 1
    return $key
  }

  try {
    return $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  } catch {
    return $null
  }
}

# Multi-select. Returns the selected 0-based indexes, or $null when cancelled with Escape.
# Enter with nothing selected does not confirm: it shows a notice and keeps waiting, so a
# selection always contains at least one item. -Info supplies non-selectable detail lines
# printed under an item (one string per item, lines separated by newlines).
function Read-MultiSelect {
  param(
    [string]$Title,
    [string[]]$Items,
    [string[]]$Details,
    [string[]]$Info,
    [int[]]$Default,
    [object[]]$Keys,
    [switch]$NoRender
  )

  $chosen = @()
  for ($i = 0; $i -lt $Items.Count; $i++) { $chosen += $false }
  foreach ($index in $Default) { if ($index -ge 0 -and $index -lt $Items.Count) { $chosen[$index] = $true } }

  $cursor = 0
  $keyIndex = 0
  $drawnLines = 0
  $notice = ''

  while ($true) {
    if (!$NoRender) {
      if ($drawnLines -gt 0) { $null = Set-CursorToBlockStart -LineCount $drawnLines }
      $count = @($chosen | Where-Object { $_ -eq $true }).Count
      $lines = @("$Title ($count/$($Items.Count) selected)")
      for ($i = 0; $i -lt $Items.Count; $i++) {
        $marker = if ($i -eq $cursor) { '>' } else { ' ' }
        $box = if ($chosen[$i] -eq $true) { '[x]' } else { '[ ]' }
        $detail = if ($Details -and $i -lt $Details.Count -and ![string]::IsNullOrWhiteSpace($Details[$i])) { "  $($Details[$i])" } else { '' }
        $lines += "  $marker $box $($Items[$i])$detail"
        if ($Info -and $i -lt $Info.Count -and ![string]::IsNullOrWhiteSpace($Info[$i])) {
          foreach ($infoLine in ($Info[$i] -split "`n")) {
            if (![string]::IsNullOrWhiteSpace($infoLine)) { $lines += "      $infoLine" }
          }
        }
      }
      $lines += '  Up/Down move  Space toggle  A all  N none  I invert  Enter confirm  Esc cancel'
      if (![string]::IsNullOrWhiteSpace($notice)) { $lines += "  $notice" }
      Write-SelectionLines -Lines $lines -ClearLines $drawnLines
      $drawnLines = $lines.Count
    }

    $key = Read-UiKey -Keys $Keys -Index ([ref]$keyIndex)
    if ($null -eq $key) { return $null }

    switch ([int]$key.VirtualKeyCode) {
      38 { if ($cursor -gt 0) { $cursor-- }; $notice = '' }
      40 { if ($cursor -lt $Items.Count - 1) { $cursor++ }; $notice = '' }
      32 { $chosen[$cursor] = -not $chosen[$cursor]; $notice = '' }
      65 { for ($i = 0; $i -lt $Items.Count; $i++) { $chosen[$i] = $true }; $notice = '' }
      78 { for ($i = 0; $i -lt $Items.Count; $i++) { $chosen[$i] = $false }; $notice = '' }
      73 { for ($i = 0; $i -lt $Items.Count; $i++) { $chosen[$i] = -not $chosen[$i] }; $notice = '' }
      13 {
        $result = @()
        for ($i = 0; $i -lt $Items.Count; $i++) { if ($chosen[$i] -eq $true) { $result += $i } }
        if ($result.Count -eq 0) {
          $notice = 'Nothing selected - tick at least one, or press Esc to cancel'
          continue
        }
        if (!$NoRender) { Write-Host '' }
        return $result
      }
      27 {
        if (!$NoRender) { Write-Host '' }
        return $null
      }
    }
  }
}

# Single-select. Returns the chosen 0-based index, or -1 when cancelled with Escape.
function Read-SingleSelect {
  param(
    [string]$Title,
    [string[]]$Items,
    [string[]]$Details,
    [int]$Default = 0,
    [object[]]$Keys,
    [switch]$NoRender
  )

  $cursor = if ($Default -ge 0 -and $Default -lt $Items.Count) { $Default } else { 0 }
  $keyIndex = 0
  $drawnLines = 0

  while ($true) {
    if (!$NoRender) {
      if ($drawnLines -gt 0) { $null = Set-CursorToBlockStart -LineCount $drawnLines }
      $lines = @($Title)
      for ($i = 0; $i -lt $Items.Count; $i++) {
        $marker = if ($i -eq $cursor) { '>' } else { ' ' }
        $radio = if ($i -eq $cursor) { '(*)' } else { '( )' }
        $detail = if ($Details -and $i -lt $Details.Count -and ![string]::IsNullOrWhiteSpace($Details[$i])) { "  $($Details[$i])" } else { '' }
        $lines += "  $marker $radio $($Items[$i])$detail"
      }
      $lines += '  Up/Down or Left/Right move  digits jump  Enter confirm  Esc cancel'
      Write-SelectionLines -Lines $lines -ClearLines $drawnLines
      $drawnLines = $lines.Count
    }

    $key = Read-UiKey -Keys $Keys -Index ([ref]$keyIndex)
    if ($null -eq $key) { return -1 }

    $code = [int]$key.VirtualKeyCode
    switch ($code) {
      37 { if ($cursor -gt 0) { $cursor-- } }
      38 { if ($cursor -gt 0) { $cursor-- } }
      39 { if ($cursor -lt $Items.Count - 1) { $cursor++ } }
      40 { if ($cursor -lt $Items.Count - 1) { $cursor++ } }
      13 {
        if (!$NoRender) { Write-Host '' }
        return $cursor
      }
      27 {
        if (!$NoRender) { Write-Host '' }
        return -1
      }
      default {
        if ($code -ge 49 -and $code -le 57) {
          $jump = $code - 49
          if ($jump -lt $Items.Count) { $cursor = $jump }
        }
      }
    }
  }
}

# Single-key yes/no. Returns $true for yes, $false for no or cancel.
function Read-KeyConfirm {
  param(
    [string]$Prompt,
    [bool]$DefaultYes = $true,
    [object[]]$Keys,
    [switch]$NoRender
  )

  $keyIndex = 0
  if (!$NoRender) { Write-Host -NoNewline "$Prompt " }

  while ($true) {
    $key = Read-UiKey -Keys $Keys -Index ([ref]$keyIndex)
    if ($null -eq $key) { return $DefaultYes }

    $code = [int]$key.VirtualKeyCode
    if ($code -eq 89) { if (!$NoRender) { Write-Host 'yes' }; return $true }
    if ($code -eq 78) { if (!$NoRender) { Write-Host 'no' }; return $false }
    if ($code -eq 13) {
      if (!$NoRender) { Write-Host $(if ($DefaultYes) { 'yes' } else { 'no' }) }
      return $DefaultYes
    }
    if ($code -eq 27) { if (!$NoRender) { Write-Host 'cancelled' }; return $false }
  }
}

# True only when a real console can deliver raw keys. Redirected input or output (piped
# stdin, `< file`, the web harness, CI, ISE) would make ReadKey block forever, so the
# caller falls back to the typed prompt instead.
function Test-KeyInputAvailable {
  param([switch]$PlainSelect)

  if ($PlainSelect) { return $false }
  try {
    if ([Console]::IsInputRedirected) { return $false }
    if ([Console]::IsOutputRedirected) { return $false }
  } catch {
    return $false
  }
  try {
    $null = $Host.UI.RawUI.WindowSize
  } catch {
    return $false
  }
  return $true
}

function Get-ToolCatalog {
  param([string]$ProjectDir)

  $dshHome = if (![string]::IsNullOrWhiteSpace($env:DSH_HOME)) { $env:DSH_HOME } else { Join-Path $HomeDir '.dsh' }
  $agentsHome = if (![string]::IsNullOrWhiteSpace($env:DSH_AGENTS_HOME)) { $env:DSH_AGENTS_HOME } else { Join-Path $HomeDir '.agents' }

  $catalog = @(
    [pscustomobject]@{
      Key = 'dsh'; Label = 'DSH (DeepSeek Harness)'
      UserRoot = (Join-Path $dshHome 'skills'); ProjectFolder = '.dsh'
      Gitignore = '.dsh/'; CopyOnly = $false; SupportsUser = $true
      DetectPaths = @($dshHome); DetectCommands = @('dsh'); ProjectMarkers = @('.dsh')
      Note = 'follows directory links'
    }
    [pscustomobject]@{
      Key = 'agents'; Label = 'Shared cross-runtime agent skills'
      UserRoot = (Join-Path $agentsHome 'skills'); ProjectFolder = '.agents'
      Gitignore = '.agents/'; CopyOnly = $false; SupportsUser = $true
      DetectPaths = @($agentsHome); DetectCommands = @(); ProjectMarkers = @('.agents')
      Note = 'follows directory links'
    }
    [pscustomobject]@{
      Key = 'codex'; Label = 'Codex'
      UserRoot = (Join-Path $HomeDir '.codex\skills'); ProjectFolder = '.codex'
      Gitignore = $null; CopyOnly = $false; SupportsUser = $true
      DetectPaths = @((Join-Path $HomeDir '.codex')); DetectCommands = @('codex'); ProjectMarkers = @('.codex')
      Note = ''
    }
    [pscustomobject]@{
      Key = 'claude'; Label = 'Claude Code user skills'
      UserRoot = (Join-Path $HomeDir '.claude\skills'); ProjectFolder = '.claude'
      Gitignore = $null; CopyOnly = $false; SupportsUser = $true
      DetectPaths = @((Join-Path $HomeDir '.claude')); DetectCommands = @('claude'); ProjectMarkers = @('.claude')
      Note = 'skill directories only; plugin installation is not covered'
    }
    [pscustomobject]@{
      Key = 'trae'; Label = 'Trae IDE'
      UserRoot = $null; ProjectFolder = '.trae'
      Gitignore = '.trae/'; CopyOnly = $false; SupportsUser = $false
      DetectPaths = @((Join-Path $HomeDir '.trae-cn'), (Join-Path $HomeDir '.trae')); DetectCommands = @(); ProjectMarkers = @('.trae')
      Note = 'project only'
    }
    [pscustomobject]@{
      Key = 'codearts'; Label = 'CodeArts (Huawei Cloud)'
      UserRoot = $null; ProjectFolder = '.codeartsdoer'
      Gitignore = '.codeartsdoer/'; CopyOnly = $true; SupportsUser = $false
      DetectPaths = @((Join-Path $HomeDir '.codeartsdoer'), (Join-Path $HomeDir '.codearts-doer-for-coding')); DetectCommands = @(); ProjectMarkers = @('.codeartsdoer')
      Note = 'project only; copies real files'
    }
    [pscustomobject]@{
      Key = 'custom'; Label = 'Custom directory (-Path)'
      UserRoot = $null; ProjectFolder = $null
      Gitignore = $null; CopyOnly = $false; SupportsUser = $false
      DetectPaths = @(); DetectCommands = @(); ProjectMarkers = @()
      Note = 'needs -Path'
    }
  )

  foreach ($tool in $catalog) {
    $projectRoot = $null
    if (![string]::IsNullOrWhiteSpace($ProjectDir) -and ![string]::IsNullOrWhiteSpace($tool.ProjectFolder)) {
      $projectRoot = Join-Path $ProjectDir ($tool.ProjectFolder + '\skills')
    }

    # Local detection: state directory, command on PATH, or the -Target project already
    # carrying the tool's folder.
    $reasons = @()
    foreach ($probe in $tool.DetectPaths) {
      if (Test-Path -LiteralPath $probe) { $reasons += $probe }
    }
    foreach ($commandName in $tool.DetectCommands) {
      try {
        if (Get-Command -Name $commandName -ErrorAction SilentlyContinue) { $reasons += "command $commandName" }
      } catch { }
    }
    if (![string]::IsNullOrWhiteSpace($ProjectDir)) {
      foreach ($marker in $tool.ProjectMarkers) {
        $markerPath = Join-Path $ProjectDir $marker
        if (Test-Path -LiteralPath $markerPath) { $reasons += $markerPath }
      }
    }

    $reason = if ($reasons.Count -gt 0) { $reasons[0] } else { '' }
    $tool | Add-Member -NotePropertyName ProjectRoot -NotePropertyValue $projectRoot
    $tool | Add-Member -NotePropertyName Detected -NotePropertyValue ($reasons.Count -gt 0)
    $tool | Add-Member -NotePropertyName DetectReason -NotePropertyValue $reason
  }

  return $catalog
}

function Resolve-ToolTargets {
  param(
    [object]$Tool,
    [string]$ProjectDir,
    [string]$CustomPath
  )

  $targets = @()

  if ($Tool.Key -eq 'custom') {
    if (![string]::IsNullOrWhiteSpace($CustomPath)) {
      $targets += [pscustomobject]@{ Scope = 'custom'; Root = (Get-NormalizedPath $CustomPath) }
    }
    return $targets
  }

  $useUser = switch ($Scope) { 'user' { $true } 'project' { $false } default { $Tool.SupportsUser } }
  $useProject = switch ($Scope) { 'user' { $false } 'project' { $true } default { -not $Tool.SupportsUser } }

  if ($useUser -and $Tool.SupportsUser) {
    $targets += [pscustomobject]@{ Scope = 'user'; Root = (Get-NormalizedPath $Tool.UserRoot) }
  }
  if ($useProject -and $Tool.ProjectFolder -and ![string]::IsNullOrWhiteSpace($ProjectDir)) {
    $targets += [pscustomobject]@{ Scope = 'project'; Root = (Get-NormalizedPath (Join-Path $ProjectDir ($Tool.ProjectFolder + '\skills'))) }
  }

  return $targets
}

# Installs or removes one skill for one tool root. Returns 'installed', 'linked',
# 'unchanged', 'removed', or 'skipped'.
function Invoke-SkillEntry {
  param(
    [string]$SkillName,
    [string]$SourceSkill,
    [string]$ToolRoot,
    [string]$Mode
  )

  $dest = Join-Path $ToolRoot $SkillName
  $sourceResolved = (Resolve-Path -LiteralPath $SourceSkill).Path
  $normalizedSource = Get-NormalizedPath $sourceResolved
  $exists = Test-Path -LiteralPath $dest

  if ($Uninstall) {
    if (!$exists) { return 'skipped' }
    $recorded = Get-LinkTarget -Path $dest
    if ($null -eq $recorded) {
      if ((Test-DirectoryMirrors -Path $dest -Source $sourceResolved) -or $Force) {
        Write-Step "Would remove copied skill directory: $dest"
        if (!$WhatIf) {
          Remove-Item -LiteralPath $dest -Recurse -Force
          Write-Host "Removed copy $SkillName <- $dest"
        }
        return 'removed'
      }
      Write-Host "Skipped real directory that does not mirror the repository: $dest (use -Force to delete)"
      return 'skipped'
    }
    Write-Step "Would remove link: $dest -> $(if ($recorded -eq '') { '<unreadable target>' } else { $recorded })"
    if (!$WhatIf) {
      Remove-SkillLink -Path $dest
      Write-Host "Removed link $SkillName <- $dest"
    }
    return 'removed'
  }

  if ($exists) {
    $recorded = Get-LinkTarget -Path $dest
    if ($null -eq $recorded) {
      if (Test-DirectoryMirrors -Path $dest -Source $sourceResolved) {
        if ($Reinstall) {
          Write-Step "Would remove previous copy for reinstall: $dest"
        } elseif ($Mode -eq 'copy') {
          Write-Step "Would refresh previous copy: $dest"
        } else {
          Write-Step "Removing previous copy to replace it with a link: $dest"
        }
        if (!$WhatIf) { Remove-Item -LiteralPath $dest -Recurse -Force }
      } elseif ($Force) {
        Write-Step "Would overwrite real directory (-Force): $dest"
        if (!$WhatIf) { Remove-Item -LiteralPath $dest -Recurse -Force }
      } else {
        throw "Existing real directory at $dest does not mirror '$SkillName'; re-run with -Force to overwrite it, or remove it manually."
      }
    } elseif ($Reinstall) {
      Write-Step "Would remove existing link for reinstall: $dest -> $(if ($recorded -eq '') { '<unreadable target>' } else { $recorded })"
      if (!$WhatIf) { Remove-SkillLink -Path $dest }
    } elseif ($Mode -ne 'copy' -and $recorded -ne '' -and $recorded -eq $normalizedSource) {
      Write-Step "Link already in place: $dest"
      return 'unchanged'
    } else {
      Write-Step "Would remove existing link: $dest -> $(if ($recorded -eq '') { '<unreadable target>' } else { $recorded })"
      if (!$WhatIf) { Remove-SkillLink -Path $dest }
    }
  }

  if ($Mode -eq 'copy') {
    Write-Step "Would copy $sourceResolved -> $dest"
    if (!$WhatIf) {
      Copy-Item -LiteralPath $sourceResolved -Destination $dest -Recurse -Force
      Write-Host "Copied $SkillName -> $dest"
    }
    return 'installed'
  }

  Write-Step "Would link $dest -> $sourceResolved"
  if (!$WhatIf) {
    $kind = New-SkillLink -LinkPath $dest -SourcePath $sourceResolved -Kind $Mode
    Write-Host "Linked $SkillName ($kind) -> $dest"
  }
  return 'linked'
}

# ---- 1. Skill plan -------------------------------------------------------------

$AllSkills = @(
  Get-ChildItem -LiteralPath $SkillsRoot -Directory |
    Sort-Object Name |
    Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') } |
    ForEach-Object { $_.Name }
)
if ($AllSkills.Count -eq 0) { throw "No skill directories with SKILL.md found under $SkillsRoot" }

$PlanSkillNames = @()
foreach ($planGroup in $SkillPlan) {
  foreach ($planSkill in $planGroup.Skills) { $PlanSkillNames += $planSkill.Name }
}
$MissingPlanSkills = @($PlanSkillNames | Where-Object { $AllSkills -notcontains $_ })
if ($MissingPlanSkills.Count -gt 0) {
  throw "The skill plan references skill(s) that do not exist under ${SkillsRoot}: $($MissingPlanSkills -join ', '). Update the plan in this script or restore the skill directory."
}
$DefaultGroupKeys = @($SkillPlan | Where-Object { $_.Default } | ForEach-Object { $_.Key })
$PlanSkillWidth = 1
foreach ($planSkillName in $PlanSkillNames) {
  if ($planSkillName.Length -gt $PlanSkillWidth) { $PlanSkillWidth = $planSkillName.Length }
}

# Group rows for the wizards: label, one-line group note, and the skill intro lines shown
# underneath. A group is selected as a whole, so only the group rows are selectable.
$GroupItems = @()
$GroupDetails = @()
$GroupInfo = @()
foreach ($planGroup in $SkillPlan) {
  $count = $planGroup.Skills.Count
  $word = if ($count -eq 1) { 'skill' } else { 'skills' }
  $GroupItems += $planGroup.Label
  $GroupDetails += "($count $word) $($planGroup.Note)"
  $infoLines = @()
  foreach ($planSkill in $planGroup.Skills) {
    $infoLines += ("  {0}  {1}" -f $planSkill.Name.PadRight($PlanSkillWidth), $planSkill.Intro)
  }
  $GroupInfo += ($infoLines -join "`n")
}

function Resolve-PlanGroupKey {
  param([string]$Value)
  $raw = $Value.Trim().ToLowerInvariant()
  if ($raw -eq 'all' -or $raw -eq '*') { return 'all' }
  # Accept the key, the label ("Ideas and memory") or an unambiguous prefix.
  $needle = ($raw -replace '[^a-z0-9]+', '-').Trim('-')
  if ([string]::IsNullOrWhiteSpace($needle)) { return $null }
  $exact = @($SkillPlan | Where-Object { $_.Key -eq $needle })
  if ($exact.Count -eq 1) { return $exact[0].Key }
  $byLabel = @($SkillPlan | Where-Object { ($_.Label -replace '[^a-z0-9]+', '-').Trim('-').ToLowerInvariant() -eq $needle })
  if ($byLabel.Count -eq 1) { return $byLabel[0].Key }
  $byPrefix = @($SkillPlan | Where-Object { $_.Key -like "$needle*" })
  if ($byPrefix.Count -eq 1) { return $byPrefix[0].Key }
  return $null
}

# ---- 2. Tool catalog -----------------------------------------------------------

$ProjectDir = $Target
$catalog = @(Get-ToolCatalog -ProjectDir $ProjectDir)

if ($List) {
  Write-Host "Repository: $Root"
  Write-Host ''
  Write-Host "Skill plan ($($SkillPlan.Count) groups, $($PlanSkillNames.Count) skills):"
  foreach ($planGroup in $SkillPlan) {
    $mark = if ($planGroup.Default) { '  [installed by default]' } else { '' }
    Write-Host ("  {0}  ({1}){2}" -f $planGroup.Key, $planGroup.Label, $mark)
    Write-Host ("      {0}" -f $planGroup.Note)
    foreach ($planSkill in $planGroup.Skills) {
      Write-Host ("      - {0}  {1}" -f $planSkill.Name.PadRight($PlanSkillWidth), $planSkill.Intro)
    }
  }
  Write-Host ''
  Write-Host 'Skills outside this plan are ignored by this script (install and uninstall).'
  Write-Host ''
  Write-Host 'Tools:'
  foreach ($tool in $catalog) {
    $userText = if ($tool.SupportsUser) { $tool.UserRoot } else { '(none)' }
    $projectText = if ($tool.ProjectFolder) { "<project>\$($tool.ProjectFolder)\skills" } else { $(if ($tool.Key -eq 'custom') { '(use -Path)' } else { '(none)' }) }
    $flags = @()
    if ($tool.Detected) { $flags += "detected: $($tool.DetectReason)" } else { $flags += 'not detected' }
    if ($tool.CopyOnly) { $flags += 'copy only' }
    if ($tool.Note) { $flags += $tool.Note }
    Write-Host ("  {0,-9} {1}  [{2}]" -f $tool.Key, $tool.Label, ($flags -join '; '))
    Write-Host ("            user: {0}" -f $userText)
    Write-Host ("            project: {0}" -f $projectText)
  }
  Write-Host ''
  Write-Host 'LinkType: auto | junction | symbolic | copy      Scope: auto | user | project'
  return
}

# ---- 3. Action, then skills ----------------------------------------------------

$interactive = -not $Tools
$useKeyInput = Test-KeyInputAvailable -PlainSelect:$PlainSelect
if ($interactive -and !$useKeyInput) {
  if ($PlainSelect) {
    Write-Host 'Typed selection requested (-PlainSelect).'
  } else {
    Write-Host 'Arrow-key selection is unavailable here (no raw console input); using the typed prompt.'
  }
}

if ($Uninstall -and $Reinstall) { throw '-Uninstall and -Reinstall cannot be combined.' }

$requestedAction = $null
if ($Uninstall) { $requestedAction = 'uninstall' }
if ($Reinstall) { $requestedAction = 'reinstall' }
if ($Action) {
  if ($requestedAction -and $requestedAction -ne $Action) {
    throw "-Action $Action conflicts with the -Uninstall/-Reinstall switch."
  }
  $requestedAction = $Action
}

$actionKeys = @('install', 'reinstall', 'uninstall')
$actionItems = @(
  'Install    - add the selected skills (entries that are already correct are kept)'
  'Reinstall  - remove the selected entries and add them again'
  'Uninstall  - remove the selected skills'
)

if ($interactive) {
  Write-Host ''
  Write-Host "Universal skill installer - repository: $Root"
}

if (!$requestedAction) {
  if (!$interactive) {
    $requestedAction = 'install'
  } else {
    if ($useKeyInput) {
      Write-Host ''
      $actionIndex = Read-SingleSelect -Title 'Action' -Items $actionItems -Default 0
      if ($actionIndex -lt 0) { Write-Host 'Cancelled.'; return }
    } else {
      Write-Host ''
      Write-Host 'Action:'
      for ($i = 0; $i -lt $actionItems.Count; $i++) { Write-Host ("  [{0}] {1}" -f ($i + 1), $actionItems[$i]) }
      $actionIndex = -1
      while ($actionIndex -lt 0) {
        $answer = Read-Host 'Choose 1/2/3 (Enter=1, 0=cancel)'
        if ($answer.Trim() -eq '0') { Write-Host 'Cancelled.'; return }
        if ([string]::IsNullOrWhiteSpace($answer)) { $actionIndex = 0; break }
        if ($answer.Trim() -in @('1', '2', '3')) { $actionIndex = [int]$answer.Trim() - 1; break }
        Write-Host 'Enter 1, 2, 3, or 0.'
      }
    }
    $requestedAction = $actionKeys[$actionIndex]
  }
}

# The rest of the script keeps using the two switches, so the action chosen in the menu
# drives exactly the same code paths as -Uninstall / -Reinstall.
$Uninstall = ($requestedAction -eq 'uninstall')
$Reinstall = ($requestedAction -eq 'reinstall')
Write-Host ''
Write-Host "Action: $requestedAction"

if ($Skills -and $Groups) {
  throw '-Skills and -Groups cannot be combined: a group is installed as a whole.'
}

if ($Skills) {
  $unknown = @($Skills | Where-Object { $PlanSkillNames -notcontains $_ })
  if ($unknown.Count -gt 0) {
    throw "Skill(s) outside the skill plan: $($unknown -join ', '). Planned skills: $($PlanSkillNames -join ', '). Use -List to see the plan."
  }
  $selectedSkills = @($Skills)
} elseif ($Groups) {
  $wantedGroupKeys = @()
  $unknownGroups = @()
  foreach ($groupValue in $Groups) {
    $resolvedGroupKey = Resolve-PlanGroupKey -Value $groupValue
    if ($null -eq $resolvedGroupKey) { $unknownGroups += $groupValue; continue }
    if ($resolvedGroupKey -eq 'all') {
      $wantedGroupKeys = @($SkillPlan | ForEach-Object { $_.Key })
      break
    }
    if ($wantedGroupKeys -notcontains $resolvedGroupKey) { $wantedGroupKeys += $resolvedGroupKey }
  }
  if ($unknownGroups.Count -gt 0) {
    throw "Unknown group(s): $($unknownGroups -join ', '). Known groups: $($SkillPlan.Key -join ', '), all."
  }
  $selectedSkills = @($SkillPlan | Where-Object { $wantedGroupKeys -contains $_.Key } | ForEach-Object { $_.Skills.Name })
} elseif ($interactive) {
  $wizardDefaults = @()
  for ($i = 0; $i -lt $SkillPlan.Count; $i++) {
    if ($Uninstall -or $SkillPlan[$i].Default) { $wizardDefaults += $i }
  }
  $verb = if ($Uninstall) { 'Groups to remove' } else { 'Groups to install' }
  $skillTitle = "$verb ($($SkillPlan.Count) groups, $($PlanSkillNames.Count) skills)"
  if ($useKeyInput) {
    $indexes = Read-MultiSelect -Title $skillTitle -Items $GroupItems -Details $GroupDetails -Info $GroupInfo -Default $wizardDefaults
  } else {
    $indexes = Read-Selection -Title "$skillTitle (Enter = marked default):" -Items $GroupItems -Details $GroupDetails -Info $GroupInfo -Default $wizardDefaults
  }
  if ($null -eq $indexes -or @($indexes).Count -eq 0) { Write-Host 'Cancelled.'; return }
  $selectedSkills = @($indexes | ForEach-Object { $SkillPlan[$_].Skills.Name })
} elseif ($Uninstall) {
  # Without -Groups an uninstall removes every group in the plan.
  $selectedSkills = $PlanSkillNames
} else {
  $selectedSkills = @($SkillPlan | Where-Object { $DefaultGroupKeys -contains $_.Key } | ForEach-Object { $_.Skills.Name })
}
if ($selectedSkills.Count -eq 0) { Write-Host 'No skills selected; nothing to do.'; return }

# ---- 4. Select tools -----------------------------------------------------------

function Resolve-ToolKey {
  param([string]$Value)
  $key = $Value.Trim().ToLowerInvariant()
  if ($ToolAliases.ContainsKey($key)) { return $ToolAliases[$key] }
  return $key
}

if ($Tools) {
  $requestedKeys = @($Tools | ForEach-Object { Resolve-ToolKey $_ } | Select-Object -Unique)
  $unknown = @($requestedKeys | Where-Object { $catalog.Key -notcontains $_ })
  if ($unknown.Count -gt 0) {
    throw "Unknown tool(s): $($unknown -join ', '). Known tools: $($catalog.Key -join ', ')"
  }
  $selectedTools = @($catalog | Where-Object { $requestedKeys -contains $_.Key })
} else {
  $toolLabels = @($catalog | ForEach-Object { "$($_.Key)  -  $($_.Label)" })
  $toolDetails = @(
    $catalog | ForEach-Object {
      $rootText = if ($_.ProjectFolder) { "<project>\$($_.ProjectFolder)\skills" } else { '(use -Path)' }
      $userText = if ($_.SupportsUser) { $_.UserRoot } else { '(none)' }
      $stateText = if ($_.Detected) { "detected: $($_.DetectReason)" } else { 'not detected' }
      $copyText = if ($_.CopyOnly) { 'copy only' } else { '' }
      "user: $userText | project: $rootText | $((@($stateText, $copyText) | Where-Object { $_ }) -join ' | ')"
    }
  )
  $detectedIndexes = @(0..($catalog.Count - 1) | Where-Object { $catalog[$_].Detected })
  $defaultIndexes = if ($detectedIndexes.Count -gt 0) { $detectedIndexes } else { @(0..($catalog.Count - 1)) }
  $toolTitle = if ($Uninstall) { 'Tools to remove from' } else { 'Tools to install for' }
  if ($useKeyInput) {
    $indexes = Read-MultiSelect -Title $toolTitle -Items $toolLabels -Details $toolDetails -Default $defaultIndexes
  } else {
    $indexes = Read-Selection -Title "$toolTitle (detected tools are marked default):" -Items $toolLabels -Details $toolDetails -Default $defaultIndexes
  }
  if ($null -eq $indexes -or @($indexes).Count -eq 0) { Write-Host 'Cancelled.'; return }
  $selectedTools = @($indexes | ForEach-Object { $catalog[$_] })
}
if ($selectedTools.Count -eq 0) { Write-Host 'No tools selected; nothing to do.'; return }

# ---- 5. Names the selected tools still need ------------------------------------

$needsProject = $false
foreach ($tool in $selectedTools) {
  if ($Scope -eq 'user') { continue }
  if ($Scope -eq 'project') { $needsProject = $true; continue }
  if (!$tool.SupportsUser -and $tool.ProjectFolder) { $needsProject = $true }
}
if ($needsProject -and [string]::IsNullOrWhiteSpace($ProjectDir)) {
  if (!$interactive) {
    throw "Project-level roots need -Target <project directory> (selected tools: $($selectedTools.Key -join ', '))."
  }
  $answer = Read-Host 'Project directory for project-level roots (Enter = current directory, 0 = cancel)'
  if ($answer.Trim() -eq '0') { Write-Host 'Cancelled.'; return }
  $ProjectDir = if ([string]::IsNullOrWhiteSpace($answer)) { (Get-Location).Path } else { $answer }
}
if (![string]::IsNullOrWhiteSpace($ProjectDir)) {
  if (!(Test-Path -LiteralPath $ProjectDir -PathType Container)) { throw "Project directory not found: $ProjectDir" }
  $ProjectDir = (Resolve-Path -LiteralPath $ProjectDir).Path
  $catalog = @(Get-ToolCatalog -ProjectDir $ProjectDir)
  $selectedTools = @($catalog | Where-Object { $selectedTools.Key -contains $_.Key })
}

if ($selectedTools.Key -contains 'custom' -and [string]::IsNullOrWhiteSpace($Path)) {
  if (!$interactive) { throw "The custom tool needs -Path <skills directory>." }
  $answer = Read-Host 'Skills directory for the custom tool (0 = cancel)'
  if ($answer.Trim() -eq '0' -or [string]::IsNullOrWhiteSpace($answer)) { Write-Host 'Cancelled.'; return }
  $Path = $answer
}

# ---- 6. Install mode -----------------------------------------------------------

if ($interactive -and !$Uninstall -and !$PSBoundParameters.ContainsKey('LinkType')) {
  $modeLabels = @(
    'Directory link (junction; installed skills follow this repository)',
    'Symbolic link',
    'Copy real files (independent snapshot; refresh by re-running)'
  )
  if ($useKeyInput) {
    Write-Host ''
    $modeIndex = Read-SingleSelect -Title 'Install mode' -Items $modeLabels -Default 0
    if ($modeIndex -lt 0) { Write-Host 'Cancelled.'; return }
  } else {
    Write-Host ''
    Write-Host 'Install mode:'
    for ($i = 0; $i -lt $modeLabels.Count; $i++) { Write-Host ("  [{0}] {1}" -f ($i + 1), $modeLabels[$i]) }
    $modeIndex = -1
    while ($modeIndex -lt 0) {
      $answer = Read-Host 'Choose 1/2/3 (Enter=1, 0=cancel)'
      if ($answer.Trim() -eq '0') { Write-Host 'Cancelled.'; return }
      if ([string]::IsNullOrWhiteSpace($answer)) { $modeIndex = 0; break }
      if ($answer.Trim() -in @('1', '2', '3')) { $modeIndex = [int]$answer.Trim() - 1; break }
      Write-Host 'Enter 1, 2, 3, or 0.'
    }
  }
  $LinkType = @('auto', 'symbolic', 'copy')[$modeIndex]
}

# ---- 7. Confirm and run --------------------------------------------------------

$resolvedTargets = @()
foreach ($tool in $selectedTools) {
  $mode = if ($tool.CopyOnly) { 'copy' } else { $LinkType }
  $probe = @(Resolve-ToolTargets -Tool $tool -ProjectDir $ProjectDir -CustomPath $Path)
  foreach ($toolTarget in $probe) {
    $resolvedTargets += [pscustomobject]@{ Tool = $tool; Scope = $toolTarget.Scope; Root = $toolTarget.Root; Mode = $mode }
  }
}

if ($resolvedTargets.Count -eq 0) {
  throw "No target root resolved. Scope '$Scope' excludes every selected tool (selected: $($selectedTools.Key -join ', '))."
}

Write-Host ''
Write-Step "Repository: $Root"
$selectedGroupText = @()
foreach ($planGroup in $SkillPlan) {
  $groupSkillNames = @($planGroup.Skills | ForEach-Object { $_.Name })
  $chosenInGroup = @($groupSkillNames | Where-Object { $selectedSkills -contains $_ })
  if ($chosenInGroup.Count -eq $groupSkillNames.Count) { $selectedGroupText += $planGroup.Label }
  elseif ($chosenInGroup.Count -gt 0) { $selectedGroupText += "$($planGroup.Label) (partial)" }
}
Write-Step "Groups: $($selectedGroupText -join ', ')"
Write-Step "Skills ($($selectedSkills.Count)): $($selectedSkills -join ', ')"
if ($Uninstall) {
  Write-Step 'Action: uninstall'
} elseif ($Reinstall) {
  Write-Step 'Action: reinstall (existing entries are removed and installed again)'
} else {
  Write-Step 'Action: install'
}
foreach ($entry in $resolvedTargets) {
  Write-Step ("Target: {0} [{1}] {2}{3}" -f $entry.Root, $entry.Scope, $entry.Tool.Label, $(if ($entry.Tool.CopyOnly -and !$Uninstall) { ' (copy only)' } else { '' }))
}

if ($interactive) {
  $confirmed = $true
  if ($useKeyInput) {
    $confirmed = Read-KeyConfirm -Prompt 'Proceed? [Y/n]' -DefaultYes $true
  } else {
    $answer = Read-Host 'Proceed? [Y/n]'
    if (![string]::IsNullOrWhiteSpace($answer) -and $answer.Trim() -notin @('y', 'Y', 'yes', 'YES')) { $confirmed = $false }
  }
  if (!$confirmed) { Write-Host 'Cancelled.'; return }
}

$failures = @()
foreach ($entry in $resolvedTargets) {
  $toolRoot = $entry.Root
  $tool = $entry.Tool
  $mode = $entry.Mode

  Write-Host ''
  Write-Step "== $($tool.Label) -> $toolRoot"

  if ($tool.CopyOnly -and !$Uninstall -and $LinkType -ne 'copy') {
    Write-Host "  $($tool.Label) does not follow directory links; copying real files instead."
  }

  $rootExists = Test-Path -LiteralPath $toolRoot
  if (!$rootExists) {
    if ($Uninstall) {
      Write-Step "Nothing to remove; target root does not exist: $toolRoot"
      continue
    }
    Write-Step "Would create $toolRoot"
    if (!$WhatIf) { New-Item -ItemType Directory -Path $toolRoot -Force | Out-Null }
  }

  foreach ($skillName in $selectedSkills) {
    $result = Invoke-SkillEntry -SkillName $skillName -SourceSkill (Join-Path $SkillsRoot $skillName) -ToolRoot $toolRoot -Mode $mode
    if ($result -eq 'skipped') { Write-Host "  $skillName : skipped" }
  }

  if (!$WhatIf) {
    foreach ($skillName in $selectedSkills) {
      $dest = Join-Path $toolRoot $skillName
      if (!(Test-Path -LiteralPath $dest)) { continue }
      if (!(Test-DirectoryMirrors -Path $dest -Source (Join-Path $SkillsRoot $skillName))) {
        $failures += "$($tool.Key) $skillName at $dest does not match the repository content"
      }
    }
  }

  if ($tool.Key -eq 'codearts') { Update-CodeArtsStatus -ToolRoot $toolRoot }

  if ($tool.Gitignore -and $entry.Scope -eq 'project' -and ![string]::IsNullOrWhiteSpace($ProjectDir)) {
    Add-GitignoreEntry -ProjectDir $ProjectDir -Entry $tool.Gitignore
  }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error $_ }
  throw 'Verification failed; the installed skills do not match the repository.'
}

Write-Host ''
if ($Uninstall) {
  Write-Step 'Done.'
} else {
  Write-Step 'Verified every installed skill against the repository content.'
  if ($LinkType -eq 'copy' -or $resolvedTargets.Mode -contains 'copy') {
    Write-Step 'Copies are snapshots: re-run this script to refresh them after repository changes.'
  }
  if ($LinkType -ne 'copy') {
    Write-Step 'Directory links follow this repository: later edits apply without reinstalling. Some tools only watch their own skill root, so restart the tool if its skill catalog looks stale.'
  }
  Write-Step 'Done.'
}

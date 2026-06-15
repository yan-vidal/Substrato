param(
  [ValidateSet("install", "uninstall")]
  [string]$Action = "install",

  [ValidateSet("auto", "agents", "codex", "gemini", "opencode", "antigravity", "claude", "workspace")]
  [string]$Target = "auto",

  [string]$Project = (Get-Location).Path,

  [ValidateSet("copy", "link")]
  [string]$Mode = "copy"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Resolve-Path (Join-Path $ScriptDir "..")
$SkillsDir = Join-Path $RootDir "skills"

if (-not (Test-Path $SkillsDir -PathType Container)) {
  throw "Substrato skills directory not found: $SkillsDir"
}

function Copy-OrLinkDir {
  param(
    [string]$Source,
    [string]$Destination
  )

  if (Test-Path $Destination) {
    Remove-Item $Destination -Recurse -Force
  }

  $Parent = Split-Path -Parent $Destination
  New-Item -ItemType Directory -Force -Path $Parent | Out-Null

  if ($Mode -eq "link") {
    New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
  } else {
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Copy-Item -Path (Join-Path $Source "*") -Destination $Destination -Recurse -Force
  }
}

function Install-SkillDirs {
  param([string]$DestinationRoot)

  New-Item -ItemType Directory -Force -Path $DestinationRoot | Out-Null
  Get-ChildItem -Path $SkillsDir -Directory | ForEach-Object {
    Copy-OrLinkDir -Source $_.FullName -Destination (Join-Path $DestinationRoot $_.Name)
  }
}

function Uninstall-SkillDirs {
  param([string]$DestinationRoot)

  Get-ChildItem -Path $SkillsDir -Directory | ForEach-Object {
    $Destination = Join-Path $DestinationRoot $_.Name
    if (Test-Path $Destination) {
      Remove-Item $Destination -Recurse -Force
    }
  }
}

function Install-Workspace {
  $ProjectRoot = (Resolve-Path $Project).Path
  Install-SkillDirs -DestinationRoot (Join-Path $ProjectRoot ".agents\skills")
  Write-Host "Installed workspace Substrato skills at $ProjectRoot\.agents\skills"
}

function Uninstall-Workspace {
  $ProjectRoot = (Resolve-Path $Project).Path
  Uninstall-SkillDirs -DestinationRoot (Join-Path $ProjectRoot ".agents\skills")
  Write-Host "Removed workspace Substrato skills from $ProjectRoot\.agents\skills"
}

function Install-Agents {
  Install-SkillDirs -DestinationRoot (Join-Path $HOME ".agents\skills")
  Write-Host "Installed agent-compatible skills at $HOME\.agents\skills"
}

function Uninstall-Agents {
  Uninstall-SkillDirs -DestinationRoot (Join-Path $HOME ".agents\skills")
  Write-Host "Removed agent-compatible Substrato skills from $HOME\.agents\skills"
}

function Install-Claude {
  Install-SkillDirs -DestinationRoot (Join-Path $HOME ".claude\skills")
  Write-Host "Installed Claude Code skills at $HOME\.claude\skills"
}

function Uninstall-Claude {
  Uninstall-SkillDirs -DestinationRoot (Join-Path $HOME ".claude\skills")
  Write-Host "Removed Claude Code Substrato skills from $HOME\.claude\skills"
}

switch ($Target) {
  "workspace" {
    if ($Action -eq "install") { Install-Workspace } else { Uninstall-Workspace }
  }
  { $_ -in @("agents", "codex", "gemini", "opencode", "antigravity") } {
    if ($Action -eq "install") { Install-Agents } else { Uninstall-Agents }
  }
  "claude" {
    if ($Action -eq "install") { Install-Claude } else { Uninstall-Claude }
  }
  "auto" {
    if ($Action -eq "install") { Install-Agents } else { Uninstall-Agents }
    $ClaudeHome = Join-Path $HOME ".claude"
    if (Test-Path $ClaudeHome) {
      try {
        if ($Action -eq "install") { Install-Claude } else { Uninstall-Claude }
      } catch {
        Write-Warning "Skipped Claude $Action during auto target; use -Target claude to fail strictly. $($_.Exception.Message)"
      }
    }
  }
}

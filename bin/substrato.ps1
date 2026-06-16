param(
  [Parameter(Position = 0)]
  [ValidateSet("install", "uninstall", "update", "help")]
  [string]$Command = "help",

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$RemainingArgs
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Resolve-Path (Join-Path $ScriptDir "..")

switch ($Command) {
  "install" {
    & (Join-Path $RootDir "installers\install.ps1") @RemainingArgs
  }
  "uninstall" {
    & (Join-Path $RootDir "installers\install.ps1") -Action uninstall @RemainingArgs
  }
  "update" {
    git -C $RootDir pull --ff-only
  }
  "help" {
    Write-Host "Usage:"
    Write-Host "  .\bin\substrato.ps1 install -Target auto|agents|codex|gemini|opencode|antigravity|claude|workspace -Project PATH -Mode copy|link -Skill NAME"
    Write-Host "  .\bin\substrato.ps1 uninstall -Target auto|agents|codex|gemini|opencode|antigravity|claude|workspace -Project PATH -Skill NAME"
    Write-Host "  .\bin\substrato.ps1 update"
  }
}

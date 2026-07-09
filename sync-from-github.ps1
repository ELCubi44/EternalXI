# Sincroniza el monorepo EternalXI desde GitHub
$git = "C:\Program Files\Git\cmd\git.exe"
$root = Split-Path $MyInvocation.MyCommand.Path -Parent
if ((Split-Path $root -Leaf) -eq "scripts") { $root = Split-Path $root -Parent }

Set-Location $root
& $git fetch origin
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $git reset --hard origin/main
& $git clean -fd
& $git log --oneline -1
& $git status -sb

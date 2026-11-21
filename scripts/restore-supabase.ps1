param(
  [Parameter(Mandatory = $true)][string]$BackupFile,
  [Parameter(Mandatory = $true)][string]$TargetProjectRef
)

$ErrorActionPreference = 'Stop'
if (-not $env:SUPABASE_RESTORE_DB_URL) { throw 'Set SUPABASE_RESTORE_DB_URL to the restore target database URL in the current shell.' }
if (-not $env:SUPABASE_RESTORE_PROJECT_REF -or $env:SUPABASE_RESTORE_PROJECT_REF -ne $TargetProjectRef) { throw 'SUPABASE_RESTORE_PROJECT_REF must match the intended target project.' }
if (-not (Get-Command pg_restore -ErrorAction SilentlyContinue)) { throw 'Install PostgreSQL client tools; pg_restore was not found.' }
$file = (Resolve-Path -LiteralPath $BackupFile).Path
$manifest = "$file.manifest.txt"
if (-not (Test-Path -LiteralPath $manifest)) { throw 'Backup manifest is missing; verify the archive manually before continuing.' }
$expected = (Select-String -LiteralPath $manifest -Pattern '^SHA256=(.+)$').Matches.Groups[1].Value
$actual = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
if (-not $expected -or $expected -ne $actual) { throw 'Backup SHA256 verification failed.' }
Write-Warning "This replaces public/private application schemas on target $TargetProjectRef. Restore into a disposable staging project first whenever possible."
$confirmation = Read-Host "Type RESTORE $TargetProjectRef to continue"
if ($confirmation -cne "RESTORE $TargetProjectRef") { throw 'Restore cancelled.' }
pg_restore --dbname=$env:SUPABASE_RESTORE_DB_URL --clean --if-exists --no-owner --no-acl --schema=public --schema=private $file
if ($LASTEXITCODE -ne 0) { throw 'pg_restore reported errors. Inspect the target before using it.' }
Write-Output "Database restore command completed for target $TargetProjectRef. Run the application smoke checks before reopening operations."

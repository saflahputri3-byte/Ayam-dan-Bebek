param(
  [Parameter(Mandatory = $true)][string]$ProjectRef,
  [string]$OutputDirectory = "backups"
)

$ErrorActionPreference = 'Stop'
if (-not $env:SUPABASE_DB_URL) { throw 'Set SUPABASE_DB_URL to a database connection string in the current shell.' }
if ($ProjectRef -notmatch '^[a-z0-9]{15,25}$') { throw 'ProjectRef format is invalid.' }
if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) { throw 'Install PostgreSQL client tools; pg_dump was not found.' }

$resolved = Join-Path (Get-Location) $OutputDirectory
New-Item -ItemType Directory -Force -Path $resolved | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$file = Join-Path $resolved "$ProjectRef-$stamp.dump"
pg_dump --dbname=$env:SUPABASE_DB_URL --format=custom --no-owner --no-acl --schema=public --schema=private --file=$file
if ($LASTEXITCODE -ne 0) { Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue; throw 'pg_dump failed.' }
$archive = Get-Item -LiteralPath $file
if ($archive.Length -lt 1024) { throw 'Backup is unexpectedly small; inspect database access and dump output.' }
$hash = Get-FileHash -LiteralPath $file -Algorithm SHA256
"ProjectRef=$ProjectRef`nCreatedAt=$((Get-Date).ToUniversalTime().ToString('o'))`nBytes=$($archive.Length)`nSHA256=$($hash.Hash)" | Set-Content -LiteralPath "$file.manifest.txt" -Encoding utf8
Write-Output "Backup created: $file"
Write-Output "SHA256: $($hash.Hash)"

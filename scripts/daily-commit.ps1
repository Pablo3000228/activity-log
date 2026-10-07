<#
.SYNOPSIS
    Добавляет запись в activity/<год>.md, коммитит и пушит. Одна запись в день.

.EXAMPLE
    .\daily-commit.ps1
    .\daily-commit.ps1 -Note "Разобрался с async/await"
    .\daily-commit.ps1 -RepoPath C:\code\my-activity
#>
param(
    # Путь к клону репозитория (по умолчанию — папка над scripts\)
    [string]$RepoPath = (Split-Path -Parent $PSScriptRoot),
    # Необязательная заметка — попадёт в лог и в сообщение коммита
    [string]$Note
)

$ErrorActionPreference = 'Stop'
$logDir = Join-Path $env:LOCALAPPDATA 'daily-commit'
New-Item -ItemType Directory -Force $logDir | Out-Null
$logFile = Join-Path $logDir 'log.txt'

function Write-Log([string]$text) {
    $line = "{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $text
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

function Invoke-Git {
    # git пишет предупреждения в stderr; в PowerShell 5.1 при 'Stop' это считалось бы ошибкой
    $ErrorActionPreference = 'Continue'
    $out = & git @args 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "git $($args -join ' ') завершился с кодом ${LASTEXITCODE}: $out" }
    $out
}

try {
    Set-Location $RepoPath

    $email = (& git config user.email)
    if (-not $email) { throw 'Не задан git user.email — коммит не засчитается в профиль.' }

    # После включения ПК сеть может появиться не сразу — ждём до 10 минут
    for ($i = 1; ; $i++) {
        try { Invoke-Git pull --rebase --autostash --quiet | Out-Null; break }
        catch {
            if ($i -ge 20) { throw }
            Write-Log "GitHub недоступен (попытка $i из 20), жду 30 секунд..."
            Start-Sleep -Seconds 30
        }
    }

    $now   = Get-Date
    $today = $now.ToString('yyyy-MM-dd')
    $dir   = Join-Path $RepoPath 'activity'
    $file  = Join-Path $dir ("{0}.md" -f $now.Year)
    New-Item -ItemType Directory -Force $dir | Out-Null

    $message = "Activity log: $today"
    if ($Note) { $message += " — $Note" }

    if ((Test-Path $file) -and (Select-String -Path $file -Pattern "^- $today" -Quiet)) {
        Write-Log "Запись за $today уже есть."
    }
    else {
        $entry = "- $today $($now.ToString('HH:mm'))"
        if ($Note) { $entry += " — $Note" }
        # UTF-8 без BOM, LF — чтобы файл одинаково выглядел на GitHub
        [IO.File]::AppendAllText($file, "$entry`n", (New-Object Text.UTF8Encoding $false))
    }

    # Доделываем то, что могло не завершиться в прошлый запуск: незакоммиченную запись и неотправленные коммиты
    if (Invoke-Git status --porcelain -- $file) {
        Invoke-Git add -- $file | Out-Null
        Invoke-Git commit --quiet -m $message | Out-Null
        Write-Log "Коммит: $message (автор $email)"
    }
    if ([int](Invoke-Git rev-list --count '@{u}..HEAD') -gt 0) {
        Invoke-Git push --quiet | Out-Null
        Write-Log 'Push выполнен.'
    }
    else {
        Write-Log 'Отправлять нечего.'
    }
}
catch {
    Write-Log "ОШИБКА: $_"
    exit 1
}

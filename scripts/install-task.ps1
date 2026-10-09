<#
.SYNOPSIS
    Регистрирует ежедневную задачу в Планировщике заданий Windows, которая запускает daily-commit.ps1.

.EXAMPLE
    .\install-task.ps1                 # каждый день в 12:00
    .\install-task.ps1 -Time 21:30
    Unregister-ScheduledTask -TaskName 'GitHub Daily Commit'   # удалить задачу
#>
param(
    [string]$Time = '12:00',
    [string]$TaskName = 'GitHub Daily Commit'
)

$ErrorActionPreference = 'Stop'
$script = Join-Path $PSScriptRoot 'daily-commit.ps1'

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$script`""
$daily = New-ScheduledTaskTrigger -Daily -At $Time
# Задача выполняется только при вошедшем пользователе. Если в назначенное время никто не вошёл
# (ПК выключен или висит на экране входа), StartWhenAvailable не поможет — поэтому запускаем
# ещё и при входе в Windows. Второго коммита за день не будет: скрипт пропускает уже сделанный день.
$logon = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$logon.Delay = 'PT2M'
# Сеть скрипт ждёт сам, поэтому условие RunOnlyIfNetworkAvailable не ставим — оно могло бы отменить запуск
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $daily, $logon -Settings $settings `
    -Description 'Ежедневный коммит в activity-лог на GitHub' -Force | Out-Null

Write-Host "Задача '$TaskName' зарегистрирована: каждый день в $Time и при входе в Windows."
Write-Host "Лог запусков: $env:LOCALAPPDATA\daily-commit\log.txt"

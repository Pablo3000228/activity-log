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
$trigger = New-ScheduledTaskTrigger -Daily -At $Time
# StartWhenAvailable: если компьютер был выключен в назначенное время — запустится при включении
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RunOnlyIfNetworkAvailable `
    -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings `
    -Description 'Ежедневный коммит в activity-лог на GitHub' -Force | Out-Null

Write-Host "Задача '$TaskName' зарегистрирована: каждый день в $Time."
Write-Host "Лог запусков: $env:LOCALAPPDATA\daily-commit\log.txt"

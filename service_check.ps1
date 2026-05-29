# Скрипт мониторинга служб Windows
# service_check.ps1

# Конфигурация Telegram
$TOKEN = "8989072388:AAGy5uHr3IblRpqgDRo_4r3mt84zidMvygo"
$CHAT_ID = "1700981610"

# Список критических служб для проверки
$Services = @(
    @{Name="wuauserv"; DisplayName="Центр обновления Windows"},
    @{Name="MpsSvc"; DisplayName="Брандмауэр Windows"},
    @{Name="Schedule"; DisplayName="Планировщик заданий"},
    @{Name="Spooler"; DisplayName="Диспетчер печати"},
    @{Name="EventLog"; DisplayName="Журнал событий Windows"}
)

$Running = 0
$Stopped = 0
$Restarted = 0
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$RunningList = ""
$RestartedList = ""
$StoppedList = ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DevOpsAlert | Мониторинг служб Windows" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($Svc in $Services) {
    $Service = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    
    if ($null -eq $Service) {
        Write-Host "[НЕ НАЙДЕНА] $($Svc.DisplayName)" -ForegroundColor Gray
        continue
    }
    
    if ($Service.Status -eq "Running") {
        Write-Host "[РАБОТАЕТ]   $($Svc.DisplayName)" -ForegroundColor Green
        $RunningList += "  • $($Svc.DisplayName)`n"
        $Running++
    } else {
        Write-Host "[ОСТАНОВЛЕНА] $($Svc.DisplayName) — попытка запуска..." -ForegroundColor Red
        try {
            Start-Service -Name $Svc.Name -ErrorAction Stop
            Write-Host "[ПЕРЕЗАПУЩЕНА] $($Svc.DisplayName)" -ForegroundColor Yellow
            $RestartedList += "  • $($Svc.DisplayName)`n"
            $Restarted++
        } catch {
            Write-Host "[ОШИБКА]     $($Svc.DisplayName) — $($_.Exception.Message)" -ForegroundColor Red
            $StoppedList += "  • $($Svc.DisplayName)`n"
            $Stopped++
        }
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Итого: Работает: $Running | Перезапущено: $Restarted | Остановлено: $Stopped" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Формирование сообщения
$MESSAGE = "🖥 МОНИТОРИНГ СЛУЖБ | DevOpsAlert`n" +
           "━━━━━━━━━━━━━━━━━━━━━`n" +
           "💻 Сервер: WorkStation-Admin`n" +
           "🕐 Время: $TIMESTAMP`n" +
           "━━━━━━━━━━━━━━━━━━━━━`n`n"

if ($RunningList -ne "") {
    $MESSAGE += "✅ Работает:`n$RunningList`n"
}
if ($RestartedList -ne "") {
    $MESSAGE += "🔄 Перезапущено:`n$RestartedList`n"
}
if ($StoppedList -ne "") {
    $MESSAGE += "❌ Остановлено:`n$StoppedList`n"
}

if ($Restarted -gt 0 -or $Stopped -gt 0) {
    $MESSAGE += "━━━━━━━━━━━━━━━━━━━━━`n" +
                "🔧 Требуется вмешательство администратора"
} else {
    $MESSAGE += "━━━━━━━━━━━━━━━━━━━━━`n" +
                "✅ Все службы работают в штатном режиме"
}

$Body = @{
    chat_id = $CHAT_ID
    text = $MESSAGE
}

Invoke-RestMethod -Uri "https://api.telegram.org/bot$TOKEN/sendMessage" -Method Post -Body $Body | Out-Null
Write-Host ""
Write-Host "Уведомление отправлено в Telegram" -ForegroundColor Cyan
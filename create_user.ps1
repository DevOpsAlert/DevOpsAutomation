# Скрипт создания локальных пользователей
# create_user.ps1

# Массив пользователей для создания
$Users = @(
    @{Name="ivanov.ii"; FullName="Иванов Иван Иванович"; Description="Менеджер отдела продаж"; Group="Users"},
    @{Name="petrov.pp"; FullName="Петров Пётр Петрович"; Description="Системный администратор"; Group="Administrators"},
    @{Name="sidorova.aa"; FullName="Сидорова Анна Алексеевна"; Description="Бухгалтер"; Group="Users"}
)

# Счётчики
$Created = 0
$Skipped = 0
$Errors = 0

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  DevOpsAlert | Создание учётных записей" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

foreach ($User in $Users) {
    # Проверка существования через WMI
    $Exists = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True AND Name='$($User.Name)'"

    if ($Exists) {
        Write-Host "[ПРОПУЩЕН]  $($User.Name) — уже существует" -ForegroundColor Yellow
        $Skipped++
    } else {
        try {
            # Создание пользователя через NET
            $Result = net user $User.Name "P@ssw0rd123!" /add /fullname:"$($User.FullName)" /comment:"$($User.Description)" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                # Добавление в группу
                if ($User.Group -eq "Administrators") {
                    net localgroup Administrators $User.Name /add 2>&1 | Out-Null
                }
                Write-Host "[СОЗДАН]    $($User.Name) — $($User.FullName) [$($User.Group)]" -ForegroundColor Green
                $Created++
            } else {
                Write-Host "[ОШИБКА]    $($User.Name) — $Result" -ForegroundColor Red
                $Errors++
            }
        } catch {
            Write-Host "[ОШИБКА]    $($User.Name) — $($_.Exception.Message)" -ForegroundColor Red
            $Errors++
        }
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Итого: Создано: $Created | Пропущено: $Skipped | Ошибок: $Errors" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Показать список пользователей
Write-Host "Текущие пользователи системы:" -ForegroundColor White
Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True" | 
    ForEach-Object { Write-Host "  - $($_.Name) | $($_.FullName)" -ForegroundColor White }
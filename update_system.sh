#!/bin/bash

# Конфигурация
TOKEN="8989072388:AAGy5uHr3IblRpqgDRo_4r3mt84zidMvygo"
CHAT_ID="1700981610"
LOG_FILE="/var/log/update_system.log"

# Временная метка начала
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "${TIMESTAMP} | Начало обновления системы" >> "$LOG_FILE"
echo "${TIMESTAMP} | Начало обновления системы"

# Обновление индекса пакетов
echo "Обновление списка пакетов..."
sudo apt update -y >> "$LOG_FILE" 2>&1

# Установка обновлений
echo "Установка обновлений..."
sudo apt upgrade -y >> "$LOG_FILE" 2>&1

# Удаление устаревших пакетов
echo "Удаление устаревших пакетов..."
sudo apt autoremove -y >> "$LOG_FILE" 2>&1

# Проверка необходимости перезагрузки
if [ -f /var/run/reboot-required ]; then
    REBOOT_MSG="⚠️ Требуется перезагрузка сервера"
else
    REBOOT_MSG="✅ Перезагрузка не требуется"
fi

# Временная метка завершения
TIMESTAMP_END=$(date '+%Y-%m-%d %H:%M:%S')
echo "${TIMESTAMP_END} | Обновление завершено | ${REBOOT_MSG}" >> "$LOG_FILE"
echo "${TIMESTAMP_END} | Обновление завершено | ${REBOOT_MSG}"

# Отправка уведомления в Telegram
FULL_MESSAGE="$(printf '🔄 ОБНОВЛЕНИЕ СИСТЕМЫ | DevOpsAlert\n━━━━━━━━━━━━━━━━━━━━━\n🖥 Сервер: %s\n🕐 Начало: %s\n🕐 Завершение: %s\n━━━━━━━━━━━━━━━━━━━━━\n\n✅ Обновление выполнено успешно\n%s\n━━━━━━━━━━━━━━━━━━━━━' "$(hostname)" "$TIMESTAMP" "$TIMESTAMP_END" "$REBOOT_MSG")"
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    --data-urlencode "text=${FULL_MESSAGE}" > /dev/null

#!/bin/bash

# Конфигурация
TOKEN="8989072388:AAGy5uHr3IblRpqgDRo_4r3mt84zidMvygo"
CHAT_ID="1700981610"
LOG_FILE="/var/log/check_resources.log"

# Пороговые значения
CPU_THRESHOLD=80
RAM_THRESHOLD=85
DISK_THRESHOLD=90

# Получение метрик
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | cut -d',' -f1)
RAM=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100}')
DISK=$(df / | tail -1 | awk '{print $5}' | cut -d'%' -f1)

# Формирование сообщения
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
MESSAGE=""
ALERT=0

if [ "${CPU%.*}" -ge "$CPU_THRESHOLD" ]; then
    MESSAGE="${MESSAGE}⚠️ CPU: ${CPU}% (порог ${CPU_THRESHOLD}%)"$'\n'
    ALERT=1
fi

if [ "$RAM" -ge "$RAM_THRESHOLD" ]; then
    MESSAGE="${MESSAGE}⚠️ RAM: ${RAM}% (порог ${RAM_THRESHOLD}%)"$'\n'
    ALERT=1
fi

if [ "$DISK" -ge "$DISK_THRESHOLD" ]; then
    MESSAGE="${MESSAGE}⚠️ DISK: ${DISK}% (порог ${DISK_THRESHOLD}%)"$'\n'
    ALERT=1
fi

# Отправка уведомления
if [ "$ALERT" -eq 1 ]; then
    FULL_MESSAGE="🚨 ВНИМАНИЕ | DevOpsAlert
━━━━━━━━━━━━━━━━━━━━━
🖥 Сервер: $(hostname)
🕐 Время: ${TIMESTAMP}
━━━━━━━━━━━━━━━━━━━━━

${MESSAGE}
━━━━━━━━━━━━━━━━━━━━━
🔧 Требуется вмешательство администратора"
    curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
        -d chat_id="${CHAT_ID}" \
        --data-urlencode "text=${FULL_MESSAGE}" > /dev/null
fi

# Логирование
echo "${TIMESTAMP} | CPU: ${CPU}% | RAM: ${RAM}% | DISK: ${DISK}%" >> "$LOG_FILE"
echo "${TIMESTAMP} | CPU: ${CPU}% | RAM: ${RAM}% | DISK: ${DISK}%"

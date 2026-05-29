#!/bin/bash

# Конфигурация
TOKEN="8989072388:AAGy5uHr3IblRpqgDRo_4r3mt84zidMvygo"
CHAT_ID="1700981610"
SOURCE_DIR="/home/ubuntuserver2204"
BACKUP_DIR="/var/backups/home"
LOG_FILE="/var/log/backup.log"
RETENTION_DAYS=7

# Создание директории если не существует
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
    chmod 700 "$BACKUP_DIR"
fi

# Формирование имени архива
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz"

# Создание архива
tar -czf "$BACKUP_FILE" "$SOURCE_DIR" 2>/dev/null
EXIT_CODE=$?

# Проверка результата
if [ $EXIT_CODE -eq 0 ]; then
    STATUS="✅ Резервная копия создана успешно"
    FILE_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
    RESULT_MSG="$(printf '📦 Файл: backup_%s.tar.gz\n📊 Размер: %s' "$TIMESTAMP" "$FILE_SIZE")"
else
    STATUS="❌ Ошибка создания резервной копии"
    RESULT_MSG="🔴 Код ошибки: ${EXIT_CODE}"
fi

# Ротация старых архивов
DELETED=$(find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +${RETENTION_DAYS} -delete -print | wc -l)

# Отправка уведомления в Telegram
FULL_MESSAGE="$(printf '💾 РЕЗЕРВНОЕ КОПИРОВАНИЕ | DevOpsAlert\n━━━━━━━━━━━━━━━━━━━━━\n🖥 Сервер: %s\n🕐 Время: %s\n━━━━━━━━━━━━━━━━━━━━━\n\n%s\n%s\n\n🗑 Удалено устаревших копий: %s\n━━━━━━━━━━━━━━━━━━━━━' "$(hostname)" "$TIMESTAMP" "$STATUS" "$RESULT_MSG" "$DELETED")"
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    --data-urlencode "text=${FULL_MESSAGE}" > /dev/null

# Логирование
echo "${TIMESTAMP} | ${STATUS} | Удалено архивов: ${DELETED}" >> "$LOG_FILE"
echo "${TIMESTAMP} | ${STATUS}"

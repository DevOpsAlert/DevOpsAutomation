#!/bin/bash

# Конфигурация
TOKEN="8989072388:AAGy5uHr3IblRpqgDRo_4r3mt84zidMvygo"
CHAT_ID="1700981610"
LOG_FILE="/var/log/ssh_hardening.log"
SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.backup_$(date '+%Y-%m-%d_%H-%M')"

# Создание лог файла
sudo touch "$LOG_FILE" && sudo chmod 666 "$LOG_FILE"

# Временная метка
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "${TIMESTAMP} | Начало настройки SSH" >> "$LOG_FILE"
echo "${TIMESTAMP} | Начало настройки SSH"

# Создание резервной копии конфига
sudo cp "$SSHD_CONFIG" "$BACKUP_FILE"
echo "${TIMESTAMP} | Резервная копия создана: ${BACKUP_FILE}" >> "$LOG_FILE"
echo "Резервная копия создана: ${BACKUP_FILE}"

# Применение настроек безопасности
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$SSHD_CONFIG"
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' "$SSHD_CONFIG"
sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSHD_CONFIG"
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$SSHD_CONFIG"
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' "$SSHD_CONFIG"

echo "Настройки безопасности применены"

# Проверка синтаксиса конфига
sudo sshd -t
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    # Перезапуск SSH
    sudo systemctl restart ssh
    STATUS="✅ Настройка SSH выполнена успешно"
    echo "${TIMESTAMP} | ${STATUS}" >> "$LOG_FILE"
    echo "${STATUS}"
else
    # Откат изменений
    sudo cp "$BACKUP_FILE" "$SSHD_CONFIG"
    sudo systemctl restart ssh
    STATUS="❌ Ошибка конфига SSH — выполнен откат"
    echo "${TIMESTAMP} | ${STATUS}" >> "$LOG_FILE"
    echo "${STATUS}"
fi

# Отправка уведомления в Telegram
TIMESTAMP_END=$(date '+%Y-%m-%d %H:%M:%S')
FULL_MESSAGE="$(printf '🔐 ЗАЩИТА SSH | DevOpsAlert\n━━━━━━━━━━━━━━━━━━━━━\n🖥 Сервер: %s\n🕐 Время: %s\n━━━━━━━━━━━━━━━━━━━━━\n\n%s\n\n🔒 Вход по паролю: отключён\n🔑 Вход по ключу: включён\n🚫 Root login: запрещён\n━━━━━━━━━━━━━━━━━━━━━' "$(hostname)" "$TIMESTAMP_END" "$STATUS")"
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
    -d chat_id="${CHAT_ID}" \
    --data-urlencode "text=${FULL_MESSAGE}" > /dev/null

# Daily commit

Раз в день добавляет строку в `activity/<год>.md`, коммитит от вашего имени и пушит.
Два способа — выберите **один**:

| | GitHub Actions | Скрипт на ПК |
|---|---|---|
| Компьютер должен быть включён | нет | да (пропуск догоняется при включении) |
| Можно добавить заметку к записи | нет | да: `-Note "..."` |

## Чтобы коммиты засчитывались в профиль

GitHub засчитывает коммит, если **все** условия выполнены:

1. E-mail автора коммита привязан к вашему аккаунту (или это ваш noreply-адрес вида
   `12345678+login@users.noreply.github.com` — его видно на https://github.com/settings/emails).
2. Репозиторий **публичный** и **не является форком**.
3. Коммит попал в ветку по умолчанию (`main`).

## Вариант 1. GitHub Actions (работает в облаке)

1. Создайте на GitHub новый публичный репозиторий (например, `activity-log`) и загрузите туда содержимое этой папки.
2. В репозитории: **Settings → Secrets and variables → Actions → вкладка Variables → New repository variable**:
   - `COMMIT_AUTHOR_NAME` — ваше имя или логин
   - `COMMIT_AUTHOR_EMAIL` — e-mail из пункта 1 выше
3. **Settings → Actions → General → Workflow permissions** → выберите *Read and write permissions*.
4. Вкладка **Actions → Daily commit → Run workflow** — проверьте ручной запуск.

Время запуска задаётся в `.github/workflows/daily-commit.yml` (cron, в UTC). GitHub иногда
запускает расписание с опозданием на 5–30 минут — это нормально.

## Вариант 2. Скрипт на Windows + Планировщик заданий

```powershell
git clone https://github.com/<логин>/activity-log.git C:\code\activity-log
cd C:\code\activity-log\scripts

.\daily-commit.ps1                              # разовый запуск — проверка, что push проходит
.\install-task.ps1 -Time 12:00                  # ежедневная задача
.\daily-commit.ps1 -Note "Разобрался с Docker"  # запись с заметкой вручную
```

- Используется ваш обычный `git config user.email` и сохранённые учётные данные Git.
- Если прошлый запуск упал (нет сети и т.п.), следующий допушит то, что не ушло.
- Лог: `%LOCALAPPDATA%\daily-commit\log.txt`.
- Удалить задачу: `Unregister-ScheduledTask -TaskName 'GitHub Daily Commit'`.
- Если PowerShell пишет, что выполнение скриптов запрещено: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

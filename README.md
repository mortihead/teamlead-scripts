# teamlead-scripts

# Библиотека скриптов для управления релизами

Эта библиотека скриптов предназначена для управления релизами и предоставляет полезный функционал для работы с ветками.

- **create_release.sh** - 1. Создание релиза на базе develop ветки
			  develop -> release/X.Y.Z (Версии вида 2.0.1, "2.0" - версия продукта. "1" - версия релиза)
			  Скрипт использует GNU версию sed утилиты (gsed).
- **update_tag.sh** - 2.1 Поднятие тега в release ветке
		      К примеру, в релизную ветку  release/X.Y.Z были вливания cherry pick hot fix PR
		      После этого тег инкрементом увеличивается на 1. 
		      2.0.1 -> 2.0.1.1, 2.0.1.1 - 2.0.1.2
		      Так же, версия прописывается в `pom.xml` и `package.json` (Java и React проекты)
- **update_release.sh** - 2.2 вливание в релизную ветку develop с инкрементом тегов, прописыванием номера версии в `pom.xml` и `package.json`
			К примеру, мы решили не черипикать весь отдельные задачи с hotfix в релизную ветку, в обновить релизную полностью из develop
- **update_jira_task_version.sh** - массовое изменение версий в задачах JIRA. Список задач в `tasks.txt`
				  Должны быть определены переменные JIRA_LOGIN, JIRA_PASSWORD, and JIRA_REST в ~/.zprofile (MacOS) или ~/.bashrc (Linux)
				  Используется basic авторизация
				  Добавьте следующий код с вашими учетными данными
				  `export JIRA_LOGIN=User
				  export JIRA_PASSWORD=SecretP@ssw0rd
                                  export JIRA_REST='https://jira.mycompany.org/rest/api/2/issue'`
                                  в ~/.zprofile (MacOS) или ~/.bashrc (Linux)
- **jira_task_close.sh** - массовое закрытие задач JIRA. Список задач в `tasks.txt`
			  Должны быть определены переменные JIRA_LOGIN, JIRA_PASSWORD, and JIRA_REST в ~/.zprofile (MacOS) или ~/.bashrc (Linux)

- **git-show-large-files.sh** - поиск больших файлов в репозитории
- **move_tag_to_top.sh** - (legacy) - сдвиг тега в топ ветки
- **update_release_old.sh** (legacy) - вливание в релизную ветку develop


# Script Library for Release Management

This script library is designed for managing releases and provides useful functionality for working with branches.

- **create_release.sh** - creates a release based on the develop branch
- **git-show-large-files.sh** - finds large files in the repository
- **jira_task_close.sh** - bulk closing of JIRA tasks. The list of tasks is in `tasks.txt`
- **move_tag_to_top.sh** - (legacy) - moves the tag to the top of the branch
- **update_jira_task_version.sh** - bulk updating of versions in JIRA tasks. The list of tasks is in `tasks.txt`
- **update_release.sh** - merges into the develop release branch with tag increment, writing the version number in `pom.xml` and `package.json`
- **update_release_old.sh** (legacy) - merges into the develop release branch
- **update_tag.sh** - raises the tag in the release branch
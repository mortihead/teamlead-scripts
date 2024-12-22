# teamlead-scripts

# Библиотека скриптов для управления релизами

Эта библиотека скриптов предназначена для управления релизами и предоставляет полезный функционал для работы с ветками.

- **create_release.sh** - создание релиза на базе develop ветки
- **git-show-large-files.sh** - поиск больших файлов в репозитории
- **jira_task_close.sh** - массовое закрытие задач JIRA. Список задач в `tasks.txt`
- **move_tag_to_top.sh** - (legacy) - сдвиг тега в топ ветки
- **update_jira_task_version.sh** - массовое изменение версий в задачах JIRA. Список задач в `tasks.txt`
- **update_release.sh** - вливание в релизную ветку develop с инкрементом тегов, прописыванием номера версии в `pom.xml` и `package.json`
- **update_release_old.sh** (legacy) - вливание в релизную ветку develop
- **update_tag.sh** - поднятие тега в release ветке


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
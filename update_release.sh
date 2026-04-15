helpFunction()
{
   echo ""
   echo "Update release branches release//{release_number} from develop and increase tag release_number"
   echo "    tag 2.0.4   -> 2.0.4.1"
   echo "    tag 2.0.4.1 -> 2.0.4.2"
   echo ""
   echo "Usage: $0 release_number"
   echo ""
   echo "Required: gsed, jq, git, mvn, java"
   exit 1 # Exit script after printing help
}

if [ -z "$1" ] 
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

release=$1
echo "Release: $release"
echo "\$MINOR_VERSION_SUFFIX: $MINOR_VERSION_SUFFIX"


git status
git checkout develop
git pull

if ! git diff-index --quiet HEAD --; then
    echo "Exists changes to be committed!"
    exit 1
else
    echo "Nothing to commit, working tree clean."
fi


# теги больше не перемещаем и не удаляем
# поднимаем минорную версию тега на 1
# т.е. было 2.0.4, станет 2.0.4.1

#git tag -d $1 && git push --delete origin $1
#git tag -a $1 -m "$1" && git push origin --tags

# Получаем последний тег
#last_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
# Получение последнего тега передалано на поиск тега по заданному параметру релиза.
# дело в том, что в старые релизы могут доливаться хотфиксы, из-за чего теги предыдущего релиза
# оказываюся выше текущего. Т.е. тег 2.0.46.7 может быть новее 2.0.47

last_tag=$(git tag | grep "$release" | sort -V | tail -n 1)
if [ -z "$last_tag" ] 
then
   echo "Last tag are empty. Does release exist?";
   helpFunction
fi



ver_tag=$last_tag
# Заменяем точки на пробелы и используем wc для подсчёта слов
ver_count=$(echo $last_tag | tr '.' ' ' | wc -w)
# Разбиваем тег на составляющие
IFS='.' read -ra TAG <<< "$ver_tag"

# Проверяем количество слов и выводим соответствующее сообщение
if [ "$ver_count" -eq 3 ]; then
  echo "Major version tag found: '$ver_tag'"
  ver_tag+=".1"
  echo "New version tag: '$ver_tag'"
elif [ "$ver_count" -eq 4 ]; then
  echo "Minor version tag found: '$ver_tag'"
  minor=${TAG[3]}
  echo "Minor: $minor"

  # Проверяем, есть ли в minor дефис (префикс)
  if [[ $minor == *"-"* ]]; then
    echo "Found prefix in minor version"
    # Разделяем по дефису
    IFS='-' read -ra MINOR_PARTS <<< "$minor"
    prefix_part=${MINOR_PARTS[1]}
    number_part=${MINOR_PARTS[0]}
    echo "Number: $number_part, Prefix: $prefix_part"
    let "number_part+=1"
    minor="$number_part"
  else
    # Обычная числовая версия
    let "minor+=1"
  fi

  # Собираем новый тег
  ver_tag="${TAG[0]}.${TAG[1]}.${TAG[2]}.$minor"
  echo "New version tag: '$ver_tag'"
else
  echo "Wrong tag version: $ver_tag"
fi

                                                                       
git checkout release/$1
git pull
git merge develop --strategy-option theirs

if [ -f "pom.xml" ]; then
	# set reease number for java maven project
	echo "File pom.xml found."
	mvn dependency:tree -DoutputFile=maven-dependency-tree.txt
	mvn versions:set -DnewVersion=$ver_tag -DgenerateBackupPoms=false
	git add -A && git commit -m "Add maven-dependency-tree.txt file; Set version $ver_tag"
elif  [ -f "package.json" ]; then
	# set reease number for front React project
	echo "File package.json found."

	gsed -i '0,/\"version\": \"[^\"]*\"/s//\"version\": \"'$ver_tag'\"/' package.json 

	if [ -n "$MINOR_VERSION_SUFFIX" ]; then
    		ver_tag="${TAG[0]}.${TAG[1]}.${TAG[2]}.$minor-$MINOR_VERSION_SUFFIX"
                echo "New version tag with suffix: '$ver_tag'"
        fi

        # кастомные действия 
        # Удаление папки .yarn и упоминания packageManager в package.json
        jq 'del(.packageManager)' package.json > tmp.json && mv tmp.json package.json
        rm -rf .yarn

	git add -A && git commit -m "Set version $ver_tag"
else
     echo "File pom.xml or package.json not found."
     helpFunction
fi


git tag -a $ver_tag -m "Set tag $ver_tag" && git push origin --tags && git push
#git checkout develop
git branch --show-current
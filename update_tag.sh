helpFunction()
{
   echo ""
   echo "Update last tag release_number"
   echo "    tag 2.0.4   -> 2.0.4.1"
   echo "    tag 2.0.4.1 -> 2.0.4.2"
   echo ""
   echo "For react projects with \$MINOR_VERSION_SUFFIX variables"
   echo "    tag 2.0.51.10-ibm -> 2.0.51.11-ibm"
   echo ""
   echo "Usage: $0 release_number"
   echo ""
   echo "Required: gsed, git, mvn, java"
   exit 1 # Exit script after printing help
}

if [ -z "$1" ] 
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

release=$1
echo "Release: $release"


# теги больше не перемещаем и не удаляем
# поднимаем минорную версию тега на 1
# т.е. было 2.0.4, станет 2.0.4.1

#git tag -d $1 && git push --delete origin $1
#git tag -a $1 -m "$1" && git push origin --tags

# Получаем последний тег
# last_tag=$(git describe --tags `git rev-list --tags --max-count=1`)
# Получение последнего тега передалано на поиск тега по заданному параметру релиза.
# дело в том, что в старые релизы могут доливаться хотфиксы, из-за чего теги предыдущего релиза
# оказываюся выше текущего. Т.е. тег 2.0.46.7 может быть новее 2.0.47

last_tag=$(git tag | grep "$release" | sort -V | tail -n 1)

if [ -z "$last_tag" ] 
then
   echo "Last tag are empty. Does release exist?";
   helpFunction
fi


echo "Last tag found: $last_tag"


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
  echo "Wrong tag: $ver_tag"
  helpFunction
fi

if [ -f "pom.xml" ]; then
	# set reease number for java maven project
	echo "File pom.xml found."
	mvn dependency:tree > maven-dependency-tree.txt  
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

	git add -A && git commit -m "Set version $ver_tag"
else
     echo "File pom.xml or package.json not found."
     helpFunction
fi


git tag -a $ver_tag -m "Set tag $ver_tag" && git push origin --tags && git push
helpFunction()
{
   echo ""
   echo "Creating release branches release//{release_number} and tag release_number in maven or react project"
   echo ""
   echo "Usage: $0 release_number"
   exit 1 # Exit script after printing help
}

if [ -z "$1" ] 
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

echo "Release: $1"

IFS='.' read -ra TAG <<< "$1"
# version format: X.Y.Z
minor=${TAG[2]}
let "minor+=1"
# Собираем новый тег
ver_tag="${TAG[0]}.${TAG[1]}.$minor-SNAPSHOT"
echo "Next iteration developer version will be: '$ver_tag'"

git status
git checkout develop
git pull

if ! git diff-index --quiet HEAD --; then
    echo "Exists changes to be committed!"
    exit 1
else
    echo "nothing to commit, working tree clean."
fi

if [ -f "pom.xml" ]; then
	# set reease number for java maven project
	echo "File pom.xml found."
	mvn versions:set -DnewVersion=$1 -DgenerateBackupPoms=false
	mvn dependency:tree > maven-dependency-tree.txt
elif  [ -f "package.json" ]; then
	# set reease number for front React project
	echo "File package.json found."
	gsed -i '0,/\"version\": \"[^\"]*\"/s//\"version\": \"'$1'\"/' package.json 
else
     echo "File pom.xml or package.json not found."
     helpFunction
fi

git add -A && git commit -m "Set release version $1" && git push
git tag -a $1 -m "$1" && git push origin --tags

git checkout -b release/$1
git push --set-upstream origin release/$1

git checkout develop
if [ -f "pom.xml" ]; then
	mvn versions:set -DnewVersion=$ver_tag -DgenerateBackupPoms=false
elif  [ -f "package.json" ]; then
	gsed -i '0,/\"version\": \"[^\"]*\"/s//\"version\": \"'${ver_tag}'\"/' package.json 

else
     echo "File pom.xml or package.json not found."
     helpFunction
fi

git add -A && git commit -m "Set developer version to $ver_tag" && git push
git branch --show-current


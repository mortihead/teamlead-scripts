helpFunction()
{
   echo ""
   echo "Update release branches release//{release_number} from develop branch"
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

git status
git checkout develop
git pull

if ! git diff-index --quiet HEAD --; then
    echo "Exists changes to be committed!"
    exit 1
else
    echo "nothing to commit, working tree clean."
fi

git checkout release/$1
git pull
git merge develop --strategy-option theirs
git push
git checkout develop
git branch --show-current


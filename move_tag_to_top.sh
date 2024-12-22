helpFunction()
{
   echo ""
   echo "Update (Move tag to top) tag release_number"
   echo ""
   echo "Usage: $0 tag release_number"
   exit 1 # Exit script after printing help
}

if [ -z "$1" ] 
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

echo "Release: $1"

git tag -d $1 && git push --delete origin $1
git tag -a $1 -m "$1" && git push origin --tags
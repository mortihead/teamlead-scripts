FIX_VERSION=$1
TASKS_FILE=$2
 

helpFunction()
{
   echo ""
   echo "Update fixVersions for Jira tasks"
   echo ""
   echo "Usage: $0 'version' tasks.txt"
   echo "   'version' - release version '2.0.1' for example"
   echo "   tasks.txt - an optional parameter, the name of the file that contains lines with task names from Jira. "
   echo "               This can be the result of the git log command - in this case, the script parses the lines in the file and finds the Jira task numbers."
   echo "               If the parameter is not specified, the script looks for the file tasks.txt."
   echo ""
   exit 1 # Exit script after printing help
}
exe() { echo "\$ $@" ; "$@" ; }

if [ -z "$FIX_VERSION" ]; then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Проверка переменных
if [[ -z "$JIRA_LOGIN" || -z "$JIRA_PASSWORD" || -z "$JIRA_REST" ]]; then
    echo "The variables JIRA_LOGIN, JIRA_PASSWORD, and JIRA_REST must be defined in the ~/.zprofile (MacOS) or ~/.bashrc (Linux)."
    helpFunction
fi

if [ -z "$TASKS_FILE" ]; then
   TASKS_FILE='tasks.txt' 
   echo "Use default task file: $TASKS_FILE";
else
   echo "Task file assigned to $TASKS_FILE";
fi 


echo "Jira login : '${JIRA_LOGIN}'"
echo "Jira REST  : ${JIRA_REST}"
echo "fixVersions: ${FIX_VERSION}"
echo "Tasks file : ${TASKS_FILE}"

CURL_DATA='{
    "update": {
        "fixVersions": [
            {
                "add": {
                    "name": "'$FIX_VERSION'"
                }
            }
        ]
    }
}';
 
arrTasks=()
tempFile=$(mktemp)
echo "Temp file  : ${tempFile}"
echo "" > $tempFile

cat ./$TASKS_FILE | grep -Eo '[A-Z][A-Z0-9]+-[0-9]+' | while read line; do
	 echo $line
	 echo $line >> $tempFile

	 echo $CURL_DATA

	 curl_status=$( \
	 curl -D- --user $JIRA_LOGIN:$JIRA_PASSWORD --request PUT \
	     --url $JIRA_REST'/'$line'' \
	     --header 'Content-Type: application/json; charset=utf-8' \
	     --data "$CURL_DATA"  \
	     -s -o /dev/null --write-out '%{http_code}'  | grep -i 'HTTP/1.1 ' | awk '{print $2}'| sed -e 's/^[ \t]*//' \
	     );

	  echo "HTTP response: ${curl_status}"

	  if [ $curl_status -eq 403 ]; then
	    echo "ERROR HTTP STATUS 403: AUTHENTICATION_DENIED. Check login '${JIRA_LOGIN}' and password."
	    exit 1
	  elif  [ $curl_status -eq 401 ]; then
	    echo "HTTP STATUS 401. Unauthorized for '${JIRA_LOGIN}'. Check login '${JIRA_LOGIN}' and password."
	    exit 1
	  elif  [ $curl_status -eq 200 ]; then
	    echo "OK"
	  elif  [ $curl_status -eq 204 ]; then
	    echo "OK"
	  elif  [ $curl_status -eq 400 ]; then
	    echo "Got $STATUS. Bad request. Check new release '${FIX_VERSION}' was added in JIRA releases page!"
	    exit 1
	  else
	    echo "Got $STATUS :( Not done yet..."
	    exit 1
	  fi
done


echo "----------------"
cat $tempFile | tr ' ' '\n' | sort -u | tr '\n' '\n'
echo "----------------"


echo "Update version copmlete!"
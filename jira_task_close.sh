TASKS_FILE=$2
 

helpFunction()
{
   echo ""
   echo "Close for Jira tasks"
   echo ""
   echo "Usage: $0 tasks.txt"
   echo "   tasks.txt - an optional parameter, the name of the file that contains lines with task names from Jira. "
   echo "               This can be the result of the git log command - in this case, the script parses the lines in the file and finds the Jira task numbers."
   echo "               If the parameter is not specified, the script looks for the file tasks.txt."
   echo ""
   exit 1 # Exit script after printing help
}

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


echo "Jira login: '${JIRA_LOGIN}'"
echo "Jira REST : ${JIRA_REST}"
echo "Tasks file: ${TASKS_FILE}"

# Transition id for Close status is unique for every project
# Here you need to manually check transitions[] values at which index 'Closed' present 

CURL_DATA='{
        "update": {
            "comment": [
                {
                    "add": {
                        "body": "Resolved via automated process."
                    }
                }
            ]
        },
        "transition": {
            "id": "261"
        }
    }';
 

cat ./$TASKS_FILE | grep -Eo '[A-Z][A-Z0-9]+-[0-9]+' | while read line; do
 echo $line
 echo "Check correct close transitions id in url: "$JIRA_REST/$line/transitions?expand=transitions.fields
 # echo $CURL_DATA
 curl_status=$( \
	 curl -D- --user $JIRA_LOGIN:$JIRA_PASSWORD --request POST \
	     --url $JIRA_REST'/'$line'/transitions' \
	     --header 'Content-Type: application/json; charset=utf-8' \
	     --data "$CURL_DATA" \
             -s -o /dev/null --write-out '%{http_code}'  | grep -i 'HTTP/1.1 ' | awk '{print $2}'| sed -e 's/^[ \t]*//' );

  echo "Http response: ${curl_status}"

  if [ $curl_status -eq 403 ]; then
    echo "ERROR HTTP STATUS 403: AUTHENTICATION_DENIED. Check login '${JIRA_LOGIN}' and password."
    break
  elif  [ $curl_status -eq 401 ]; then
    echo "HTTP STATUS 401. Unauthorized for '${JIRA_LOGIN}'"
    break
  elif  [ $curl_status -eq 200 ]; then
    echo "OK"
  elif  [ $curl_status -eq 204 ]; then
    echo "OK"
  elif  [ $curl_status -eq 400 ]; then
    echo "Something wrong. HTTP status 400. May be the task '${line}' is aleady closed?"
  else
    echo "Got $STATUS :( Not done yet..."
    break
  fi


done

echo "Update tasks complete!"
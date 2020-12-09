#!/bin/bash
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${CURRENT_DIR}/common-util.sh

# return codes for success
RC_SEND_MESSAGE_SUCCESS=0

# return codes for various errors
RC_SLACK_ERROR=1
RC_NOTIFY_TYPE=901
RC_NOTIFY_MSG=902
RC_NOTIFY_LEVEL=903
RC_BAD_USAGE=999

# general
CALLER_CMD_INFO="$(ps -o args= $PPID)"
NOTIFY_SUBJECT="${OPS_DEPLOY_ENV} - $(hostname)"
SEND_TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%SZ%z")

# slack common
OPS_SLACK_URL="${OPS_SLACK_URL}"

# slack sender
SLACK_SENDER_GOOD="OPS-GOOD"
SLACK_SENDER_WARN="OPS-WARN"
SLACK_SENDER_CRIT="OPS-CRIT"
SLACK_SENDER_UNKNOWN="OPS-UNKNOWN"

# slack color types
SLACK_COLOR_GOOD="good"
SLACK_COLOR_WARN="warning"
SLACK_COLOR_CRIT="danger"

# slack emoji types
SLACK_EMOJI_GOOD=":sunny:"
SLACK_EMOJI_WARN=":bangbang:"
SLACK_EMOJI_CRIT=":fire:"

# slack channel
SLACK_CHANNEL_GOOD="#ops-image-build"
SLACK_CHANNEL_WANR="#ops-image-build-alarm"
SLACK_CHANNEL_CRIT="#ops-image-build-alarm"
SLACK_CHANNEL_UNKNOWN="#playground"

function error_1() {
  logger "send slack failed" "ERROR"
}

function error_901() {
  logger "notification type must be used when invoking this script." "ERROR"
}

function error_902() {
  logger "notification_level must be used when invoking this script." "ERROR"
}

function error_903() {
  logger "notification_level must be used when invoking this script." "ERROR"
}

function error_999() {
  logger "probably you are doing bad things, please follow the usage to execute the script." "ERROR"
}

function err_exit() {
  local _errid=${1}
  error_${_errid}
  exit ${_errid}
}

show_usage() {
 /bin/cat << EOF
Send notification massage.
Usage: -t notification_type 
       -l notification_level
       -m notification_message
       [-h] help page optional
Options:
  -m    (required) Use notification message for user input.  May container URLs using slack notification format <url|name>.  
        For example: send-message.sh -l good -m 'Got 200 response from <http://www.google.com|google> and <http://www.yahoo.com|yahoo>.  Search is alive and well' 
  -l    (required) Use notification level for user input. 
        Valid values are 'GOOD', 'WARN', and 'CRIT'. 
  -h    Display this help message and exit

Example: sh send-message.sh -t slack -l crit -m "something failed"

Notes:
* message supports markdown but you MUST double quote and escape special characters e.g. -m "it's a \`test\` message"

EOF
}

function send_slack() {
  NOTIFY_LEVEL=$(echo $NOTIFY_LEVEL | tr '[:upper:]' '[:lower:]')
  case $NOTIFY_LEVEL in
    GOOD|good)
      local slack_sender="${SLACK_SENDER_GOOD}"
      local slack_color="${SLACK_COLOR_GOOD}"
      local slack_emoji="${SLACK_EMOJI_GOOD}"
      local slack_channel="${SLACK_CHANNEL_GOOD}"
      local slack_subject="${NOTIFY_SUBJECT} - level [GOOD]";;
    CRIT|crit)
      local slack_sender="${SLACK_SENDER_CRIT}"
      local slack_color="${SLACK_COLOR_CRIT}"
      local slack_emoji="${SLACK_EMOJI_CRIT}"
      local slack_channel="${SLACK_CHANNEL_CRIT}"
      local slack_subject="${NOTIFY_SUBJECT} - level [CRIT]";;
    WARN|warn)
      local slack_sender="${SLACK_SENDER_WARN}"
      local slack_color="${SLACK_COLOR_WARN}"
      local slack_emoji="${SLACK_EMOJI_WARN}"
      local slack_channel="${SLACK_CHANNEL_WANR}"
      local slack_subject="${NOTIFY_SUBJECT} - level [WARN]";;
    *) 
      local slack_sender="${SLACK_SENDER_UNKNOWN}"
      local slack_color="#c3cab9"
      local slack_emoji=":ghost:"
      local slack_channel="${SLACK_CHANNEL_UNKNOWN}"
      local slack_subject="${NOTIFY_SUBJECT} - level [UNKNOWN]";;
  esac

  local payload=" 
                 {\"channel\": \"${slack_channel}\", 
                  \"mrkdwn_in\": [\"pretext\",\"text\",\"fields\"],
                  \"username\": \"${slack_sender}\",
                  \"icon_emoji\": \"${slack_emoji}\",
                  \"attachments\": [{
                  \"pretext\": \"${NOTIFY_MSG}\",
                  \"fields\": [
                    { \"title\": \"Deploy Environment:\", \"value\": \"\`${OPS_DEPLOY_ENV}\`\", \"short\": true },
                    { \"title\": \"Host:\", \"value\": \"\`$(hostname)\`\", \"short\": true },
                    { \"title\": \"Level:\", \"value\": \"\`${NOTIFY_LEVEL}\`\", \"short\": true },
                    { \"title\": \"Timestamp:\", \"value\": \"\`${SEND_TIMESTAMP}\`\", \"short\": true },
                    { \"title\": \"Process:\", \"value\": \"\`${CALLER_CMD_INFO}\`\", \"short\": false }
                 ],
                 \"color\": \"$sc\"}]}
                "

  logger "send type [slack], slack url [${OPS_SLACK_URL}]"
  logger "send message [${_slack_msg}]"
  logger "send payload [${payload}]"

  echo "$curl -X POST -w %{http_code} -s -o /dev/null -d payload=${payload} ${OPS_SLACK_URL}"
  local response="$(curl -X POST -w %{http_code} -s -o /dev/null -d "payload=${payload}" ${OPS_SLACK_URL})"
  echo "$curl -X POST -w %{http_code} -s -o /dev/null -d payload=${payload} ${OPS_SLACK_URL}"
  local result=$?
  if [ "${result}" -eq 0 ]; then
    if [ "$response" -eq 200 ]; then
      logger "slack notification message has been sent succesfully."
      local ret_value=0
    elif [ "$response" -eq 404 ]; then
      logger "slack notification message failed with (Response code = ${response} 'Bad Slack Webhook URL token')." "ERROR"
      local ret_value=$response
    elif [ "$response" -eq 500 ]; then
      logger "slack notification message failed with (Response code = ${response} 'Slack Payload was not valid')." "ERROR"
      local ret_value=$response
    else
      logger "Slack notification message failed with (Response code = ${response})." "ERROR"
      local ret_value=$response
    fi
  else
    logger "curl command failed with retun code value ${result}" "ERROR"
    local ret_value=$result
  fi

  SLACK_RET_VALUE=$ret_value
}

function send() {
  local _send_type="${1}"

  case ${_send_type} in 
    "slack") 
      send_slack "${_message}" "${_level}"
      ;;
    "email") ;;
    *)  ;;
  esac
}

# main
logger "show arguments [$*]"
while getopts ":t:m:l:h" FLAG; do
  case ${FLAG} in
    t) NOTIFY_TYPE=${OPTARG} ;;
    m) NOTIFY_MSG=${OPTARG} ;;
    l) NOTIFY_LEVEL=${OPTARG} ;;
    h) show_usage && exit 0;;
    *) show_usage && err_exit ${RC_BAD_USAGE};;
  esac
done

shift $((OPTIND-1))
INVALID_ARGUMENTS=$*
[ -n "${INVALID_ARGUMENTS}" ] && show_usage && err_exit ${RC_BAD_USAGE}
[ -z "${NOTIFY_TYPE}" ] && show_usage && err_exit ${RC_NOTIFY_TYPE}
[ -z "${NOTIFY_MSG}" ] && show_usage && err_exit ${RC_NOTIFY_MSG}
[ -z "${NOTIFY_LEVEL}" ] && show_usage && err_exit ${RC_NOTIFY_LEVEL}
 
logger "script Input: SEND_TYPE = '${SEND_TYPE}', NOTIFY_LEVEL = '${NOTIFY_LEVEL}', NOTIFY_MSG = '${NOTIFY_MSG}'" "INFO"

send "${NOTIFY_TYPE}" "${NOTIFY_MSG}" "${NOTIFY_LEVEL}"

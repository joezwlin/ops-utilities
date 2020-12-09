#!/bin/bash
OPS_DEPLOY_ENV="${OPS_DEPLOY_ENV:-DEV}"
OPS_LOGGER_MUTE="0"
PROC_NAME="`basename $0`"
DIR_PREFIX="${OPS_DEPLOY_DIR:-/opt/devops}"
PATH="${PATH}:${DIR_PREFIX}/bin:/usr/local/bin"

TMP_DIR="${DIR_PREFIX}/tmp" && [ -d $TMP_DIR ] || mkdir -p $TMP_DIR
CONF_DIR="${DIR_PREFIX}/conf" && [ -d $CONF_DIR ] || mkdir -p $CONF_DIR
LOG_DIR="${DIR_PREFIX}/log" && [ -d $LOG_DIR ] || mkdir -p $LOG_DIR
KEY_DIR="${DIR_PREFIX}/key" && [ -d $KEY_DIR ] || mkdir -p $KEY_DIR

LOG_FILE=${LOG_DIR}/${PROC_NAME}.log.`date +%d`
if [ -f $LOG_FILE ]; then
  if [ ! `find $LOG_FILE -mtime -1 | wc -l` = 1 ]; then
    : > $LOG_FILE
  fi
fi

function logger() {
    local log_message="${1}"
    local log_level="${2:-INFO}"
    local log_file="${3:-$LOG_FILE}"

    local log_heading="$(date +'%Y/%m/%d %H:%M:%S') ${PROC_NAME} $$"
    local func_name="${FUNCNAME[1]}"

    # colorful log level
    local color_reset='\e[0m'
    local color_red='\e[0;31m';
    local color_green='\e[0;32m';
    local color_yellow='\e[0;33m';
    case $log_level in
      INFO)
        log_color_heading="${log_heading} ${color_green}$log_level${color_reset}"
        ;;
      WARN)
        log_color_heading="${log_heading} ${color_yellow}$log_level${color_reset}"
        ;;
      ERROR)
        log_color_heading="${log_heading} ${color_red}$log_level${color_reset}"
        ;;
      *)
        log_color_heading="${log_heading} ${color_green}$log_level${color_reset}"
        ;;
    esac

    log_heading="${log_heading} $log_level ${func_name}:"
    log_color_heading="${log_color_heading} ${func_name}:"

    if [[ "x$log_file" == "x" ]]; then
      echo "log_file doesn't exist, please set it up!"
    else
      if [[ ${OPS_LOGGER_MUTE} -eq 1 ]]; then
        echo -e "$log_heading $log_message" >> $log_file
      else
        echo -e "$log_color_heading $log_message"
        echo -e "$log_heading $log_message" >> $log_file
      fi
    fi
}

function show_curtime() {
  date '+%Y/%m/%d %H:%M:%S %Z'
}

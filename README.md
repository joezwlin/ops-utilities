# ops utilities
Set of utility scripts for general DevOps usage.

# common-util.sh
Basically all ops scripts MUST source this file to locate the DIR `${OPS_DEPLOY_ENV}` where you run the ops scrtips, and using the function slogger to have a good readibility format which support ANSI color stdout, furthermore if you want to have colorful output in CICD tools then you have to install the relative plugin to them e.g. Jenkins -> ansiColor.

### Usage:
Deploy your ops scripts in `${OPS_DEPLOY_DIR}/bin`.
Make sure your scripts run in the same folder with common-util.sh, and always keep the head of scripts have the code shown as below:
```
#!/bin/bash
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
source ${CURRENT_DIR}/common-util.sh
```

### Notes:
The global variables that MUST be defined as `ENVIORMENT VARIABLES` or replaced in script.
| name            | type       | description                                                               |
|---------------- |------------|---------------------------------------------------------------------------|
| OPS_DEPLOY_ENV  | string     | the deployment environment e.g. PROD, STAGE, DEV, default is `DEV`        |
| OPS_DEPLOY_DIR  | string     | the directory where you deploy your ops scripts, default is `/opt/devops` | 
| OPS_LOGGER_MUTE | string     | disables stdout, but still writes into log file                           |


# send-message.sh
A generic message sending tool writen by shell script to support different sending approach e.g. slack, email ...etc.

### Synopsis:
```
./send-message.sh [-h]
./send-message.sh -t send_type -l level -m message
```

### Options:
```
-h  optional, display the help message and exit
-t  required, the notification type, e.g. slack, email
-l  required, the notification level, supports GOOD, WARN, CRIT, others show UNKNOWN.
-m  required, the notification message that will send out to the receiver
```

### Notes:
The global variables that MUST be defined as `ENVIORMENT VARIABLES` or replaced in script.
| name            | type       | description                                                               |
|---------------- |------------|---------------------------------------------------------------------------|
| OPS_SLACK_URL   | string     | the deployment environment e.g. PROD, STAGE, DEV, default is `DEV`        |

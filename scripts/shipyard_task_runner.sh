#!/usr/bin/env bash

set -e
set -o pipefail

# environment variables used
# SHIPYARD_SYSTEM_PROLOGUE_CMD: pre-exec system cmd
# SHIPYARD_USER_PROLOGUE_CMD: pre-exec user cmd
# SHIPYARD_SYSTEM_EPILOGUE_CMD: post-exec system cmd
# SHIPYARD_ENV_EXCLUDE: environment vars to exclude
# SHIPYARD_ENV_FILE: env file
# SHIPYARD_RUNTIME: docker or singularity
# SHIPYARD_RUNTIME_CMD: run or exec
# SHIPYARD_RUNTIME_CMD_OPTS: options
# SHIPYARD_CONTAINER_IMAGE_NAME: container name
# SHIPYARD_USER_CMD: user command

## Load environment modules, if available
if [ -f /etc/profile.d/modules.sh ]; then
    # shellcheck disable=SC1091
    source /etc/profile.d/modules.sh
fi

## PRE-EXEC
if [ -n "$SHIPYARD_SYSTEM_PROLOGUE_CMD" ]; then
    eval "$SHIPYARD_SYSTEM_PROLOGUE_CMD"
fi

if [ -n "$SHIPYARD_USER_PROLOGUE_CMD" ]; then
    eval "$SHIPYARD_USER_PROLOGUE_CMD"
fi

## TASK EXEC
if [ -n "$SHIPYARD_ENV_EXCLUDE" ]; then
    env | grep -vE "$SHIPYARD_ENV_EXCLUDE" > "$SHIPYARD_ENV_FILE"
else
    env > "$SHIPYARD_ENV_FILE"
fi

SHIPYARD_RUNTIME_CMD_OPTS=$(eval echo "${SHIPYARD_RUNTIME_CMD_OPTS}")

set +e

if [ -n "$SHIPYARD_RUNTIME" ]; then
    eval "$SHIPYARD_RUNTIME $SHIPYARD_RUNTIME_CMD $SHIPYARD_RUNTIME_CMD_OPTS \
        $SHIPYARD_CONTAINER_IMAGE_NAME $SHIPYARD_USER_CMD"
    SHIPYARD_TASK_EC=$?
else
    eval "$SHIPYARD_USER_CMD"
    SHIPYARD_TASK_EC=$?
fi

## POST EXEC
if [ -n "$SHIPYARD_SYSTEM_EPILOGUE_CMD" ]; then
    if [ "$SHIPYARD_TASK_EC" -eq 0 ]; then
        export SHIPYARD_TASK_RESULT=success
    else
        export SHIPYARD_TASK_RESULT=fail
    fi
    eval "$SHIPYARD_SYSTEM_EPILOGUE_CMD"
fi

exit $SHIPYARD_TASK_EC

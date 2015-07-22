#!/bin/bash

set -e

# Modify docker group id to match host system.
if [ -S /var/run/docker.sock ]; then
  groupmod --gid $(ls -n /var/run/docker.sock | awk '{print $4}') docker
fi

# Ensure a valid home directory.
mkdir -p ${GITLAB_CI_HOME}
chown ${GITLAB_CI_USER}:${GITLAB_CI_USER} ${GITLAB_CI_HOME}

# Ensure config permission.
touch ${GITLAB_CI_CONFIG}
chown ${GITLAB_CI_USER}:${GITLAB_CI_USER} ${GITLAB_CI_CONFIG}
chmod 0600 ${GITLAB_CI_CONFIG}

# Assign arguments unless already specified. Note that we can't go
# Dockerfile CMD way here because CMD will not do variable
# substitution.
args="run"
if [ $# != 0 ]; then
  args="${args} $@";
else
  args="${args} --working-directory ${GITLAB_CI_HOME}"
  args="${args} --config ${GITLAB_CI_CONFIG}"
fi

# Start Gitlab CI Multi Runner service
start-stop-daemon --start \
  --chuid ${GITLAB_CI_USER} \
  --chdir ${GITLAB_CI_HOME} \
  --exec ${GITLAB_CI_RUNNER_PATH} \
  --name ${GITLAB_CI_RUNNER_NAME} \
  --pidfile /var/run/${GITLAB_CI_RUNNER_NAME}.pid --make-pidfile \
  --no-close --background \
  -- ${args} >> /var/log/${GITLAB_CI_RUNNER_NAME}.log

# Further setups, e.g. runner registration.
if [ -d "${GITLAB_CI_RUNNERS_DIR}" ]; then
  eval run-parts ${GITLAB_CI_RUNNERS_ARGS:+--arg=\"${GITLAB_CI_RUNNERS_ARGS}\"} -- ${GITLAB_CI_RUNNERS_DIR}
fi

while [ true ]; do
  sleep 1000d;
done

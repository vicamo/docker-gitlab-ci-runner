FROM buildpack-deps:sid-scm

MAINTAINER You-Sheng Yang <vicamo@gmail.com>

ENV GITLAB_CI_USER=gitlab-ci \
	GITLAB_CI_RUNNER_URL=https://gitlab-ci-multi-runner-downloads.s3.amazonaws.com/master/binaries/gitlab-ci-multi-runner-linux-amd64 \
	GITLAB_CI_RUNNER_NAME=gitlab-ci-multi-runner \
	GITLAB_CI_RUNNERS_DIR=/etc/gitlab-ci/runners.d \
	GITLAB_CI_RUNNERS_ARGS= \
	GITLAB_CI_DATA_DIR=/var/lib/gitlab-ci
ENV GITLAB_CI_RUNNER_PATH=/usr/bin/${GITLAB_CI_RUNNER_NAME} \
	GITLAB_CI_HOME=/home/${GITLAB_CI_USER} \
	GITLAB_CI_CONFIG=${GITLAB_CI_DATA_DIR}/config.toml

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		apt-transport-https \
		apt-utils \
		ca-certificates \
		docker.io \
		locales \
	&& update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
	&& locale-gen en_US.UTF-8 \
	&& dpkg-reconfigure locales \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*_dists_*

# Install gitlab-ci-multi-runner manually.
#
# See https://github.com/ayufan/gitlab-ci-multi-runner/blob/master/packaging/scripts/postinst.deb
RUN wget -q -O ${GITLAB_CI_RUNNER_PATH} ${GITLAB_CI_RUNNER_URL} \
	&& chmod +x ${GITLAB_CI_RUNNER_PATH} \
	&& useradd --comment 'GitLab CI Runner' \
		--home ${GITLAB_CI_HOME} --create-home \
		--shell /bin/bash \
		${GITLAB_CI_USER} \
	&& usermod -aG docker ${GITLAB_CI_USER}

VOLUME ["${GITLAB_CI_HOME}", "${GITLAB_CI_DATA_DIR}"]
WORKDIR ${GITLAB_CI_HOME}

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

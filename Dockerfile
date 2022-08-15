ARG BASE_IMAGE_URI=quay.io/ansible/ansible-runner
ARG BASE_IMAGE_TAG=stable-2.12-latest

FROM ${BASE_IMAGE_URI}:${BASE_IMAGE_TAG} AS base

ARG BUILD_DATE
ARG BUILD_TAG
ARG BASE_IMAGE_TAG

# Copy Payload
COPY payload /runner/

# NOTE: Need to match the python devel ver to base image ver, currently 3.8
# Update readme if you change Python version!

# NOTE: Ansible collections and roles are installed into a non-default location
# Downstream implementers and users are expected to include this location if
# these built-ins are desired by setting the Ansible collections path variable
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && cp /runner/deps/*.repo /etc/yum.repos.d/ \
    && dnf clean expire-cache \
    && dnf install -y python38-devel git curl which bash gcc vim unzip \
    && pip install -r /runner/deps/python_base.txt \
    && ansible-galaxy role install -p /opt/cldr-runner/roles -r /runner/deps/ansible.yml \
    && ansible-galaxy collection install -p /opt/cldr-runner/collections -r /runner/deps/ansible.yml \
    && mkdir -p /home/runner/.ansible/log \
    && mv /runner/bashrc /home/runner/.bashrc \
    && echo "Purging Pip cache" &&  pip cache purge || echo "No Pip cache to purge" \
    && echo "Cleaning dnf/yum cache" && dnf clean all \
  	&& rm -rf /var/cache/yum \
    && rm -rf /var/cache/dnf

ENV CLDR_BUILD_DATE=${BUILD_DATE}
ENV CLDR_BUILD_VER=${BUILD_TAG}

# Metadata
LABEL maintainer="Cloudera Labs <cloudera-labs@cloudera.com>" \
      org.label-schema.url="https://github.com/cloudera-labs/cldr-runner/blob/main/README.adoc" \
      org.opencontainers.image.source="https://github.com/cloudera-labs/cldr-runner" \
      org.label-schema.build-date="${CLDR_BUILD_DATE}" \
      org.label-schema.version="${CLDR_BUILD_VER}" \
      org.label-schema.vcs-url="https://github.com/cloudera-labs/cldr-runner.git" \
      org.label-schema.vcs-ref="https://github.com/cloudera-labs/cldr-runner" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.description="Ansible-Runner image with deps for CDP and underlying infrastructure" \
      org.label-schema.schema-version="1.0"

## Set up the execution
CMD ["ansible-runner", "run", "/runner"]
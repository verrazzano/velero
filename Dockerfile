# Copyright 2020 the Velero contributors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
FROM ghcr.io/oracle/oraclelinux:7-slim as builder-env

RUN yum update -y \
    && yum-config-manager --save --setopt=ol7_ociyum_config.skip_if_unavailable=true \
    && yum install -y tar gzip bzip2\
    && yum install -y oracle-golang-release-el7 \
    && yum install -y golang-1.17.5-1.el7.x86_64 \
    && yum clean all \
    && rm -rf /var/cache/yum/* \
    && go version

ARG GOPROXY
ARG PKG
ARG VERSION
ARG GIT_SHA
ARG GIT_TREE_STATE
ARG REGISTRY

ENV CGO_ENABLED=0 \
    GO111MODULE=on \
    GOPROXY=${GOPROXY} \
    LDFLAGS="-X ${PKG}/pkg/buildinfo.Version=${VERSION} -X ${PKG}/pkg/buildinfo.GitSHA=${GIT_SHA} -X ${PKG}/pkg/buildinfo.GitTreeState=${GIT_TREE_STATE} -X ${PKG}/pkg/buildinfo.ImageRegistry=${REGISTRY}"

WORKDIR /go/src/github.com/vmware-tanzu/velero

COPY . /go/src/github.com/vmware-tanzu/velero

FROM builder-env as builder

ENV TARGETOS=linux
ENV TARGETARCH=amd64
ENV TARGETVARIANT=""
ARG PKG
ARG BIN
ARG RESTIC_VERSION

ENV GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    GOARM=${TARGETVARIANT}

RUN mkdir -p /output/usr/bin && \
    bash ./hack/download-restic.sh && \
    export GOARM=$( echo "${GOARM}" | cut -c2-) && \
    go build -o /output/${BIN} \
    -ldflags "${LDFLAGS}" ${PKG}/cmd/${BIN}

FROM ghcr.io/oracle/oraclelinux:7-slim
COPY --from=builder /output /
RUN  yum update -y  && \
     yum clean all && \
     rm -rf /var/cache/yum/*
USER 1000

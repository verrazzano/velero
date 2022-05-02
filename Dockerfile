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
FROM ghcr.io/oracle/oraclelinux:8-slim as builder-env


RUN microdnf update -y \
    && microdnf install -y oraclelinux-developer-release-el8 \
    && microdnf module enable go-toolset:ol8addon \
    && microdnf install go-toolset \
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

ENV GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    GOARM=${TARGETVARIANT}

RUN mkdir -p /output/usr/bin && \
    export GOARM=$( echo "${GOARM}" | cut -c2-) && \
    go build -o /output/${BIN} \
    -ldflags "${LDFLAGS}" ${PKG}/cmd/${BIN}

FROM ghcr.io/oracle/oraclelinux:8-slim
ARG RESTIC_VERSION
COPY --from=builder /output /
RUN  microdnf update -y  && \
     rm -rf /var/cache/yum/* \
     && rpm -ivh  https://artifacthub-iad.oci.oraclecorp.com/olcne-yum-stable-ol8/restic-${RESTIC_VERSION}.el8.x86_64.rpm
USER 1000

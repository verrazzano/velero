# Build Instructions

The base tag this release is branched from is `v1.8.1`

Create Environment Variables

```
export DOCKER_REPO=<Docker Repository>
export DOCKER_NAMESPACE=<Docker Namespace>
export DOCKER_REPO_NAME = "velero"
export DOCKER_IMAGE_NAME = "velero"
export DOCKER_RESTIC_REPO_NAME = "velero-restic-restore-helper"
export DOCKER_RESTIC_IMAGE_NAME = "velero-restic-restore-helper"
export DOCKER_TAG=v1.8.1-BFS
```

Build and Push Images

```
# Build and push Velero
git tag -d v1.8.1
git tag  v1.8.1
REGISTRY=${DOCKER_REPO}/${DOCKER_NAMESPACE}/${DOCKER_IMAGE_NAME} VERSION=${DOCKER_IMAGE_TAG} make container
docker push ${DOCKER_REPO}/${DOCKER_NAMESPACE}/${DOCKER_REPO_NAME}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
REGISTRY=${DOCKER_REPO}/${DOCKER_NAMESPACE}/${DOCKER_RESTIC_IMAGE_NAME} VERSION=${DOCKER_IMAGE_TAG} make container
docker push ${DOCKER_REPO}/${DOCKER_NAMESPACE}/${DOCKER_REPO_NAME}/${DOCKER_RESTIC_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
```
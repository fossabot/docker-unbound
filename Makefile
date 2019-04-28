.PHONY: default
default: build

# Build Docker image
.PHONY: build
build: docker_build output

# Build and push Docker image
.PHONY: release
release: docker_build docker_push output

# Image can be overidden with env vars.
DOCKER_IMAGE ?= jmdilly/unbound

# Get the latest commit.
GIT_COMMIT = $(strip $(shell git rev-parse --short HEAD))

# Get the version number from the code
CODE_VERSION = $(strip $(shell cat VERSION))


# Use the version number as the release tag.
DOCKER_TAG = $(CODE_VERSION)

ifndef CODE_VERSION
$(error You need to create a VERSION file to build a release)
endif


.PHONY: docker_build
docker_build:
	# Build Docker image
	docker build \
  --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
  --build-arg BUILD_VERSION=$(CODE_VERSION) \
  --build-arg VCS_URL="https://github.com/jmdilly/docker-unbound/" \
  --build-arg VCS_REF=$(GIT_COMMIT) \
	-t $(DOCKER_IMAGE):$(DOCKER_TAG) .

.PHONY: docker_push
docker_push:
	# Tag image as latest
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):latest

	# Push to DockerHub
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	docker push $(DOCKER_IMAGE):latest

.PHONY: output
output:
	@echo Docker Image: $(DOCKER_IMAGE):$(DOCKER_TAG)

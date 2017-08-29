default:
	@echo "No default action"
.PHONY: default

VENDOR_NAME=ddotsenko
IMAGE_NAME=nginx
IMAGE_NAME_FULL=$(VENDOR_NAME)/$(IMAGE_NAME)
CONTAINER_NAME=$(VENDOR_NAME)-$(IMAGE_NAME)-container

# Build

NGINX_VERSION=latest

# use as `make image NGINX_VERSION=1.12.1` Version is `latest` otherwise
image:
	docker build -t $(IMAGE_NAME_FULL):$(NGINX_VERSION) --build-arg NGINX_VERSION=$(NGINX_VERSION) -f Dockerfile .

.PHONY: image

# Dev-oriented

rm-container:
	docker rm $(CONTAINER_NAME) || true

run: rm-container
	docker run -it \
	--name $(CONTAINER_NAME) \
	-p 8888:80 \
	-e EXAMPLE_VAR=example_val \
	$(IMAGE_NAME_FULL)

shell:
	docker exec -it \
	$(CONTAINER_NAME) \
	bash

.PHONY: rm-container run shell

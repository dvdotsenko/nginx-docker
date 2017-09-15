default:
	@echo "No default action"
.PHONY: default

REGISTRY_URL:=$(if $(REGISTRY_URL),$(REGISTRY_URL),docker.io)
VENDOR_NAME=ddotsenko
IMAGE_NAME=nginx
IMAGE_NAME_FULL=$(VENDOR_NAME)/$(IMAGE_NAME)
CONTAINER_NAME=$(VENDOR_NAME)-$(IMAGE_NAME)-container

# Build

NGINX_VERSIONS:=$(shell more versions.txt)

# use as `make image NGINX_VERSION=1.12.1` Version is `latest` otherwise
images:
	@for NGINX_VERSION in $(NGINX_VERSIONS) ; do \
	    echo ">>> Processing Nginx version $$NGINX_VERSION <<<" ; \
	    docker pull nginx:$$NGINX_VERSION ; \
	    docker build \
            -t $(IMAGE_NAME_FULL):$$NGINX_VERSION \
            --build-arg NGINX_VERSION=$$NGINX_VERSION \
            -f Dockerfile . ; \
	done

.PHONY: image

upload: images
	@for NGINX_VERSION in $(NGINX_VERSIONS) ; do \
	    echo ">>> Processing Nginx version $$NGINX_VERSION <<<" ; \
		docker tag \
			$(IMAGE_NAME_FULL):$$NGINX_VERSION \
			$(REGISTRY_URL)/$(IMAGE_NAME_FULL):$$NGINX_VERSION ; \
		docker push \
			$(REGISTRY_URL)/$(IMAGE_NAME_FULL):$$NGINX_VERSION ; \
	done

.PHONY: upload


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

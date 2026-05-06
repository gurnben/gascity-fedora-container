IMAGE_NAME ?= gascity-fedora
REGISTRY   ?= ghcr.io/gurnben/gascity-fedora-container
TAG        ?= latest

.PHONY: build test lint clean

build:
	podman build -t $(IMAGE_NAME):$(TAG) -f Containerfile .

test: build
	podman run --rm $(IMAGE_NAME):$(TAG) gc version
	podman run --rm $(IMAGE_NAME):$(TAG) dolt version
	podman run --rm $(IMAGE_NAME):$(TAG) bd version
	podman run --rm $(IMAGE_NAME):$(TAG) crush --version
	podman run --rm $(IMAGE_NAME):$(TAG) claude --version
	podman run --rm $(IMAGE_NAME):$(TAG) opencode -v
	podman run --rm $(IMAGE_NAME):$(TAG) gemini --version

lint:
	hadolint Containerfile || true

clean:
	podman rmi $(IMAGE_NAME):$(TAG) 2>/dev/null || true

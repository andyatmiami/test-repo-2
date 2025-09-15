# Variables
IMAGE_NAME := test-repo
REGISTRY := ghcr.io
FULL_IMAGE_NAME := $(REGISTRY)/$(IMAGE_NAME)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "latest")
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Go build variables
BINARY_NAME := main
GO_FILES := $(shell find . -name "*.go" -type f)

.PHONY: help build clean docker-build docker-run docker-push docker-tag test lint

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Go application locally
	@echo "Building Go application..."
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o $(BINARY_NAME) .
	@echo "Build complete: $(BINARY_NAME)"

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -f $(BINARY_NAME)
	@echo "Clean complete"

test: ## Run Go tests
	@echo "Running tests..."
	go test -v ./...

lint: ## Run Go linter
	@echo "Running linter..."
	golangci-lint run

docker-build: ## Build Docker image
	@echo "Building Docker image: $(FULL_IMAGE_NAME):$(VERSION)"
	docker build \
		--build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg GIT_COMMIT="$(GIT_COMMIT)" \
		--build-arg VERSION="$(VERSION)" \
		-t $(FULL_IMAGE_NAME):$(VERSION) \
		-t $(FULL_IMAGE_NAME):latest \
		.
	@echo "Docker build complete"

docker-run: ## Run Docker container locally
	@echo "Running Docker container..."
	docker run --rm $(FULL_IMAGE_NAME):latest

docker-tag: ## Tag Docker image with version
	@echo "Tagging image: $(FULL_IMAGE_NAME):$(VERSION)"
	docker tag $(FULL_IMAGE_NAME):latest $(FULL_IMAGE_NAME):$(VERSION)

docker-push: ## Push Docker image to registry
	@echo "Pushing Docker image to $(REGISTRY)..."
	docker push $(FULL_IMAGE_NAME):$(VERSION)
	docker push $(FULL_IMAGE_NAME):latest
	@echo "Push complete"

docker-push-latest: ## Push only latest tag
	@echo "Pushing latest tag to $(REGISTRY)..."
	docker push $(FULL_IMAGE_NAME):latest
	@echo "Push complete"

docker-clean: ## Remove local Docker images
	@echo "Removing local Docker images..."
	docker rmi $(FULL_IMAGE_NAME):$(VERSION) $(FULL_IMAGE_NAME):latest 2>/dev/null || true
	@echo "Docker clean complete"

all: clean build docker-build ## Build everything (clean, build, docker-build)

# Development targets
dev: ## Run the application locally (without Docker)
	@echo "Running application locally..."
	go run main.go

# Show image info
image-info: ## Show Docker image information
	@echo "Image: $(FULL_IMAGE_NAME)"
	@echo "Version: $(VERSION)"
	@echo "Build Date: $(BUILD_DATE)"
	@echo "Git Commit: $(GIT_COMMIT)"

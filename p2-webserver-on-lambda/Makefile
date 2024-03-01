# Makefile

# The binary to build (just the basename).
BIN=bootstrap
ARCH=arm64

# Lambda function name
FUNCTION_NAME=simple_webserver

# Output directory
OUT_DIR=entrypoint
ZIP_FILE=$(OUT_DIR)/$(BIN).zip

.PHONY: build
build:
	@echo "Building $(BIN) version $(VERSION)"
	GOOS=linux GOARCH=$(ARCH) go build -tags lambda.norpc -o $(OUT_DIR)/$(BIN) ./cmd/lambda.go
	@echo "Build complete"

.PHONY: package
package: build
	@echo "Packaging $(BIN) into $(ZIP_FILE)"
	@zip $(ZIP_FILE) $(BIN)
	@echo "Package complete"

.PHONY: clean
clean:
	@echo "Cleaning"
	@rm -rf $(OUT_DIR)/*

.PHONY: deploy
deploy: package
	@echo "Uploading $(ZIP_FILE) to AWS Lambda $(FUNCTION_NAME)"
	aws lambda update-function-code --function-name $(FUNCTION_NAME) --zip-file fileb://$(ZIP_FILE)
	@echo "Deploy complete"
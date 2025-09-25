# Focus Detective Makefile
# Build the macOS app from command line

# Configuration
PROJECT_NAME = FocusDetective
SCHEME = FocusDetective
CONFIGURATION = Release
BUILD_DIR = build
DERIVED_DATA_PATH = $(BUILD_DIR)/DerivedData
ARCHIVE_PATH = $(BUILD_DIR)/$(PROJECT_NAME).xcarchive
APP_NAME = FocusDetective.app
EXPORT_PATH = $(BUILD_DIR)/Export

# Xcode build settings
XCODE_WORKSPACE = $(PROJECT_NAME).xcodeproj
SDK = macosx

.PHONY: all clean build archive export install help

# Default target
all: build

# Build the app for development
build:
	@echo "Building $(PROJECT_NAME)..."
	xcodebuild -project "$(XCODE_WORKSPACE)" \
		-scheme "$(SCHEME)" \
		-configuration Debug \
		-sdk $(SDK) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		build

# Build release version
release:
	@echo "Building $(PROJECT_NAME) for release..."
	xcodebuild -project "$(XCODE_WORKSPACE)" \
		-scheme "$(SCHEME)" \
		-configuration $(CONFIGURATION) \
		-sdk $(SDK) \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		-derivedDataPath "$(DERIVED_DATA_PATH)" \
		build
	@echo "Copying app to root directory..."
	cp -R "$(DERIVED_DATA_PATH)/Build/Products/$(CONFIGURATION)/Focus Detective.app" ./
	@echo "Cleaning extended attributes..."
	xattr -cr "Focus Detective.app"
	@echo "Release build complete: Focus Detective.app"

# Create archive
archive:
	@echo "Archiving $(PROJECT_NAME)..."
	xcodebuild -project "$(XCODE_WORKSPACE)" \
		-scheme "$(SCHEME)" \
		-configuration $(CONFIGURATION) \
		-sdk $(SDK) \
		-archivePath "$(ARCHIVE_PATH)" \
		archive

# Export app from archive
export: archive
	@echo "Exporting $(PROJECT_NAME)..."
	xcodebuild -exportArchive \
		-archivePath "$(ARCHIVE_PATH)" \
		-exportPath "$(EXPORT_PATH)" \
		-exportOptionsPlist ExportOptions.plist

# Install the app to /Applications (requires export first)
install: export
	@echo "Installing $(APP_NAME) to /Applications..."
	cp -R "$(EXPORT_PATH)/$(APP_NAME)" /Applications/

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf "$(BUILD_DIR)"
	xcodebuild -project "$(XCODE_WORKSPACE)" \
		-scheme "$(SCHEME)" \
		clean

# Run the app (debug build)
run: build
	@echo "Running $(PROJECT_NAME)..."
	open "$(DERIVED_DATA_PATH)/Build/Products/Debug/$(APP_NAME)"

# Show build information
info:
	@echo "Project: $(PROJECT_NAME)"
	@echo "Scheme: $(SCHEME)"
	@echo "Configuration: $(CONFIGURATION)"
	@echo "SDK: $(SDK)"
	@echo "Build Directory: $(BUILD_DIR)"

# Display help
help:
	@echo "Focus Detective Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build     - Build debug version"
	@echo "  release   - Build release version"
	@echo "  archive   - Create archive for distribution"
	@echo "  export    - Export app from archive (requires ExportOptions.plist)"
	@echo "  install   - Install app to /Applications"
	@echo "  run       - Build and run the app"
	@echo "  clean     - Remove build artifacts"
	@echo "  info      - Show build configuration"
	@echo "  help      - Show this help message"
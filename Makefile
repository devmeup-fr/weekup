# Makefile - WeekUp (Flutter)
# Usage: make help

SHELL := /bin/bash

FLUTTER ?= flutter
DART ?= dart

# --- Build number (Unix timestamp seconds) ---
# Android: must be <= 2100000000 (Google Play). Unix seconds stays under that until 2038.
# iOS: used as CFBundleVersion; numeric is accepted.
BUILD_NUMBER := $(shell date +%s)

# --- iOS (Xcode) settings ---
# IMPORTANT: iOS CFBundleShortVersionString (MARKETING_VERSION) must be numeric (e.g. 0.14.1).
# A suffix like "-dev" is NOT valid for the marketing version. Use display name / in-app label instead.
IOS_DIR ?= ios
IOS_WORKSPACE ?= $(IOS_DIR)/Runner.xcworkspace
# If you use Flutter flavors on iOS, you typically have Xcode schemes matching the flavor names.
IOS_SCHEME_DEV ?= Runner
IOS_SCHEME_PROD ?= Runner
IOS_CONFIGURATION ?= Release
IOS_ARCHIVE_DIR ?= build/ios/archive
IOS_EXPORT_DIR ?= build/ios/ipa_xcode
# You must provide an ExportOptions.plist compatible with your signing method.
# Typical path: ios/ExportOptions.plist
IOS_EXPORT_OPTIONS_PLIST ?= $(IOS_DIR)/ExportOptions.plist
# MARKETING_VERSION must stay numeric; derived from pubspec.yaml's version (before the "+build").
IOS_MARKETING_VERSION ?= $(shell sed -n 's/^version: *\([0-9.]*\).*/\1/p' pubspec.yaml)
# Optional: add "-dev" visually via app display name (Info.plist key injection at build time)
IOS_DISPLAY_NAME_DEV ?= WeekUp Dev
IOS_DISPLAY_NAME_PROD ?= WeekUp

.DEFAULT_GOAL := help

.PHONY: help icons \
        android-run android-bundle \
        ios-pod ios-run ios-ipa \
        ios-archive ios-export ios-dist \
        clean deps fmt analyze test check

help:
	@echo "WeekUp - Makefile"
	@echo ""
	@echo "Common:"
	@echo "  make icons               # Generate launcher icons"
	@echo "  make deps                # flutter pub get"
	@echo "  make fmt                 # dart format ."
	@echo "  make analyze             # flutter analyze"
	@echo "  make test                # flutter test"
	@echo "  make check               # deps + fmt + analyze + test"
	@echo ""
	@echo "Android:"
	@echo "  make android-run"
	@echo "  make android-bundle"
	@echo ""
	@echo "iOS (Flutter, macOS only):"
	@echo "  make ios-run"
	@echo "  make ios-ipa         # flutter build ipa (requires signing)"
	@echo ""
	@echo "iOS (Xcode archive/export, macOS only):"
	@echo "  make ios-dist        # xcodebuild archive + export (requires ExportOptions.plist)"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean"

# --- 1) Icons ---
icons:
	$(FLUTTER) pub run flutter_launcher_icons

# --- 4) Android ---
# No product flavors are configured in android/app/build.gradle for this project.

android-run:
	$(FLUTTER) run -t lib/main.dart

android-bundle:
	$(FLUTTER) build appbundle --release -t lib/main.dart --build-number=$(BUILD_NUMBER)

# --- 5) iOS (Flutter, macOS only) ---
.PHONY: ios-pod
ios-pod:
	cd $(IOS_DIR) && pod install

ios-run:
	$(FLUTTER) run -t lib/main.dart

ios-ipa:
	$(FLUTTER) build ipa --release -t lib/main.dart --build-number=$(BUILD_NUMBER)

# --- 6) iOS (Xcode archive/export) ---
# Produces:
#  - Archive: $(IOS_ARCHIVE_DIR)/WeekUp-<scheme>.xcarchive
#  - IPA:     $(IOS_EXPORT_DIR)/<scheme>/*.ipa
#
# Notes:
#  - MARKETING_VERSION must be numeric.
#  - If you want a visible suffix, inject CFBundleDisplayName via INFOPLIST_KEY_CFBundleDisplayName.

define ios_xcode_archive
	mkdir -p $(IOS_ARCHIVE_DIR)
	cd $(IOS_DIR) && xcodebuild \
		-workspace Runner.xcworkspace \
		-scheme $(1) \
		-configuration $(IOS_CONFIGURATION) \
		-archivePath ../$(IOS_ARCHIVE_DIR)/WeekUp-$(1).xcarchive \
		CURRENT_PROJECT_VERSION=$(BUILD_NUMBER) \
		MARKETING_VERSION=$(IOS_MARKETING_VERSION) \
		INFOPLIST_KEY_CFBundleDisplayName="$(2)" \
		archive
endef

define ios_xcode_export
	mkdir -p $(IOS_EXPORT_DIR)/$(1)
	cd $(IOS_DIR) && xcodebuild \
		-exportArchive \
		-archivePath ../$(IOS_ARCHIVE_DIR)/WeekUp-$(1).xcarchive \
		-exportPath ../$(IOS_EXPORT_DIR)/$(1) \
		-exportOptionsPlist $(notdir $(IOS_EXPORT_OPTIONS_PLIST))
endef

ios-archive: ios-pod
	$(call ios_xcode_archive,$(IOS_SCHEME_DEV),$(IOS_DISPLAY_NAME_DEV))

ios-export: ios-pod
	$(call ios_xcode_export,$(IOS_SCHEME_DEV))

ios-dist: ios-ipa ios-archive ios-export

# --- Clean ---
clean:
	$(FLUTTER) clean

# --- Flutter Standards ---
deps:
	$(FLUTTER) pub get

fmt:
	$(DART) format .

analyze:
	$(FLUTTER) analyze

test:
	$(FLUTTER) test

check: deps fmt analyze test

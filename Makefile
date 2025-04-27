# Makefile for installing project dependencies and kubectl plugins
# Installs AWS CLI, kubectl, git, and kubectl plugins

# Detect operating system
OS := $(shell uname -s)
SHELL := /bin/bash

# Plugin directory
PLUGIN_SRC_DIR := .
KUBE_PLUGIN_PATH := /usr/local/bin

.PHONY: all install-deps install-aws-cli install-kubectl install-git install help clean

all: install-deps

install-deps: install-aws-cli install-kubectl install-git install-jq
	@echo "All dependencies installed successfully!"

install-jq:
	@echo "Checking for jq..."
	@if command -v jq >/dev/null 2>&1; then \
		echo "jq is already installed."; \
		jq --version; \
	else \
		echo "Installing jq..."; \
		if [ "$(OS)" = "Linux" ]; then \
			sudo apt-get update -qq; \
			sudo apt-get install -y jq; \
		else \
			echo "Unsupported OS. Please install jq manually"; \
			exit 1; \
		fi; \
		jq --version; \
		echo "jq installed successfully!"; \
	fi

install-aws-cli:
	@echo "Checking for AWS CLI..."
	@if command -v aws >/dev/null 2>&1; then \
		echo "AWS CLI is already installed."; \
		aws --version; \
	else \
		echo "Installing AWS CLI..."; \
		if [ "$(OS)" = "Linux" ]; then \
			echo "Detected Linux OS"; \
			curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; \
			unzip -q awscliv2.zip; \
			sudo ./aws/install; \
			rm -rf aws awscliv2.zip; \
		else \
			echo "Unsupported OS. Please install AWS CLI manually: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"; \
			exit 1; \
		fi; \
		aws --version; \
		echo "AWS CLI installed successfully!"; \
	fi

install-kubectl:
	@echo "Checking for kubectl..."
	@if command -v kubectl >/dev/null 2>&1; then \
		echo "kubectl is already installed."; \
		kubectl version --client; \
	else \
		echo "Installing kubectl..."; \
		if [ "$(OS)" = "Linux" ]; then \
			curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
			chmod +x kubectl; \
			sudo mv kubectl /usr/local/bin/; \
		else \
			echo "Unsupported OS. Please install kubectl manually: https://kubernetes.io/docs/tasks/tools/"; \
			exit 1; \
		fi; \
		kubectl version --client; \
		echo "kubectl installed successfully!"; \
	fi

install-git:
	@echo "Checking for git..."
	@if command -v git >/dev/null 2>&1; then \
		echo "git is already installed."; \
		git --version; \
	else \
		echo "Installing git..."; \
		if [ "$(OS)" = "Linux" ]; then \
			sudo apt-get update -qq; \
			sudo apt-get install -y git; \
		else \
			echo "Unsupported OS. Please install git manually: https://git-scm.com/downloads"; \
			exit 1; \
		fi; \
		git --version; \
		echo "git installed successfully!"; \
	fi

install:
	@echo "Installing kubectl plugins..."
	@mkdir -p $(KUBE_PLUGIN_PATH)
	@for plugin in $(shell find . -maxdepth 1 -name "kubectl*"); do \
		plugin_name=$$(basename $$plugin); \
		echo "Installing plugin: $$plugin_name"; \
		mkdir -p $(KUBE_PLUGIN_PATH); \
		cp -r $$plugin $(KUBE_PLUGIN_PATH)/$$plugin_name; \
	done
	@echo "All kubectl plugins have been installed!"

clean:
	@echo "Cleaning up temporary files..."
	rm -f awscliv2.zip AWSCLIV2.pkg
	rm -rf aws

help:
	@echo "Available targets:"
	@echo "  all             - Install all dependencies and plugins (default)"
	@echo "  install-deps    - Install all dependencies"
	@echo "  install-aws-cli - Install AWS CLI only"
	@echo "  install-kubectl - Install kubectl only"
	@echo "  install-git     - Install git only"
	@echo "  install         - Install kubectl plugins"
	@echo "  clean           - Remove temporary files"
	@echo "  help            - Show this help message"

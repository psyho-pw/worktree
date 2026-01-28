.PHONY: help init worktree worktree-add-pr worktree-add-branch worktree-remove worktree-prune worktree-lock worktree-repair worktree-list

SHELL := /bin/zsh

# 기본 설정
BARE_DIR := .bare
GIT := git -C $(BARE_DIR)
GIT_WORKTREE := $(GIT) worktree

help: ## 사용 가능한 명령어 목록 출력
	@echo "\n📚 Git Worktree Boilerplate 명령어\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""

init: ## Bare repository 초기화 (e.g. make init REPO_URL=git@github.com:user/repo.git)
	@if [ -z "$(REPO_URL)" ]; then \
		echo "❌ Error: REPO_URL이 필요합니다."; \
		echo "사용법: make init REPO_URL=git@github.com:user/repo.git"; \
		exit 1; \
	fi
	@if [ -d "$(BARE_DIR)" ]; then \
		echo "⚠️  $(BARE_DIR) 디렉터리가 이미 존재합니다."; \
		read "REPLY?기존 디렉터리를 삭제하고 다시 초기화하시겠습니까? (y/N): "; \
		if [ "$$REPLY" != "y" ] && [ "$$REPLY" != "Y" ]; then \
			echo "취소되었습니다."; \
			exit 1; \
		fi; \
		rm -rf $(BARE_DIR); \
	fi
	@echo "🚀 Bare repository 초기화 중..."
	@git clone --bare $(REPO_URL) $(BARE_DIR)
	@echo "✅ Bare repository가 성공적으로 생성되었습니다."
	@echo "\n📌 다음 단계:"
	@echo "  1. make worktree-add-branch main  # main 브랜치 워크트리 생성"
	@echo "  2. make worktree-list             # 워크트리 목록 확인"
	@echo ""

worktree: ## git worktree 래퍼 (e.g. make worktree list, make worktree add ../test test, ...)
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		echo "먼저 'make init REPO_URL=<your-repo-url>'을 실행하세요."; \
		exit 1; \
	fi
	$(GIT_WORKTREE) $(filter-out $@,$(MAKECMDGOALS))

worktree-add-pr: ## PR 번호로 워크트리 생성 (e.g. make worktree-add-pr 2135)
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		exit 1; \
	fi
	$(eval PR_NUM := $(filter-out $@,$(MAKECMDGOALS)))
	@if [ -z "$(PR_NUM)" ]; then \
		echo "❌ Error: PR 번호가 필요합니다."; \
		echo "사용법: make worktree-add-pr 2135"; \
		exit 1; \
	fi
	$(eval REPO := $(shell $(GIT) config --get remote.origin.url | sed -E 's|.*[:/]([^/]+/[^/]+)\.git$$|\1|'))
	$(eval BRANCH_NAME := $(shell gh pr view $(PR_NUM) -R $(REPO) --json headRefName -q .headRefName))
	@echo "🔍 PR #$(PR_NUM) 정보 가져오는 중..."
	@echo "📦 브랜치: $(BRANCH_NAME)"
	$(GIT) fetch origin $(BRANCH_NAME):$(BRANCH_NAME)
	$(GIT_WORKTREE) add ../pr-$(PR_NUM) $(BRANCH_NAME)
	@echo "✅ 워크트리가 ../pr-$(PR_NUM)에 생성되었습니다."

worktree-add-branch: ## 브랜치 이름으로 워크트리 생성 (e.g. make worktree-add-branch feature/swc)
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		exit 1; \
	fi
	$(eval BRANCH_NAME := $(filter-out $@,$(MAKECMDGOALS)))
	@if [ -z "$(BRANCH_NAME)" ]; then \
		echo "❌ Error: 브랜치 이름이 필요합니다."; \
		echo "사용법: make worktree-add-branch main"; \
		exit 1; \
	fi
	$(eval DIR_NAME := $(shell echo $(BRANCH_NAME) | sed 's/\//-/g'))
	@if $(GIT) show-ref --verify --quiet refs/heads/$(BRANCH_NAME); then \
		echo "✅ 로컬 브랜치 $(BRANCH_NAME) 발견, 체크아웃 중..."; \
		$(GIT_WORKTREE) add ../$(DIR_NAME) $(BRANCH_NAME); \
	elif $(GIT) show-ref --verify --quiet refs/remotes/origin/$(BRANCH_NAME); then \
		echo "🌐 원격 브랜치 $(BRANCH_NAME) 발견, fetch 중..."; \
		$(GIT) fetch origin $(BRANCH_NAME):$(BRANCH_NAME); \
		$(GIT_WORKTREE) add ../$(DIR_NAME) $(BRANCH_NAME); \
	else \
		echo "🆕 새 브랜치 $(BRANCH_NAME) 생성 중..."; \
		$(GIT_WORKTREE) add ../$(DIR_NAME) -b $(BRANCH_NAME); \
	fi
	@echo "✅ 워크트리가 ../$(DIR_NAME)에 생성되었습니다."

worktree-remove: ## 워크트리 제거 (e.g. make worktree-remove pr-2135)
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		exit 1; \
	fi
	$(eval TARGET := $(filter-out $@,$(MAKECMDGOALS)))
	@if [ -z "$(TARGET)" ]; then \
		echo "❌ Error: 제거할 워크트리 이름이 필요합니다."; \
		echo "사용법: make worktree-remove pr-2135"; \
		exit 1; \
	fi
	@echo "🗑️  워크트리 제거 중: $(TARGET)"
	$(GIT_WORKTREE) remove --force ../$(TARGET)
	@echo "✅ 워크트리가 제거되었습니다."

worktree-prune: ## 삭제된 워크트리 정리
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		exit 1; \
	fi
	@echo "🧹 삭제된 워크트리 정리 중..."
	$(GIT_WORKTREE) prune
	@echo "✅ 정리 완료"

worktree-lock: ## 워크트리 잠금 (e.g. make worktree-lock main)
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		exit 1; \
	fi
	$(eval TARGET := $(filter-out $@,$(MAKECMDGOALS)))
	@if [ -z "$(TARGET)" ]; then \
		echo "❌ Error: 잠글 워크트리 이름이 필요합니다."; \
		exit 1; \
	fi
	$(GIT_WORKTREE) lock ../$(TARGET)
	@echo "🔒 워크트리가 잠겼습니다: $(TARGET)"

worktree-repair: ## 워크트리 복구
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		exit 1; \
	fi
	@echo "🔧 워크트리 복구 중..."
	$(GIT_WORKTREE) repair
	@echo "✅ 복구 완료"

worktree-list: ## 워크트리 목록 출력
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		echo "먼저 'make init REPO_URL=<your-repo-url>'을 실행하세요."; \
		exit 1; \
	fi
	@echo "📋 워크트리 목록:\n"
	@$(GIT_WORKTREE) list
	@echo ""

# Make가 인자를 명령어로 해석하지 않도록 처리
%:
	@:

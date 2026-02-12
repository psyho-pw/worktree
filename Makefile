.PHONY: help init clean check-bare worktree worktree-add-pr worktree-add-branch worktree-remove worktree-prune worktree-lock worktree-repair worktree-list

SHELL := /bin/zsh
BARE_DIR := .bare
GIT := git -C $(BARE_DIR)
GIT_WORKTREE := $(GIT) worktree

help: ## 사용 가능한 명령어 목록 출력
	@echo "\n📚 Git Worktree Commands\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""

init: ## Bare repository 초기화 (e.g. make init git@github.com:user/repo.git)
	$(eval REPO_URL := $(filter-out $@,$(MAKECMDGOALS)))
	@test -n "$(REPO_URL)" || (echo "REPO_URL is required. Example: make init git@..."; exit 1)
	@test ! -d "$(BARE_DIR)" || (echo "$(BARE_DIR) already exists. Delete it and try again."; exit 1)
	@git clone --bare $(REPO_URL) $(BARE_DIR)
	@$(GIT) config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

check-bare:
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR) does not exist."; \
		echo "Run 'make init REPO_URL=<your-repo-url>' first."; \
		exit 1; \
	fi

worktree: check-bare ## git worktree 래퍼 (e.g. make worktree list, make worktree add ../test test, ...)
	$(GIT_WORKTREE) $(filter-out $@,$(MAKECMDGOALS))

worktree-add-pr: check-bare ## PR 번호로 워크트리 생성 (e.g. make worktree-add-pr 2135)
	$(eval PR_NUM := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval REPO := $(shell $(GIT) config --get remote.origin.url | sed -E 's|.*[:/]([^/]+/[^/]+)\.git$$|\1|'))
	$(eval BRANCH_NAME := $(shell gh pr view $(PR_NUM) -R $(REPO) --json headRefName -q .headRefName))
	$(GIT) fetch origin $(BRANCH_NAME):$(BRANCH_NAME)
	$(GIT_WORKTREE) add ../pr-$(PR_NUM) $(BRANCH_NAME)

worktree-add-branch: check-bare ## 브랜치 이름으로 워크트리 생성 (e.g. make worktree-add-branch feature/swc)
	$(eval BRANCH_NAME := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval DIR_NAME := $(shell echo $(BRANCH_NAME) | sed 's/\//-/g'))
	@if $(GIT) show-ref --verify --quiet refs/heads/$(BRANCH_NAME); then \
		echo "Branch $(BRANCH_NAME) exists, checking out..."; \
		$(GIT_WORKTREE) add ../$(DIR_NAME) $(BRANCH_NAME); \
	elif $(GIT) show-ref --verify --quiet refs/remotes/origin/$(BRANCH_NAME); then \
		echo "Branch $(BRANCH_NAME) exists on remote, fetching..."; \
		$(GIT) fetch origin $(BRANCH_NAME):$(BRANCH_NAME); \
		$(GIT_WORKTREE) add ../$(DIR_NAME) $(BRANCH_NAME); \
	else \
		echo "Branch $(BRANCH_NAME) does not exist, creating new branch..."; \
		$(GIT_WORKTREE) add ../$(DIR_NAME) -b $(BRANCH_NAME); \
	fi

worktree-remove: check-bare ## 워크트리 제거 (e.g. make worktree-remove pr-2135)
	$(GIT_WORKTREE) remove --force $(filter-out $@,$(MAKECMDGOALS))

worktree-prune: check-bare ## 삭제된 워크트리 정리
	$(GIT_WORKTREE) prune

worktree-lock: check-bare ## 워크트리 잠금 (e.g. make worktree-lock ../test)
	$(GIT_WORKTREE) lock $(filter-out $@,$(MAKECMDGOALS))

worktree-unlock: ## 워크트리 잠금 해제
	$(GIT_WORKTREE) unlock $(filter-out $@,$(MAKECMDGOALS))

worktree-repair: check-bare ## 워크트리 복구
	$(GIT_WORKTREE) repair

worktree-list: check-bare ## 워크트리 목록 출력
	$(GIT_WORKTREE) list

clean: check-bare ## Bare repository 및 모든 워크트리 제거
	@echo "⚠️  Warning: The following items will be deleted:"
	@echo ""
	@$(GIT_WORKTREE) list
	@echo ""
	@bash -c 'read -p "Are you sure you want to delete? (y/n): " CONFIRM; \
	if [ "$$CONFIRM" != "y" ]; then \
		echo "Canceled."; \
		exit 1; \
	fi'
	@echo "🗑️  Removing worktree directories..."
	@bash -c '$(GIT_WORKTREE) list --porcelain | grep "^worktree" | cut -d" " -f2 | while read dir; do \
		if [ "$$dir" != "$(shell pwd)/$(BARE_DIR)" ]; then \
			echo "  - Removing: $$dir"; \
			rm -rf "$$dir"; \
		fi; \
	done'
	@echo "🗑️  Removing bare repository..."
	@rm -rf $(BARE_DIR)
	@echo "✅ Done"

# Prevent Make from interpreting arguments as commands
%:
	@:

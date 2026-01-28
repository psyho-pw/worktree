.PHONY: help init worktree worktree-add-pr worktree-add-branch worktree-remove worktree-prune worktree-lock worktree-repair worktree-list

SHELL := /bin/zsh
BARE_DIR := .bare
GIT := git -C $(BARE_DIR)
GIT_WORKTREE := $(GIT) worktree

help: ## 사용 가능한 명령어 목록 출력
	@echo "\n📚 Git Worktree Boilerplate 명령어\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""

init: ## Bare repository 초기화 (e.g. make init REPO_URL=git@github.com:user/repo.git)
	@test -n "$(REPO_URL)" || (echo "REPO_URL is required. Example: make init REPO_URL=git@..."; exit 1)
	@test ! -d "$(BARE_DIR)" || (echo "$(BARE_DIR) already exists. Delete it and try again."; exit 1)
	@git clone --bare $(REPO_URL) $(BARE_DIR)

worktree: ## git worktree 래퍼 (e.g. make worktree list, make worktree add ../test test, ...)
	@if [ ! -d "$(BARE_DIR)" ]; then \
		echo "❌ Error: $(BARE_DIR)가 존재하지 않습니다."; \
		echo "먼저 'make init REPO_URL=<your-repo-url>'을 실행하세요."; \
		exit 1; \
	fi
	$(GIT_WORKTREE) $(filter-out $@,$(MAKECMDGOALS))

worktree-add-pr: ## PR 번호로 워크트리 생성 (e.g. make worktree-add-pr 2135)
	$(eval PR_NUM := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval REPO := $(shell $(GIT) config --get remote.origin.url | sed -E 's|.*[:/]([^/]+/[^/]+)\.git$$|\1|'))
	$(eval BRANCH_NAME := $(shell gh pr view $(PR_NUM) -R $(REPO) --json headRefName -q .headRefName))
	$(GIT) fetch origin $(BRANCH_NAME):$(BRANCH_NAME)
	$(GIT_WORKTREE) add ../pr-$(PR_NUM) $(BRANCH_NAME)

worktree-add-branch: ## 브랜치 이름으로 워크트리 생성 (e.g. make worktree-add-branch feature/swc)
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

worktree-remove: ## 워크트리 제거 (e.g. make worktree-remove pr-2135)
	$(GIT_WORKTREE) remove --force $(filter-out $@,$(MAKECMDGOALS))

worktree-prune: ## 삭제된 워크트리 정리
	$(GIT_WORKTREE) prune

worktree-lock: ## 워크트리 잠금 (e.g. make worktree-lock ../test)
	$(GIT_WORKTREE) lock $(filter-out $@,$(MAKECMDGOALS))

worktree-repair: ## 워크트리 복구
	$(GIT_WORKTREE) repair

worktree-list: ## 워크트리 목록 출력
	$(GIT_WORKTREE) list

# Prevent Make from interpreting arguments as commands
%:
	@:

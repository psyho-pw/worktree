# Git Worktree Boilerplate

Git worktree를 사용하여 하나의 저장소에서 여러 브랜치를 동시에 작업할 수 있는 boilerplate입니다.

## 🎯 개요

이 boilerplate는 bare repository를 기반으로 한 git worktree 환경을 쉽게 구성할 수 있도록 도와줍니다.

### 장점

- ✅ 여러 브랜치를 동시에 작업 가능
- ✅ 브랜치 전환 없이 즉시 다른 브랜치 확인 가능
- ✅ 각 브랜치가 독립적인 디렉터리로 존재
- ✅ node_modules 등을 브랜치마다 독립적으로 관리
- ✅ PR 리뷰를 위한 별도 워크트리 생성 가능

## 📦 사전 요구사항

- Git 2.5 이상
- zsh 쉘
- GitHub CLI (`gh`) - PR 기능 사용 시 필요

```bash
# GitHub CLI 설치 (macOS)
brew install gh

# GitHub CLI 로그인
gh auth login
```

## 🚀 빠른 시작

### 1. Boilerplate 클론

```bash
git clone <this-boilerplate-repo-url> my-project
cd my-project
```

### 2. 실제 프로젝트 저장소 초기화

```bash
make init REPO_URL=git@github.com:your-org/your-repo.git
```

### 3. 메인 브랜치 워크트리 생성

```bash
make worktree-add-branch main
```

### 4. 프로젝트 디렉터리 구조

```
my-project/
├── .bare/              # Bare repository (git 메타데이터)
├── Makefile            # 워크트리 관리 명령어
├── README.md           # 이 파일
└── .gitignore          # Bare repo와 워크트리 제외

상위 디렉터리에 워크트리 생성:
../
├── my-project/         # 이 디렉터리
├── main/               # main 브랜치 워크트리
├── feature-auth/       # feature/auth 브랜치 워크트리
└── pr-2135/           # PR #2135 워크트리
```

## 📚 사용법

### 도움말 보기

```bash
make help
```

### Bare Repository 초기화

```bash
# HTTPS
make init REPO_URL=https://github.com/user/repo.git

# SSH
make init REPO_URL=git@github.com:user/repo.git
```

### 브랜치로 워크트리 생성

```bash
# 기존 브랜치 체크아웃
make worktree-add-branch main
make worktree-add-branch develop

# 새 브랜치 생성
make worktree-add-branch feature/new-feature

# 슬래시(/)는 자동으로 하이픈(-)으로 변환됨
# feature/auth → ../feature-auth/
```

### PR로 워크트리 생성

```bash
# PR #2135의 브랜치로 워크트리 생성
make worktree-add-pr 2135

# 결과: ../pr-2135/ 디렉터리 생성
```

### 워크트리 목록 확인

```bash
make worktree-list
```

### 워크트리 제거

```bash
# 워크트리 제거 (디렉터리도 삭제됨)
make worktree-remove main
make worktree-remove pr-2135
```

### 삭제된 워크트리 정리

```bash
# 수동으로 삭제된 워크트리 정보 정리
make worktree-prune
```

### 워크트리 복구

```bash
# 손상된 워크트리 복구
make worktree-repair
```

### 워크트리 잠금

```bash
# 실수로 삭제되지 않도록 워크트리 보호
make worktree-lock main
```

### 고급 사용 (git worktree 직접 실행)

```bash
# git worktree 명령어 직접 실행
make worktree add ../custom-dir custom-branch
make worktree move ../old-dir ../new-dir
```

## 💡 워크플로우 예시

### 일반적인 개발 워크플로우

```bash
# 1. 초기 설정
make init REPO_URL=git@github.com:company/product.git
make worktree-add-branch main

# 2. 새 기능 개발
make worktree-add-branch feature/user-auth
cd ../feature-user-auth
# ... 작업 ...
git add .
git commit -m "feat: 사용자 인증 구현"
git push origin feature/user-auth

# 3. 다른 브랜치 확인하면서 작업 계속
cd ../main
# main 브랜치에서 확인
cd ../feature-user-auth
# 다시 feature 브랜치로 돌아와서 작업

# 4. PR 리뷰
make worktree-add-pr 2135
cd ../pr-2135
# ... 리뷰 ...
cd ../my-project
make worktree-remove pr-2135
```

### 긴급 핫픽스 워크플로우

```bash
# 1. 현재 feature 브랜치에서 작업 중
cd ../feature-user-auth
# ... 작업 중 ...

# 2. 긴급 버그 발견! 브랜치 전환 없이 핫픽스
cd ../my-project
make worktree-add-branch hotfix/critical-bug
cd ../hotfix-critical-bug
# ... 버그 수정 ...
git add .
git commit -m "fix: 크리티컬 버그 수정"
git push origin hotfix/critical-bug

# 3. 다시 원래 작업으로
cd ../feature-user-auth
# node_modules나 빌드 상태가 그대로 유지됨!
```

## 🔧 고급 설정

### Makefile 변수 커스터마이징

`Makefile`에서 다음 변수를 수정할 수 있습니다:

```makefile
BARE_DIR := .bare          # Bare repository 디렉터리 이름
SHELL := /bin/zsh          # 사용할 쉘
```

### .gitignore 커스터마이징

프로젝트에 맞게 `.gitignore`를 수정하세요:

```gitignore
# 공통 무시 패턴
node_modules/
.env
*.log

# 프로젝트별 패턴 추가
dist/
build/
```

## 📝 Best Practices

1. **메인 브랜치는 항상 유지**: main/develop 워크트리는 삭제하지 말고 유지하세요.
2. **PR 워크트리는 리뷰 후 삭제**: PR 리뷰가 끝나면 `make worktree-remove`로 정리하세요.
3. **정기적인 prune**: 수동으로 삭제한 디렉터리가 있다면 `make worktree-prune`을 실행하세요.
4. **워크트리별 설정**: 각 워크트리에서 독립적인 `.env` 파일 등을 관리할 수 있습니다.

## 🐛 문제 해결

### "$(BARE_DIR)가 존재하지 않습니다" 오류

```bash
make init REPO_URL=<your-repo-url>
```

### 워크트리가 손상됨

```bash
make worktree-repair
```

### 삭제한 디렉터리가 여전히 목록에 표시됨

```bash
make worktree-prune
```

### GitHub CLI 인증 오류

```bash
gh auth login
gh auth status
```

## 🔗 참고 자료

- [Git Worktree 공식 문서](https://git-scm.com/docs/git-worktree)
- [GitHub CLI 문서](https://cli.github.com/manual/)

## 📄 라이선스

이 boilerplate는 자유롭게 사용하실 수 있습니다.

## 🤝 기여

개선 사항이나 버그 리포트는 언제든 환영합니다!

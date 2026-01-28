#!/bin/bash

set -e

echo "🚀 Git Worktree 최초 설정 스크립트"
echo ""

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Repository URL 입력받기
if [ -z "$1" ]; then
    echo -e "${YELLOW}원격 저장소 URL을 입력하세요:${NC}"
    read -p "REPO_URL: " REPO_URL
else
    REPO_URL=$1
fi

if [ -z "$REPO_URL" ]; then
    echo -e "${RED}❌ Error: Repository URL이 필요합니다.${NC}"
    exit 1
fi

# Main/Master 브랜치 선택
echo ""
echo -e "${YELLOW}메인 브랜치 이름을 입력하세요 (기본값: main):${NC}"
read -p "Branch name: " MAIN_BRANCH
MAIN_BRANCH=${MAIN_BRANCH:-main}

echo ""
echo "📋 설정 요약:"
echo "  Repository: $REPO_URL"
echo "  Main Branch: $MAIN_BRANCH"
echo ""

read -p "계속하시겠습니까? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "취소되었습니다."
    exit 0
fi

echo ""
echo "🔧 1/3: Bare repository 초기화 중..."
make init REPO_URL="$REPO_URL"

echo ""
echo "🔧 2/3: 메인 브랜치 워크트리 생성 중..."
make worktree-add-branch "$MAIN_BRANCH"

echo ""
echo "🔧 3/3: 워크트리 목록 확인..."
make worktree-list

echo ""
echo -e "${GREEN}✅ 설정 완료!${NC}"
echo ""
echo "📁 워크트리 디렉터리: $MAIN_BRANCH"
echo ""
echo "🎯 다음 단계:"
echo "  cd $MAIN_BRANCH"
echo "  # 프로젝트 작업 시작"
echo ""
echo "💡 추가 명령어:"
echo "  make help                          # 명령어 목록 확인"
echo "  make worktree-add-branch develop   # develop 브랜치 추가"
echo "  make worktree-add-pr 123           # PR 워크트리 추가"
echo ""

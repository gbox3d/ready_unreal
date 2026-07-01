# _forAI Guide

## 한 줄 요약

이 디렉터리는 `ready_unreal` 작업을 이어받을 때 필요한 AI 작업 문맥을 정리해 두는 곳이다.

## 읽는 순서

1. `README.md`
2. `inventory.md`
3. `memo.md`
4. `dev_log.md`
5. `plan.md`

## 문서 역할

- `inventory.md`: 저장소에 실제로 있는 구조, 엔트리포인트, 빌드/검증 명령을 기록한다.
- `plan.md`: 앞으로 진행할 개발 계획과 우선순위만 기록한다.
- `memo.md`: 프로토콜, 핀맵, 기본값, 디버깅 교훈 같은 참고 메모를 모은다.
- `dev_log.md`: 날짜별 작업 이력과 `_forAI` 정리 내역을 남긴다.

## 현재 스냅샷

- 저장소 경로: `C:\works\ue_prjs\ready_unreal`
- 성격: UE 5.8 + Unreal MCP + Claude Code 셋업 **교재/가이드 레포** (정적 문서)
- 대상 플랫폼: Windows 11 / PowerShell · UE 5.8(Experimental MCP) · Claude Code(CLI·VSCode 확장)
- MCP 엔드포인트: `http://127.0.0.1:8000/mcp` (HTTP 전용, loopback)
- 메인 엔트리포인트: 사람=`readme.md`(에디터 셋업) / AI=`_forAI/memo.md`(클라이언트 등록·운영)

## 유지 규칙

- 계획이 아닌 참고 정보는 `plan.md`가 아니라 `memo.md`에 둔다.
- 저장소 구조나 실행 명령이 바뀌면 `inventory.md`를 먼저 갱신한다.
- 작업 이력은 날짜를 붙여 `dev_log.md`에만 남긴다.
- 새 작업을 시작할 때는 `inventory.md`와 `memo.md`를 먼저 읽고, 실제 할 일은 `plan.md`에서 확인한다.
- 사용자 동의 없이 git commit을 하지 않는다.
- 사용자 동의 없이 `_forAI/` 문서를 수정하지 않는다.

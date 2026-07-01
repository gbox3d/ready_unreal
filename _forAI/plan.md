# Plan

## Current goal

- UE 5.8 Unreal MCP를 Claude Code에서 안정적으로 쓰는 셋업/운영 지식을 **교재 수준으로 정리**하고
  최신 상태로 유지한다. (에디터 측 = `readme.md`, 클라이언트 측 = `_forAI/memo.md`)

## Near-term work

- `describe_toolset`로 자주 쓰는 toolset(예: `SceneTools`, `ActorTools`, `MaterialInstanceTools`,
  `BlueprintTools`)의 tool·입력 스키마를 뽑아 교재 부록으로 정리.
- 실제 연결 테스트 시나리오(PointLight 스폰·색온도 지정 등)를 캡처와 함께 본문에 추가.
- `mcp_setup.html` / `index.html`에 클라이언트 측 스코프(local/project/user) 설명 반영
  (현재는 `_forAI/memo.md`에만 정리됨).

## Structure decisions

- 역할 분담: `readme.md`=에디터 준비 절차, `_forAI/memo.md`=클라이언트 등록/운영. 중복 금지.
- 개인 작업 PC 기준 **user(전역) 스코프 단일화**를 표준으로 삼는다.

## Risks

- UE 5.8 MCP/Toolset은 **Experimental** → 버전 업 시 toolset 이름·콘솔 명령·동작이 바뀔 수 있음.
- 엔드포인트가 무인증 loopback → 문서에 인증/보안 관련 주의는 별도로 명시할 필요.
- 문서가 특정 버전(UE 5.8) 스냅샷이므로, 엔진 업데이트 시 `dev_log`에 차이를 남겨야 함.

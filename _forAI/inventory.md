# Inventory

## Repository

- Name: `ready_unreal`
- Path: `C:\works\ue_prjs\ready_unreal`
- Summary: **UE 5.8 + Unreal MCP + Claude Code 협업 셋업을 다루는 교재/가이드 레포.**
  실행 코드가 아니라 문서·스크린샷 중심의 정적 자료다.

## Top-level structure

- `readme.md` — 핵심 본문. "UE 5.8 + MCP + Claude Code 협업 셋업 가이드" (에디터 측 절차)
- `mcp_setup.html` — 셋업 가이드의 HTML 버전(브라우저 열람용)
- `index.html` — 진입 페이지
- `screen_shot/` — 가이드용 캡처
  - `setup_model_context_protocol.png` (Editor Preferences > MCP)
  - `mcp_plugin_install.png` (Unreal MCP 플러그인 활성화)
  - `toolsets_install.png` (AllToolsets/Toolset Registry 활성화)
  - `cmd.png`, `cmd_log.png` (콘솔 명령 / 로그)
- `_forAI/` — AI 작업 문맥 문서 세트(본 디렉터리)
- `.gitignore`, `.git/`

## Entrypoints and key modules

- 사람 대상 진입점: `index.html` → `mcp_setup.html` / `readme.md`
- AI 대상 진입점: `_forAI/README.md`(읽는 순서) → `memo.md`(클라이언트 등록/운영)
- 실제 연결 대상(런타임): UE 5.8 에디터 내 MCP 서버 `http://127.0.0.1:8000/mcp`

## Build and validation commands

- **빌드 없음** (정적 문서 레포). HTML은 브라우저로 직접 연다.
- MCP 연결 검증:
  ```powershell
  Test-NetConnection -ComputerName 127.0.0.1 -Port 8000 -InformationLevel Quiet  # 서버 생존
  claude mcp list            # 등록/연결 상태
  claude mcp get unreal-mcp  # 스코프 확인
  ```
  Claude 세션 내부에서는 `/mcp`로 확인.

## Tests

- 자동화 테스트 없음(문서 레포). 동작 검증 = 위 MCP 연결 확인 + `list_toolsets` 응답.

## Notes

- 가이드 본문(`readme.md`)은 **에디터 측 준비**에 집중. **클라이언트(Claude Code) 측
  등록·스코프·CLI·운영**은 `_forAI/memo.md`에 보강되어 있다(짝 문서).
- 동일 MCP를 쓰는 형제 프로젝트: `C:\works\ue_prjs\MyProject`(UE 5.8 C++ 프로젝트).

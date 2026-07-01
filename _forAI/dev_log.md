# Dev Log

## Entries

### 2026-06-26 — Claude Code 클라이언트 측 MCP 등록 정리 + `_forAI` 내용 작성

- **전역(user) 스코프로 `unreal-mcp` 통일**
  - `claude mcp add unreal-mcp --scope user --transport http http://127.0.0.1:8000/mcp`
  - 검증: `claude mcp get unreal-mcp` → `Scope: User config (available in all your projects)`, `✓ Connected`
- **잘못된 local 등록 제거**: 비언리얼 프로젝트 `C:\works\baro_calory`에 박혀 있던
  local 스코프 `unreal-mcp` 삭제 (`claude mcp remove unreal-mcp --scope local`)
- **중복 제거**: `C:\works\ue_prjs\MyProject\.mcp.json` 삭제(개인 작업 PC라 전역 한 곳으로 통일).
  `ue_prjs` 하위에 다른 `.mcp.json` 없음 확인.
- **서버 생존 확인**: `127.0.0.1:8000` LISTENING, `list_toolsets` 정상 응답
  (씬/액터·에셋·블루프린트·머티리얼/Niagara/PCG·데이터·Sequencer·GAS·UMG/Slate·물리·테스트 등 풀세트).
- **`_forAI` 내용 작성** (스캐폴드 TODO → 실제 내용):
  - `memo.md`: MCP 등록 스코프(local/project/user)·설정파일 구분·claude.ai 커넥터 vs 로컬 MCP·
    CLI 레퍼런스·세션 1회 로드/재시작·toolset 게이트웨이 구조 및 카테고리 표·반복 금지
  - `inventory.md`: 레포 구조(문서/스크린샷)·진입점·검증 명령
  - `plan.md`, `README.md`(현재 스냅샷) 채움
- 메모: `readme.md`(에디터 측 셋업)와 `memo.md`(클라이언트 측 등록/운영)는 짝 문서로 역할 분담.
- **추가**: `memo.md`에 "전역(user) 등록 — 한방 레시피 & 지시문" 섹션 보강
  (복붙 CLI 두 줄 + 스코프 치트시트 + AI에 던지는 한 문장 지시문 + 어렵게 돌아간 이유 회고).
  핵심 통찰: VSCode 확장도 CLI와 같은 `~/.claude.json`을 읽으므로 `--scope user` 한 번이면 전역 적용.
- **교재 본문 반영**: `readme.md` 8장↔9장 사이에 **"부록 A. 클라이언트 측 등록 심화 —
  스코프와 전역(user) 단일화"** 추가(A-1 스코프 3종 ~ A-8 함정표). 학생용 본문이므로
  `_forAI/memo.md`(AI용)와 짝을 이루도록 동일 핵심을 교재 톤으로 정리.
  ※ `mcp_setup.html`/`index.html`에는 아직 미반영(요청 시 동기화).
- git commit은 하지 않음(파일 보강까지만).

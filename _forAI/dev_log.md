# Dev Log

## 목차

- [Entries](#entries)

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

### 2026-07-01 — 새 프로젝트 MCP 자동 셋업 스크립트 추가 + 문서화

- **신규**: `tools/Enable-UnrealMcp.ps1` — 프로젝트별 반복 작업(2·3장)을 명령 한 줄로 자동화.
  - `.uproject` Plugins 배열에 `ModelContextProtocol` + `AllToolsets` 멱등 주입(기존 플러그인/필드 보존, 타임스탬프 백업).
  - `Config/DefaultEditorPerProjectUserSettings.ini` 에 자동시작 기록:
    `[/Script/ModelContextProtocolEngine.ModelContextProtocolSettings]` → `bAutoStartServer=True` / `ServerPortNumber` / `ServerUrlPath=/mcp`.
  - 옵션: `-DryRun`(미리보기), `-Port`, `-NoAutoStart`. 폴더/`.uproject` 경로 모두 허용.
  - 설정 키 출처: 엔진 `ModelContextProtocolEngine/…/ModelContextProtocolSettings.h`(config=EditorPerProjectUserSettings).
    보너스: 실행 인자 `-ModelContextProtocolStartServer` 로도 서버 즉시 기동 가능.
- **검증**: 합성 `.uproject`(플러그인 有)로 실행 → 두 플러그인 추가·기존 보존·유효 JSON, ini 생성, 2회차 멱등(전부 건너뜀) 확인.
  baro_world 5.8 대상 `-DryRun` → 이미 활성이라 플러그인 건너뜀 + 자동시작만 기록 예정으로 정상.
- **문서**: `readme.md` 에 **부록 B**(스크립트 사용법 B-1~B-4) 추가. 핵심 재확인 — 클라이언트 등록은 전역 1회(부록 A),
  에디터 측(플러그인+자동시작)만 프로젝트별. 엔진 차원 기본활성은 Runtime 모듈이 배포 빌드에 딸려가 비권장.
  ※ `mcp_setup.html`/`index.html`·`inventory.md` 에는 아직 미반영(요청 시 동기화).

### 2026-07-02 — 연결확인 스크린샷 + Claude Code 직접 연결 프롬프트 + 문서 정리

- **`screen_shot/unreal_mcp_connected.png` 반영**: `readme.md` 5장에 **"연결 확인 (`/mcp`)"**
  절 신설, 캡처 삽입. 캡처 해설(User 스코프 그룹 표시 / claude.ai 커넥터와의 구분 / `failed` 시
  에디터 기동 후 리커넥트)까지 본문화. 부록 A-4와 상호참조 연결.
- **5장 "방법 C — Claude Code에게 프롬프트로 맡기기" 신설**: 복붙 프롬프트 3종 정리 —
  ① 전역(user) 등록+검증, ② 연결 실패 진단(포트 생존→스코프→에디터 기동 순 점검),
  ③ 부록 B 스크립트로 새 프로젝트 에디터 측 셋업 위임. (①은 `memo.md` C절 지시문과 동일 원본)
- **전 문서 목차(TOC) 추가**: `readme.md` + `_forAI/` 5종 모두 제목 아래 `## 목차` 섹션 배치
  (전역 문서 규칙). `README.md` 유지 규칙에도 명문화.
- **`inventory.md` 현행화**: `tools/Enable-UnrealMcp.ps1`, `unreal_mcp_connected.png`,
  readme 부록 A/B·방법 C 구조 반영 (2026-07-01 미반영분 해소).
- ※ `mcp_setup.html` / `index.html` 은 여전히 미동기화(요청 시 반영).
- git commit 수행(사용자 요청).

# Memo

> 이 메모는 **클라이언트(Claude Code) 측에서 Unreal MCP를 등록·운영**하는 데 필요한
> 참고 정보를 모은다. **에디터 측 셋업 절차**(플러그인 활성화, 서버 자동시작,
> `GenerateClientConfig`)는 저장소 루트 `readme.md`에 정리되어 있으므로 중복하지 않는다.
> 두 문서는 짝이다: `readme.md`(에디터 준비) → 이 메모(클라이언트 등록/운영).

## 제품 기준선

- 엔진: **UE 5.8** 내장 *Experimental* Unreal MCP 플러그인 + Toolset Registry(AllToolsets)
- 플랫폼: Windows 11 / PowerShell
- 클라이언트: Claude Code (CLI + VSCode 확장 — 둘 다 같은 설정 파일을 읽는다)
- 전송: **HTTP 전용** (stdio·WebSocket 미지원)

## 기본 설정값

- 엔드포인트: `http://127.0.0.1:8000/mcp` (loopback 전용, 인증 없음)
- 기본 포트 `8000`, URL 경로 `/mcp`
- **MCP 서버는 에디터 프로세스 안에서 돈다** → 에디터가 켜져 있어야 연결된다.
- 포트가 살아있는지 빠른 확인:
  ```powershell
  Test-NetConnection -ComputerName 127.0.0.1 -Port 8000 -InformationLevel Quiet
  ```

## MCP 등록 스코프 (핵심 개념)

Claude Code는 **3개 스코프**에서 MCP 서버를 읽는다. 같은 이름이 여러 스코프에 있으면
**우선순위가 높은 것 하나만** 활성화된다.

| 스코프 | 저장 위치 (Windows) | 적용 범위 | 우선순위 | 공유 |
|--------|---------------------|-----------|:--------:|:----:|
| **local** | `~/.claude.json` 의 해당 프로젝트 항목 | 그 프로젝트(폴더)만 | 1 (최상) | ✗ |
| **project** | 프로젝트 루트의 `.mcp.json` | 그 프로젝트만 | 2 | ✓ (git) |
| **user** | `~/.claude.json` 최상위 `mcpServers` | **모든 프로젝트** | 3 | ✗ |

- Windows의 `~` = `C:\Users\<사용자>` (= `C:\Users\gbox3`). `CLAUDE_CONFIG_DIR` 설정 시 그 경로.
- **개인 작업 PC라면 `user`(전역) 한 곳으로 통일**하는 게 관리가 깔끔하다.
- 팀과 공유하려면 `project`(`.mcp.json`)를 git에 올린다.

### 설정 파일 구분 (헷갈리기 쉬움)

| 파일 | 무엇을 담나 |
|------|-------------|
| `~/.claude.json` | **MCP 서버 정의** (local + user 스코프), 프로젝트별 상태 |
| `<프로젝트>/.mcp.json` | **MCP 서버 정의** (project 스코프) |
| `~/.claude/settings.json`, `.claude/settings.local.json` | **권한(permissions)·env·hooks 전용 — MCP 서버 정의 아님** |
| VSCode 자체 `settings.json` | VSCode 에디터 설정일 뿐, Claude Code MCP와 무관 |

> ⚠️ "Gmail처럼 settings.json에 넣으면 되지 않나?"는 오해다. 로컬 MCP는 `settings.json`이
> 아니라 `~/.claude.json`(또는 `.mcp.json`)에 들어간다.

### claude.ai 커넥터 vs 로컬 MCP (완전히 다름)

- **claude.ai 커넥터** (Gmail / Google Drive / Hugging Face): claude.ai가 호스팅하는 **원격**
  통합. 설정 파일 어디에도 없고 **claude.ai 계정 로그인으로 자동 따라온다**. 우선순위 최하위.
- **로컬 MCP** (`unreal-mcp` 등): 내 머신에서 도는 서버. `~/.claude.json` 또는 `.mcp.json`에
  **명시적으로 등록**해야 한다. ← 우리가 다루는 대상.

## CLI 레퍼런스 (`claude mcp ...`)

```powershell
# 전역(user) 등록 — 모든 프로젝트에서 사용
claude mcp add unreal-mcp --scope user --transport http http://127.0.0.1:8000/mcp

# 프로젝트(project) 등록 — .mcp.json 에 기록, 팀 공유
claude mcp add unreal-mcp --scope project --transport http http://127.0.0.1:8000/mcp

# 스코프 지정 제거 (local / project / user)
claude mcp remove unreal-mcp --scope local

# 목록 / 상세(스코프 포함) 확인
claude mcp list
claude mcp get unreal-mcp
```

- `--scope`(별칭 `-s`) 미지정 시 기본은 **local**.
- `claude.exe` 기본 경로: `C:\Users\gbox3\.local\bin\claude.exe`
- **CLI로 수정하는 것을 권장**한다. `~/.claude.json`은 Claude Code가 실행 중에 관리하는
  상태 파일이라, 세션 도중 손으로 편집하면 종료 시 덮어쓰여 변경이 유실될 수 있다.

## 전역(user) 등록 — 한방 레시피 & 지시문 (재사용)

> 단계별로 헤맬 필요 없다. **핵심은 단 하나: `--scope user` + `--transport http`로 CLI 한 줄.**
> VSCode 확장도 CLI와 **같은 `~/.claude.json`을 읽으므로**, CLI에서 user 스코프로 한 번
> 등록하면 VSCode 확장에서도 전역으로 적용된다(확장 쪽 설정을 따로 만질 필요 없음).

### A. 한방 명령어 (복붙용)

```powershell
# 전역(user) 등록 + 즉시 검증 — 이 두 줄이면 끝
claude mcp add unreal-mcp --scope user --transport http http://127.0.0.1:8000/mcp
claude mcp list
```

→ 그다음 **VSCode에서 Claude 세션만 새로 시작**하면 `/mcp`에 `unreal-mcp ✓ connected`.

### B. 스코프별 치트시트

```powershell
claude mcp add <name> -s user    -t http <url>   # 전역(모든 프로젝트)   ← 개인 PC 표준
claude mcp add <name> -s project -t http <url>   # 이 프로젝트만(.mcp.json, 팀 공유)
claude mcp add <name> -s local   -t http <url>   # 이 프로젝트 + 내 머신만(기본값)
claude mcp remove <name> -s <scope>              # 해당 스코프에서 제거
claude mcp list ; claude mcp get <name>          # 목록 / 스코프·상태 확인
```

`-s` = `--scope`, `-t` = `--transport`. stdio 서버는 `-t stdio` 대신
`claude mcp add <name> -- <command> <args...>` 형태(`--` 뒤가 실행 명령).

### C. AI에게 던지는 한 문장 지시문 (복붙용)

명령어를 외우기 싫으면 Claude Code에 이대로 붙여넣으면 알아서 처리한다:

> `unreal-mcp`(http://127.0.0.1:8000/mcp, http transport)를 **user(전역) 스코프**로 등록해줘.
> 다른 스코프(local/project)에 같은 이름이 있으면 정리하고, `claude mcp list`로 검증까지 한 뒤,
> **현재 세션엔 재시작해야 반영된다는 점**을 알려줘.

- 더 짧게: *"unreal-mcp 를 전역(user)으로 등록하고 검증해줘. 중복 있으면 정리하고."*
- 포트/URL만 바꾸면 어떤 http MCP에도 동일하게 쓰는 범용 지시문이다.

### D. 왜 이게 "한방"인가 (이번에 어렵게 돌아간 이유)

- 처음엔 `.mcp.json`(project 스코프) + local 스코프가 섞여 **세션 cwd마다 보였다 안 보였다** 했다.
- 정답은 **user 스코프 단일화** → cwd·프로젝트와 무관하게 항상 로드. `.mcp.json` 중복도 불필요.
- `settings.json`은 MCP와 무관(권한/hook 전용)하므로 거기서 찾지 말 것.

## 로딩 동작 (반드시 기억)

- **MCP 서버는 세션이 시작될 때 단 한 번 로드된다.** 세션 도중 `.mcp.json`/`~/.claude.json`을
  바꿔도 그 세션엔 반영되지 않는다 → **Claude Code 재시작(또는 새 세션)** 필요.
- 로드 기준은 **세션의 기준 디렉터리(cwd)**. 멀티루트 VSCode 워크스페이스라도
  추가 폴더의 `.mcp.json`은 자동 로드되지 않는다(전역 user 스코프면 무관).
- 확인: 새 세션에서 `/mcp` → `unreal-mcp ✓ connected`.

## Toolset 게이트웨이 구조

`unreal-mcp`는 모든 Tool을 한꺼번에 노출하지 않고, **게이트웨이 3종**으로 지연(lazy) 노출한다
(컨텍스트 절약). 도구 이름은 `mcp__unreal-mcp__<name>` 형태.

| 게이트웨이 | 역할 |
|-----------|------|
| `list_toolsets` | 사용 가능한 toolset 목록 + 설명 |
| `describe_toolset` | 특정 toolset의 tool 이름·설명·입력 스키마 상세 |
| `call_tool` | 실제 tool 실행 |

### 주요 Toolset 카테고리 (UE 5.8 기준, `list_toolsets` 결과 요약)

| 영역 | 주요 toolset |
|------|--------------|
| 씬/액터/레벨 | `SceneTools`, `ActorTools`, `PrimitiveTools`, `EditorAppToolset`(뷰포트·PIE·콘솔변수) |
| 에셋 일반 | `AssetTools`, `ObjectTools`(프로퍼티 리플렉션), `StaticMesh`/`SkeletalMesh`/`Texture`, `SemanticSearchToolset`(벡터+BM25 검색) |
| 블루프린트/플러그인 | `BlueprintTools`, `PluginToolset`, `ProgrammaticToolset`(샌드박스 파이썬으로 여러 tool 배치 오케스트레이션) |
| 머티리얼/VFX | `MaterialTools`, `MaterialInstanceTools`, **Niagara**(System/Component/Blueprint/Assets/Info), `PCGToolset`/`PCGSpatial` |
| 데이터 | `DataTable`/`CurveTable`/`DataAsset`/`StringTable`/`DataRegistry`/`GameplayTags`/`ConfigSettings` |
| 애니메이션/시네마틱 | `ControlRigTools`, **Sequencer** 풀세트(코어·키프레이밍·ControlRig·임포트/익스포트·아웃라이너·조건·커스텀바인딩) |
| 게임플레이 시스템 | **GAS**(GameplayCue/AttributeSet/AbilitySystemInspector), `BehaviorTreeTools`, `StateTreeTools`, `ConversationTools`, `WorldConditionTools`, `DataflowAgent` |
| UI/물리/테스트 | `UMGToolSet`, `SlateInspectorToolset`(Playwright식 에디터 UI 자동화), `PhysicsAssetToolset`, `AutomationTestToolset` |
| 에이전트/운영 | `AgentSkillToolset`, `LogsToolset`, `GameFeaturesToolset` |

> UMG 작업 시 필수 순서: 위젯마다 `ObjectTools.list_properties` → `get_properties` →
> `set_properties`. 프로퍼티명은 위젯 클래스마다 달라 추측 불가(생략 시 조용히 실패).

## 동작 규칙

- 에디터(서버) 먼저 켜고 → Claude 세션을 (재)시작하는 순서.
- 커스텀 toolset 작성 후에는 에디터 콘솔에서 `ModelContextProtocol.RefreshTools`.
- Tool은 게임 스레드에서 **순차 실행** → 동시 호출이 겹치지 않게.

## 반복 금지 (이번에 겪은 함정)

- **비(非)언리얼 프로젝트에 `unreal-mcp`를 local 스코프로 박지 말 것.** (예: `baro_calory`에
  잘못 들어가 있던 것을 제거했다.) 전역(user)에 한 번만 등록하면 충분.
- **설정 바꾼 뒤 "현재 세션에서 안 뜬다"고 당황하지 말 것** — 세션 1회 로드 특성. 재시작이 답.
- **같은 서버를 user와 project 양쪽에 중복 등록**하면 우선순위가 높은 project가 가려서
  활성화된다(같은 URL이면 무해하나 관리상 혼란). 개인 PC면 user 한 곳으로 통일.

# Unreal Engine 5.8 + MCP + Claude Code 협업 셋업 가이드

> UE 5.8(2026-06-17, Unreal Fest Chicago 공개)에 내장된 **실험적(Experimental) Unreal MCP 플러그인**으로
> Claude Code가 에디터를 직접 조작(액터 스폰·라이팅·머티리얼·블루프린트·레벨 편집·자동화 테스트)하도록 연결하는 절차.
>
> 대상 프로젝트: `C:\works\ue_prjs\MyProject` (UE 5.8 C++ 프로젝트)
> 플랫폼: Windows 11 / PowerShell

---

## 0. 동작 원리 (한 장 요약)

```
┌────────────────────┐         HTTP / JSON-RPC          ┌──────────────────┐
│  Unreal Editor 5.8 │  http://127.0.0.1:8000/mcp        │   Claude Code    │
│  └ Unreal MCP 서버 │ ◀───────────────────────────────▶ │   (CLI 터미널)   │
│  └ AllToolsets     │   (loopback 전용, 인증 없음)       │  .mcp.json 자동  │
│     = 실제 Tool들   │                                    │     디스커버리    │
└────────────────────┘                                    └──────────────────┘
```

핵심 사실:
- **MCP 서버가 에디터 프로세스 "안"에서 돈다.** 따라서 에디터가 켜져 있어야 Claude가 붙는다.
- **Unreal MCP 플러그인 단독으로는 Tool이 없다.** `AllToolsets`(Toolset Registry) 플러그인을 켜야 실제 조작 Tool이 등록된다. → 안 켜면 "연결은 되는데 할 수 있는 게 없는" 상태가 된다.
- **전송 방식은 HTTP 전용** (stdio·WebSocket 미지원). 기본 바인딩 `127.0.0.1:8000`, 경로 `/mcp`.
- **Tool은 게임 스레드에서 순차 실행** → 동시 호출 겹치지 않게.

---

## 1. 사전 준비

| 항목 | 확인 |
|------|------|
| UE 5.8 설치 | Epic Games Launcher / GitHub 빌드 (2026-06-17 릴리스) |
| 프로젝트 엔진 버전 | `MyProject.uproject` → `"EngineAssociation": "5.8"` ✅ (이미 충족) |
| Claude Code CLI | 터미널에서 `claude --version` 동작 확인 |
| 모델 | 복잡한 Blueprint 그래프 조작은 tool-calling 강한 모델 권장 (Opus/Sonnet) |

---

## 2. 플러그인 활성화 (에디터)

1. **Unreal MCP 켜기**
   - `Edit > Plugins` → 검색창에 **"Unreal MCP"** → `Enabled` 체크
   - 의존 플러그인 **"Toolset Registry"** 가 자동으로 함께 켜진다.
2. **AllToolsets 켜기 (필수 — 빼먹으면 Tool 0개)**
   - 같은 Plugins 창에서 **"Toolsets"** 또는 **"AllToolsets"** 검색 → `Enabled`
   - 기본 제공 Toolset: `SceneTools`, `ActorTools`, `MaterialInstanceTools`, `ObjectTools`
3. **에디터 재시작** (프롬프트가 뜨면 재시작)
   - C++ 프로젝트라 플러그인 모듈 빌드가 필요하면 재컴파일 프롬프트가 뜰 수 있음 → 빌드 진행.

> ⚠️ 모두 **Experimental** 표시. 프로덕션 빌드에는 주의.

---

## 3. MCP 서버 설정 (자동 시작 켜기)

1. `Edit > Editor Preferences > General > Model Context Protocol`
2. **`Auto Start Server`** 체크 → 에디터 켜질 때 서버 자동 기동
3. 기본값 확인/조정:
   - **Listening Port**: `8000`
   - **URL Path**: `/mcp`
   - 최종 엔드포인트: `http://127.0.0.1:8000/mcp`

수동 제어가 필요하면 콘솔 명령(아래 표) 사용.

---

## 4. 클라이언트 설정 파일 생성 (`.mcp.json`)

1. 에디터에서 콘솔 열기 — **백틱(`` ` ``)** 키
2. 다음 명령 실행:

   ```
   ModelContextProtocol.GenerateClientConfig ClaudeCode
   ```

3. **프로젝트 루트**(`C:\works\ue_prjs\MyProject\`)에 `.mcp.json` 이 생성된다:

   ```json
   {
     "mcpServers": {
       "unreal-mcp": {
         "type": "http",
         "url": "http://127.0.0.1:8000/mcp"
       }
     }
   }
   ```

- 여러 클라이언트를 한 번에: `ModelContextProtocol.GenerateClientConfig All`
- 지원 인자: `ClaudeCode`, `Cursor`, `VSCode`, `Gemini`, `Codex`, `All`

---

## 5. Claude Code 연결

### 방법 A — 자동 디스커버리 (권장)

생성된 `.mcp.json` 이 있는 **프로젝트 루트에서** Claude Code를 실행한다:

```powershell
cd C:\works\ue_prjs\MyProject
claude
```

- Claude Code가 프로젝트 스코프 `.mcp.json` 을 자동 발견 → **MCP 서버 신뢰(approve) 프롬프트**가 뜨면 승인.
- 확인: Claude Code 안에서 `/mcp` 입력 → `unreal-mcp` 가 `connected` 로 보이면 성공.

### 방법 B — CLI 등록

```powershell
claude mcp add --transport http unreal-mcp http://127.0.0.1:8000/mcp
```

### 연결 테스트 프롬프트

```
> 지금 선택된 액터가 뭐야?
> Unreal에서 네가 할 수 있는 일 몇 가지 알려줘
> 빈 레벨에 PointLight 하나 스폰하고 색온도 3200K로 맞춰줘
```

---

## 6. 콘솔 명령 레퍼런스

| 명령 | 용도 |
|------|------|
| `ModelContextProtocol.StartServer [port]` | 서버 수동 시작 |
| `ModelContextProtocol.StopServer` | 서버 중지 |
| `ModelContextProtocol.RefreshTools` | 커스텀 Toolset 작성 후 Tool 재등록 |
| `ModelContextProtocol.GenerateClientConfig <Client>` | 클라이언트 설정 생성 |

---

## 7. (선택) 에디터 내장 터미널에서 Claude 실행

별도 터미널 대신 에디터 안에서 돌리고 싶다면:

1. `Edit > Plugins` → **"Terminal"** 플러그인 활성화
2. `Editor Preferences > General > Terminal` 시작 명령 설정:
   - `set TERM=xterm-256color`  (Windows)
   - `cd "C:\works\ue_prjs\MyProject"`
   - `claude`

---

## 8. 트러블슈팅

| 증상 | 원인 / 해결 |
|------|-------------|
| Claude에 Tool이 하나도 안 보임 | **AllToolsets 미활성** → 2-2 단계 확인. 작성 후 `RefreshTools` 실행 |
| `Connection closed` / 연결 실패 | ① 에디터가 실제로 켜져 있고 서버가 떠 있는지(Output Log에서 bind 주소·포트 확인) ② `.mcp.json` 이 있는 **프로젝트 루트에서** `claude` 를 띄웠는지 |
| `/mcp` 에 unreal-mcp 안 뜸 | 실행 디렉터리에 `.mcp.json` 없음 → 4단계 재실행 또는 방법 B로 등록 |
| 포트 충돌 | Editor Preferences에서 포트 변경 후 `GenerateClientConfig` 재실행 (설정 파일도 갱신해야 함) |
| 복잡한 Blueprint 작업 실패 | tool-calling 약한 모델 → Opus/Sonnet 사용 |

---

## 9. 출처 (2026-06 기준)

- [Unreal MCP in Unreal Editor — UE 5.8 공식 문서 (Epic)](https://dev.epicgames.com/documentation/unreal-engine/unreal-mcp-in-unreal-editor?lang=en-US)
- [UE 5.8 AI: Claude, Codex, MCP Editor Guide 2026 — explainx.ai](https://explainx.ai/blog/unreal-engine-5-8-claude-codex-mcp-ai-integration-2026)
- [Unreal Engine 5.8 Adds Claude and Gemini AI to Editor — techmymoney](https://techmymoney.com/2026/06/18/unreal-engine-5-8-connects-claude-and-gemini-directly-into-game-editors/)
- [The Impact of Unreal Engine 5.8's 'MCP Support' — note.com (香川友志)](https://note.com/kagawatomo/n/na6d10e54d4ee?hl=en)
- [UE5.8 MCP Server Setup & Test (YouTube)](https://www.youtube.com/watch?v=Ko3dy_G75-s)
- [Epic Dev Community 포럼 — Experimental UE 5.8 MCP Server "Connection Closed" 이슈](https://forums.unrealengine.com/t/testing-experimental-ue-5-8-mcp-server-with-local-llms-qwen-coder-and-claude-desktop-connection-closed-issue/2729403)

# AI-TFT 스타터 키트 (Windows · 행정 업무용)

한국외대 AI-TFT 교육(5회차~)에서 쓰는 Claude Code 설정 묶음입니다.
수강생 모두가 **같은 스킬 · 훅 · 화면 배치**로 바로 실습을 시작할 수 있게 만들었습니다.
(외부 키트를 그대로 쓰지 않고 Windows · 한글(HWP) · 학교 Google 계정 환경에 맞게 새로 만들었습니다.)

## 설치 (약 1분)

PowerShell 창에서:

```powershell
git clone https://github.com/ai-tft-alt/ai-tft-kit.git C:\ai_tft\ai-tft-kit
cd C:\ai_tft\ai-tft-kit
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Project C:\ai_tft\kit51 -Learning
```

또는 Claude CLI에 그대로 붙여넣기:

> https://github.com/ai-tft-alt/ai-tft-kit 을 C:\ai_tft\ai-tft-kit 에 내려받고, install.ps1 을 -Project C:\ai_tft\kit51 -Learning 옵션으로 실행해줘. 설치 결과를 표로 보여줘.

설치 후 Claude를 새로 실행하면 스킬이 보입니다.

### VS Code 터미널 설정 (권장)

VS Code 터미널 안에서 Zellij를 쓸 때 단축키가 먹지 않거나, **화살표는 되는데 ESC만 안 먹는** 경우(Windows 10)가 있습니다.
`-VSCode` 옵션을 붙이면 `%APPDATA%\Code\User\settings.json`에 아래 3줄을 추가합니다(이미 있는 줄은 건너뛰고, 원본은 `settings.json.bak`으로 백업).

```json
"terminal.integrated.sendKeybindingsToShell": true,
"terminal.integrated.defaultProfile.windows": "PowerShell",
"terminal.integrated.windowsUseConptyDll": true
```

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -VSCode
```

추가한 뒤 VS Code 터미널을 닫았다가 새로 열면 적용됩니다.

같은 옵션으로 **Zellij 중복 실행 방지**도 PowerShell 프로필(`Documents\WindowsPowerShell\profile.ps1`)에 넣습니다.
Zellij 칸 안에서 `zellij`를 또 입력하면 실행하지 않고 안내만 띄웁니다. 두 겹이 되면 ESC가 다시 안 먹고, 맨 위 탭 줄과 맨 아래 단축키 줄이 2줄씩 보입니다.
`zellij ls`, `zellij action …` 같은 관리 명령은 그대로 됩니다. 꼭 겹쳐 켜야 하면 `zellij.exe`로 직접 실행하세요.

## 들어 있는 것

| 구분 | 이름 | 하는 일 |
|---|---|---|
| 스킬 + CLI | `tft-hwp-read` + `cli/hwp.py` | 한글(.hwp/.hwpx) 문서를 텍스트로 읽기. 한컴오피스 자동화 또는 pyhwp 사용, 문서는 PC 밖으로 안 나감 |
| 스킬 | `tft-official-brief` | 공문 → 한 장 요약(해야 할 일 · 기한 · 확인할 점) |
| 스킬 | `tft-context-save` | 진행 상황을 context.md에 저장 → /clear 후 이어서 (Context Writing) |
| 스킬 | `tft-decision-log` | 끝난 작업의 결정과 이유를 decisions/에 기록 (Decision Writing) |
| 스킬 | `tft-prd-coach` | 바로 만들지 않고 질문 → PRD.md → 작업 목록 (gstack `/office-hours` 방식을 줄인 것) |
| 훅 | `hooks/learning-mode.mjs` | UserPromptSubmit 훅. 작업에서 배운 점을 CLAUDE.md `## 배운 점`에 쌓게 함 (`-Learning` 폴더에만) |
| 레이아웃 | `layouts/*.kdl` | Zellij 화면 배치: event(설명회 준비 4칸), team(직원 3명), blog(블로그 실습) |
| 템플릿 | `templates/CLAUDE.md` | 행정 업무 프로젝트용 CLAUDE.md (계층형 · 개인정보 · 초안 규칙) |

## 스킬 연결 예 (체이닝)

> 공문 폴더의 hwp 파일을 읽고 한 장 요약을 만든 다음, 그 요약으로 부서장 안내 메일을 Gmail 초안으로 만들어줘

`tft-hwp-read`(CLI로 읽기) → `tft-official-brief`(요약) → Gmail 커넥터(초안) 순서로 Claude가 알아서 이어 씁니다.

## 원칙

- 전역 설정(`%USERPROFILE%\.claude\settings.json`)은 건드리지 않습니다. 훅은 `-Project` 폴더에만 켭니다.
- 같은 이름의 스킬이 이미 있으면 덮어쓰지 않습니다 (`-Force`로 덮어쓰기).
- 메일 · 메시지는 초안까지만, 보내기는 사람이.
- 지우기: `.\install.ps1 -Uninstall`

## 더 해 볼 것

- 기획을 더 깊게: [gstack](https://github.com/garrytan/gstack) (MIT, YC Garry Tan). 설치에 Bun이 필요합니다.
- 내 과거 결과물로 스킬 만들기: 예전 보고서 3개를 한 폴더에 넣고 "이 양식대로 보고서를 만드는 스킬을 skill-creator로 만들어줘".

MIT License

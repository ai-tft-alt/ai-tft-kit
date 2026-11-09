---
name: tft-hwp-read
description: 한글 문서(.hwp, .hwpx)를 읽어 텍스트로 가져옵니다. 사용자가 한글 파일·공문·HWP·HWPX를 읽거나 요약하거나 다른 문서로 바꾸려고 할 때 사용합니다.
---

# 한글(HWP/HWPX) 문서 읽기

한글 문서는 Claude가 바로 읽지 못하므로, 키트에 들어 있는 CLI(`hwp.py`)로 텍스트를 뽑아서 씁니다.

## 명령

```powershell
# 이 PC에서 쓸 수 있는 방법 확인
python "$env:USERPROFILE\.ai-tft-kit\cli\hwp.py" check
# 본문 텍스트
python "$env:USERPROFILE\.ai-tft-kit\cli\hwp.py" text "<파일 경로>"
# 텍스트를 파일로 저장 (긴 문서)
python "$env:USERPROFILE\.ai-tft-kit\cli\hwp.py" text "<파일 경로>" --out "<결과.txt>"
```

## 순서

1. 사용자가 말한 파일을 찾는다. 경로가 없으면 현재 폴더에서 `*.hwp`, `*.hwpx`를 찾아 목록을 보여 준다.
2. `text` 명령으로 본문을 읽는다. 3,000자가 넘으면 `--out`으로 저장한 뒤 필요한 부분만 읽는다.
3. 읽은 내용을 바탕으로 사용자가 요청한 일(요약, 표 정리, 다른 스킬로 넘기기)을 한다.

## 규칙

- 문서 원본은 고치지 않는다. 결과는 새 파일로 만든다.
- 읽기에 실패하면 `check` 결과를 보여 주고, 한컴오피스 설치나 `pip install pyhwp`를 안내한다.
- 문서 안의 개인정보(주민번호, 전화번호 등)는 요약에 옮기지 않는다.

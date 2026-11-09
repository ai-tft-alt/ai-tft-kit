#!/usr/bin/env node
// UserPromptSubmit 훅: 학습 모드
// 사용자가 프롬프트를 보낼 때마다 아래 안내를 Claude의 맥락에 덧붙입니다.
// → 작업 중 새로 알게 된 사실(오류 원인, 프로젝트 규칙, 자주 쓰는 경로)을 CLAUDE.md "## 배운 점"에 1~2줄로 쌓게 합니다.
// 끄기: 프로젝트 폴더에 .claude/learning-off 파일을 만들거나, settings.json에서 훅을 지웁니다.
import { existsSync, readFileSync } from 'node:fs';
import path from 'node:path';

let input = {};
try { input = JSON.parse(readFileSync(0, 'utf8') || '{}'); } catch { /* 입력이 없어도 동작 */ }
const root = process.env.CLAUDE_PROJECT_DIR || input.cwd || process.cwd();
if (existsSync(path.join(root, '.claude', 'learning-off'))) process.exit(0);

const prompt = String(input.prompt || '');
if (prompt.trim().startsWith('/')) process.exit(0); // 슬래시 명령에는 붙이지 않음

const note = [
  '[학습 모드] 이 요청을 마친 뒤 스스로 점검하세요:',
  '- 이번 작업에서 다음에도 쓸 만한 사실(오류 원인과 해결, 이 프로젝트만의 규칙, 파일 위치, 명령)이 있었나?',
  '- 있으면 프로젝트 CLAUDE.md 의 "## 배운 점" 섹션(없으면 만들기)에 한 줄씩, 최대 2줄 추가하세요. 이미 있는 내용은 중복하지 마세요.',
  '- 응답 끝에 "📝 배운 점: (추가한 줄 또는 없음)" 한 줄을 붙이세요.',
  '- 일상적인 작업이라 새로 배운 것이 없으면 아무것도 추가하지 마세요.',
].join('\n');

process.stdout.write(note);
process.exit(0);

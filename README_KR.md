# prompt-engineering

Anthropic 공식 프롬프트 엔지니어링 레퍼런스와 모델별 프롬프팅 가이드를 근거로, Claude용 프롬프트를
작성·검토·디버깅하는 Claude Code 스킬입니다. 문서는 요약본이 아니라 **원문 그대로** 번들되어 있습니다.

`~/.claude/skills/prompt-engineering/` 에 설치되어 모든 프로젝트에서 로드됩니다.

> 영어 원본: [README.md](README.md). 이 문서는 한국어 미러이며, 내용이 어긋날 경우 영어 문서가 기준입니다.

## 무엇을 하는가

`SKILL.md` 가 두 가지 모드로 동작합니다.

**작성.** Claude 모델이 읽게 될 텍스트를 쓰거나 고칠 때 — 시스템 프롬프트, API 프롬프트, 에이전트·서브에이전트
지시문, `CLAUDE.md` / `AGENTS.md`, 다른 스킬, 애플리케이션 코드 안의 프롬프트 문자열.

**진단.** 사용자가 고치고 싶은 동작을 서술할 때 — "너무 장황하다", "툴을 안 쓴다", "서브에이전트를 남발한다",
"끝내기 전에 멈춘다", "디자인이 매번 똑같다", 예상 못 한 400 에러나 거부 — 66행짜리 증상 인덱스가 그것을
해당 모델 가이드의 정확한 섹션으로 연결합니다.

## 왜 필요한가

이 가이드는 1년 남짓 주기로 뒤집힙니다. 그래서 기억에 의존해 프롬프트를 쓰는 건 부정확한 정도가 아니라
**적극적으로 위험**합니다. 예전 모델에서 핵심 역할을 하던 지시문이 지금은 원하던 동작을 지나치게 밀어붙입니다.

- `CRITICAL: You MUST use this tool` 은 이제 존재하지 않는 언더트리거를 고치려고 쓰던 문구입니다.
  지금은 **오버트리거**를 일으킵니다.
- `Always double-check your answer` 는 Opus 5가 이미 하는 자체 검증과 겹쳐서, 품질 개선 없이 토큰만 씁니다.
- `Hold all findings for the final response` 는 Fable 5.1이 긴 툴 체인 도중 침묵하는 문서화된 원인입니다.
- `temperature`, `budget_tokens`, assistant prefill 은 각각 현행 모델에서 400을 반환합니다.

그래서 스킬은 **덧붙이기 전에 빼기**를 중심으로 짜여 있습니다. 프롬프트가 이상하게 동작하면, 이를 상쇄할
새 문장을 쓰기 전에 원인이 되는 낡은 문장부터 찾습니다. 또 하나의 축은 **모델 먼저, 기법은 그다음**입니다.
크로스 모델 레퍼런스와 개별 모델 가이드가 같은 항목을 두고 정반대를 가리킬 수 있고 — 장황함이 가장 대표적인
사례입니다 — 그럴 때는 모델 가이드가 이깁니다.

## 구성

```
prompt-engineering/
├── SKILL.md                        워크플로, 증상 인덱스, 낡은 패턴 목록
├── README.md                       영어 원본
├── README_KR.md                    이 문서
├── references/                     platform.claude.com 원문 사본
│   ├── core-techniques.md          Prompting best practices (크로스 모델)
│   ├── model-fable-5-1.md          Fable 5.1 / Mythos 5.1
│   ├── model-fable-5.md            Fable 5 / Mythos 5
│   ├── model-opus-5.md             Opus 5
│   ├── model-sonnet-5.md           Sonnet 5
│   └── model-opus-4-8.md           Opus 4.8
├── scripts/
│   └── refresh.sh                  6개 페이지 재다운로드
└── evals/
    └── evals.json                  테스트 케이스 3개, assertion 20개
```

매번 웹에서 가져오지 않고 번들한 이유는 오프라인 동작과, 패러프레이즈가 아닌 **현재 문구를 그대로 인용**하기
위해서입니다. 패러프레이즈하면 효과가 새어나갑니다 — 문서에는 그대로 붙여넣도록 만들어진 검증된 블록들이
있습니다 (`<default_to_action>`, `<use_parallel_tool_calls>`, `<investigate_before_answering>`,
`<frontend_aesthetics>`).

프로그레시브 디스클로저는 의도대로 작동합니다. 테스트에서 Sonnet 5 문제를 진단하던 세션은 `SKILL.md`,
Sonnet 5 가이드, 그리고 `core-techniques.md` 의 지정된 두 구간만 읽었고 나머지 모델 가이드 4개는 열지
않았습니다.

## 발동 방식

`SKILL.md` 프런트매터의 `description` 으로 자동 발동합니다. 의도적으로 넓게 잡혀 있어서 "프롬프트
엔지니어링"이라는 말이 없어도 **증상 서술만으로** 걸립니다. 수동 호출은 `/prompt-engineering`.

모델 ID, 가격, effort 레벨, API 파라미터는 `claude-api` 스킬로 위임합니다. 이 스킬이 다루는 것은
**동작과 문구**이지 API 표면이 아닙니다.

## 번들 문서 최신 유지

```bash
./scripts/refresh.sh --check    # 드리프트만 보고, 파일은 쓰지 않음
./scripts/refresh.sh            # 6개 페이지 전부 재다운로드
```

스크립트는 프런트매터 마크다운이 아닌 응답을 거부하므로, 로그인 페이지로 리다이렉트되더라도 멀쩡한 레퍼런스
파일을 덮어쓰지 않습니다. Anthropic은 새 모델이 나올 때마다 이 페이지들을 개정합니다. 갱신으로 섹션이
바뀌거나 추가되면 `SKILL.md` 의 증상 인덱스도 함께 고쳐야 합니다 — 인덱스는 리터럴 헤딩을 가리키고 있고,
낡은 포인터는 없는 것만 못합니다.

갱신 후에는 아래로 인덱스를 검증하세요.

```bash
python3 - <<'PY'
import re, pathlib
refs = pathlib.Path('references')
heads = {f.name: set(re.findall(r'^#{2,4}\s+(.+?)\s*$', f.read_text(), re.M))
         for f in refs.glob('*.md')}
MAP = {'core':'core-techniques.md', 'Fable 5.1':'model-fable-5-1.md',
       'Fable 5':'model-fable-5.md', 'Opus 5':'model-opus-5.md',
       'Sonnet 5':'model-sonnet-5.md', 'Opus 4.8':'model-opus-4-8.md'}
text = re.sub(r'\s+', ' ', pathlib.Path('SKILL.md').read_text())
pairs = re.findall(r'((?:core|Fable 5\.1|Fable 5|Opus 5|Sonnet 5|Opus 4\.8)'
                   r'(?:\s*/\s*(?:core|Fable 5\.1|Fable 5|Opus 5|Sonnet 5|Opus 4\.8))*)'
                   r'\s*→\s*"([^"]+)"', text)
bad = ok = 0
for labels, sec in pairs:
    for lab in (l.strip() for l in labels.split('/')):
        if sec in heads[MAP[lab]]: ok += 1
        else: bad += 1; print(f'  MISMATCH {lab} has no section "{sec}"')
print(f"{ok} pointers resolve, {bad} bad")
PY
```

모델을 추가하려면 세 군데를 고칩니다: `refresh.sh` 의 `PAGES` 에 `<로컬-이름>|<문서-슬러그>` 한 줄 추가,
`SKILL.md` 모델 표에 행 추가, 증상 인덱스에 해당 증상 추가.

## 평가

케이스 3개를 스킬 유/무로 각각 한 번씩 실행하고, assertion 20개에 대해 독립 채점 에이전트가 채점했습니다.
assertion은 실행이 끝나기 전에 미리 작성했습니다.

| | 스킬 사용 | 스킬 없음 |
| --- | --- | --- |
| Pass rate | **100%** (20/20) | 50% (10/20) |
| 소요 시간 | 135.0s ± 19.1 | 150.8s ± 47.0 |
| 토큰 | 59,033 ± 3,887 | 45,673 ± 8,417 |

케이스별: Sonnet 5 장황함 `6/6 vs 4/6`, Opus 5 서브에이전트 남발 `5/5 vs 2/5`, 낡은 코드리뷰 프롬프트
`9/9 vs 4/9`.

갈린 지점은 세 가지였습니다.

1. **최신 API 사실.** 스킬을 쓴 실행은 매번 구체적으로 짚었습니다 — Sonnet 5에서 `temperature` → 400,
   `budget_tokens` 제거, 4.6 이후 prefill 미지원, `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`. 베이스라인은
   **하나도 언급하지 못했고**, `effort` 라는 단어가 세 답변 어디에도 나오지 않았습니다. 한 베이스라인은
   오히려 후퇴해서 `budget_tokens=10000` 을 그대로 두고 `temperature` 와 prefill을 동작 가능한 대안으로
   제시했습니다.
2. **빼기 대 덧붙이기.** 모델이 과잉 검증한다는 질문에 스킬을 쓴 실행은 검증 지시를 **삭제**했습니다.
   베이스라인은 그 자리에 더 긴 규칙 블록을 넣었습니다 — 스캐폴딩을 고치려고 스캐폴딩을 더한 셈입니다.
3. **근본 원인 프레이밍.** 베이스라인 둘 다 설정 탓으로 시작했고, 스킬을 쓴 실행 둘 다 문서화된 모델 기본
   동작을 인용하며 시작했습니다.

### 한계

이 수치는 케이스 3개를 한 번 돌린 결과이지 넓은 벤치마크가 아닙니다. 100%는 "완벽"이 아니라 "이 20개
항목에서 실패가 없었다"는 뜻입니다.

- **케이스 2(서브에이전트 남발)는 변별력이 약합니다.** 양쪽 실행 모두 이 시나리오를 로컬 머신 설정에 대한
  질문으로 읽고 `~/.claude/` 를 뒤졌습니다. 그래서 이 케이스는 스킬보다 로컬 탐색 능력을 부분적으로 재고
  있습니다. 프롬프트에 가상 시나리오임을 명시했어야 했습니다.
- **assertion 두 개가 무릅니다.** 케이스 3의 "coverage-first" 항목은 복합 조건이라 베이스라인이 세 절 중
  두 개만 만족하고도 통과했습니다. 케이스 2에는 검증 스캐폴딩을 *추가하는* 행위를 감점할 항목이 없어서,
  한 줄 지우고 열 줄 더해도 통과할 수 있습니다.
- **토큰을 약 29% 더 씁니다.** 레퍼런스를 읽는 게 목적이니 당연하고, 이런 질문에서는 값어치를 합니다.
  토큰이 더 드는데도 소요 시간은 오히려 짧은데, 헤매지 않고 어디를 볼지 알기 때문으로 보입니다.

### 재실행

테스트 케이스와 assertion은 `evals/evals.json` 에 있습니다. 실행 결과와 채점, 벤치마크는 형제 디렉터리
`~/.claude/skills/prompt-engineering-workspace/` 에 있습니다. 재실행은 `skill-creator` 스킬로 하면
서브에이전트 실행·채점·집계·리뷰 뷰어까지 처리됩니다.

## 출처

레퍼런스 내용은 전부
`https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/` 에서 각 페이지가 제공하는
`.md` 엔드포인트로 받았습니다. 여기 있는 사본은 수정하지 않은 원문이며, 수정이 필요한 내용은 `SKILL.md`
에 씁니다.

# prompt-engineering

A Claude Code skill that writes, reviews, and debugs prompts for Claude, working from
Anthropic's official prompt engineering reference and the per-model prompting guides —
bundled here verbatim rather than summarized.

Installed at `~/.claude/skills/prompt-engineering/`, so it loads in every project.

> Korean mirror: [README_KR.md](README_KR.md). Source of truth: this English document.

## What it does

Two modes, both driven from `SKILL.md`:

**Authoring.** Writing or revising anything a Claude model will read — a system prompt, an
API prompt, agent or subagent instructions, a `CLAUDE.md` / `AGENTS.md`, another skill, or
prompt strings inside application code.

**Diagnosis.** Someone describes a behavior they want changed — "too verbose", "won't call
the tool", "spawns too many subagents", "stops before it finishes", "every design looks the
same", an unexpected 400 or refusal — and a symptom index of 66 rows maps it to the exact
section of the exact model guide that covers it.

## Why it exists

This guidance inverts every year or so, which makes writing prompts from memory actively
risky rather than merely imprecise. Instructions that were load-bearing on older models
now push current models past the behavior you wanted:

- `CRITICAL: You MUST use this tool` was written to fix undertriggering that no longer
  exists. It now causes overtriggering.
- `Always double-check your answer` compounds with self-verification Opus 5 already does,
  costing tokens with no quality gain.
- `Hold all findings for the final response` is a documented cause of Fable 5.1 going
  silent during long tool chains.
- `temperature`, `budget_tokens`, and assistant prefills each return a 400 on current
  models.

So the skill is organized around **subtraction before addition**: when a prompt misbehaves,
find the stale line causing it before writing a new line to counteract it. It also insists
on **model first, then technique**, because the cross-model reference and a model guide can
point in opposite directions on the same knob — verbosity being the clearest case — and the
model guide wins.

## Layout

```
prompt-engineering/
├── SKILL.md                        workflow, symptom index, stale-pattern list
├── README.md                       this file
├── README_KR.md                    Korean mirror
├── references/                     verbatim copies from platform.claude.com
│   ├── core-techniques.md          Prompting best practices (cross-model)
│   ├── model-fable-5-1.md          Fable 5.1 / Mythos 5.1
│   ├── model-fable-5.md            Fable 5 / Mythos 5
│   ├── model-opus-5.md             Opus 5
│   ├── model-sonnet-5.md           Sonnet 5
│   └── model-opus-4-8.md           Opus 4.8
├── scripts/
│   └── refresh.sh                  re-download the six pages
└── evals/
    └── evals.json                  3 test cases, 20 assertions
```

References are bundled rather than fetched so the skill works offline and quotes current
wording instead of a paraphrase. Paraphrase is where the effect leaks out — the docs carry
tested blocks (`<default_to_action>`, `<use_parallel_tool_calls>`,
`<investigate_before_answering>`, `<frontend_aesthetics>`) that are meant to be quoted.

Progressive disclosure works as intended: in testing, a session diagnosing a Sonnet 5 issue
read `SKILL.md`, the Sonnet 5 guide, and two directed section ranges of
`core-techniques.md`, leaving the other four model guides unopened.

## Triggering

Automatic, from the `description` field in the `SKILL.md` frontmatter. It is deliberately
broad: it fires on symptom descriptions, not just on the words "prompt engineering". Invoke
it by hand with `/prompt-engineering`.

It defers to the `claude-api` skill for model IDs, pricing, effort levels, and API
parameters. This skill covers behavior and wording, not the API surface.

## Keeping the bundled docs current

```bash
./scripts/refresh.sh --check    # report drift, write nothing
./scripts/refresh.sh            # re-download all six pages
```

The script rejects any response that isn't front-matter markdown, so a redirect to a login
page won't overwrite a good reference file. Anthropic revises these pages when models ship.
If a refresh renames or adds a section, update the symptom index in `SKILL.md` to match —
the index points at literal headings, and a stale pointer is worse than no pointer.

Verify the index after any refresh:

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

To add a model: append a `<local-name>|<doc-slug>` line to `PAGES` in `refresh.sh`, add a
row to the model table in `SKILL.md`, and add its symptoms to the index.

## Evaluation

Three cases, run twice each — once with the skill, once without — and graded by an
independent agent against 20 assertions written before the runs finished.

| | With skill | Without skill |
| --- | --- | --- |
| Pass rate | **100%** (20/20) | 50% (10/20) |
| Wall clock | 135.0s ± 19.1 | 150.8s ± 47.0 |
| Tokens | 59,033 ± 3,887 | 45,673 ± 8,417 |

Per case: Sonnet 5 verbosity `6/6 vs 4/6`, Opus 5 subagent sprawl `5/5 vs 2/5`, stale code
review prompt `9/9 vs 4/9`.

Three differences separated the runs:

1. **Current API facts.** Every with-skill run named the specific breakages — `temperature`
   → 400 on Sonnet 5, `budget_tokens` removed, prefill unsupported since 4.6,
   `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS`. No baseline run named any of them, and the word
   `effort` appears zero times across all three baseline answers. One baseline actively
   regressed, keeping `budget_tokens=10000` and offering `temperature` plus a prefill as a
   working fallback.
2. **Subtraction versus addition.** Asked about a model over-verifying, the with-skill run
   deleted the verification instructions. The baseline replaced them with a longer rule
   block — more scaffolding to fix scaffolding.
3. **Root-cause framing.** Both baselines opened by blaming configuration; both with-skill
   runs opened with the documented model default and quoted the guide.

### Caveats

These numbers describe one run of three cases, not a broad benchmark. 100% means no failures
across those 20 assertions, not that the skill is complete.

- **Case 2 (subagent sprawl) is weakly discriminating.** Both runs read the scenario as a
  question about the local machine's own configuration and went digging through
  `~/.claude/`, so the case partly measures local exploration rather than the skill. The
  prompt should have marked it as hypothetical.
- **Two assertions are soft.** The "coverage-first framing" assertion on case 3 is compound,
  and the baseline satisfied two of its three clauses while still passing. Case 2 has no
  assertion that penalizes *adding* verification scaffolding, so a run could pass by
  deleting one line while adding ten.
- **The skill costs about 29% more tokens.** Reading references is the point, and it pays
  for itself on these questions. Wall clock is lower despite the extra tokens, which is
  consistent with knowing where to look instead of searching.

### Re-running

Test cases and assertions live in `evals/evals.json`. Results, graded runs, and the
benchmark are in the sibling directory `~/.claude/skills/prompt-engineering-workspace/`.
Re-run through the `skill-creator` skill, which handles spawning, grading, aggregation, and
the review viewer.

## Source

All reference content comes from
`https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/`, retrieved via
the `.md` endpoint each page exposes. Copies here are unmodified; edits belong in `SKILL.md`.

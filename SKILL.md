---
name: prompt-engineering
description: >-
  Write, review, and debug prompts for Claude using Anthropic's official prompt engineering
  reference and the per-model prompting guides (Opus 5, Sonnet 5, Fable/Mythos 5.1 and 5,
  Opus 4.8), all bundled offline. Use this whenever the user is authoring or tuning any
  instruction text a Claude model will read — a system prompt, an API prompt, agent or
  subagent instructions, a CLAUDE.md / AGENTS.md, a skill, an eval prompt, or prompt strings
  inside application code. Use it just as readily when the user describes a Claude behavior
  they want changed rather than asking about prompts: "too verbose", "too short", "ignores
  my instructions", "won't call the tool", "calls tools too much", "spawns too many
  subagents", "stops before it finishes", "keeps asking permission", "over-engineers",
  "rewrites whole files", "output format drifts", "every design looks the same", "code review
  finds less than it used to", or an unexpected refusal / 400 error from prefill,
  budget_tokens, or temperature. Consult it even when the words "prompt engineering" never
  appear, and before hand-writing prompt text from memory.
---

# Prompt engineering for Claude

Anthropic publishes one cross-model reference plus a separate guide per model. Both are
bundled here verbatim under `references/`, so this skill works offline and quotes the
current wording rather than a half-remembered version of it.

The reason to open them rather than write from memory is that this guidance inverts every
year or so. Instructions that were load-bearing on older models — "CRITICAL: you MUST use
this tool", "always double-check your answer", "never use bullet points" — now push current
models past the behavior you wanted. A prompt written from 2024 habits is not neutral; it is
actively miscalibrated. The docs say which specific habits went stale on which model.

## Three rules that shape every use of this skill

**Model first, then technique.** The cross-model reference and the model guide can point in
opposite directions on the same knob, and the model guide wins. Verbosity is the clearest
case: Sonnet 5 calibrates length to task complexity, Opus 5 runs long by default and ignores
`effort` as a length lever, and Fable 5.1 goes quiet during long tool chains. One
"be concise" line is right for one of them and wrong for another. So establish the target
model before writing a word.

**Subtract before you add.** When a prompt misbehaves, the first question is which existing
line is causing it, not which new line will counteract it. Telling Opus 5 to verify its work
makes it over-verify; telling Fable 5.1 to hold findings for the final response is what made
it go quiet; telling any current model "if in doubt, use the tool" is what makes it
overtrigger. Layering a correction on top of the real cause leaves both in the prompt and
costs tokens in both directions. Read the relevant model section, find the stale instruction,
delete it, and only then consider adding.

**A prompt change is a claim, and claims get measured.** Every quantitative statement in
these docs came from an eval. When you hand back a revised prompt, say what you expect to
change and how the user could see it — a few real inputs run before and after is usually
enough. Never assert that a rewrite is better; say what it targets.

## Step 1 — establish the target model

The model that runs the prompt is often not the model reading this skill. Ask, or derive it
from the code (`model=` in an API call, a config file, the harness the user is describing).

| Target | Read | Distinctive tuning knobs |
| --- | --- | --- |
| Claude Fable 5.1 / Mythos 5.1 | `references/model-fable-5-1.md` | Sparse progress updates, one-tool-call-per-turn in agent loops, append-only history, dense prose, under-formatting, finishing long tasks |
| Claude Fable 5 / Mythos 5 | `references/model-fable-5.md` | Very long turns, memory systems, grounding progress claims, early stopping, context-budget anxiety, `reasoning_extraction` refusals |
| Claude Opus 5 | `references/model-opus-5.md` | Long default responses, heavy narration, over-verification, eager subagents, correction narration, artifacts when thinking is off |
| Claude Sonnet 5 | `references/model-sonnet-5.md` | Effort calibration, adaptive thinking on by default, literal instruction following, fixed design defaults, code-review recall |
| Claude Opus 4.8 | `references/model-opus-4-8.md` | Effort calibration, reasoning favored over tool calls, few subagents, cream/serif house style |
| Older, or genuinely unknown | `references/core-techniques.md` | Apply cross-model technique only; say in your answer that model-specific tuning was skipped and why |

If the user names a model with no bundled guide, check whether one shipped since:
`./scripts/refresh.sh --check` reports drift, and adding a page is two lines in that script.
For model IDs, pricing, effort levels, and API parameters, defer to the `claude-api` skill and
the models overview — this skill covers behavior and wording, not the API surface.

## Step 2 — pick the mode

### Mode A: authoring or revising a prompt

1. **Pin down the job.** What does a good output look like, what does a bad one look like,
   and how will the user tell them apart? A prompt written before its success criteria exist
   is guesswork, and the docs open by saying so. If the user can't articulate this yet, one
   focused question is worth more than a polished draft.
2. **Read the model guide** for the target, then the cross-model sections your task touches
   (map below).
3. **Draft against the structure that fits.** Long inputs at the top, then instructions, then
   examples, then the query — queries at the end measurably improve quality on multi-document
   inputs. XML tags to separate instruction from context from input. Three to five diverse
   examples if format or tone matters.
4. **State the why, not only the what.** "Never use ellipses" underperforms "your response
   will be read aloud by a text-to-speech engine, so never use ellipses — it can't pronounce
   them," because the second generalizes to cases you didn't enumerate. This is the single
   highest-leverage habit in the whole reference, and it is the one people skip.
5. **Say what to do, not what to avoid.** Positive examples of the style you want beat
   prohibitions, on every current model. The docs repeat this per-model because it keeps
   getting ignored.
6. **Audit what you wrote against the stale-pattern list below** before handing it over.
7. **Hand back the prompt plus a short rationale**: which model it targets, which sections it
   draws on, and what to watch for on the first few runs.

### Mode B: diagnosing a behavior the user doesn't want

1. Get the symptom in the user's own words, plus the model.
2. Find it in the symptom index below and read that section — the reference usually names
   both the cause and the exact instruction that fixes it.
3. Check whether the user's existing prompt contains the *stale* instruction that produces
   the symptom. That is the fix more often than a new instruction is.
4. Propose the smallest edit, quote the doc's own sample wording where one exists, and say
   what should change.

## Symptom index

Section names below are literal headings in the reference files — grep for them.

### Length, tone, and formatting

| Symptom | Read |
| --- | --- |
| Responses too long | model guide → "Response length and verbosity"; Opus 5 also → "Written deliverable length" for files it writes to disk |
| Responses too short, or skips summarizing after tool calls | core → "Communication style and verbosity" |
| Goes silent for minutes during long tool chains | Fable 5.1 → "Ask for user-facing progress updates" (check `thinking.display` first — the updates may exist and not be rendered) |
| Narrates too much during agentic work | Opus 5 → "User-facing progress updates" |
| Too many bullets and bold | core → "Control the format of responses" |
| Too *few* headers and lists; wall of text | Fable 5.1 → "Formatting in chat" — and delete the anti-formatting block that older prompts carry |
| Prose is dense, metaphor-heavy, tiring | Fable 5.1 → "Writing density" |
| Final summary unreadable after a long session | Fable 5 → "Readability when communicating with the user" |
| Unwanted LaTeX in math | core → "LaTeX output" |
| Preambles ("Here is the...") | core → "Migrating away from prefilled responses" → Eliminating preambles |
| Corrects itself out loud too often | Opus 5 → "Self-correction" |

### Scope, completion, and autonomy

| Symptom | Read |
| --- | --- |
| Over-engineers: extra files, abstractions, unrequested config | core → "Overeagerness"; Fable 5 → "Consider all effort levels"; Fable 5.1 → "Keep changes and tests to what the task asks for" |
| Fixes nearby code, commits extra test files | Fable 5.1 → "Keep changes and tests to what the task asks for" |
| Expands scope, applies its own judgment about the task | Opus 5 → "Task scope and over-verification" |
| Ends the turn on "Next, I'll…" without doing it | Fable 5.1 → "Finish the whole task"; Fable 5 → "Rare cases of early stopping" |
| Asks permission for work already requested | same two sections |
| Verifies and re-checks far more than needed | Opus 5 → "Task scope and over-verification" — remove the verification instruction rather than rewriting it |
| Acts when the user was only thinking out loud | Fable 5 → "State the boundaries" |
| Takes risky or irreversible actions unprompted | core → "Balancing autonomy and safety" |
| Reports progress that didn't happen | Fable 5 → "Ground progress claims during long runs" |
| Wraps up early citing context limits | Fable 5 → "Rare cases of context-budget concern"; core → "Context awareness and multiwindow workflows" |
| Leaves temp scripts behind | core → "Reduce file creation in agentic coding" |

### Tools, thinking, and subagents

| Symptom | Read |
| --- | --- |
| Suggests changes instead of making them | core → "Tool usage" (includes a `<default_to_action>` block) |
| Won't call a tool at all | Sonnet 5 → "Tool use triggering"; Opus 4.8 → same; raise `effort` before rewriting the prompt |
| Answers from memory instead of searching | Fable 5.1 → "Search triggering at low effort" |
| Calls tools far too eagerly | core → "Overthinking and excessive thoroughness" — dial back "CRITICAL"/"you MUST"/"if in doubt" phrasing |
| One tool call per turn in an agent loop | Fable 5.1 → "Batch independent tool calls in agent loops"; core → "Optimize parallel tool calling" |
| Thinks too long, latency spikes | core → "Overthinking and excessive thoroughness"; lower `effort` |
| Shallow reasoning on hard problems | Sonnet 5 / Opus 4.8 → "Calibrating effort and thinking depth" — raise `effort` rather than prompting around it |
| Too many subagents | Opus 5 → "Controlling subagent spawning"; core → "Subagent orchestration" |
| Too few subagents | Opus 4.8 → "Controlling subagent spawning"; Fable 5 → "Parallel subagents" |
| Lead agent idles waiting on subagents | Fable 5.1 → "Let the lead agent keep working while subagents run" |
| `<thinking>` tags or a tool call leaking into visible text | Opus 5 → "Running with thinking disabled" — the real fix is to re-enable thinking at lower effort |

### Coding, review, and vision

| Symptom | Read |
| --- | --- |
| Claims things about code it never opened | core → "Minimizing hallucinations in agentic coding" |
| Hardcodes to make tests pass | core → "Avoid focusing on passing tests and hardcoding" |
| Rewrites whole files for small edits | Fable 5.1 → "Prefer targeted edits over whole-file rewrites" |
| Code review reports fewer bugs than the old model did | Sonnet 5 / Opus 4.8 → "Code review harnesses" — a "don't nitpick" line is being followed more literally, not a capability regression |
| Loses the thread across context windows | core → "Workflows across multiple context windows", "State management best practices" |
| Misses detail in dense charts and screenshots | Fable 5.1 → "Give vision work tools to crop and zoom"; core → "Improved vision capabilities" |
| Every design comes out the same | Sonnet 5 / Opus 4.8 → "Design and frontend defaults"; core → "Frontend design". Generic negatives just move it to a different fixed palette — give a concrete spec, or have it propose four directions first |

### Errors and refusals

| Symptom | Read |
| --- | --- |
| 400 on a prefilled assistant turn | core → "Migrating away from prefilled responses" |
| 400 on `budget_tokens` | core → "Leverage thinking & interleaved thinking capabilities" — move to adaptive thinking plus `effort` |
| 400 on `temperature` / `top_p` / `top_k` | Sonnet 5 → "Tone and writing style" — steer voice from the system prompt instead |
| `bound to a different conversation`, dropped thinking blocks | Fable 5.1 → "Keep the conversation history append-only" |
| `stop_reason: "refusal"` on benign work | Fable 5.1 → "Reduce safeguard false positives"; Fable 5 → the note near the top of the page |
| Refusal after a "show your reasoning" instruction | Fable 5 → "Recommended scaffolding changes" (`reasoning_extraction`) |
| Truncated output, `stop_reason: "max_tokens"` | Sonnet 5 → note under "Calibrating effort and thinking depth"; Fable 5.1 → "Leave room for long outputs at xhigh and max effort" |
| Client or harness times out on long turns | Fable 5 → "Longer turns by default" |
| Compaction summary drops constraints | Fable 5.1 → "Tell the model what to preserve in compaction summaries" |

## Stale patterns worth removing on sight

Each of these was correct advice once. Read the linked section before deleting, since a few
are model-conditional rather than universally wrong.

- **`CRITICAL:` / `You MUST` / `ALWAYS` around tool or skill use.** Written to fix
  undertriggering that no longer exists; now causes overtriggering. Plain "Use this tool
  when…" is the current form. (core → "Tool usage")
- **"Double-check your answer", "add a final verification step".** Compounds with
  self-verification the model already does. (Opus 5 → "Task scope and over-verification",
  "Self-correction")
- **"After every N tool calls, summarize progress."** Scaffolding for models that didn't
  narrate. (Sonnet 5 / Opus 4.8 → "User-facing progress updates")
- **"Hold all findings for the final response."** A direct cause of Fable 5.1 going quiet.
  (Fable 5.1 → "Ask for user-facing progress updates")
- **Blanket anti-formatting blocks.** Fable 5.1 already under-formats; suppressing further
  removes structure the content needs. (Fable 5.1 → "Formatting in chat")
- **Prefilled assistant turns.** A 400 on Claude 4.6 and later. (core → "Migrating away from
  prefilled responses")
- **`budget_tokens`.** Removed on Claude 4.7 and later; use `effort`. (core → thinking section)
- **`temperature` for stylistic variety.** A 400 on Sonnet 5. (Sonnet 5 → "Tone and writing
  style")
- **"Echo / transcribe / explain your reasoning" in a skill or system prompt.** Can trip the
  `reasoning_extraction` refusal on Fable 5. Read structured `thinking` blocks instead.
  (Fable 5 → "Recommended scaffolding changes")
- **"If in doubt, use \[tool]" / "Default to using \[tool]".** (core → "Overthinking and
  excessive thoroughness")
- **Long prescriptive step-by-step reasoning plans.** "Think thoroughly" generally beats a
  hand-written procedure now; the model's own reasoning exceeds what a human prescribes.
  (core → thinking section)
- **Whole skills and prompts tuned for a prior model.** Fable 5's guide is explicit that
  over-prescriptive skills degrade its output. When migrating, try deleting first and
  measuring. (Fable 5 → "Recommended scaffolding changes")

## Cross-model technique map

Jump points inside `references/core-techniques.md`:

- Clarity, motivation, examples, XML structure, roles → "General principles"
- 20k+ token inputs, multi-document prompts, quote grounding → "Long context prompting"
- Output shape, markdown control, LaTeX, prefill migration → "Output and formatting"
- Tool triggering, parallel calls → "Tool use"
- Adaptive thinking, effort, self-check, CoT fallback → "Thinking and reasoning"
- Long-horizon work, state files, subagents, autonomy, research, hallucination, overeagerness
  → "Agentic systems"
- Vision, frontend aesthetics → "Capability-specific tips"
- Coming from an older generation → "Migration considerations"

The reference carries ready-to-paste blocks — `<default_to_action>`,
`<use_parallel_tool_calls>`, `<investigate_before_answering>`, `<frontend_aesthetics>`, the
overengineering block, the multi-context-window block. Quote them rather than paraphrasing;
they are the tested wording, and paraphrase is where the effect leaks out.

## Writing prompts for this environment

When the artifact is a `CLAUDE.md`, `AGENTS.md`, subagent brief, or skill rather than an API
prompt, the same guidance applies with two adjustments. Effort and thinking parameters aren't
yours to set, so behavioral steering has to come from wording alone. And these files are
always in context, which puts a real price on length — every stale line competes with the
task for attention. The cross-model reference's own advice about deleting over-prompting is
sharper here than it is for a single API call.

## Keeping the bundled docs current

`./scripts/refresh.sh` re-downloads all six pages; `--check` reports drift without writing.
Anthropic revises these pages when models ship, so a symptom the user reports that isn't in
the index is a reason to refresh before concluding it isn't documented. If a refresh renames
or adds a section, update the symptom index to match — the index points at headings, and a
stale pointer is worse than no pointer.

## References

| File | Contents |
| --- | --- |
| `references/core-techniques.md` | Prompting best practices — the cross-model reference |
| `references/model-fable-5-1.md` | Prompting Claude Fable 5.1 / Mythos 5.1 |
| `references/model-fable-5.md` | Prompting Claude Fable 5 / Mythos 5 |
| `references/model-opus-5.md` | Prompting Claude Opus 5 |
| `references/model-sonnet-5.md` | Prompting Claude Sonnet 5 |
| `references/model-opus-4-8.md` | Prompting Claude Opus 4.8 |
| `scripts/refresh.sh` | Re-download the six pages from platform.claude.com |

# OMP Context & Compaction Configuration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove billion-context from every managed config surface and give omp per-model compaction ceilings sized to each model's cost, with native cache warming replacing the removed plugin.

**Architecture:** Pure chezmoi source edits in a dotfiles repo (no application code, no test suite). Five source files lose their billion-context wiring, one gains a `compaction.modelThresholds` block with fixed `"f<tokens>"` triggers, and one runtime command uninstalls the npm package outside chezmoi. Validation is `chezmoi diff` / `chezmoi --dry-run apply` plus `mise run lint-report`, per `AGENTS.md`.

**Tech Stack:** chezmoi (Go templates + `private_`/`dot_` source-state naming), omp v18.15.0 (oh-my-pi) `config.yml`, mise, zsh, opencode JSONC.

**Spec:** `docs/superpowers/specs/2026-11-03-omp-context-compaction-design.md` (design approved in conversation; values in the Global Constraints table below are the spec).

## Global Constraints

- This is a chezmoi **source tree**. Never edit rendered files under `~` — edit the source path and let `chezmoi apply` render. Target names strip chezmoi attributes: `private_dot_omp/private_agent/private_config.yml.tmpl` → `~/.omp/agent/config.yml`.
- Shell indentation is **4 spaces** (`.editorconfig`); comments/messages in this repo are Brazilian Portuguese (pt-BR) and new comments keep that style.
- Commit messages use conventional commits (`feat:`, `fix:`, `chore:`, `docs:`).
- No test suite exists. The verification for every task is `chezmoi diff` (reviewable output) and `chezmoi --dry-run apply` (exit 0). A static non-mutating check is `mise run lint-report`.
- Exact compaction values, copied verbatim from the approved spec:

| `compaction.modelThresholds` key | Value | Rationale |
| --- | --- | --- |
| `anthropic/claude-opus-5-5` | `"f250000"` | 1M window, US$ 4.00/M input — hold the most expensive model down |
| `anthropic/claude-sonnet-5-5` | `"f300000"` | 1M window, US$ 2.00/M input |
| `google-antigravity/gemini-3.8-flash` | `"f400000"` | 1M window, US$ 0.75/M input — cheap, let it run wide |
| `xiaomi-token-plan-sgp/mimo-v2.6-pro` | `"f400000"` | 1M window, US$ 0.435/M input |
| `openai-codex/gpt-6-luna` | *(absent)* | 272k window; omp's default reserve policy already compacts near ~231k |

- `compaction.modelThresholdsEnabled` stays `true` (already the default; do not write it unless absent).
- `providers.cacheWarming` becomes `"auto"` (was `"off"`).
- `compaction.idleThresholdTokens` becomes `400000` (was `200000`).
- `disabledProviders` keeps exactly: `commandcode`, `alibaba-token-plan`, `gitlab-duo`, `gitlab-duo-agent`, `llama.cpp`, `minimax`, `opencode`, `zai`. `opencode-go` and `opencode-zen` are **removed** from the list.
- Everything else in `compaction`/`snapcompact`/`providers` is left untouched: `experimentalContextManagement: true`, `methodOrder`, `asyncEnabled`, `midTurnEnabled`, `snapcompact.systemPrompt: agents-md`, `snapcompact.toolResults: true`, `cacheRetention: auto`, `appendOnlyContext: auto`, `extendedContext: false`.
- The value syntax is omp's fixed trigger form `"f<tokens>"` — exact trigger point, **not** a token base that the 85%-scaling policy would reinterpret.

## Review Focus

1. **`f<tokens>` syntax silently rejected or rescaled.** omp's validator for `compaction.modelThresholds` accepts exactly three forms: a positive integer token count (e.g. `90000`, which the policy then *rescales* — 85% of it for bases above ~109k), a fixed trigger with **explicit digits** (`"f90000"`), or a percentage (`"80%"`). Two failure modes: writing `250000` instead of `"f250000"` makes Opus compact at ~212k, and writing the `k` shorthand `"f250k"` is **rejected outright** — the `f400k` form exists only in the `/models` hub UI, not in config. Pin it: assert the rendered values match `^"f[0-9]+"$`, and pass the map through `omp config set` in a throwaway `--profile` to prove the validator accepts it. *(Task 2, Step 3.)*
2. **Thinking-level suffix leaks into the threshold key.** `modelRoles` values are `anthropic/claude-sonnet-5-5:auto`, but `compaction.modelThresholds` keys are bare selectors (`anthropic/claude-sonnet-5-5`). A key with `:auto` matches nothing and the model silently falls back to the 85% default. Pin it: assert no key in the rendered block contains `:` after the model id. *(Task 2, Step 3.)*
3. **`extensions:` block left half-behind.** Removing the billion-context path but keeping an empty `extensions: []` key, or leaving the stale comment about cache warming, re-introduces confusion and possibly an empty-extension load. Pin it: assert the rendered `~/.omp/agent/config.yml` has no `extensions` key and no `billion`/`bili` substring. *(Task 1, Step 3.)*
4. **The zsh wrapper silently keeps routing through `bili`.** `aiagents.zsh.tmpl` builds `omp()` to call `command bili omp -- "$@"`. If only the `if` branch is removed and the wrapper is left calling `bili` unconditionally, every omp launch breaks when `bili` is uninstalled. Pin it: assert the rendered zsh file contains `command omp "$@"` and no `bili`. *(Task 4, Step 2.)*
5. **`mise uninstall` is destructive and outside chezmoi.** It deletes the `bili` shim and the npm package. It is a separate, explicitly approved step and must not be folded into `chezmoi apply`. Pin it: run it as its own step and confirm `command -v bili` then fails. *(Task 6.)*

---

### Task 1: Strip billion-context from the omp config template

**Files:**
- Modify: `private_dot_omp/private_agent/private_config.yml.tmpl` (the `extensions:` block at end of file; the `providers.cacheWarming` entry and its comment)

**Interfaces:**
- Consumes: nothing.
- Produces: a rendered `~/.omp/agent/config.yml` with `providers.cacheWarming: "auto"` and no `extensions` key. Task 2 edits the same file and must re-read it after this task.

- [ ] **Step 1: Record the current rendered output as the baseline**

Run: `chezmoi execute-template < private_dot_omp/private_agent/private_config.yml.tmpl > /tmp/omp-config-before.yml`
Expected: exit 0; `/tmp/omp-config-before.yml` contains `extensions:` and `billion-context`.

- [ ] **Step 2: Remove the `extensions:` block and its two comment lines; set `cacheWarming` to `auto` and rewrite its comment**

Delete from `private_dot_omp/private_agent/private_config.yml.tmpl`:

```yaml
# shortcut: caminho versionado do billion-context, atualize via bili plugin install omp
# se o mise bumpar a versao; upgrade: resolver dinamicamente no template
extensions:
  - {{ .chezmoi.homeDir }}/.local/share/mise/installs/npm-billion-context/0.1.212/lib/node_modules/billion-context/dist/agent/omp-native.js
```

Replace this pair:

```yaml
  # So o billion-context mantem o prompt-cache aquecido; sem warming duplicado.
  cacheWarming: "off"
```

with (pt-BR comment, same 2-space indent inside `providers:`):

```yaml
  # Aquecimento de prompt-cache no provider: auto respeita TTL e custo de cada um.
  cacheWarming: "auto"
```

The comment must not name the removed plugin — Task 1 Step 3 greps for it.

No other key in the file changes.

- [ ] **Step 3: Verify the render has no trace of the plugin and the new value is present**

Run: `chezmoi execute-template < private_dot_omp/private_agent/private_config.yml.tmpl | grep -nE 'billion|bili|extensions|cacheWarming'`
Expected: exactly one line, `cacheWarming: "auto"`. Any `billion`, `bili`, or `extensions` match is a failure.

- [ ] **Step 4: Commit**

```bash
git add private_dot_omp/private_agent/private_config.yml.tmpl
git commit -m "chore(omp): remove billion-context extension, enable native cache warming"
```

---

### Task 2: Add per-model compaction ceilings

**Files:**
- Modify: `private_dot_omp/private_agent/private_config.yml.tmpl` (the `compaction:` block)

**Interfaces:**
- Consumes: the file in its post-Task-1 state.
- Produces: `compaction.modelThresholds` map with exactly the four keys in the Global Constraints table. Nothing else depends on its shape.

- [ ] **Step 1: Record the rendered `compaction` block before the change**

Run: `chezmoi execute-template < private_dot_omp/private_agent/private_config.yml.tmpl | sed -n '/^compaction:/,/^snapcompact:/p' > /tmp/omp-compaction-before.yml`
Expected: exit 0; the file has no `modelThresholds` key.

- [ ] **Step 2: Add `modelThresholds` and raise `idleThresholdTokens` inside the `compaction:` block**

In `private_dot_omp/private_agent/private_config.yml.tmpl`, inside `compaction:`, add `modelThresholds` and change `idleThresholdTokens` so the block reads:

```yaml
compaction:
  # thresholdPercent não definido → OMP usa modo automático: max(16384, 15% da janela).
  # Tetos fixos por modelo: "f<tokens>" dispara no ponto exato, sem o escalamento
  # de 85% que o modo automatico aplica a bases de janela. Proporcionais ao custo
  # de input — os modelos de 1M de janela nao podem esperar os 85% (~850k).
  modelThresholds:
    "anthropic/claude-opus-5-5": "f250000"        # 1M janela, US$ 4,00/M — o mais caro
    "anthropic/claude-sonnet-5-5": "f300000"      # 1M janela, US$ 2,00/M
    "google-antigravity/gemini-3.8-flash": "f400000"  # 1M janela, US$ 0,75/M
    "xiaomi-token-plan-sgp/mimo-v2.6-pro": "f400000"  # 1M janela, US$ 0,435/M
    # openai-codex/gpt-6-luna (272k) fica no default: a politica usual ja
    # compacta perto de 231k, e o teto so se aplica a janelas maiores.
  idleEnabled: true
  # No topo da banda de trabalho: a compactacao ociosa a 200k descartaria
  # contexto que o teto do modelo ainda permitiria usar.
  idleThresholdTokens: 400000
  # Experimental: notas persistentes e histórico pesquisável entre janelas.
  experimentalContextManagement: true
  handoffSaveToDisk: true
```

Every other `compaction` sub-key keeps its current value and position.

- [ ] **Step 3: Verify the rendered thresholds are exact triggers on bare selectors**

Run: `chezmoi execute-template < private_dot_omp/private_agent/private_config.yml.tmpl | sed -n '/modelThresholds:/,/idleEnabled:/p'`
Expected: four entries, each value matching `^"f[0-9]+"$`, each key matching `^"provider/model-id"$` with **no** `:` anywhere after the slash (no `:auto`/`:low` suffix), and `idleThresholdTokens: 400000` present below. Then run `chezmoi execute-template < private_dot_omp/private_agent/private_config.yml.tmpl | grep -c 'modelThresholds'` → `1`.

- [ ] **Step 4: Commit**

```bash
git add private_dot_omp/private_agent/private_config.yml.tmpl
git commit -m "feat(omp): per-model compaction ceilings sized to input cost"
```

---

### Task 3: Drop `opencode-go` and `opencode-zen` from `disabledProviders`

**Files:**
- Modify: `private_dot_omp/private_agent/private_config.yml.tmpl` (the `disabledProviders:` list)

**Interfaces:**
- Consumes: the file in its post-Task-2 state.
- Produces: `disabledProviders` of length 8. No other task reads it.

- [ ] **Step 1: Remove the two list entries**

Delete exactly these two lines from `disabledProviders:` in `private_dot_omp/private_agent/private_config.yml.tmpl`:

```yaml
  - opencode-go
  - opencode-zen
```

Keep `opencode` and the other six entries untouched, preserving order.

- [ ] **Step 2: Verify the rendered list**

Run: `chezmoi execute-template < private_dot_omp/private_agent/private_config.yml.tmpl | sed -n '/^disabledProviders:/,/^[a-z]/p'`
Expected: eight `- ` entries — `commandcode`, `alibaba-token-plan`, `gitlab-duo`, `gitlab-duo-agent`, `llama.cpp`, `minimax`, `opencode`, `zai`. No `opencode-go` or `opencode-zen` line.

- [ ] **Step 3: Commit**

```bash
git add private_dot_omp/private_agent/private_config.yml.tmpl
git commit -m "feat(omp): enable opencode-go and opencode-zen providers"
```

---

### Task 4: Route the zsh `omp()` wrapper straight to omp

**Files:**
- Modify: `private_dot_config/zsh/aiagents.zsh.tmpl`

**Interfaces:**
- Consumes: nothing.
- Produces: a rendered `~/.config/zsh/aiagents.zsh` whose `omp()` still calls `zsh-load-tokens` and still exports `PONYTAIL_DEFAULT_MODE=ultra`, but execs `command omp`.

- [ ] **Step 1: Remove the `bili` branch from the wrapper**

In `private_dot_config/zsh/aiagents.zsh.tmpl`, replace the comment block and the `omp()` body:

```zsh
# Via `bili omp` quando disponivel: proxy de compressao de contexto (ACP),
# cobrindo tambem o trafego Anthropic/Cowork que o modo nativo nao alcanca.
export PONYTAIL_DEFAULT_MODE=ultra

omp() {
    zsh-load-tokens
    if (( $+commands[bili] )); then
        command bili omp -- "$@"
    else
        command omp "$@"
    fi
}
```

with (pt-BR comment, 4-space indent inside the function, matching the file):

```zsh
export PONYTAIL_DEFAULT_MODE=ultra

omp() {
    zsh-load-tokens
    command omp "$@"
}
```

The `PONYTAIL_DEFAULT_MODE` export stays; only the `bili` comment and branch go.

- [ ] **Step 2: Verify the render**

Run: `chezmoi execute-template < private_dot_config/zsh/aiagents.zsh.tmpl | grep -nE 'bili|omp\(\)|command omp|PONYTAIL|zsh-load-tokens'`
Expected: three lines — `PONYTAIL_DEFAULT_MODE=ultra`, `omp() {`, and `command omp "$@"` (plus the `zsh-load-tokens` line). No `bili` anywhere. Then `chezmoi execute-template < private_dot_config/zsh/aiagents.zsh.tmpl | grep -c bili` → `0`.

- [ ] **Step 3: Commit**

```bash
git add private_dot_config/zsh/aiagents.zsh.tmpl
git commit -m "fix(zsh): call omp directly instead of the bili compression proxy"
```

---

### Task 5: Remove billion-context from the mise, opencode and plugin-hook wiring

**Files:**
- Modify: `private_dot_config/mise/config.toml.tmpl` (the `npm:billion-context` entry and its two comment lines)
- Modify: `private_dot_config/opencode/opencode.jsonc` (the `"billion-context"` entry in `plugins`)
- Modify: `.chezmoiscripts/run_onchange_after_53-omp-plugins.sh.tmpl` (the `bili plugin install omp` block at the end)

**Interfaces:**
- Consumes: nothing.
- Produces: a mise tool list without `billion-context` (Task 6's `mise uninstall` reads the live mise state, not this file), an opencode plugin list of length 10, and a plugins hook that no longer shells out to `bili`. The script's hash comment lines (`OmpMarketplaces hash`, `OmpPlugins hash`) are untouched, so the hook's re-run trigger does not change.

- [ ] **Step 1: Remove the mise entry**

In `private_dot_config/mise/config.toml.tmpl`, delete:

```toml
# compressão de contexto (bili) — launcher `bili omp` e plugin nativo do opencode
# pinado: o resolve de "latest" para este pacote estoura o timeout do mise npm
"npm:billion-context" = "0.1.212"
```

Leave the surrounding tool entries and the `# MCP servers` comment block unchanged.

- [ ] **Step 2: Remove the opencode plugin entry**

In `private_dot_config/opencode/opencode.jsonc`, delete the `"billion-context",` line from the `plugins` array, leaving the comma structure of the remaining ten entries valid JSON.

- [ ] **Step 3: Remove the `bili` install block from the plugins hook**

In `.chezmoiscripts/run_onchange_after_53-omp-plugins.sh.tmpl`, delete the trailing block:

```bash
# billion-context: idempotente, resolve o caminho correto da versao instalada
if command -v bili >/dev/null 2>&1; then
    echo ":: bili plugin install omp"
    bili plugin install omp 2>&1
fi
```

The `failed` guard and `exit 1` block immediately above it must remain the end of the script.

- [ ] **Step 4: Verify all three renders**

Run: `chezmoi execute-template < private_dot_config/mise/config.toml.tmpl | grep -c billion` → `0`.
Run: `chezmoi execute-template < private_dot_config/opencode/opencode.jsonc | grep -c billion` → `0`.
Run: `chezmoi execute-template < .chezmoiscripts/run_onchange_after_53-omp-plugins.sh.tmpl | grep -cE 'billion|bili'` → `0`.
Run: `chezmoi execute-template < private_dot_config/opencode/opencode.jsonc | python3 -c "import json,sys,re; s=sys.stdin.read(); s=re.sub(r'^\s*//.*$','',s,flags=re.M); d=json.loads(s); print(len(d['plugins']))"` → `10`.

- [ ] **Step 5: Commit**

```bash
git add private_dot_config/mise/config.toml.tmpl private_dot_config/opencode/opencode.jsonc .chezmoiscripts/run_onchange_after_53-omp-plugins.sh.tmpl
git commit -m "chore: drop billion-context from mise tools, opencode plugins and omp plugin hook"
```

---

### Task 6: Uninstall the billion-context npm package (runtime, outside chezmoi)

**Files:**
- None in the repo. This mutates live mise state and is explicitly approved.

**Interfaces:**
- Consumes: Task 5 having removed the manifest entry (so nothing reinstalls it).
- Produces: no `bili` executable on PATH.

- [ ] **Step 1: Confirm what will be removed**

Run: `command -v bili && mise which bili`
Expected: a shim path under `~/.local/share/mise/shims/bili` resolving to the `npm:billion-context` install.

- [ ] **Step 2: Uninstall**

Run: `mise uninstall npm:billion-context`
Expected: exit 0.

- [ ] **Step 3: Verify the shim is gone and no repo file references it**

Run: `command -v bili` → exit 1 (not found).
Run: `grep -rniE 'billion|\bbili\b' private_dot_omp private_dot_config .chezmoiscripts dot_OmpPlugins 2>/dev/null | grep -v Binary` → no output. (Use `\bbili\b`, not bare `bili` — `private_dot_config/nvim/lua/polish.lua` contains the substring in "incompatibility".)

- [ ] **Step 4: Commit (nothing to commit; repo already clean from Tasks 1–5)**

Skip. Record the uninstall in the PR/summary text instead.

---

### Task 7: Whole-change validation

**Files:**
- None.

**Interfaces:**
- Consumes: Tasks 1–6 complete.
- Produces: evidence that the tree is consistent and applies cleanly.

- [ ] **Step 1: Review the full pending diff**

Run: `chezmoi diff`
Expected: only the six files above change; every removal is a deletion, every addition is the `modelThresholds` block, `cacheWarming: "auto"`, and `idleThresholdTokens: 400000`. No rendered file outside those targets moves.

- [ ] **Step 2: Dry-run apply**

Run: `chezmoi --dry-run apply`
Expected: exit 0, no template errors.

- [ ] **Step 3: Static lint report**

Run: `mise run lint-report`
Expected: exits 0 (non-blocking by design); no new YAML/TOML/JSONC syntax errors reported for the five edited files.

- [ ] **Step 4: Rendered omp config sanity check**

Run: `chezmoi execute-template < private_dot_omp/private_agent/private_config.yml.tmpl | python3 -c "import sys,yaml; d=yaml.safe_load(sys.stdin); print(d['compaction']['modelThresholds']); print(d['providers']['cacheWarming']); print(d['compaction']['idleThresholdTokens']); print(len(d['disabledProviders'])); print('extensions' in d)"`
Expected: the four-entry threshold map with `f`-prefixed strings, `auto`, `400000`, `8`, `False`.

- [ ] **Step 5: Report the applied state to the user**

Tell the user that `chezmoi apply` must run to render these into `~`, and that running it will also re-trigger the package-sync hooks described in `AGENTS.md`. Do not run `chezmoi apply` without asking — it writes to `~`.

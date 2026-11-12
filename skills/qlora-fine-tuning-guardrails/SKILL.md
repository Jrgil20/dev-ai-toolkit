---
name: qlora-fine-tuning-guardrails
description: >-
  Trigger: qlora, lora fine-tuning, synthetic dataset, mode collapse, disco rayado,
  peft training, llama-server context sizing. Audit and execute robust QLoRA/LoRA
  fine-tuning pipelines, prevent synthetic dataset mode collapse, enforce multi-turn
  conversational entropy, size multi-tenant inference contexts in llama-server,
  and validate PEFT adapter convergence on edge/remote compute.
---

# QLoRA & PEFT Fine-Tuning Guardrails Runbook

This skill establishes automated engineering guardrails and decision gates for fine-tuning Small Language Models (SLMs) using QLoRA / LoRA and serving them via `llama.cpp` (`llama-server`) or PyTorch.

It directly codifies post-mortem lessons from real-world failures: **synthetic dataset mode collapse**, **caricatured single-turn behavioral overfitting**, **KV cache context exhaustion in multi-slot servers**, and **unverified premature delivery**.

---

## 1. Quality Gates & Decision Matrix

Every fine-tuning workflow must pass 5 consecutive, non-negotiable gates before declaring completion:

```
[ Gate 1: Dataset Entropy ] ──> [ Gate 2: Multi-Turn Ratio ] ──> [ Gate 3: LoRA Hyperparameters ]
                                                                             │
[ Gate 5: E2E Conversational QA ] <── [ Gate 4: Runtime Context Sizing ] <───┘
```

| Gate | Verification Target | Strict Threshold | Failure Consequence |
| :--- | :--- | :--- | :--- |
| **G1: Dataset Entropy** | Top 3-word prefix repetition | **Max <= 10.0%** (< 20% hard limit) | Rejection / Mode collapse (*"disco rayado"*) |
| **G2: Conversational Balance** | Multi-turn dialogue ratio | **Min >= 35.0%** of total pairs | Overfitting to single-turn monologue caricature |
| **G3: Hyperparameter Safety** | LoRA Alpha to Rank ratio | **$\alpha / r \le 2.0$** (recommended 1.0) | Attention distortion, loss of base model fluency |
| **G4: Runtime Context Sizing** | KV cache slot allocation | **`-np 1` with `-c \ge 16384`** | Mid-chat amnesia, truncation, repetition loop |
| **G5: Pre-Delivery E2E Test** | Multi-turn simulated dialogue | **5 consecutive turns** audited | User forced to act as live bug tester |

---

## 2. Gate 1 — Synthetic Dataset Entropy & Anti-Monotony

**The Anti-Pattern**: Allowing a teacher LLM to generate synthetic training pairs without assert gates results in low-entropy attractor states (e.g. 88% starting with the same phrase).

### Hardening Protocol:
1. **Dynamic Teacher Prompting**:
   - Randomly sample 3 diverse few-shot demonstrations from a pool of at least 30 heterogeneous pairs for every batch.
   - Run teacher at `temperature >= 0.85` and `top_p >= 0.90`.
2. **Automated Assertion Gate (`assets/audit_dataset.py`)**:
   Run the audit script on the generated dataset before touching training hardware:
   ```bash
   python3 .agents/skills/qlora-fine-tuning-guardrails/assets/audit_dataset.py --dataset path/to/dataset.json --max-prefix-pct 10.0
   ```
   If the script exits with non-zero status, **do not train**. The dataset must be programmatically rebalanced first.

---

## 3. Gate 2 — Multi-Turn Conversational Cadence

**The Anti-Pattern**: Training 100% on single-turn pairs (`[Instruction -> 120-word speech]`) trains the adapter that $P(\text{monologue} \mid \text{any input}) \approx 1.0$. The model becomes unable to answer *"yes"*, ask clarifying questions, or maintain realistic dialogue pacing.

### Hardening Protocol:
1. **Dataset Split Distribution**:
   - **60% Single-Turn:** Direct domain answers, technical explanations, edge cases, negative/adversarial samples.
   - **40% Multi-Turn:** 3 to 5 turn dialogues with natural pacing:
     - *Turn 1:* Initial diagnosis + clarifying question back to user.
     - *Turn 2:* Brief colloquial response (*"Pásame la llave trece"*).
     - *Turn 3:* Grounded pragmatic resolution.
2. **Length Variation**: Ensure output lengths vary normally across 20 to 250 tokens; do not allow synthetic teachers to generate uniform-length walls of text.

---

## 4. Gate 3 — LoRA Hyperparameter Guardrails

| Hyperparameter | Safe Default | Dangerous Anti-Pattern | Rationale |
| :--- | :--- | :--- | :--- |
| `lora_rank` ($r$) | `8` or `16` | `64+` on <7B SLMs | High rank causes catastrophic forgetting of base pretraining. |
| `lora_alpha` ($\alpha$) | `8` (ratio 1.0) or `16` (ratio 2.0) | `32+` ($\alpha / r > 2.0$) | High alpha aggressively warps base model attention weights. |
| `learning_rate` | `1e-4` to `2e-4` | `> 5e-4` | Causes adapter gradient instability and loss divergence. |
| `num_train_epochs`| `2.0` to `3.0` | `5.0+` | Small synthetic datasets overfit within 2-3 epochs. |
| `warmup_steps` | `10` to `20` steps | `0` | Omitting warmup causes early gradient shocks to new adapters. |

### Validation Gate:
Monitor `eval_loss` every 20 steps. If `eval_loss` starts increasing while `train_loss` continues decreasing for 2 consecutive checkpoints, **halt training** (early stopping triggered).

---

## 5. Gate 4 — Serving Context Allocation in `llama-server`

**The Anti-Pattern**: Running `llama-server -c 4096` divides context across default parallel slots (`n_slots = 4`), leaving **only 1,024 tokens per conversation slot**. Multi-turn chats exhaust this budget within 3 turns, triggering silent context truncation (context-shifting) and amnesia.

### Hardening Protocol:
When deploying `llama-server` for interactive chat or evaluation:
1. **Explicit Slot Sizing**:
   Always pass `-np 1` (or specify slot budget matching your user concurrency):
   ```bash
   /path/to/llama-server \
       -m /path/to/model_q8.gguf \
       --host 0.0.0.0 \
       --port 8090 \
       -ngl 99 \
       -c 16384 \
       -np 1 \
       --repeat-penalty 1.15 \
       --temp 0.7
   ```
2. **Slot Formula**:
   $$\text{Tokens Available per User} = \frac{\text{Total Context Budget } (-c)}{\text{Parallel Slots } (-np)}$$
   Ensure `Tokens Available per User` is **at least 8,192 tokens** for conversational agents.

---

## 6. Gate 5 — Automated Pre-Delivery E2E Verification

**The Anti-Pattern**: Testing one single curl query and declaring success. The developer delivers an unusable endpoint that fails on turn 2.

### Hardening Protocol:
Before presenting any serving endpoint (GGUF or PyTorch) to the user, execute the automated multi-turn verification harness:
```bash
python3 .agents/skills/qlora-fine-tuning-guardrails/assets/e2e_healthcheck.py --url http://127.0.0.1:8090/v1/chat/completions --model maestro-yiyo
```

The script evaluates:
- Successful 5-turn multi-turn memory retention.
- Lexical diversity ratio ($> 0.45$ distinct tokens).
- Generation throughput ($> 15$ tok/s).
- Absence of looped or broken phrases.

---

## 7. Pre-Flight Checklist

Before announcing completion of any fine-tuning task:
- [ ] Synthetic dataset passed `audit_dataset.py` with top prefix $< 10\%$.
- [ ] Dataset contains verified multi-turn traces (or distinct pacing variations).
- [ ] Training loss and eval loss converged without divergent gap.
- [ ] `llama-server` explicitly configured with dedicated context slot (`-np 1`, `-c >= 16384`).
- [ ] Multi-turn automated test passed 5 consecutive turns without amnesia or repetition.
- [ ] Artifacts, recipes, and dataset commits documented with Conventional Commits.

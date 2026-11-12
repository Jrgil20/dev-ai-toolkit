#!/usr/bin/env python3
"""
Automated Multi-Turn Conversational Healthcheck
Enforces Gate 5 of the qlora-fine-tuning-guardrails skill.
"""
import argparse
import json
import sys
import time
import urllib.request
import urllib.error

TEST_DIALOGUE = [
    "Hola, ¿cómo estás?",
    "Tengo un problema: el carro me recalienta subiendo la autopista.",
    "¿Y qué repuesto le compro para resolver eso?",
    "¿Pero cuánto me va a costar esa broma?",
    "Listo compa, gracias por la ayuda."
]

def parse_args():
    parser = argparse.ArgumentParser(description="Multi-turn E2E conversational QA test for inference endpoints.")
    parser.add_argument("--url", default="http://127.0.0.1:8090/v1/chat/completions", help="Endpoint URL (default: http://127.0.0.1:8090/v1/chat/completions)")
    parser.add_argument("--model", default="maestro-yiyo", help="Model alias name")
    return parser.parse_args()

def main():
    args = parse_args()
    print("=" * 60)
    print("🤖 AUTOMATED MULTI-TURN E2E HEALTHCHECK")
    print(f"🌐 Target: {args.url} (Model: {args.model})")
    print("=" * 60)

    history = []
    total_tokens = 0
    total_time = 0.0

    for i, user_msg in enumerate(TEST_DIALOGUE, 1):
        print(f"\n[Turn {i}/5] User: {user_msg}")
        history.append({"role": "user", "content": user_msg})

        payload = {
            "model": args.model,
            "messages": history,
            "temperature": 0.7,
            "max_tokens": 150
        }

        req = urllib.request.Request(
            args.url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )

        t0 = time.time()
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except Exception as e:
            print(f"❌ Connection or Inference Error: {e}")
            sys.exit(1)
        elapsed = time.time() - t0

        bot_msg = data["choices"][0]["message"]["content"].strip()
        history.append({"role": "assistant", "content": bot_msg})

        tokens = len(bot_msg.split())
        total_tokens += tokens
        total_time += elapsed
        speed = tokens / elapsed if elapsed > 0 else 0

        print(f"🤖 Bot: {bot_msg[:100]}..." if len(bot_msg) > 100 else f"🤖 Bot: {bot_msg}")
        print(f"⏱️ {elapsed:.2f}s | ~{tokens} words | {speed:.1f} words/s")

        if len(bot_msg) < 5:
            print("❌ FAILED: Bot returned empty or truncated response.")
            sys.exit(2)

    # Diversity audit across conversation
    all_words = " ".join([m["content"] for m in history if m["role"] == "assistant"]).lower().split()
    unique_ratio = len(set(all_words)) / len(all_words) if all_words else 0
    print("\n" + "=" * 60)
    print(f"📊 SUMMARY: 5 turns completed in {total_time:.2f}s ({total_tokens} total words)")
    print(f"🔤 Lexical Diversity: {unique_ratio:.1%} unique words (Threshold: > 35%)")

    if unique_ratio < 0.35:
        print("❌ FAILED: Response diversity too low (model is looping / repeating phrases).")
        sys.exit(3)

    print("✅ E2E MULTI-TURN HEALTHCHECK PASSED!")
    print("=" * 60)
    sys.exit(0)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Synthetic Dataset Entropy & Anti-Monotony Auditor
Enforces Gate 1 of the qlora-fine-tuning-guardrails skill.
"""
import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser(description="Audit fine-tuning datasets for mode collapse and monotony.")
    parser.add_argument("--dataset", required=True, type=Path, help="Path to JSON dataset (Alpaca or ShareGPT format)")
    parser.add_argument("--max-prefix-pct", type=float, default=10.0, help="Maximum allowed percentage for the top 3-word prefix (default: 10.0%)")
    parser.add_argument("--min-samples", type=int, default=100, help="Minimum required samples (default: 100)")
    return parser.parse_args()

def extract_outputs(data: list) -> list[str]:
    outputs = []
    for item in data:
        if isinstance(item, dict):
            if "output" in item and item["output"]:
                outputs.append(str(item["output"]).strip())
            elif "conversations" in item: # ShareGPT
                bot_turns = [t["value"] for t in item["conversations"] if t.get("from") in ("gpt", "assistant")]
                outputs.extend(bot_turns)
    return outputs

def main():
    args = parse_args()
    if not args.dataset.exists():
        print(f"❌ Error: Dataset file not found: {args.dataset}")
        sys.exit(1)

    with open(args.dataset, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        print("❌ Error: Dataset must be a JSON array of objects.")
        sys.exit(1)

    total_samples = len(data)
    outputs = extract_outputs(data)

    print("=" * 60)
    print("🔍 DATASET ENTROPY & MONOTONY AUDIT")
    print(f"📁 File: {args.dataset.name}")
    print(f"📊 Total items: {total_samples} | Extracted outputs: {len(outputs)}")
    print("=" * 60)

    if total_samples < args.min_samples:
        print(f"❌ FAILED: Dataset has {total_samples} samples, required minimum is {args.min_samples}.")
        sys.exit(1)

    # 1. Analyze 3-word prefixes
    tri_grams = [" ".join(re.findall(r"\w+", o.lower())[:3]) for o in outputs if len(re.findall(r"\w+", o)) >= 3]
    counts_3g = Counter(tri_grams)
    top_3g, top_count = counts_3g.most_common(1)[0]
    top_pct = (top_count / len(tri_grams)) * 100 if tri_grams else 0

    print(f"\n[Prefix Analysis] Top 3-word prefix: '{top_3g}'")
    print(f"  Count: {top_count} / {len(tri_grams)} ({top_pct:.1f}%) | Limit: <= {args.max_prefix_pct:.1f}%")

    print("\nTop 5 most frequent 3-word prefixes:")
    for prefix, count in counts_3g.most_common(5):
        pct = (count / len(tri_grams)) * 100
        print(f"  - '{prefix}': {count} ({pct:.1f}%)")

    # 2. Length variation check
    lengths = [len(o.split()) for o in outputs]
    avg_len = sum(lengths) / len(lengths) if lengths else 0
    min_len, max_len = min(lengths) if lengths else 0, max(lengths) if lengths else 0
    print(f"\n[Length Distribution] Avg: {avg_len:.1f} words | Min: {min_len} | Max: {max_len}")

    # Final verdict
    print("\n" + "=" * 60)
    if top_pct > args.max_prefix_pct:
        print(f"❌ AUDIT FAILED: Prefix repetition of {top_pct:.1f}% exceeds limit of {args.max_prefix_pct:.1f}%.")
        print("⚠️ Mode collapse risk: Rebalance your dataset before training!")
        sys.exit(2)
    else:
        print(f"✅ AUDIT PASSED: Prefix repetition ({top_pct:.1f}%) is within safe bounds (<= {args.max_prefix_pct:.1f}%).")
        print("=" * 60)
        sys.exit(0)

if __name__ == "__main__":
    main()

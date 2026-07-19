# Step 13 — Scoring Engine

The scoring layer converts governed account evidence into reproducible priority decisions.

## Control model

Model → immutable version → factors → rules → score run → account score → factor components.

Production scores retain the exact model version, input snapshot, factor contribution, confidence, explanation, and evidence references used at calculation time. Model edits create a new version; they never rewrite historical scores.

## Factor types

- Calculated: deterministic values from accepted operational data.
- AI-assisted: bounded model judgment requiring evidence and confidence.
- Manual: authorized user assessment with audit history.
- Hard exclusion: overrides the numeric score and records an explicit reason.

## Runtime safeguards

Active non-exclusion weights must total 100. Inputs are clamped to 0–100. Simulations are isolated from production score runs. Account tiers are derived from versioned thresholds. AI-assisted factors cannot silently replace verified facts.

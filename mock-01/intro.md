# CKA 2025 — Mock Exam

This scenario presents the full 15-question CKA mock exam from `questions.md` as an interactive Killercoda exercise. Each question is a separate step with built-in verification.

## Environment

| Killercoda node | CKA exam equivalent |
|---|---|
| `controlplane` | control-plane / node01 |
| `node01` | worker / node02 |

Questions that reference SSH to a node, node names in manifests, or `kubectl drain` use the names above.

## Rules (exam conditions)

Only the following documentation is permitted:

- `kubernetes.io/docs`
- `kubernetes.io/blog`
- `gateway-api.sigs.k8s.io`
- `helm.sh/docs`

## Time budget

The real CKA gives ~2 hours for 15–20 questions. Aim to finish this set in **2 h 15 min**. If you exceed 15 minutes on any single question, skip and return later — exactly as you would on exam day.

## Score breakdown

| Weight | Questions |
|---|---|
| 8% | Q1, Q5, Q8, Q13 |
| 7% | Q2, Q3, Q12 |
| 6% | Q4, Q10, Q15 |
| 5% | Q6, Q7, Q9, Q11, Q14 |
| 4% | Q11 |

## Setup

The background script is creating the prerequisite resources (namespaces, pre-existing Deployments, backup directory). Wait for "**Setting up exam environment…**" to disappear before starting Q1.

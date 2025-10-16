# Project: Autonomous AI Software Development Team

## Vision

To create a fully autonomous software development lifecycle (SDLC) managed by a central **Orchestrator Agent** that dispatches tasks to a fleet of specialized, **on-demand Worker Agents**. This system, triggered by `@claude` mentions, uses a persistent orchestrator to manage the entire workflow, from planning to final review, while dynamically provisioning containerized environments tailored to each specific task.

## Core Principles

1.  **GitHub-Native Orchestration:** A central, persistent **Orchestrator Runner** manages the workflow entirely within the GitHub Actions ecosystem.
2.  **On-Demand Worker Agents:** The Orchestrator dispatches tasks to ephemeral, on-demand runners, each configured for a specific job.
3.  **Label-Driven Status:** The Orchestrator manages and tracks progress by applying and updating labels on the relevant GitHub issue or PR (e.g., `status:planning`, `status:coding`).
4.  **Persona-Driven Execution:** Each Worker Agent assumes a specific **System Prompt Persona** (e.g., "Senior QA Engineer") to execute its task with the appropriate expertise.
5.  **Mention-Driven Workflow:** The entire process is initiated by a simple `@claude` trigger in an issue or PR.
6.  **Human-in-the-Loop Oversight:** The final merge and deployment approval remains a critical human checkpoint.

---

## System Architecture: The "In-GitHub" Orchestrator Model

This model keeps the entire SDLC process within GitHub Actions, using a persistent runner for orchestration and dynamic runners for execution.

#### 1. The Orchestrator Runner (The Project Manager)

This is a **single, persistent, self-hosted GitHub Actions runner** that is always on, waiting for a job. It is the master controller of the workflow.

*   **Responsibilities:**
    *   **Listens** for `@claude` mentions via the primary `claude.yml` workflow.
    *   **Plans:** Runs a long-running script that analyzes the user's request and breaks it down into a sequence of steps.
    *   **Manages State via Labels:** Updates the GitHub issue with labels to reflect the current status (e.g., `status:planning`, `status:coding`, `status:testing`).
    *   **Dispatches & Waits:** Triggers the correct Worker Agent for each step using `workflow_dispatch`. It then **waits** for the worker job to complete before proceeding to the next step.
    *   **Communicates:** Posts the plan, progress updates, and final summaries to the GitHub issue or PR.

#### 2. On-Demand Worker Agents (The Specialists)

These are **ephemeral, stateless GitHub Actions runners** launched by the Orchestrator for a single, well-defined task.

*   **Responsibilities:**
    *   **Execute a single task:** A Worker's job is simple (e.g., "run all linting checks" or "implement the function described in the prompt").
    *   **Embody a Persona:** The workflow file for each worker defines a specific **System Prompt Persona** that guides the AI's behavior for that task.
    *   **Utilize Custom Environments:** Each Worker runs in a custom Docker image containing the baseline stack (e.g., Node.js, Python) required for its persona and task. These images will be defined and built as needed.

---

## The Refined Workflow Lifecycle

1.  **Trigger:** A user mentions `@claude` in an issue or PR.
2.  **Orchestration:** The `claude.yml` workflow is triggered and assigns the job to the dedicated, always-on **Orchestrator Runner**.
3.  **Planning & Labeling (Orchestrator):**
    *   The Orchestrator Runner starts its master script.
    *   It analyzes the request, generates a plan, and posts it as a comment.
    *   It applies a label to the issue, e.g., `status: planning`.
4.  **Dispatch, Wait, & Update (Orchestrator -> Worker):**
    *   The Orchestrator script determines the first step is "linting". It updates the label to `status: linting`.
    *   It uses the `gh` CLI to trigger a `workflow_dispatch` for the `lint-worker.yml` workflow.
    *   The script then enters a wait state (e.g., using `gh run watch`) until the linting job is finished.
5.  **Continuous Loop (Orchestrator):**
    *   Upon completion of the worker job, the Orchestrator script regains control.
    *   It updates the label for the next step (e.g., `status: testing`) and dispatches the `test-worker.yml`.
    *   This **Dispatch -> Wait -> Update** loop continues for all steps in the plan, providing a transparent, real-time view of progress directly on the GitHub issue.
6.  **Completion:**
    *   Once all steps are complete, the Orchestrator script posts a final summary and updates the issue with a `status: complete` label.
    *   It then awaits further instructions or human review for a PR merge.
# Project: Autonomous AI Software Development Team

## Vision

To create a fully autonomous software development lifecycle (SDLC) managed by a central **Orchestrator Agent** that dispatches tasks to a fleet of specialized, **on-demand Worker Agents**. This system, triggered by `@claude` mentions, uses a persistent orchestrator to manage the entire workflow, from planning to final review, while dynamically provisioning containerized environments tailored to each specific task.

## Core Principles

1.  **Orchestrator-Worker Model:** A central, stateful **Orchestrator** manages the "what" and "why," while ephemeral, specialized **Workers** handle the "how."
2.  **On-Demand Infrastructure:** Worker runners are created dynamically for each task, equipped with the precise tools needed (e.g., a Python environment, a Node.js environment), and are terminated upon completion to save resources.
3.  **Continuous Status Reporting:** The Orchestrator provides real-time progress updates directly in the GitHub issue or PR, offering a transparent view of the AI's thought process and actions.
4.  **Mention-Driven Workflow:** The entire process is initiated by a simple `@claude` trigger, which now serves as a request to the central Orchestrator.
5.  **Human-in-the-Loop Oversight:** The final merge and deployment approval remains a critical human checkpoint.

---

## System Architecture: The Orchestrator-Worker Model

This model separates the system into two distinct components: a single, persistent Orchestrator and multiple, ephemeral Workers.



#### 1. The Orchestrator Agent (The Project Manager)

This is a **long-running, stateful service** (e.g., a dedicated Docker container running a web service like FastAPI or Express). It does *not* run as a standard, ephemeral GitHub Actions job.

* **Responsibilities:**
    * **Listens** for incoming tasks triggered by the lightweight GitHub Action.
    * **Maintains State:** Tracks the progress of every task across multiple steps (e.g., "Task #123: Step 2 of 5 - In QA").
    * **Plans:** Analyzes the initial request and breaks it down into a sequence of executable steps.
    * **Dispatches:** Triggers the correct on-demand Worker Agent for each step.
    * **Communicates:** Acts as the sole communicator with GitHub, posting plans, status updates ("*Step 1/3: Coding the API routes...*"), and final summaries in the relevant issue or PR.

#### 2. On-Demand Worker Agents (The Specialists)

These are **ephemeral, stateless GitHub Actions runners** that are created and destroyed for a single job.

* **Responsibilities:**
    * **Execute a single task:** A Worker's job is simple and well-defined (e.g., "run `npm install` and `npm test`," or "write the Python function defined in this prompt").
    * **Specialized Environments:** Each Worker runs in a Docker container pre-configured for its task. You can have `python-worker:latest`, `node-worker:latest`, `qa-worker:latest`, each with the necessary libraries and tools baked in.
    * **Report Back:** Upon completion (success or failure), it reports the result back to the Orchestrator.

---

## The Refined Workflow Lifecycle

1.  **Trigger:** A user mentions `@claude` in an issue.
2.  **Notification:** A very lightweight `claude.yml` workflow fires. Its **only job** is to send a webhook (API call) to the running **Orchestrator Agent**, passing along the payload from the GitHub event.
3.  **Planning & Acknowledgement (Orchestrator):**
    * The Orchestrator receives the webhook and acknowledges the task.
    * It immediately posts a comment to the issue: "*Acknowledged. I am analyzing the request and will post a plan shortly.*"
    * It generates the implementation plan and posts it as a new comment or checklist in the issue.
4.  **Dispatch & Execution (Orchestrator -> Worker):**
    * The Orchestrator decides the first step is "Add dependencies to `package.json`" and requires a Node.js environment.
    * It uses the GitHub API to trigger a `workflow_dispatch` event for a `node-worker.yml` workflow, passing the specific instructions.
    * A new, on-demand runner spins up, runs the `node-worker` job, commits the changes to a new branch, and signals completion back to the Orchestrator.
5.  **Continuous Update & Loop (Orchestrator):**
    * The Orchestrator receives the completion signal.
    * It updates the GitHub comment: "*✅ Step 1/3: Dependencies added. Now dispatching QA worker to run tests...*"
    * It then triggers the `qa-worker.yml` workflow to validate the changes. This loop (Dispatch -> Execute -> Update) continues for all steps in the plan.
6.  **Handling Feedback & Completion:**
    * If a human provides feedback (`@claude, use version 2.0 of that library`), the webhook is sent to the Orchestrator, which adjusts its current plan and re-dispatches workers as needed.
    * Once all steps are complete, the Orchestrator finalizes the PR, requests human review, and awaits further instructions.
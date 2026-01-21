# Playbook: How to Create a New Agent Playbook

*Status: Stable*

This playbook outlines the standard procedure for an AI Agent to create a new operational playbook for the cc1101_tcp project. Playbooks are essential for standardizing complex tasks, troubleshooting, and development workflows.

## 1. Prerequisites & Context Gathering

**CRITICAL STEP**: Before attempting to write a new playbook, you must establish a complete mental model of the system. Do not skip this.

1.  **Read the Root Documentation**:
    *   `README.md`: Understand the project's design parameters, `rtl_tcp` compatibility goals, and current state.
    *   `AGENTS.md`: Understand the organizational structure, guidelines, and role of agents.
2.  **Verify Current State**:
    *   Check `playbooks/` to ensure a similar playbook does not already exist.

## 2. When to Create a Playbook

Create a new playbook when:
*   **Complexity**: A task involves more than 3 distinct steps or spans multiple domains.
*   **Repetition**: The user asks for the same multi-step operation frequently.
*   **Troubleshooting**: You successfully solve a difficult error and want to document the fix for future agents.
*   **Workflow**: A new feature is added that requires a specific deployment or testing sequence.

## 3. Drafting the Playbook

### Filename Convention
*   Use **verbose, descriptive filenames** using snake_case.
*   The filename should be a sentence fragment that answers "What is this for?".
*   *Bad*: `deploy.md`, `fix_error.md`
*   *Good*: `how_to_deploy_firmware_updates.md`, `troubleshooting_offline_nodes.md`

### File Structure
Start with the following template:

```markdown
# Playbook: [Title of the Task]

*Status: [Draft | Stable | Deprecated]*

## Objective
A 1-sentence summary of what this playbook achieves.

## Prerequisites
*   Tools required (e.g., PowerShell, Arduino CLI).
*   Access required (e.g., Local Network, USB Cable).

## Step-by-Step Instructions
1.  **Step Name**: 
    *   Command to run.
    *   Expected output.
    *   What to do if it fails.

## Verification
How to confirm the task was successful.
```

## 4. Writing Guidelines

*   **Be Specific**: Do not say "Run the script." Say "Run `.\scripts\build.ps1`" (or the appropriate command).
*   **Anticipate Failure**: If a step is prone to error (like network timeouts), provide a specific remediation sub-step.
*   **Code-First**: Where possible, reference specific scripts in the repo rather than writing long manual terminal commands.
*   **Idempotency**: Playbooks should ideally be repeatable without breaking the system.

## 5. Finalizing

1.  Save the file to `playbooks/`.
2.  (Optional) If this is a major workflow, mention it in `AGENTS.md` under the "Agent Playbooks" section.

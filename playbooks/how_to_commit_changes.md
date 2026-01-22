# Playbook: How to Commit Changes

*Status: Stable*

## Objective
Safely stage, review, and commit changes to the repository with a descriptive, user-approved message. This ensures that the git history remains clean, strictly relevant, and accurately described.

## Prerequisites
*   Git initialized in the workspace.
*   Pending changes (modified, added, or deleted files).

## Step-by-Step Instructions

### 1. Check Workspace Status
Before assuming anything, check the state of the repo to see what files have been changed.

*   **Action**: `run_in_terminal`
*   **Command**: `git status`
*   **Analysis**: Identify which files are staged, which are modified but unstaged, and which are untracked.

### 2. Review Detailed Diffs
An agent must **never** commit blindly. You must read the actual diffs to ensure no debug code, secrets, or unintentional deletions are included.

*   **Action**: `get_changed_files` (or `run_in_terminal` with `git diff`)
*   **Command**: `git diff` (for unstaged) and `git diff --cached` (for staged).
*   **Analysis**: Summarize the changes for yourself.
    *   *Self-Correction*: If you see `secrets.h` or temporary log files being tracked, **STOP**. Add them to `.gitignore` first.

### 3. Propose Commit Strategy
Present a plan to the user. Do not execute the commit yet.

*   **Format**:
    ```text
    I have analyzed the changes:
    - [File A]: [Brief summary of change]
    - [File B]: [Brief summary of change]

    start_edit
    Proposed Commit Message:
    [Short Subject Line]
    
    [Optional Body identifying specific additions/fixes]
    end_edit
    
    Shall I proceed with this commit?
    ```

### 4. Execute Commit (After Approval)
Once the user confirms "Yes" or approves the plan:

1.  **Stage Files**:
    *   Command: `git add .` (or specific files if requested).
2.  **Commit**:
    *   Command: `git commit -m "Subject Line" -m "Optional Body"`
3.  **Verify**:
    *   Command: `git log -1`
    *   Confirm the commit hash and message are correct.

## Verification
*   The `git log -1` output shows the new commit with the correct author and message.
*   `git status` returns "working tree clean" (unless you intentionally left files out).

# Git Hooks

This project uses versioned Git hooks to maintain code quality and standards.

## Configuration

Hooks are configured to run automatically from this folder:

```bash
git config core.hooksPath scripts/git-hooks
```

## Requirements

- **Gitleaks**: A tool for detecting leaked secrets in the code.
  - Windows: `choco install gitleaks -y`
  - Linux/macOS: `brew install gitleaks`
  - Or download the binary: https://github.com/gitleaks/gitleaks/releases

## Available Hooks

### pre-commit

Scans staged files for **leaked secrets** (API keys, tokens, passwords, etc.) using Gitleaks.

**What is checked:**

- API keys (OpenAI, AWS, Google, Stripe, Mercado Pago)
- Authentication tokens (Bearer, JWT, Slack)
- Private keys (PEM/RSA)
- Database connection strings
- Sensitive Firebase configurations
- Suspicious environment variables

**Configuration:** Rules are defined in [.gitleaks.toml](../../.gitleaks.toml)

**If the hook blocks your commit:**

1. Remove the secret from the code.
2. Use environment variables (.env) that are not versioned.
3. If it is a false positive, add it to the allowlist in .gitleaks.toml.

### commit-msg

Validates that commit messages follow the **Conventional Commits** standard.

**Accepted format:**

```
type(scope): description
```

**Valid types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Tests
- `build`: Build system
- `ci`: Continuous integration
- `chore`: General tasks
- `revert`: Revert commits

**Valid examples:**

- `feat: add new feature`
- `fix(auth): fix token validation`
- `docs(readme): update instructions`

**Invalid examples:**

- `add new feature` ❌
- `Fix bug` ❌
- `WIP` ❌

## Setup on New Clone

After cloning the repository:

1. **Install Gitleaks** (if you haven't already):

   ```bash
   # Windows with Chocolatey
   choco install gitleaks -y

   # Linux/macOS with Homebrew
   brew install gitleaks
   ```

2. **Configure Git to use the hooks:**
   ```bash
   git config core.hooksPath scripts/git-hooks
   ```

````

On Windows with Git Bash, the hooks should work automatically.

## Note on Permissions

On Linux/macOS, you may need to grant execution permissions:

```bash
chmod +x scripts/git-hooks/*
````

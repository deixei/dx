# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**dx** is a Bash CLI tool suite for recurring development tasks on Linux/Ubuntu. It installs shell scripts to `/opt/dxtools` and provides a unified `dx` command for git, Azure, Ansible, and developer tooling workflows.

## Installation & Setup

```bash
chmod +x ./install.sh
sudo ./install.sh [--tools_folder /path] [--user_path /home/user]
dx config init    # creates ~/.dx/config.ini and updates .bashrc
```

## There Are No Automated Tests

All testing is manual. When modifying commands, verify by running the relevant `dx` subcommand and documenting observed output.

## Architecture

**Command dispatcher pattern:** `dx.sh` parses the first argument and routes to the corresponding module in `scripts/`.

```
dx <command> [options]
    → dx.sh (dispatcher, also handles: me, venv, --help, --version, --update)
        → sources scripts/common.sh (logging, colors, config loading)
        → sources scripts/<command>.sh (command implementation)
```

**Key modules:**
- `scripts/common.sh` — shared utilities sourced by all modules: `print_error`, `print_info`, `print_warning`, `print_success`, `load_config`, color constants, global path variables
- `scripts/config.sh` — manages `~/.dx/config.ini` (git, Azure, service principals)
- `scripts/ansible.sh` — builds/tests Ansible collections, discovers `galaxy.yml` files
- `scripts/azcli.sh` — Azure CLI wrappers (login, subscriptions, resource groups, REST)
- `scripts/install.sh` — installs Python, pip, Ansible, dev tools via apt/pip
- `scripts/git.sh` — repo cloning with URL auto-parsing (GitHub/ADO)
- `scripts/cookiecutter.sh` — project scaffolding via cookiecutter

**Stub modules** (minimal implementation): `ado.sh`, `github.sh`

## Configuration System

- User config: `~/.dx/config.ini` — simple `key=value` format
- Environment export: `user_config/exporting_vars.sh` reads the INI and exports keys as uppercase env vars (e.g., `git_name` → `GIT_NAME`)
- Template/defaults: `user_config/config.ini`

## Shell Script Conventions

All scripts use:
- `set -euo pipefail` with `IFS=$'\n\t'`
- `trap 'print_error "Error on line $LINENO."' ERR`
- Logging via `common.sh` functions (not raw `echo`)

## Adding a New Command

Use `scripts/cmd_template.sh` as the starting point. Add routing in `dx.sh`'s case statement.

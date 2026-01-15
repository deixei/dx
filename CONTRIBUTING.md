# Contributing to dx

Thanks for your interest in contributing! This project is a collection of shell
helpers for Linux/Ubuntu workflows, and we welcome improvements to scripts,
documentation, and examples.

## Getting started

1. Fork the repository and create a new branch for your change.
2. Clone your fork locally.
3. Install dependencies and set up the tool locally if needed:

   ```bash
   chmod +x ./install.sh
   sudo ./install.sh
   ```

4. Initialize your configuration:

   ```bash
   /opt/dxtools/dx.sh config init
   ```

## Making changes

- Keep changes focused and aligned with the existing script structure.
- Update documentation when behavior or commands change.
- Prefer small, incremental commits for easier review.

## Testing

There are currently no automated tests in this repository. When possible,
include manual verification steps in your pull request description (for example,
which `dx` commands you exercised and what output you observed).

## Submitting a pull request

1. Push your branch to GitHub.
2. Open a pull request using the provided template.
3. Describe the problem, the solution, and any manual testing performed.

## Reporting issues

Please use the issue templates to report bugs or request features. Include clear
steps to reproduce issues and the environment details (OS, shell, and any
relevant versions).

## Code of Conduct

Please review our [Code of Conduct](CODE_OF_CONDUCT.md) before participating in
this project.

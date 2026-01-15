# dx

Command-line helper for recurring development tasks on Linux/Ubuntu. It installs a
collection of shell scripts under `/opt/dxtools` (or a custom path) and exposes
the `dx` command for common workflows.

## Requirements

- Linux/Ubuntu with bash
- git
- sudo/root permissions to run `install.sh`
- Optional: python3 for the `dx venv` helpers

## Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/deixei/dx.git
cd dx
chmod +x ./install.sh
sudo ./install.sh
```

### Custom paths

In case you are not running as root, pass the target user home path:

```bash
sudo ./install.sh --user_path /home/your-user
```

If you need to change the installation folder:

```bash
sudo ./install.sh --tools_folder /folder/name
```

## Configuration

After install, initialize the user configuration from the installation folder:

```bash
/opt/dxtools/dx.sh config init
```

Restart your terminal so `dx` is available on your PATH. To reset the
configuration later, run:

```bash
dx config init
```

## Usage

See the full help output with:

```bash
dx --help
```

Common commands include:

```bash
dx config init
dx git <args>
dx ado <args>
dx ansible <args>
dx install <args>
dx me
dx venv -v|-a|-d
dx --update
```

## Self updating

By executing the update option you get the latest from the repo. This will break
your default configuration.

```bash
dx --update
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for
setup and workflow guidance.

## Code of Conduct

Please review our [Code of Conduct](CODE_OF_CONDUCT.md) before contributing.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).

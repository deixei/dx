# dx
Linux / Ubuntu command line for recurrent commands

```bash
git clone https://github.com/deixei/dx.git
```

## Setup

After downloading the repo, change permission for install.sh

```bash
chmod +x ./install.sh

./install.sh
```

In case you are not running as root

```bash
sudo ./install.sh --user_path /home/marcio
```

If you need to change the installation folder

```bash
sudo ./install.sh --tools_folder /folder/name
```

Next run the user configuration init from the installation folder

```bash
/opt/dxtools/dx.sh config init
```

Restart your terminal, and now you have dx command available.

## Reset configuration init

To run the configuration for the user, start by making an initialization, to move the defaults to your user path.

```bash
dx config init
```

## Self updating

By executing the update option you get the latest form the repo, this will break your default configuration.

```bash
dx --update
```

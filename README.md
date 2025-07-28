# Visual Studio Code opensource #

## Why? ##

Pristine VSCode OSS build, result of 'systems primitivism' R&D - 'as much benefits from as simple toolbox as possible'

## How ? ##

Linux with docker & docker-compose, user with UID/GID 10001, a member of docker group, enough disk space in ```${HOME}``` (Drive C: in Windows) to store source and build files

[Windows host](win.txt)

Both Linux and Windows expect a ```.github_token``` file in ```${HOME}``` for archive upload

Linux Swapfile (1.98.0 on)

```sudo mkswap -U clear --size 16G --file /swapfile```

Put ```/swapfile none swap defaults 0 0``` to ```/etc/fstab```

### Linux with Docker ###

In ```.env``` adjust ```DISTRO``` variable to any of ```{debian,fedora}```

```shell
mkdir -p ${HOME}/vscode-buildbed
```

```shell
DISTRO=debian DUMMY_UID=`id -u` DUMMY_GID=`id -g` docker-compose run --build --rm vscode
```

or

```shell
DISTRO=fedora DUMMY_UID=`id -u` DUMMY_GID=`id -g` docker-compose run --build --rm vscode
```

### Windows or docker-free Linux ###

Git Bash

```shell
./entrypoint.sh
```

### Installation & setup tweaks ###

Untar, copy-paste an extensionsGallery to ```resources/app/product.json```

### Limitations ###

[netcoredbg](https://wiki.archlinux.org/title/Talk:Visual_Studio_Code) as [vsdbg is only available in Microsoft Visual Studio Code](https://github.com/OmniSharp/omnisharp-vscode/wiki/Microsoft-.NET-Core-Debugger-licensing-and-Microsoft-Visual-Studio-Code)

[Pyright](https://marketplace.visualstudio.com/items?itemName=ms-pyright.pyright) as OSS replacement for [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance)

### License ###

Perl "Artistic License"

# Visual Studio Code opensource #

## Why? ##

Pristine VSCode OSS build, result of 'systems primitivism' R&D - 'as much benefits from as simple toolbox as possible'

## How ? ##

Linux with docker & docker-compose, user with UID/GID 10001, a member of docker group, enough disk space in ```${HOME}``` (Drive C: in Windows) to store source and build files

[Windows host](win.txt)

Both Linux and Windows expect a ```.github_token``` file in ```${HOME}``` for archive upload

### Linux with Docker ###

```shell
docker-compose run --rm vscode
```

### Windows or docker-free Linux ###

Git Bash

```shell
./entrypoint.bash
```

### Installation & setup tweaks ###

Untar, copy-paste an extensionsGallery to ```resources/app/product.json```

### Limitations ###

[netcoredbg](https://wiki.archlinux.org/title/Talk:Visual_Studio_Code) as [vsdbg is only available in Microsoft Visual Studio Code](https://github.com/OmniSharp/omnisharp-vscode/wiki/Microsoft-.NET-Core-Debugger-licensing-and-Microsoft-Visual-Studio-Code)

[Pyright](https://marketplace.visualstudio.com/items?itemName=ms-pyright.pyright) as OSS replacement for [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance)

### License ###

Perl "Artistic License"

# Visual Studio Code opensource #

## Why? ##

Pristine VSCode OSS build, result of 'systems primitivism' R&D - 'as much benefits from as simple toolbox as possible'

## How ? ##

Linux with docker & docker-compose, user with UID/GID 10001, a member of docker group, enough disk space in ```${HOME}``` (Drive C: in Windows) to store source and build files

[Windows host](win.txt)

Both Linux and Windows expect a ```.github_token``` file in ```${HOME}``` for archive upload

### Linux ###

```shell
docker-compose run --rm vscode
```

### Windows ###

Git Bash

```shell
export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 && export NODE_OPTIONS="--max-old-space-size=8192" && ./entrypoint.bash
```

### Installation & setup tweaks ###

Untar, copy-paste an extensionsGallery to ```resources/app/product.json```

### Limitations ###

Use [netcoredbg](https://wiki.archlinux.org/title/Talk:Visual_Studio_Code) as [vsdbg is only available in Microsoft Visual Studio Code](https://github.com/OmniSharp/omnisharp-vscode/wiki/Microsoft-.NET-Core-Debugger-licensing-and-Microsoft-Visual-Studio-Code)

### License ###

Perl "Artistic License"

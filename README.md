### Build vscode opensource ###

#### Host requirements ####

Linux with docker, user with UID 10001, a member of GID 10001 and docker groups, enough disk space in ```${HOME}``` to store source and build files

[Windows host](win.txt)

#### How-to run ####

##### Linux #####

```shell script
bash builder.bash
```

##### Windows #####

Clone repo to ```${HOME}/dev/VSC```, cd to it, run ```bash entrypoint.bash```

#### Tweaks ####

Put some extensionsGallery to ```resources/app/product.json```

#### License ####

Perl "Artistic License"

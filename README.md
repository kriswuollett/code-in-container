# code-in-container

Work in progress, initial release has not been tagged yet!

## Summary

Easily configure your development environment using [Docker](https://www.docker.com/) and
[Visual Studio Code](https://code.visualstudio.com/). Based on Visual Studio Code's
["Docker from Docker"](https://github.com/microsoft/vscode-dev-containers/tree/f77b7d0fb99bfa7cee6d257160a77ce15f07be4f/containers/docker-from-docker)
`vscode-dev-container` configuration, this software enables additional software to be installed
without the standard package manager provided by the base container image's operating system.

## How it works

The `vscode-dev-container`'s `initializeCommand` option is used to build a `Dockerfile` based on the
configuration in a simple `code-in-container.tsv` file and code fragments in
`code-packages(-[a-z]+)*` directories. The directory layout allows for customization directly in
your own code repository -- or even multiple subdirectories (git submodules, etc.) if you need to
share your customization among multiple projects, or have non-free dependencies which cannot be
made available from this repository (not implemented yet).

The `code-in-container.tsv` file must end with an empty line.

## Usage

Add this code repository as a git submodule, checkout the desired version, and copy the
example configuration file, e.g.:

```
CODE_IN_CONTAINER_VERSION=0.0.1
(mkdir .devcontainer \
  && cd .devcontainer
  && git submodule add https://github.com/kriswuollett/code-in-container.git \
  && git submodule update --init --recursive \
  && cd code-in-container  \
  && git checkout v${CODE_IN_CONTAINER_VERSION} \
  && cp devcontainer-example.json ../devcontainer.json \
  && cp code-in-container-example.tsv ../code-in-container.tsv)
```

Edit `.devcontainer/code-in-container.tsv` and `.devcontainer/devcontainer.json` as needed. The
`code-in-container.tsv` is tab-delimited with the following columns:

| Column     | Description                                                                            |
| ---------- | -------------------------------------------------------------------------------------- |
| 1) source  | The source of the package, e.g., `_` (this software), apt, pip, npm                    |
| 2) order   | The order of the package among others for configuring items like `PATH` in `profile.d` |
| 3) name    | The name of the software package, e.g., nodejs                                         |
| 4) version | The version of the software package in source's syntax, e.g., 16.7.0, \_ (N/A)         |

The specifications for how the software is to be installed can be found within the
`.devcontainer/code-in-container/packages` directory. If you wish to override the package
definitions, or create custom ones, you may add those within a directory created at
`.devcontainer/code-packages`.

## Roadmap

There are no plans anticipated at the moment to expand the functionality greatly other than a simple
depends-on mechanism to support compile-time dependencies, as well as multiple versions of
packages. It is assumed most complex dependencies can be usually provided by the operating system's
package manager, or that of a software platform such as `npm`. However the logic may be refactored
to accomodate generating `Dockerfile`s for more general purposes. Also the file generation may be
updated to use temporary files.

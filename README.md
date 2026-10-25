# jldev_poetry

Enhance your JOps (= Julia + Python/Poetry + VSCode + JupyterLab + Docker + Pluto)

# How to use

## Supported Julia versions

CI tests Julia 1.10 and the latest stable Julia 1.x release (`1`). Julia 1.6 is no longer supported; nightly builds are outside the supported CI matrix.

## Prerequisite

- Please install Git, GNU Make, Docker and Docker Compose.

## Setup environment

```console
$ git clone https://github.com/terasakisatoshi/jldev_poetry.git
$ cd jldev_poetry
$ make
```

After that go to the next chapter.

# How to run

## Initialize JupyterLab

```console
$ docker-compose up lab
```

## Dive into the Docker container

```console
$ docker-compose run --rm shell bash
jovyan@e74b3f5d0d5e:/workspace/jldev_poetry.jl$ # do something awesome e.g. julia or python
```

## Test

```console
$ make test
```

## Docs

```console
$ docker-compose up web
```

Then, go to localhost:8000

## Format file

```console
docker-compose run --rm shell poe format
```

## Update packages

- Julia

```console
$ docker-compose run --rm shell julia -e 'using Pkg; Pkg.add("Example")'
$ make # rebuild Docker image
```

- Python

```console
$ docker-compose run --rm shell poetry add "numpy"
$ make # rebuild Docker image
```

## VSCode

- Install VSCode in advance

```console
$ cd /path/to/this/repository
$ code . # Open VSCode
```

Then dive into Remote Container.

## Clean up

```console
$ make clean
```

## JupyterLab 4 migration

The notebook environment now uses JupyterLab 4 and Notebook 7. Python and Julia (IJulia) kernels remain supported. The formatter and topbar text extensions are updated for Lab 4.

The incompatible legacy topbar container, system monitor, Sublime keybindings, and WebIO frontend extensions are removed. WebIO-specific interactive displays will need a Lab 4-compatible replacement; ordinary Julia notebooks are unaffected by that frontend removal. Pluto proxy remains installed.

CI exercises real Python and Julia notebook kernels, HTML export, scientific plotting, and authenticated Lab startup. Browser interaction with every extension and a complete Docker build are not covered by this smoke test.

FROM julia:1.10.0

# create user with a home directory
ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    python3 \
    python3-dev \
    python3-distutils \
    python3-venv \
    python3-pip \
    curl \
    ca-certificates \
    git \
    zip \
    && \
    apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* # clean up

# Dependencies for development
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    htop \
    nano \
    openssh-server \
    tig \
    tree \
    && \
    apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* # clean up

# Install NodeJS to build extensions of JupyterLab
RUN apt-get update && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* # clean up

ENV PATH=${HOME}/.local/bin:${PATH}

RUN curl -sSL https://install.python-poetry.org | python3 -

WORKDIR /workspace/jldev_poetry
COPY pyproject.toml poetry.toml poetry.lock /workspace/jldev_poetry/

# https://stackoverflow.com/questions/74385209/poetry-install-throws-connection-pool-is-full-discarding-connection-pypi-org
RUN poetry config installer.max-workers 10 && \
    poetry install --no-root && echo done
RUN poetry run pip3 install poethepoet

SHELL ["poetry", "run", "/bin/bash", "-c"]

RUN mkdir -p ${HOME}/.local ${HOME}/.jupyter
# Set color theme Monokai++ by default
RUN mkdir -p ${HOME}/.jupyter/lab/user-settings/@jupyterlab/notebook-extension && \
    echo '{"codeCellConfig": {"lineNumbers": true}}' \
    >> ${HOME}/.jupyter/lab/user-settings/@jupyterlab/notebook-extension/tracker.jupyterlab-settings

RUN mkdir -p ${HOME}/.jupyter/lab/user-settings/@jupyterlab/shortcuts-extension && \
    echo '{"shortcuts": [{"command": "runmenu:restart-and-run-all", "keys": ["Alt R"], "selector": "[data-jp-code-runner]"}]}' \
    >> ${HOME}/.jupyter/lab/user-settings/@jupyterlab/shortcuts-extension/shortcuts.jupyterlab-settings

RUN julia -e 'using Pkg; Pkg.add(["Revise", "BenchmarkTools", "OhMyREPL", "Documenter", "LiveServer", "Pluto", "PlutoUI"])'
RUN julia -e 'using Pkg; Pkg.add(["JET", "Aqua", "JuliaFormatter", "TestEnv", "ReTestItems"])'
RUN julia -e '\
              using Pkg; \
              Pkg.add("IJulia"); \
              using IJulia; \
              installkernel("Julia");\
              ' && \
    echo "Done"

ENV JULIA_PROJECT "@."
WORKDIR /workspace/jldev_poetry

COPY ./playground/notebook /workspace/jldev_poetry
COPY ./playground/pluto /workspace/jldev_poetry
COPY ./docs/Project.toml /workspace/jldev_poetry/docs
COPY ./src /workspace/jldev_poetry/src
COPY ./Project.toml /workspace/jldev_poetry

ENV PATH=${PATH}:${HOME}/.local/bin

USER root
RUN chown -R ${NB_UID} ${HOME}
RUN chown -R ${NB_UID} /workspace/
USER ${USER}

RUN poetry install && zip -r .venv.zip .venv

RUN rm -f Manifest.toml && julia --project=/workspace/jldev_poetry -e '\
    using InteractiveUtils; \
    ENV["PYTHON"] = "/workspace/jldev_poetry/.venv/bin/python3"; \
    ENV["JUPYTER"] = "/workspace/jldev_poetry/.venv/bin/jupyter"; \
    using Pkg; \
    Pkg.instantiate(); \
    Pkg.precompile(); \
    versioninfo(); \
    ' && \
    echo Done

USER ${USER}
EXPOSE 8000
EXPOSE 8888
EXPOSE 1234

RUN echo "source /usr/share/bash-completion/completions/git" >> ~/.bashrc

CMD ["julia"]

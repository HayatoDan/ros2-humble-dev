FROM ros:humble

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Base tools
RUN apt-get update && apt-get install -y \
    sudo \
    git \
    curl \
    wget \
    gnupg2 \
    lsb-release \
    ca-certificates \
    software-properties-common \
    bash-completion \
    build-essential \
    cmake \
    gdb \
    vim \
    nano \
    less \
    unzip \
    zip \
    locales \
    iproute2 \
    iputils-ping \
    net-tools \
    usbutils \
    udev \
    evtest \
    joystick \
    fzf \
    python3-pip \
    python3-vcstool \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-argcomplete \
    && rm -rf /var/lib/apt/lists/*

# Locale
RUN locale-gen en_US en_US.UTF-8 ja_JP ja_JP.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ROS 2 full desktop + Cyclone DDS
# gazebo不要ならros-humble-desktopに変更してもOK
RUN apt-get update && apt-get install -y \
    ros-humble-desktop-full \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-cyclonedds \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Node.js + Codex CLI
ARG NODE_MAJOR=22
ARG CODEX_VERSION=latest

RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g "@openai/codex@${CODEX_VERSION}" && \
    node --version && \
    npm --version && \
    codex --version && \
    rm -rf /var/lib/apt/lists/*

# rosdep init
RUN rosdep init || true

# User
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}

# Prepare Codex home
RUN mkdir -p /home/${USERNAME}/.codex && \
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.codex

USER ${USERNAME}
WORKDIR /home/${USERNAME}

# uv: install as dev user, per-user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# ros2-aliases: install under $HOME/.local
# Ubuntu 22.04 coreutils does not support `cp --update=none`,
# so replace it with the equivalent `cp -n`.
RUN mkdir -p "$HOME/.local" && \
    git clone https://github.com/kimushun1101/ros2-aliases.git "$HOME/.local/ros2-aliases" && \
    sed -i 's/cp --update=none /cp -n /' \
      "$HOME/.local/ros2-aliases/ros2_aliases.bash"

# Shell setup
RUN { \
    echo 'source /opt/ros/humble/setup.bash'; \
    echo 'export PATH="$HOME/.local/bin:$PATH"'; \
    echo 'if command -v uv >/dev/null 2>&1; then eval "$(uv generate-shell-completion bash)"; fi'; \
    echo 'if [ -f "$HOME/.local/ros2-aliases/ros2_aliases.bash" ]; then source "$HOME/.local/ros2-aliases/ros2_aliases.bash"; fi'; \
    echo 'if [ -f "$HOME/ros2_ws/install/setup.bash" ]; then source "$HOME/ros2_ws/install/setup.bash"; fi'; \
    echo 'export ROS_LOCALHOST_ONLY=0'; \
    echo 'export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp'; \
} >> "$HOME/.bashrc"

COPY --chmod=755 entrypoint.sh /entrypoint.sh

WORKDIR /home/${USERNAME}/ros2_ws
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
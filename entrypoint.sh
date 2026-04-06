#!/bin/bash
set -e

WS_DIR="$HOME/ros2_ws"
ALIASES_DIR="$HOME/.local/ros2-aliases"
ALIASES_ENV="$ALIASES_DIR/.env"

echo "[entrypoint] prepare ros2 workspace"

mkdir -p "$WS_DIR/src"

# ros2-aliases を読み込む
if [ -f "$ALIASES_DIR/ros2_aliases.bash" ]; then
  source "$ALIASES_DIR/ros2_aliases.bash"
fi

# ros2-aliases の .env を初回だけ作成
if [ ! -f "$ALIASES_ENV" ]; then
  if declare -F setenvfile >/dev/null 2>&1; then
    printf 'y\n' | setenvfile || true
  else
    touch "$ALIASES_ENV"
  fi
fi

if [ -f "$ALIASES_ENV" ]; then
  grep -q '^ROS_WORKSPACE=' "$ALIASES_ENV" \
    && sed -i "s|^ROS_WORKSPACE=.*|ROS_WORKSPACE=$WS_DIR|" "$ALIASES_ENV" \
    || echo "ROS_WORKSPACE=$WS_DIR" >> "$ALIASES_ENV"

  grep -q '^COLCON_BUILD_CMD=' "$ALIASES_ENV" \
    && sed -i "s|^COLCON_BUILD_CMD=.*|COLCON_BUILD_CMD=colcon build --symlink-install --parallel-workers \$(nproc)|" "$ALIASES_ENV" \
    || echo 'COLCON_BUILD_CMD=colcon build --symlink-install --parallel-workers $(nproc)' >> "$ALIASES_ENV"
fi

# 初回だけ空ワークスペースをビルド
if [ ! -f "$WS_DIR/install/setup.bash" ]; then
  echo "[entrypoint] first colcon build"
  cd "$WS_DIR"
  colcon build --symlink-install || true
fi

if [ -f "$WS_DIR/install/setup.bash" ]; then
  source "$WS_DIR/install/setup.bash"
fi

exec "$@"
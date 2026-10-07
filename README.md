# ros2-humble-dev

WSL2 上で Docker Engine を直接利用することを前提とした、ROS 2 Humble 開発用コンテナ環境です。

ROS 2 のビルド・実行環境を Docker コンテナ内にまとめつつ、ソースコードの実体は WSL2 側に保持します。

Codex CLI および VS Code Dev Containers にも対応しており、コンテナ内で ROS 2 パッケージの編集、ビルド、テストまで行えます。

## 構成

```text
Windows
└─ WSL2
   └─ ~/docker_work/ros2-humble-dev/
      ├─ Dockerfile
      ├─ docker-compose.yml
      ├─ entrypoint.sh
      ├─ .devcontainer/
      │  └─ devcontainer.json
      └─ ros2_ws/
         ├─ src/
         ├─ build/
         ├─ install/
         └─ log/
```

WSL2 側の

```text
ros2_ws/
```

を、コンテナ内の

```text
/home/dev/ros2_ws
```

へ bind mount しています。

そのため、ソースコードの実体は WSL2 側に保持されますが、編集や Git 操作は WSL2 側・コンテナ側のどちらから行っても構いません。

## 含まれているもの

- ROS 2 Humble
- ROS 2 desktop-full
- Cyclone DDS
- colcon
- rosdep
- ros2-aliases
- Git
- GitHub CLI (`gh`)
- Python 3
- `uv`
- CMake / GCC / GDB
- Codex CLI
- joystick 関連ツール
- VS Code Dev Containers 用設定

## 前提

WSL2 上に Docker Engine がインストールされていることを前提とします。

Docker Desktop 経由ではなく、WSL2 内で Docker Engine を直接動かす構成を想定しています。

### WSL2 ネットワーク

可能であれば Windows 側の `.wslconfig` で mirrored networking を利用します。

```ini
[wsl2]
networkingMode=mirrored
```

変更後は Windows 側で WSL を再起動します。

```powershell
wsl --shutdown
```

### USB joystick

USB joystick を利用する場合は、`usbipd-win` 等を利用して WSL2 にデバイスを attach しておきます。

まず WSL2 側で、

```bash
ls /dev/input/js*
```

に joystick が見えていることを確認してください。

## 初回セットアップ

リポジトリを clone します。

```bash
cd ~/docker_work
git clone https://github.com/HayatoDan/ros2-humble-dev.git
cd ros2-humble-dev
```

イメージをビルドします。

```bash
docker compose build --no-cache
```

コンテナを起動します。

```bash
docker compose up -d
```

起動状態を確認します。

```bash
docker ps
```

コンテナに入ります。

```bash
docker exec -it ros2-humble-dev bash
```

## 動作確認

コンテナ内で以下を確認します。

```bash
whoami
id
ros2 --help >/dev/null && echo "ROS2 OK"
uv --version
gh --version
codex --version
```

ROS 2 の基本動作も確認できます。

```bash
ros2 run demo_nodes_cpp talker
```

別ターミナルからコンテナに入り、

```bash
ros2 run demo_nodes_cpp listener
```

を実行します。

## ROS 2 workspace

workspace はコンテナ内では

```text
/home/dev/ros2_ws
```

です。

`entrypoint.sh` により、必要に応じて

```text
/home/dev/ros2_ws/src
```

が自動的に作成されます。

通常は、

```bash
cd ~/ros2_ws
```

から作業します。

## ROS 2 パッケージの clone

ROS 2 パッケージは

```text
ros2_ws/src/
```

以下に配置します。

`ros2_ws` は WSL2 側からコンテナへ bind mount されているため、clone は WSL2 側・コンテナ側のどちらから行っても構いません。

### WSL2 側から clone

```bash
cd ~/docker_work/ros2-humble-dev/ros2_ws/src
git clone <repository>
```

### コンテナ側から clone

```bash
cd ~/ros2_ws/src
git clone <repository>
```

WSL2 側のユーザーとコンテナ内の `dev` ユーザーは同じ UID/GID を使用する構成になっているため、どちらから作成したファイルも同じ所有権で扱えます。

workspace 内のファイル操作では、原則として `sudo` を使用しないでください。

例えば、

```bash
sudo git clone ...
sudo mkdir ...
```

のような操作を行うと、WSL2 側から見たときに root 所有のファイルが作成される可能性があります。

## 新規 ROS 2 パッケージの作成

新規パッケージの作成はコンテナ内で行います。

```bash
docker exec -it ros2-humble-dev bash
```

例えば Python パッケージの場合、

```bash
cd ~/ros2_ws/src
ros2 pkg create <package_name>
cd <package_name>
uv init . --lib --python-preference only-system
uv venv --system-site-packages
```

とします。

## ビルド

ビルドはコンテナ内で行います。

```bash
docker exec -it ros2-humble-dev bash
```

workspace 全体をビルドする場合、

```bash
cd ~/ros2_ws
colcon build --symlink-install
```

または ros2-aliases の設定に応じて、

```bash
cb
```

を使用できます。

特定パッケージだけをビルドする場合、

```bash
colcon build \
  --symlink-install \
  --packages-select <package_name>
```

とします。

ビルド後は必要に応じて、

```bash
source ~/ros2_ws/install/setup.bash
```

を実行してください。

通常は `.bashrc` から自動的に読み込まれます。

## テスト

特定パッケージをテストする場合、

```bash
cd ~/ros2_ws

colcon test \
  --packages-select <package_name>

colcon test-result --verbose
```

を実行します。

## Codex CLI

Codex CLI はコンテナ内にインストールされています。

コンテナに入ります。

```bash
docker exec -it ros2-humble-dev bash
```

ROS 2 リポジトリへ移動して、

```bash
cd ~/ros2_ws/src/<repository>
codex
```

とすると、その ROS 2 開発環境をそのまま利用して Codex を実行できます。

Codex から、

- ソースコードの編集
- Git 操作
- `colcon build`
- `colcon test`
- `ros2` コマンド
- CMake
- Python / `uv`

等を実行できます。

例えば、

```text
この ROS 2 Humble package を調査して、
colcon build --packages-select <package_name>
が通るところまで修正してください。

修正後は
colcon test --packages-select <package_name>
と
colcon test-result --verbose
も実行してください。
```

のように指示できます。

### Codex 設定の永続化

Codex の設定は Docker named volume

```text
codex-home
```

を

```text
/home/dev/.codex
```

へ mount して永続化しています。

そのため、

```bash
docker compose down
```

やコンテナの再作成では Codex の設定・認証情報は保持されます。

## VS Code Dev Containers

VS Code から Dev Container として接続できます。

まず、

```bash
cd ~/docker_work/ros2-humble-dev
docker compose up -d
```

でコンテナを起動します。

その後 VS Code でこのディレクトリを開き、Dev Containers を利用してコンテナへ接続します。

コンテナ内の workspace は、

```text
/home/dev/ros2_ws
```

です。

Dev Container には ROS、Python、CMake、および Codex 関連の VS Code 拡張を導入する構成になっています。

Codex CLI と VS Code の Codex 拡張は用途に応じて使い分けられます。

- コードを見ながら細かく修正する場合: VS Code 拡張
- ビルド・テストを含めてまとまった作業を任せる場合: Codex CLI

## Git の考え方

このリポジトリは ROS 2 の「開発環境」を管理します。

一方、

```text
ros2_ws/src/
```

以下に配置する各 ROS 2 パッケージは、それぞれ独立した Git repository として扱います。

そのため `ros2_ws/.gitignore` では、

```gitignore
build/
install/
log/
src/
```

を除外します。

例えば、

```text
ros2-humble-dev/
└─ ros2_ws/
   └─ src/
      ├─ package-a/    # 独立した Git repository
      ├─ package-b/    # 独立した Git repository
      └─ package-c/    # 独立した Git repository
```

という使い方を想定しています。

## GitHub CLI

GitHub CLI がコンテナ内にインストールされています。

```bash
gh --version
```

認証状態は、

```bash
gh auth status
```

で確認できます。

private repository の clone や push 等をコンテナ内から行う場合は、必要に応じて GitHub CLI または Git の認証を設定してください。

## Docker 操作

### 起動

```bash
docker compose up -d
```

### コンテナに入る

```bash
docker exec -it ros2-humble-dev bash
```

### 停止・削除

```bash
docker compose down
```

### 再ビルド

```bash
docker compose build
docker compose up -d
```

完全に再ビルドする場合、

```bash
docker compose build --no-cache
docker compose up -d
```

とします。

### イメージも削除

```bash
docker compose down --rmi all --remove-orphans
```

### named volume も含めて削除

```bash
docker compose down --rmi all -v --remove-orphans
```

`-v` を付けると `codex-home` も削除されます。

そのため Codex の認証情報や設定を残したい場合は、通常は `-v` を付けないでください。

## joystick の確認

WSL2 側で、

```bash
ls /dev/input/js*
jstest /dev/input/js0
```

を実行します。

コンテナ内では、

```bash
ls /dev/input/js*
ros2 run joy joy_node
```

とします。

topic を確認する場合、

```bash
ros2 topic echo /joy
```

を実行します。

## ROS 2 通信確認

この環境では Cyclone DDS を使用します。

WSL2 側またはコンテナ内で、

```bash
source /opt/ros/humble/setup.bash
ros2 multicast receive
```

を実行し、別端末で、

```bash
source /opt/ros/humble/setup.bash
ros2 multicast send
```

を実行すると multicast 通信を確認できます。

## GUI アプリケーション

WSLg を利用できる環境では、コンテナ内から ROS 2 の GUI アプリケーションを起動できます。

例えば、

```bash
rviz2
```

または、

```bash
rqt
```

を実行します。

Docker Compose では WSLg 関連の socket や GPU デバイスをコンテナへ渡しています。

## ネットワーク

Docker コンテナは

```yaml
network_mode: host
```

を使用します。

そのため ROS 2 の DDS 通信では WSL2 側のネットワークを共有します。

Windows、WSL2、他PCとの ROS 2 通信を行う場合は、WSL2 のネットワーク設定や Windows Firewall 等にも注意してください。

## 注意事項

- ROS 2 のビルド・実行は原則としてコンテナ内で行います。
- ソースコードの実体は WSL2 側に保持されます。
- Git 操作は WSL2 側・コンテナ側のどちらから行っても構いません。
- `ros2_ws` 内の通常のファイル操作に `sudo` は使用しないでください。
- `docker compose down -v` は Codex の設定を保存している named volume も削除します。
- joystick はコンテナへ渡す前に WSL2 側で認識されている必要があります。
- Gazebo や RViz の利用には GPU / OpenGL / WSLg 周りの追加調整が必要になる場合があります。
- ROS 2 package は `ros2_ws/src` 以下に独立した Git repository として配置することを想定しています。

## 基本的な開発フロー

通常の開発は以下の流れを想定しています。

```text
WSL2
  │
  ├─ ros2-humble-dev を保持
  │
  └─ ros2_ws/src にソースを保持
          │
          │ bind mount
          ▼
Docker container
  │
  ├─ Git / Codex による編集
  ├─ colcon build
  ├─ colcon test
  └─ ros2 run
```

例えば、

```bash
cd ~/docker_work/ros2-humble-dev
docker compose up -d
docker exec -it ros2-humble-dev bash
```

コンテナ内で、

```bash
cd ~/ros2_ws/src
git clone <repository>

cd <repository>
codex
```

あるいは手動で編集後、

```bash
cd ~/ros2_ws
colcon build --symlink-install --packages-select <package_name>
colcon test --packages-select <package_name>
colcon test-result --verbose
```

という流れになります。
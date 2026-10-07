# ros2-humble-dev

WSL2 上で Docker Engine を直接使う前提の、ROS 2 Humble 開発用コンテナ構成です。

## 前提
- WSL2上にdocker engine導入済み

## WSL2上のディレクトリ構成

```text
~/docker_work/
   └─ ros2-humble-dev/
      ├─ Dockerfile
      ├─ docker-compose.yml
      ├─ .devcontainer/
      │  └─ devcontainer.json
      └─ workspace/
```

## 含めているもの

- ROS 2 Humble
- ros2-aliases
- GitHub CLI (`gh`)
- `uv`

## 前提

- 可能なら `.wslconfig` で `networkingMode=mirrored`
- USB joystick は `usbipd-win` で WSL に attach 済み

## 初回ビルド

```bash
cd ~/docker_work/ros2-humble-dev
mkdir -p ros2_ws/src

docker compose build --no-cache
docker compose up -d
docker exec -it ros2-humble-dev bash
```

### 動作確認

コンテナ内で:

```bash
cb
rviz2
rqt
ros2 run demo_nodes_cpp talker
```

## VS Code から使う

```bash
cd ~/docker_work/ros2-humble-dev
docker compose up -d
docker exec -it ros2-humble-dev bash
```


## 開発の流れ

### パッケージ作成
新規パッケージの作成はコンテナ側で行う．
```bash
cd ~/docker_work/ros2-humble-dev
docker compose up -d
docker exec -it ros2-humble-dev bash
```
後に
```bash
cd src
ros2 pkg create [package_name]
cd [package_name]
uv init . --lib --python-preference only-system
uv venv --system-site-packages
```
詳細は
https://qiita.com/GesonAnko/items/510eeade1f8ada302b9b


### clone
cloneはWSL2側で行う．
具体的には
`ros2-humble-dev/ros2_ws/src`
内に作成/cloneする．

### ビルド
ビルド等はコンテナ側で行う．
```bash
cd ~/docker_work/ros2-humble-dev
docker compose up -d
docker exec -it ros2-humble-dev bash
cb
```


## docker操作
コンテナ一覧
`docker ps -a`

停止
`docker compose down`

再起動
`docker compose up -d`

削除
`docker compose down --rmi all -v --remove-orphans`




## joystick の確認

WSL 側で:

```bash
ls /dev/input/js*
jstest /dev/input/js0
```

コンテナ内で:

```bash
ls /dev/input/js*
ros2 run joy joy_node
ros2 topic echo /joy
```

## ROS 2 通信確認

コンテナ内や WSL 側で:

```bash
source /opt/ros/humble/setup.bash
ros2 multicast receive
```

別端末で:

```bash
source /opt/ros/humble/setup.bash
ros2 multicast send
```

## 注意

- `network_mode: host` は WSL 側ネットワークを共有します
- joystick は、まず WSL 側で認識されている必要があります
- Gazebo は GPU / OpenGL 周りで追加調整が必要になることがあります

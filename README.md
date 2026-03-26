# linux_configurator

## 🚀 项目简介

`linux_configurator` 是一个 Linux 环境配置脚本集合。  
你可以通过统一入口 `build.sh` 调用不同功能脚本，快速完成常见系统配置任务。

## 📦 当前可用功能

### `apt_changer`

用途：为 Ubuntu 切换 APT 镜像源（阿里云 / 清华），并执行 `apt update`。

## 🛠️ 如何使用 build.sh

统一调用方式：

```bash
bash build.sh <script_name> [args...]
```

参数说明：
- `<script_name>`：`./scripts` 下脚本文件名（不含 `.sh` 后缀）

查看当前可用功能：

```bash
bash build.sh --help
```

## ✅ 快速开始示例

执行 `apt_changer`：

```bash
sudo bash build.sh apt_changer
```

## ⚠️ 使用注意事项

- `apt_changer` 仅支持 Ubuntu 系统
- 涉及系统软件源修改，需使用 root 权限（建议 `sudo`）

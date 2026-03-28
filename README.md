# linux_configurator

## 🚀 项目简介

`linux_configurator` 是一个 Linux 环境配置脚本集合。  
你可以通过统一入口 `build.sh` 调用不同功能脚本，快速完成常见系统配置任务。

## 📦 当前可用功能

### `apt_changer`

用途：切换 Ubuntu APT 软件源为国内镜像源，加速 APT 软件以及依赖安装。
- 支持版本: Ubuntu 18.04 / 20.04 / 22.04 / 24.04
- 支持软件源: 阿里云 / 清华源

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

## ⚠️ 使用注意事项

- `apt_changer` 目前仅支持 Ubuntu 系统
- 涉及系统软件源修改，需使用 root 权限（建议 `sudo`）

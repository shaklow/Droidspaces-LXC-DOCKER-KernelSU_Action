**中文** | [English](README_EN.md)

# KernelSU + DroidSpaces + LXC/Docker 内核构建

基于 GitHub Actions 的自动化内核编译，集成 **KernelSU**、**DroidSpaces**、**LXC/Docker**、**KVM** 支持。

> ⚠️ 仅支持 **Non-GKI 内核**（4.19 / 4.14 / 4.9 等传统内核），不支持 GKI 5.10+
> 当前配置目标设备：**小米 SM8250 (骁龙865/Kona)**

##  警告

如果你不是内核作者，使用他人的劳动成果构建 KernelSU，请仅供自己使用，不要分享给别人，这是对原作者的劳动成果的尊重。

## 特性

- **LXC/Docker** — 完整容器运行时支持
- **DroidSpaces** — 轻量级 Linux 容器环境
- **KernelSU** — 内核级 root 方案
- **KVM** — 内核虚拟化
- **ccache + 工具链缓存** — 大幅加速重复构建
- **Action 界面开关** — 运行时可选择功能模块
- **自动打包** — AnyKernel3 卡刷包 + boot.img

## 快速开始

### 1. Fork 并配置

Fork 本仓库，编辑 [`config.env`](config.env) 适配你的设备：

- `KERNEL_SOURCE` — 内核源码地址
- `KERNEL_CONFIG` — defconfig 路径
- `ARCH` — 架构（arm64）
- `BUILD_BOOT_IMG` — 是否需要合成 boot.img

### 2. 触发构建

点击 Actions → `大容量云编译` → `Run workflow`，在界面选择所需功能后启动。

### 3. 获取产物

构建完成后下载：
- `Image-*` — 内核镜像
- `AnyKernel3-*` — TWRP 卡刷包（设备检查已关闭）
- `boot-*` — 合成 boot.img（需提供源镜像）

## 配置说明

### 基础配置

| 变量 | 说明 | 示例 |
|------|------|------|
| `KERNEL_SOURCE` | 内核源码地址 | `https://github.com/.../android_kernel_xiaomi_sm8250` |
| `KERNEL_SOURCE_BRANCH` | 内核源码分支 | `lineage-23.2` |
| `KERNEL_CONFIG` | defconfig 路径 | `vendor/kona_defconfig` |
| `KERNEL_IMAGE_NAME` | 内核镜像名称 | `Image` |
| `ARCH` | 架构 | `arm64` |
| `METHOD_OK` | 编译方案 | `A`=Clang+GCC, `B`=纯 Clang |

### 编译器

| 变量 | 说明 |
|------|------|
| `USE_CUSTOM_CLANG` | `true`=自定义 Clang, `false`=AOSP Clang |
| `CUSTOM_CLANG_SOURCE` | 自定义 Clang 下载地址（git/tar.gz/zip） |
| `CLANG_BRANCH` | AOSP Clang 分支 |
| `CLANG_VERSION` | Clang 版本号 |

### 功能开关

以下选项在 **Action 界面** 直接选择，也可在 `config.env` 文末区块取消注释覆盖：

| 选项 | 说明 |
|------|------|
| `ENABLE_KERNELSU` | 启用 KernelSU root |
| `LXC_DOCKER` | 开启 LXC/Docker 容器支持 |
| `ENABLE_KVM` | 开启 KVM 虚拟化 |
| `DROIDSPACES_PATCH` | 打入 DroidSpaces 内核补丁 |
| `DROIDSPACES_CONFIG` | 注入 DroidSpaces 内核配置 |
| `DROIDSPACES_ADDITIONAL_CONFIG` | 注入 UFW/Fail2Ban/IPSET 配置 |

### 附加选项

| 变量 | 说明 |
|------|------|
| `KERNELSU_TAG` | KernelSU 版本 tag |
| `DISABLE-LTO` | 禁用 LTO 优化 |
| `DISABLE_CC_WERROR` | 禁用编译警告即错误 |
| `ADD_KPROBES_CONFIG` | 自动注入 Kprobes 配置 |
| `ADD_OVERLAYFS_CONFIG` | 自动注入 OverlayFS 配置 |
| `ENABLE_CCACHE` | 启用 ccache 缓存 |
| `BUILD_BOOT_IMG` | 合成 boot.img |
| `SOURCE_BOOT_IMAGE` | boot 源镜像直链 |
| `NEED_DTBO` | 上传 DTBO 镜像 |
| `ANDROID_PARANOID_NETWORK_OFF` | 关闭 Android 网络隔离 |

## 目录结构

```
├── .github/workflows/
│   ├── blank.yml              # 入口工作流（手动触发）
│   └── yun-kernel.yml         # 主构建工作流
├── configs/
│   ├── droidspaces.config     # DroidSpaces 内核配置
│   └── droidspaces-additional.config  # UFW/Fail2Ban/IPSET
├── patch/
│   └── droidspaces/           # DroidSpaces 内核补丁
├── config.env                 # 构建参数配置
└── README.md
```

## 感谢

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [KernelSU](https://github.com/tiann/KernelSU)
- [Droidspaces](https://github.com/ravindu644/Droidspaces-OSS)
- [LXC-DOCKER-KernelSU_Action (原始项目)](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)

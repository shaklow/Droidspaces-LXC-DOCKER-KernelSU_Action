[中文](README.md) | **English**

# KernelSU + DroidSpaces + LXC/Docker Kernel Builder

Automated kernel compilation via GitHub Actions with **KernelSU**, **DroidSpaces**, **LXC/Docker**, and **KVM** support.

> ⚠️ Only supports **Non-GKI kernels** (4.19 / 4.14 / 4.9, etc.) — GKI 5.10+ not supported
> Current target: **Xiaomi SM8250 (Snapdragon 865 / Kona)**

## Warning

If you are not the kernel author and are using someone else's work to build KernelSU, please use it for personal use only. Do not share with others — respect the original author's efforts.

## Features

- **LXC/Docker** — Full container runtime support
- **DroidSpaces** — Lightweight Linux containers on Android
- **KernelSU** — Kernel-level root solution
- **KVM** — Kernel virtualization
- **ccache + toolchain caching** — Much faster rebuilds
- **Action UI toggles** — Enable/disable features at runtime
- **Auto packaging** — AnyKernel3 flashable zip + boot.img

## Quick Start

### 1. Fork & Configure

Fork this repo, edit [`config.env`](config.env) for your device:

- `KERNEL_SOURCE` — Kernel source URL
- `KERNEL_CONFIG` — defconfig path
- `ARCH` — Architecture (arm64)
- `BUILD_BOOT_IMG` — Whether to build boot.img

### 2. Trigger Build

Go to Actions → `大容量云编译` → `Run workflow`, select desired features, and start.

### 3. Download Artifacts

After build completes:
- `Image-*` — Kernel image
- `AnyKernel3-*` — TWRP flashable zip (device check disabled)
- `boot-*` — Repacked boot.img (requires source image)

## Configuration

### Essentials

| Variable | Description | Example |
|----------|-------------|---------|
| `KERNEL_SOURCE` | Kernel source URL | `https://github.com/.../android_kernel_xiaomi_sm8250` |
| `KERNEL_SOURCE_BRANCH` | Kernel source branch | `lineage-23.2` |
| `KERNEL_CONFIG` | defconfig path | `vendor/kona_defconfig` |
| `KERNEL_IMAGE_NAME` | Output image name | `Image` |
| `ARCH` | Architecture | `arm64` |
| `METHOD_OK` | Build method | `A`=Clang+GCC, `B`=Clang only |

### Toolchain

| Variable | Description |
|----------|-------------|
| `USE_CUSTOM_CLANG` | `true`=custom Clang, `false`=AOSP Clang |
| `CUSTOM_CLANG_SOURCE` | Custom Clang download URL (git/tar.gz/zip) |
| `CLANG_BRANCH` | AOSP Clang branch |
| `CLANG_VERSION` | Clang version |

### Feature Toggles

Toggle via **Action UI**, or uncomment in `config.env` (end of file) to override:

| Option | Description |
|--------|-------------|
| `ENABLE_KERNELSU` | Enable KernelSU root |
| `LXC_DOCKER` | Enable LXC/Docker support |
| `ENABLE_KVM` | Enable KVM virtualization |
| `DROIDSPACES_PATCH` | Apply DroidSpaces kernel patches |
| `DROIDSPACES_CONFIG` | Apply DroidSpaces kernel config |
| `DROIDSPACES_ADDITIONAL_CONFIG` | Apply UFW/Fail2Ban/IPSET config |

### Additional Options

| Variable | Description |
|----------|-------------|
| `KERNELSU_TAG` | KernelSU version tag |
| `DISABLE-LTO` | Disable LTO optimization |
| `DISABLE_CC_WERROR` | Disable -Werror |
| `ADD_KPROBES_CONFIG` | Auto-inject Kprobes config |
| `ADD_OVERLAYFS_CONFIG` | Auto-inject OverlayFS config |
| `ENABLE_CCACHE` | Enable ccache |
| `BUILD_BOOT_IMG` | Build repacked boot.img |
| `SOURCE_BOOT_IMAGE` | Boot source image direct URL |
| `NEED_DTBO` | Upload DTBO image |
| `ANDROID_PARANOID_NETWORK_OFF` | Disable Android network isolation |

## Directory Layout

```
├── .github/workflows/
│   ├── blank.yml              # Entry workflow (manual dispatch)
│   └── yun-kernel.yml         # Main build workflow
├── configs/
│   ├── droidspaces.config     # DroidSpaces kernel config
│   └── droidspaces-additional.config  # UFW/Fail2Ban/IPSET
├── patch/
│   └── droidspaces/           # DroidSpaces kernel patches
├── config.env                 # Build parameters
└── README.md
```

## Credits

- [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- [KernelSU](https://github.com/tiann/KernelSU)
- [Droidspaces](https://github.com/ravindu644/Droidspaces-OSS)
- [LXC-DOCKER-KernelSU_Action (upstream)](https://github.com/wu17481748/LXC-DOCKER-KernelSU_Action)

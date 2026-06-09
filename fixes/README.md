# 构建兼容性修复脚本

此目录存放不同内核版本/设备的构建兼容性修复脚本。

## 使用方法

在 `config.env` 中设置：

```ini
BUILD_FIXES=sm8250-4.19   # SM8250 + 4.19 内核
BUILD_FIXES=none           # 禁用所有修复
```

## 如何创建新脚本

1. 复制 `sm8250-4.19.sh` 作为模板：

```bash
cp fixes/sm8250-4.19.sh fixes/mysoc-5.4.sh
```

2. 编辑新文件，保留/删除/添加需要的 sed 修复。

3. 在 `config.env` 中引用：

```ini
BUILD_FIXES=mysoc-5.4
```

## 脚本规范

- 必须可被 `source`（`.`）执行
- 工作目录为内核源码根目录
- 每个修复后 `echo "  [XX] description"` 输出进度
- 编号从 01 到 NN，保持连续
- 文件头注释说明适用的设备和内核版本

## 可用修复列表

| 编号 | 修复项 | 适用场景 |
|------|--------|----------|
| 01 | mmu_notifier enum → unsigned long | 4.19 + KSU backport |
| 02 | mmu_notifier MMU_NOTIFY defines | 4.19 + KSU |
| 03 | vdso 删除 -n 标志 | arm64 + 旧 LLD |
| 04 | vdso32 删除 page-size 标志 | arm64 + 旧 LLD |
| 05 | head.S \x 转义修复 | 特定内核 |
| 06 | sha1-ce-core 空桩 | 旧 Clang |
| 07 | kvm_main API 修复 | 4.19 backport |
| 08 | lockdep nested 参数 | 4.19 |
| 09 | WRITE_ONCE 宏替换 | 旧 Clang |
| 10 | MODULE_IMPORT_NS 定义 | 4.19 + KSU |
| 11 | iot-rb5 DTS 跳过 | SM8250 特定 |
| 12 | EFI disabled | arm64 |
| 13 | vendor tracepoint stub | LineageOS vendor hook |

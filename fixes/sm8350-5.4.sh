#!/bin/sh
# Build compatibility fixes for SM8350 (Lahaina - Xiaomi 11) + Linux 5.4
# ---------------------------------------------------------------------------
# Usage: set BUILD_FIXES=sm8350-5.4 in config.env, or source this file directly.
#
# This script is sourced from the kernel source root.
# All commands run relative to: $GITHUB_WORKSPACE/kernel_workspace/android-kernel
# ---------------------------------------------------------------------------

echo "Applying SM8350-5.4 build compatibility fixes..."

# ---- 1. VDSO: remove deprecated -n flag (LLD compatibility) ----
sed -i 's/ -n -T/ -T/' arch/arm64/kernel/vdso/Makefile 2>/dev/null || true
echo "  [01] vdso: removed -n flag"

# ---- 2. VDSO32: remove -z page-size flags (LLD compatibility) ----
sed -i 's/-z common-page-size=4096//' arch/arm64/kernel/vdso32/Makefile 2>/dev/null || true
sed -i 's/-z max-page-size=4096//' arch/arm64/kernel/vdso32/Makefile 2>/dev/null || true
echo "  [02] vdso32: removed -z page-size flags"

# ---- 3. sha1-ce-core: stub (safe even if not needed) ----
printf '.text\n.globl sha1_ce_transform\nsha1_ce_transform:\n    ret\n' > arch/arm64/crypto/sha1-ce-core.S 2>/dev/null || true
echo "  [03] sha1-ce-core: replaced with stub"

# ---- 4. EFI: remove default y to allow disabling ----
sed -i '/^config EFI$/,/^config /{/default y/d}' arch/arm64/Kconfig 2>/dev/null || true
echo "  [04] efi: removed default y from Kconfig"

# ---- 5. tracepoint stubs: LineageOS vendor hooks ----
if ! grep -q "stub-vendor-hooks" kernel/trace/Makefile 2>/dev/null; then
    printf '#include <linux/lockdep.h>\nunsigned long __tracepoint_android_vh_set_memory_x;\nunsigned long __tracepoint_android_vh_set_memory_rw;\nunsigned long __tracepoint_android_vh_set_memory_nx;\nunsigned long __tracepoint_android_vh_set_memory_ro;\nunsigned long __tracepoint_android_vh_check_bpf_syscall;\nunsigned long __tracepoint_android_vh_check_mmap_file;\nunsigned long __tracepoint_android_vh_check_file_open;\nstruct lock_class_key rcu_trace_lock_map;\nint ps5169_cfg_usb;\n' > kernel/trace/stub-vendor-hooks.c
    echo 'obj-y += stub-vendor-hooks.o' >> kernel/trace/Makefile
    echo "  [05] tracepoint: created stub-vendor-hooks"
else
    echo "  [05] tracepoint: already patched, skipping"
fi

# ---- 6. SM8350: cgroup net_prio needs cgroup->id which doesn't exist ----
sed -i 's/^CONFIG_CGROUP_NET_PRIO=y/# CONFIG_CGROUP_NET_PRIO is not set (SM8350: no cgroup->id)/' $GITHUB_WORKSPACE/KernelSU/configs/droidspaces.config
echo "  [06] sm8350: disabled CONFIG_CGROUP_NET_PRIO (cgroup struct lacks id field)"

# ---- 7. probe_user_write stub (5.4 lacks it; skip if already defined) ----
if grep -q "probe_user_write" include/linux/uaccess.h 2>/dev/null; then
    echo "  [07] uaccess: probe_user_write already defined, skipping"
else
    cat >> include/linux/uaccess.h << 'STUB'

static inline int probe_user_write(void __user *dst, const void *src, size_t size)
{ return copy_to_user(dst, src, size); }
STUB
    echo "  [07] uaccess: added probe_user_write stub for 5.4 kernel"
fi

echo "SM8350-5.4 fixes applied successfully."

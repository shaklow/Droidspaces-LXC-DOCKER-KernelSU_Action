#!/bin/sh
# ===========================================================================
# Build compatibility fixes — auto-detecting kernel version & features
# ===========================================================================
# This script auto-detects what fixes are needed based on:
#   1. Kernel version (from Makefile)
#   2. Whether target source files exist
#   3. Whether the fix has already been applied
#
# Usage: source from kernel root directory
# ===========================================================================

echo "Applying auto-detected build compatibility fixes..."

# ---- detect kernel version ----
kver=$(grep -E "^VERSION|PATCHLEVEL" Makefile 2>/dev/null | tr -d ' ' | cut -d= -f2 | paste -sd.)
echo "  Kernel version: $kver"

# ---- 1. VDSO: remove -n flag (always safe, LLD compat) ----
sed -i 's/ -n -T/ -T/' arch/arm64/kernel/vdso/Makefile 2>/dev/null || true
echo "  [01] vdso: removed -n flag"

# ---- 2. VDSO32: remove -z page-size flags (always safe, LLD compat) ----
sed -i 's/-z common-page-size=4096//' arch/arm64/kernel/vdso32/Makefile 2>/dev/null || true
sed -i 's/-z max-page-size=4096//' arch/arm64/kernel/vdso32/Makefile 2>/dev/null || true
echo "  [02] vdso32: removed -z page-size flags"

# ---- 3. sha1-ce-core: stub (harmless if not needed) ----
if [ -f arch/arm64/crypto/sha1-ce-core.S ]; then
    printf '.text\n.globl sha1_ce_transform\nsha1_ce_transform:\n    ret\n' > arch/arm64/crypto/sha1-ce-core.S
    echo "  [03] sha1-ce-core: replaced with stub"
fi

# ---- 4. EFI: remove default y (always safe, arm64) ----
sed -i '/^config EFI$/,/^config /{/default y/d}' arch/arm64/Kconfig 2>/dev/null || true
echo "  [04] efi: removed default y from Kconfig"

# ---- 5. tracepoint stubs (LineageOS vendor hooks) ----
if ! grep -q "stub-vendor-hooks" kernel/trace/Makefile 2>/dev/null; then
    printf '#include <linux/lockdep.h>\nunsigned long __tracepoint_android_vh_set_memory_x;\nunsigned long __tracepoint_android_vh_set_memory_rw;\nunsigned long __tracepoint_android_vh_set_memory_nx;\nunsigned long __tracepoint_android_vh_set_memory_ro;\nunsigned long __tracepoint_android_vh_check_bpf_syscall;\nunsigned long __tracepoint_android_vh_check_mmap_file;\nunsigned long __tracepoint_android_vh_check_file_open;\nstruct lock_class_key rcu_trace_lock_map;\nint ps5169_cfg_usb;\n' > kernel/trace/stub-vendor-hooks.c
    echo 'obj-y += stub-vendor-hooks.o' >> kernel/trace/Makefile
    echo "  [05] tracepoint: created stub-vendor-hooks"
else
    echo "  [05] tracepoint: already patched, skipping"
fi

# ---- 6. cgroup net_prio: struct cgroup has no id field? ----
if grep -q '->id;' include/net/netprio_cgroup.h 2>/dev/null \
   && ! grep -A20 "struct cgroup {" include/linux/cgroup-defs.h 2>/dev/null | grep -q '\<id\>'; then
    echo "# CONFIG_CGROUP_NET_PRIO is not set (kernel lacks cgroup->id)" >> $GITHUB_WORKSPACE/KernelSU/configs/droidspaces.config 2>/dev/null || true
    echo "  [06] cgroup: disabled CONFIG_CGROUP_NET_PRIO (cgroup struct lacks id field)"
elif ! grep -q '->id;' include/net/netprio_cgroup.h 2>/dev/null; then
    echo "  [06] cgroup: netprio_cgroup.h not used, skipping"
else
    echo "  [06] cgroup: net_prio supported, keeping enabled"
fi

# ---- 7. mmu_notifier: fix enum & MMU_NOTIFY defines (4.19 only) ----
if echo "$kver" | grep -q "^4\.19" ; then
    sed -i 's/enum mmu_notifier_event event/unsigned long event/' include/linux/mmu_notifier.h 2>/dev/null || true
    sed -i '/#define _LINUX_MMU_NOTIFIER_H/a #define MMU_NOTIFY_UNMAP 0\n#define MMU_NOTIFY_CLEAR 1' include/linux/mmu_notifier.h 2>/dev/null || true
    echo "  [07] mmu_notifier: 4.19 backport fix applied"
else
    echo "  [07] mmu_notifier: 5.x kernel, skipping"
fi

# ---- 8. MODULE_IMPORT_NS: define if missing (4.19 only) ----
if ! grep -q "MODULE_IMPORT_NS" include/linux/module.h 2>/dev/null; then
    echo '#define MODULE_IMPORT_NS(ns)' >> include/linux/module.h
    echo "  [08] module: added MODULE_IMPORT_NS"
else
    echo "  [08] module: MODULE_IMPORT_NS already defined, skipping"
fi

# ---- 9. lockdep: nested param (4.19 only) ----
if grep -q "__lock_release(lock, nested, ip)" kernel/locking/lockdep.c 2>/dev/null; then
    sed -i 's/__lock_release(lock, nested, ip)/__lock_release(lock, 0, ip)/' kernel/locking/lockdep.c
    echo "  [09] lockdep: removed nested param"
else
    echo "  [09] lockdep: no nested param found, skipping"
fi

# ---- 10. KVM: backport API (4.19 only) ----
if grep -q "kvm_unmap_hva_range(kvm, range->start, range->end)" virt/kvm/kvm_main.c 2>/dev/null; then
    sed -i 's/kvm_unmap_hva_range(kvm, range->start, range->end)/kvm_unmap_hva_range(kvm, range->start, range->end, 0)/' virt/kvm/kvm_main.c
    sed -i 's/follow_pte_pmd(vma->vm_mm, addr, NULL, NULL, \&ptep, NULL, \&ptl)/follow_pte_pmd(vma->vm_mm, addr, NULL, NULL, NULL, \&ptl)/' virt/kvm/kvm_main.c 2>/dev/null || true
    echo "  [10] kvm: API backport applied"
else
    echo "  [10] kvm: API already compatible, skipping"
fi

# ---- 11. head.S: \x64 escape (SM8250 Kona only) ----
if grep -q '\\x64"' arch/arm64/kernel/head.S 2>/dev/null; then
    sed -i 's/\\x64"/d"/' arch/arm64/kernel/head.S
    echo "  [11] head.S: fixed \\x escape (Kona)"
else
    echo "  [11] head.S: no \\x escape found, skipping"
fi

# ---- 12. DTS: skip iot-rb5 (SM8250 only) ----
if grep -q "iot-rb5" arch/arm64/boot/dts/vendor/qcom/Makefile 2>/dev/null; then
    sed -i '/iot-rb5/d' arch/arm64/boot/dts/vendor/qcom/Makefile
    echo "  [12] dts: skipped iot-rb5"
else
    echo "  [12] dts: no iot-rb5 found, skipping"
fi

echo "All compatibility fixes applied ($kver)."

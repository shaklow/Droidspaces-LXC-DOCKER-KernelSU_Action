#!/bin/sh
# Build compatibility fixes for SM8250 (Kona) + Linux 4.19
# ---------------------------------------------------------------------------
# Usage: set BUILD_FIXES=sm8250-4.19 in config.env, or source this file directly.
#
# This script is sourced from the kernel source root.
# All commands run relative to: $GITHUB_WORKSPACE/kernel_workspace/android-kernel
# ---------------------------------------------------------------------------

echo "Applying SM8250-4.19 build compatibility fixes..."

# ---- 1. mmu_notifier: backport enum to unsigned long ----
sed -i 's/enum mmu_notifier_event event/unsigned long event/' include/linux/mmu_notifier.h
echo "  [01] mmu_notifier: enum -> unsigned long"

# ---- 2. mmu_notifier: add missing MMU_NOTIFY defines ----
sed -i '/#define _LINUX_MMU_NOTIFIER_H/a #define MMU_NOTIFY_UNMAP 0\n#define MMU_NOTIFY_CLEAR 1' include/linux/mmu_notifier.h
echo "  [02] mmu_notifier: added MMU_NOTIFY_UNMAP/CLEAR"

# ---- 3. VDSO: remove deprecated -n flag (old LLD) ----
sed -i 's/ -n -T/ -T/' arch/arm64/kernel/vdso/Makefile
echo "  [03] vdso: removed -n flag"

# ---- 4. VDSO32: remove -z page-size flags (old LLD) ----
sed -i 's/-z common-page-size=4096//' arch/arm64/kernel/vdso32/Makefile
sed -i 's/-z max-page-size=4096//' arch/arm64/kernel/vdso32/Makefile
echo "  [04] vdso32: removed -z page-size flags"

# ---- 5. head.S: replace \x64 escape (old Clang asm) ----
sed -i 's/\\x64"/d"/' arch/arm64/kernel/head.S
echo "  [05] head.S: fixed \\x escape"

# ---- 6. sha1-ce-core: stub for old Clang ----
printf '.text\n.globl sha1_ce_transform\nsha1_ce_transform:\n    ret\n' > arch/arm64/crypto/sha1-ce-core.S
echo "  [06] sha1-ce-core: replaced with stub"

# ---- 7. KVM: backport API mismatch ----
sed -i 's/kvm_unmap_hva_range(kvm, range->start, range->end)/kvm_unmap_hva_range(kvm, range->start, range->end, 0)/' virt/kvm/kvm_main.c
sed -i 's/follow_pte_pmd(vma->vm_mm, addr, NULL, NULL, \&ptep, NULL, \&ptl)/follow_pte_pmd(vma->vm_mm, addr, NULL, NULL, NULL, \&ptl)/' virt/kvm/kvm_main.c
echo "  [07] kvm: fixed API mismatch"

# ---- 8. lockdep: remove nested param (4.19) ----
sed -i 's/__lock_release(lock, nested, ip)/__lock_release(lock, 0, ip)/' kernel/locking/lockdep.c
echo "  [08] lockdep: removed nested param"

# ---- 9. fault-inject: replace WRITE_ONCE (old Clang) ----
sed -i 's/WRITE_ONCE(current->fail_nth, fail_nth - 1)/(current->fail_nth = fail_nth - 1)/' lib/fault-inject.c
echo "  [09] fault-inject: replaced WRITE_ONCE"

# ---- 10. module: define MODULE_IMPORT_NS (4.19) ----
echo '#define MODULE_IMPORT_NS(ns)' >> include/linux/module.h
echo "  [10] module: added MODULE_IMPORT_NS"

# ---- 11. DTS: skip iot-rb5 (fsa4480 conflict) ----
sed -i '/iot-rb5/d' arch/arm64/boot/dts/vendor/qcom/Makefile
echo "  [11] dts: skipped iot-rb5"

# ---- 12. EFI: remove default y to allow disabling ----
sed -i '/^config EFI$/,/^config /{/default y/d}' arch/arm64/Kconfig
echo "  [12] efi: removed default y from Kconfig"

# ---- 13. tracepoint stubs: vendor hooks + lockdep + ps5169 ----
printf '#include <linux/lockdep.h>\nunsigned long __tracepoint_android_vh_set_memory_x;\nunsigned long __tracepoint_android_vh_set_memory_rw;\nunsigned long __tracepoint_android_vh_set_memory_nx;\nunsigned long __tracepoint_android_vh_set_memory_ro;\nunsigned long __tracepoint_android_vh_check_bpf_syscall;\nunsigned long __tracepoint_android_vh_check_mmap_file;\nunsigned long __tracepoint_android_vh_check_file_open;\nstruct lock_class_key rcu_trace_lock_map;\nint ps5169_cfg_usb;\n' > kernel/trace/stub-vendor-hooks.c
echo 'obj-y += stub-vendor-hooks.o' >> kernel/trace/Makefile
echo "  [13] tracepoint: created stub-vendor-hooks"

# ---- 14. Flicker old-style KSU hooks: define as false for SukiSU compat ----
KSU_HOOKS="ksu_vfs_read_hook ksu_execveat_hook ksu_input_hook"
NEED_KSU_HOOKS=""
for h in $KSU_HOOKS; do
    if grep -rl "$h" fs/ drivers/input/ 2>/dev/null | grep -q .; then NEED_KSU_HOOKS=yes; break; fi
done
if [ "$NEED_KSU_HOOKS" = "yes" ]; then
    printf 'bool ksu_vfs_read_hook;\nbool ksu_execveat_hook;\nbool ksu_input_hook;\n' >> kernel/trace/stub-vendor-hooks.c
    echo "  [14] ksu: defined stub hook flags for Flicker kernel"
else
    echo "  [14] ksu: no old-style hooks found, skipping"
fi

# ---- 15. depot_save_stack: Flicker kernel backported 3-arg API ----
if grep -q "pid_t pid" include/linux/stackdepot.h 2>/dev/null; then
    sed -i 's/depot_save_stack(&dummy, GFP_KERNEL)/depot_save_stack(\&dummy, GFP_KERNEL, 0)/' mm/page_owner.c
    sed -i 's/depot_save_stack(\&trace, flags)/depot_save_stack(\&trace, flags, 0)/' mm/page_owner.c
    echo "  [15] page_owner: fixed depot_save_stack 2-arg → 3-arg (Flicker kernel backport)"
else
    echo "  [15] page_owner: stock stackdepot, skipping"
fi

echo "SM8250-4.19 fixes applied successfully."

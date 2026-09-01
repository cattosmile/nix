# kvm-antidetect.nix — Host-Kernel-Patches gegen KVM-Erkennungssignale
# ----------------------------------------------------------------------------
# 0001 / QemuDetection / VM::KVM_INTERCEPTION (2026-08-30):
# KVM quittiert Hypercalls aus Guest-Userspace (CPL3) stumm mit -KVM_EPERM
# in RAX und keiner Exception — echte Hardware liefert #UD. Detektoren
# (VMAware "hypervisor interception") werten die fehlende Exception als
# Hypervisor-Beweis. Der Patch injiziert #UD wie echte Hardware.
# Kanonische Quelle: QemuDetection/patches/kernel/0001-kvm-cpl3-hypercall-ud.patch
# (Kopie hier, da Flakes keine absoluten Pfade ausserhalb des Baums erlauben.)
#
# 0002 / QemuDetection / VM::TIMER exception-Achse + pafish-Klasse (2026-08-30):
# KVM interceptet #DB bedingungslos (vmx.c vmx_update_exception_bitmap,
# DB_VECTOR immer gesetzt). Ein Gast-#DB (z. B. TF-Flag) kostet damit einen
# VM-Exit, der Syscall-Vergleichspfad (ZwRaiseException) nicht — echte
# Hardware liefert #DB nativ und BILLIGER als den Syscall-Weg. Der Patch
# cleart das DB_VECTOR-Bit, solange kein Gast-Debugging aktiv ist (vor dem
# Nested-OR). Native #DB-Delivery = bare-metal-identisch; schliesst den
# Ausnahme-Latenz-Seitenkanal fuer TIMER und alle Ausnahme-Timing-Pruefungen.
# Kanonische Quelle: QemuDetection/patches/kernel/0002-kvm-db-interception-off.patch
#
# 0004 / QemuDetection / VM::TRAP ("hypervisor interception", 2026-08-30):
# kvm_vcpu_do_singlestep() (nach JEDER emulierten Instruktion mit TF, z. B.
# CPUID) injizierte die #DB mit hartcodiertem DR6_BS-Payload. Echte Hardware
# verschmilzt den Single-Step-Trap mit Execute-Breakpoint-Faults auf der
# Folginstruktion zu EINER #DB, deren DR6 BS UND die Bn-Bits traegt — Windows
# liest DR6 via MOV-DR-Exit aus KVMs Schatten und sah nur BS (VMAware TRAP
# rot, gemessen: dr6=0xffff0ff0|BS, B0=0, 8/8). Der Patch merged die
# Gast-Execute-Breakpoints (kvm_vcpu_check_hw_bp-Idiom wie im bestehenden
# Emulations-Pfad) in den Payload.
# 0005 / QemuDetection / VM::TIMER CPUID-Achse ("timing anomalies", 2026-08-30):
# VMAware TIMER misst CPUID gegen SERIALIZE mit einer Cache-Line-Uhr: ein
# Zaehler-Thread auf einem anderen Kern schreibt eine geteilte Line, der
# Mess-Thread pollt sie; waehrend der Mess-vCPU im Exit ist, burstet die Uhr
# ungebremst (gemessen: cpuid=3464 Ticks vs ref=329, Ratio 10.5, Threshold 2.5).
# Auf Intel ist CPUID ein unbedingter VM-Exit (nicht abschaltbar, anders als
# AMD SVM INTERCEPT_CPUID) — der Exit selbst ist also nicht eliminierbar.
# Der Patch maskiert stattdessen die Uhr: ein Begleit-Kernel-Thread
# (qd_poller, per qd_poller_cpu auf einen freien Host-Kern gepinnt, hier
# E-Core 16) pollt WAHREND des Exit-Handlings die Cache-Lines weiter, auf
# denen der Gast-Thread gesponnen hat (Kandidaten aus den callee-saved
# Registern am CPUID-Exit, gva->gpa->hva einmalig uebersetzt + gecacht).
# Die Uhr bleibt damit auf Cross-Core-Invalidierung getaktet wie bei nativem
# Pollen — asymmetrisch (nur im Exit), generisch (jede Cache-Clock, nicht
# detektorspezifisch), ohne Topologie-Trick und ohne Leistungsverlust
# (Poller laeuft nur bei CPUID-Exits von CPL3-Gast-Threads, schlaeft sonst).
# Aktivieren nach Reboot: echo 16 > /sys/module/kvm/parameters/qd_poller_cpu
# Kanonische Quelle: QemuDetection/patches/kernel/0005-kvm-cpuid-cache-clock-mask.patch
# Rebuild: sudo nixos-rebuild switch --flake /home/user/nix#desktop  + Reboot
# 0006-0010 / QemuDetection / TIMER-Timing-Achse (2026-08-31/09-01):
# 0006 CPUID-Exit-Fastpath, 0007 Re-Entry-Short-Circuit, 0008 TSC-Freeze
# ueber CPUID-Exits (Payback-Design), 0009 RDTSC/RDTSCP-Interception mit
# kompensiertem Return (rdtsc;cpuid;rdtsc 1513 -> 78 Zyklen = Metall),
# 0010 Sturm-gesteuertes Geschwister-Halten gegen die Cache-Uhr.
# ZUSAMMEN mit enable_apicv=0 (unten) — ohne APICv erreichen Kicks die
# Geschwister-vCPUs ueberhaupt als VM-Exits. Host-Kosten: haehere
# Interrupt-Latenz durch fehlendes APICv (~5-10% Interrupt-lastig).
# Kanonische Quellen: QemuDetection/patches/kernel/000{6,7,8,9}-*.patch,
# 0010-kvm-storm-sibling-freeze.patch (in Reihenfolge anwenden!)
# Rebuild: sudo nixos-rebuild switch --flake /home/user/nix#desktop + Reboot
{ config, lib, ... }:

{
  boot.extraModprobeConfig = ''
    options kvm_intel enable_apicv=0
  '';

  boot.kernelPatches = [
    {
      name = "kvm-cpl3-hypercall-ud";
      patch = ./kvm-cpl3-hypercall-ud.patch;
    }
    {
      name = "kvm-db-interception-off";
      patch = ./kvm-db-interception-off.patch;
    }
    {
      name = "kvm-singlestep-hwbp-merge";
      patch = ./kvm-singlestep-hwbp-merge.patch;
    }
    {
      name = "kvm-cpuid-cache-clock-mask";
      patch = ./kvm-cpuid-cache-clock-mask.patch;
    }
    {
      # Konsolidierter TIMER-Stack (0006 Fastpath + 0007 Short-Circuit +
      # 0008 TSC-Freeze + 0009 RDTSC-Interception + 0010 Sibling-Freeze,
      # exakt der auf dem Produktionssystem getestete Modulstand).
      name = "kvm-qd-timer-stack";
      patch = ./kvm-qd-timer-stack.patch;
    }
  ];
}

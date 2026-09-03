# QD-Kernel-Patch-Staging — NICHT VERDRAHTET

## REGEL (Nutzer-Entscheidung 2026-09-03, verbindlich)

QD-Entwicklungspatches werden **NIE ohne explizites Nutzer-Approval** in die
Main-Config (`kvm-antidetect.nix`) integriert. Kein Agent, keine Session,
kein Skript trägt Patches dorthin ein — auch nicht „vorbeugend" oder
„rebootfest". Das Approval des Nutzers kommt voraussichtlich erst zum
Projektende; bis dahin bleibt die Main-Config patch-frei.

Workflow für alle Zukunft:

1. **Entwicklung/Verifikation ausschließlich per Hotswap**: Kernel-Baum
   `/home/user/kernel-dev/linux-6.18.43` → `build-kvm.sh` →
   `rmmod kvm_intel` / `insmod ...ko` (kein Host-Reboot, kein Flake).
   Verifiziert = läuft in der VM UND auf dem Host-System.
2. **Kaninische Quelle** der Patches: `QemuDetection/patches/kernel/`.
   Diese Kopien hier sind der eingefrorene Stand bei Auslagerung.
3. **Freigabe**: Nur nach ausdrücklicher Nutzer-Aussage. Dann: Patch hier
   in `kvm-antidetect.nix` referenzieren (Reihenfolge unten beachten!) und
   Freigabedatum + Nutzerzitat als Kommentar festhalten. Vor dem Switch:
   `nix build /home/user/nix#nixosConfigurations."desktop".config.system.build.toplevel`
   muss durchlaufen (Patch-Applikation fehlerfrei) — Switch macht der Nutzer selbst.

## Patches (in dieser Reihenfolge anwenden)

| # | Datei | Zweck / Stand |
|---|------|---------------|
| 1 | `kvm-cpl3-hypercall-ud.patch` | 0001: CPL3-Hypercall → #UD wie echte Hardware (VM::KVM_INTERCEPTION). Hotswap-verifiziert 2026-08-30 (kvm.ko/x86.c). |
| 2 | `kvm-db-interception-off.patch` | 0002: #DB nativ liefern statt zu intercepten (Ausnahme-Latenz-Seitenkanal). Hotswap-verifiziert 2026-08-30. |
| 3 | `kvm-singlestep-hwbp-merge.patch` | 0004: DR6-BS+BN-Payload-Merge bei emuliertem Singlestep (VM::TRAP). Hotswap-verifiziert 2026-08-30. |
| 4 | `kvm-cpuid-cache-clock-mask.patch` | 0005: qd_poller-Cache-Uhr-Maskierung. Achtung: braucht Runtime-Aktivierung `echo 16 > /sys/module/kvm/parameters/qd_poller_cpu`. |
| 5 | `kvm-qd-timer-stack.patch` | 0006–0010 konsolidiert (CPUID-Fastpath, Re-Entry-Short-Circuit, TSC-Freeze, 0009 RDTSC-Interception+Kompensation, 0010 Sibling-Freeze). **BEI FREIGABE PRÜFEN: qd_storm (0010) ist seit 2026-09-02 obsolet — Produktionsstand ist qd_storm=0; der Stack hat evtl. noch default 1 → vor Freigabe auf Finalstand heben.** |
| 6 | `kvm-ept-counter-trap.patch` | 0011: EPT-Falle auf VMAware-Counter-Seite (TIMER grün). Hunk-6-Whitespace 2026-09-03 repariert (appliziert sauber gegen pristine+Stack). **Defaults noch NICHT Finalstand**: getestet sind `qd_storm=0 qd_ct_ripstorm=8 qd_ct_confirm=1 qd_ct_win_ms=500` per insmod-Params; Finalstand-Update (Defaults + evtl. v18-Teile) offen. |

Zusammen mit Patch 5/6 aktiv: `boot.extraModprobeConfig = "options kvm_intel
enable_apicv=0"` (war Teil der alten Verdrahtung, siehe git history von
`kvm-antidetect.nix`).

## Historie

- 2026-09-01: Stack (0006–0010) + 0001–0010 in `kvm-antidetect.nix` verdrahtet
  (vorbereitet für einen Nutzer-Switch, der nie kam).
- 2026-09-02: 0011 dazuverdrahtet — Regenerierung gegen verunreinigten
  Arbeitsbaum ohne pristine-Dry-Run → Hunk 6 (Whitespace in `vmx_exit()`)
  brach ab 2026-09-03 den kompletten `nixos-rebuild switch`.
- 2026-09-03: Nutzer-Regel (siehe oben) → ALLE QD-Patches aus der Main-Config
  entfernt, in dieses Staging ausgelagert; Hunk-6-Fix am 0011; Main-Config
  baut wieder (unpatchter Stock-Kernel).

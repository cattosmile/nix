# kvm-antidetect.nix — QD-Kernel-Patches: FREIGABE-GATE (Regel 2026-09-03)
# ============================================================================
# REGEL (Nutzer-Entscheid 2026-09-03, verbindlich — siehe qd-staging/README.md):
#
#   QD-Entwicklungspatches werden NIE ohne explizites Nutzer-Approval in
#   diese Main-Config integriert. Kein Agent, keine Session, kein Skript
#   traegt Patches hier ein — auch nicht "vorbeugend" oder "rebootfest".
#
#   Kandidat wird ein Patch erst durch Hotswap-Verifikation (kernel-dev-Baum
#   -> build-kvm.sh -> rmmod/insmod, kein Host-Reboot): muss in der VM UND
#   auf dem Host laufen. Freigabe nur durch ausdrueckliche Nutzer-Aussage;
#   bis dahin bleibt diese Liste LEER (Stock-Kernel).
#
#   Eingefrorene Patch-Kopien + Doku: ./qd-staging/ (nicht verdrahtet).
#   Kanonische Quellen: QemuDetection/patches/kernel/.
#
# Freigegeben (Datum + Nutzerzitat):
#   (noch nichts — 2026-09-03 alle QD-Patches ausgelagert, s. qd-staging/)
# ============================================================================
{ ... }:

{
  # BIS ZUR NAECHSTEN FREIGABE LEER — Regeln siehe Dateikopf.
  boot.kernelPatches = [ ];
}

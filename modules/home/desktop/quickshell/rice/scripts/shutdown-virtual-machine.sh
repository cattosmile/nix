#!/usr/bin/env bash

set -u

connection='qemu:///system'
vm_name="${1:-}"

case "$vm_name" in
    ''|*[!a-zA-Z0-9._-]*)
        printf 'Invalid virtual machine name\n' >&2
        exit 2
        ;;
esac

state="$(virsh -c "$connection" domstate "$vm_name" 2>/dev/null \
    | head -n 1 | sed 's/[[:space:]]*$//')"

# Send the guest a normal ACPI shutdown request. Never force-stop a VM here;
# the launcher confirmation is specifically for a graceful guest shutdown.
if [ "$state" = "running" ]; then
    exec virsh -c "$connection" shutdown "$vm_name"
fi

exit 0

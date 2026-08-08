#!/usr/bin/env bash

set -u

connection='qemu:///system'
force_shutdown=0

if [ "${1:-}" = '--force' ]; then
    force_shutdown=1
    shift
fi

vm_name="${1:-}"

case "$vm_name" in
    ''|*[!a-zA-Z0-9._-]*)
        printf 'Invalid virtual machine name\n' >&2
        exit 2
        ;;
esac

state="$(virsh -c "$connection" domstate "$vm_name" 2>/dev/null \
    | head -n 1 | sed 's/[[:space:]]*$//')"

if [ "$state" = "running" ]; then
    if [ "$force_shutdown" -eq 1 ]; then
        # virsh destroy is the libvirt name for an immediate power-off. It
        # does not undefine or modify the VM.
        exec virsh -c "$connection" destroy "$vm_name"
    fi

    # Send the guest a normal ACPI shutdown request and wait for its response.
    exec virsh -c "$connection" shutdown "$vm_name"
fi

exit 0

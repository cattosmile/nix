{ pkgs, ... }:

let
  win10nvmeXml = pkgs.writeText "win10-nvme.xml" ''
    <domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
      <name>win10-nvme</name>
      <uuid>7c2a4b91-d83f-4e12-a6b4-928c7f1e5d3a</uuid>
      <metadata>
        <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
          <libosinfo:os id="http://microsoft.com/win/10"/>
        </libosinfo:libosinfo>
      </metadata>
      <memory unit="KiB">16777216</memory>
      <currentMemory unit="KiB">16777216</currentMemory>
      <vcpu placement="static">12</vcpu>
      <cputune>
        <vcpupin vcpu="0" cpuset="0"/>
        <vcpupin vcpu="1" cpuset="1"/>
        <vcpupin vcpu="2" cpuset="2"/>
        <vcpupin vcpu="3" cpuset="3"/>
        <vcpupin vcpu="4" cpuset="4"/>
        <vcpupin vcpu="5" cpuset="5"/>
        <vcpupin vcpu="6" cpuset="6"/>
        <vcpupin vcpu="7" cpuset="7"/>
        <vcpupin vcpu="8" cpuset="8"/>
        <vcpupin vcpu="9" cpuset="9"/>
        <vcpupin vcpu="10" cpuset="10"/>
        <vcpupin vcpu="11" cpuset="11"/>
      </cputune>
      <sysinfo type="smbios">
        <bios>
          <entry name="vendor">American Megatrends Inc.</entry>
          <entry name="version">3601</entry>
          <entry name="date">10/12/2024</entry>
        </bios>
        <system>
          <entry name="manufacturer">ASUS</entry>
          <entry name="product">ROG STRIX B660-F GAMING WIFI</entry>
          <entry name="version">1.0</entry>
          <entry name="serial">P3M0KC74921W</entry>
          <entry name="uuid">7c2a4b91-d83f-4e12-a6b4-928c7f1e5d3a</entry>
          <entry name="sku">SKU-Default</entry>
          <entry name="family">Rog Strix</entry>
        </system>
        <baseBoard>
          <entry name="manufacturer">ASUS</entry>
          <entry name="product">ROG STRIX B660-F GAMING WIFI</entry>
          <entry name="version">1.0</entry>
          <entry name="serial">P3M0KC74921W</entry>
        </baseBoard>
        <chassis>
          <entry name="manufacturer">ASUS</entry>
          <entry name="version">1.0</entry>
          <entry name="serial">P3M0KC74921W</entry>
          <entry name="asset">Default String</entry>
          <entry name="sku">SKU-Default</entry>
        </chassis>
      </sysinfo>
      <os firmware="efi">
        <type arch="x86_64" machine="pc-q35-10.2">hvm</type>
        <firmware>
          <feature enabled="no" name="enrolled-keys"/>
          <feature enabled="yes" name="secure-boot"/>
        </firmware>
        <loader readonly="yes" secure="yes" type="pflash" format="raw">/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd</loader>
        <nvram template="/run/libvirt/nix-ovmf/edk2-i386-vars.fd" templateFormat="raw" format="raw">/var/lib/libvirt/qemu/nvram/win10-nvme_VARS.fd</nvram>
        <smbios mode="sysinfo"/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <hyperv mode="custom">
          <relaxed state="on"/>
          <vapic state="on"/>
          <spinlocks state="on" retries="8191"/>
          <vpindex state="on"/>
          <runtime state="on"/>
          <synic state="on"/>
          <stimer state="on"/>
          <reset state="on"/>
          <vendor_id state="on" value="GenuineIntel"/>
          <frequencies state="on"/>
        </hyperv>
        <kvm>
          <hidden state="on"/>
        </kvm>
        <vmport state="off"/>
        <smm state="on"/>
      </features>
      <cpu mode="host-passthrough" check="none" migratable="on">
        <topology sockets="1" dies="1" clusters="1" cores="6" threads="2"/>
        <cache mode="passthrough"/>
        <feature policy="disable" name="hypervisor"/>
      </cpu>
      <clock offset="localtime">
        <timer name="rtc" tickpolicy="catchup"/>
        <timer name="pit" tickpolicy="delay"/>
        <timer name="hpet" present="no"/>
        <timer name="hypervclock" present="yes"/>
        <timer name="tsc" present="yes" mode="native"/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <pm>
        <suspend-to-mem enabled="no"/>
        <suspend-to-disk enabled="no"/>
      </pm>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
        <controller type="pci" index="0" model="pcie-root"/>
        <controller type="pci" index="1" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="1" port="0x10"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
        </controller>
        <controller type="pci" index="2" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="2" port="0x11"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
        </controller>
        <controller type="pci" index="3" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="3" port="0x12"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
        </controller>
        <controller type="pci" index="4" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="4" port="0x13"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
        </controller>
        <controller type="pci" index="5" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="5" port="0x14"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
        </controller>
        <controller type="pci" index="6" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="6" port="0x15"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
        </controller>
        <controller type="pci" index="7" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="7" port="0x16"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x6"/>
        </controller>
        <controller type="pci" index="8" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="8" port="0x17"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x7"/>
        </controller>
        <controller type="pci" index="9" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="9" port="0x18"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0" multifunction="on"/>
        </controller>
        <controller type="pci" index="10" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="10" port="0x19"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x1"/>
        </controller>
        <controller type="pci" index="11" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="11" port="0x1a"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x2"/>
        </controller>
        <controller type="pci" index="12" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="12" port="0x1b"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x3"/>
        </controller>
        <controller type="pci" index="13" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="13" port="0x1c"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x4"/>
        </controller>
        <controller type="pci" index="14" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="14" port="0x1d"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x5"/>
        </controller>
        <controller type="pci" index="15" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="15" port="0x1e"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x6"/>
        </controller>
        <controller type="pci" index="16" model="pcie-root-port">
          <model name="pcie-root-port"/>
          <target chassis="16" port="0x8"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
        </controller>
        <controller type="pci" index="17" model="pcie-to-pci-bridge">
          <model name="pcie-pci-bridge"/>
          <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
        </controller>
        <controller type="virtio-serial" index="0">
          <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
        </controller>
        <controller type="sata" index="0">
          <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
        </controller>
        <controller type="usb" index="0" model="qemu-xhci" ports="15">
          <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
        </controller>
        <interface type="network">
          <mac address="a8:5e:46:9b:2c:14"/>
          <source network="default"/>
          <model type="e1000e"/>
          <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
        </interface>
        <serial type="pty">
          <target type="isa-serial" port="0">
            <model name="isa-serial"/>
          </target>
        </serial>
        <console type="pty">
          <target type="serial" port="0"/>
        </console>
        <channel type="spicevmc">
          <target type="virtio" name="com.redhat.spice.0"/>
          <address type="virtio-serial" controller="0" bus="0" port="1"/>
        </channel>
        <input type="mouse" bus="ps2"/>
        <input type="keyboard" bus="ps2"/>
        <graphics type="spice" autoport="yes" listen="127.0.0.1">
          <listen type="address" address="127.0.0.1"/>
          <image compression="off"/>
        </graphics>
        <sound model="ich9">
          <audio id="1"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x1b" function="0x0"/>
        </sound>
        <audio id="1" type="spice"/>
        <video>
          <model type="vga" vram="16384" heads="1" primary="yes"/>
          <address type="pci" domain="0x0000" bus="0x11" slot="0x01" function="0x0"/>
        </video>
        <hostdev mode="subsystem" type="pci" managed="yes">
          <source>
            <address domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
          </source>
          <boot order="1"/>
          <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
        </hostdev>
        <hostdev mode="subsystem" type="pci" managed="yes">
          <source>
            <address domain="0x0000" bus="0x09" slot="0x00" function="0x0"/>
          </source>
          <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
        </hostdev>
        <hostdev mode="subsystem" type="pci" managed="yes">
          <source>
            <address domain="0x0000" bus="0x09" slot="0x00" function="0x1"/>
          </source>
          <address type="pci" domain="0x0000" bus="0x07" slot="0x00" function="0x0"/>
        </hostdev>
        <watchdog model="itco" action="reset"/>
        <memballoon model="none"/>
      </devices>
      <qemu:commandline>
        <qemu:arg value="-object"/>
        <qemu:arg value="input-linux,id=mouse1,evdev=/dev/input/by-id/usb-Logitech_USB_Receiver-event-mouse"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="input-linux,id=kbd1,evdev=/dev/input/by-id/usb-Lenovo_Lenovo_Traditional_USB_Keyboard-event-kbd,grab_all=on,repeat=on,grab-toggle=ctrl-ctrl"/>
        <qemu:arg value="-device"/>
        <qemu:arg value="{'driver':'ivshmem-plain','id':'shmem0','memdev':'looking-glass'}"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="{'qom-type':'memory-backend-file','id':'looking-glass','mem-path':'/dev/kvmfr0','size':33554432,'share':true}"/>
      </qemu:commandline>
    </domain>
  '';

  win10normalXml = pkgs.writeText "win10-normal.xml" ''
    <domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
      <name>win10-normal</name>
      <uuid>8f4e3c2b-1a0d-4e5f-8c7b-6a5d4e3f2c1b</uuid>
      <metadata>
        <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
          <libosinfo:os id="http://microsoft.com/win/10"/>
        </libosinfo:libosinfo>
      </metadata>
      <memory unit="KiB">8388608</memory>
      <currentMemory unit="KiB">8388608</currentMemory>
      <memoryBacking>
        <source type="memfd"/>
        <access mode="shared"/>
      </memoryBacking>
      <vcpu placement="static">4</vcpu>
      <os firmware="efi">
        <type arch="x86_64" machine="pc-q35-10.2">hvm</type>
        <firmware>
          <feature enabled="no" name="enrolled-keys"/>
          <feature enabled="yes" name="secure-boot"/>
        </firmware>
        <loader readonly="yes" secure="yes" type="pflash" format="raw">/run/libvirt/nix-ovmf/edk2-x86_64-secure-code.fd</loader>
        <nvram template="/run/libvirt/nix-ovmf/edk2-i386-vars.fd" templateFormat="raw" format="raw">/var/lib/libvirt/qemu/nvram/win10-normal_VARS.fd</nvram>
        <smbios mode="host"/>
      </os>
      <features>
        <acpi/>
        <apic/>
        <hyperv mode="custom">
          <relaxed state="on"/>
          <vapic state="on"/>
          <spinlocks state="on" retries="8191"/>
          <vpindex state="on"/>
          <runtime state="on"/>
          <synic state="on"/>
          <stimer state="on"/>
          <reset state="on"/>
          <vendor_id state="on" value="GenuineIntel"/>
          <frequencies state="on"/>
        </hyperv>
        <kvm>
          <hidden state="on"/>
        </kvm>
        <vmport state="off"/>
        <smm state="on"/>
      </features>
      <cpu mode="host-passthrough" check="none" migratable="on">
        <topology sockets="1" dies="1" clusters="1" cores="2" threads="2"/>
        <cache mode="passthrough"/>
        <feature policy="disable" name="hypervisor"/>
      </cpu>
      <clock offset="localtime">
        <timer name="rtc" tickpolicy="catchup"/>
        <timer name="pit" tickpolicy="delay"/>
        <timer name="hpet" present="no"/>
        <timer name="hypervclock" present="yes"/>
        <timer name="tsc" present="yes" mode="native"/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <pm>
        <suspend-to-mem enabled="no"/>
        <suspend-to-disk enabled="no"/>
      </pm>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
        <controller type="sata" index="0"/>
        <controller type="usb" index="0" model="qemu-xhci" ports="15"/>
        <controller type="virtio-serial" index="0"/>
        <disk type="file" device="disk">
          <driver name="qemu" type="qcow2"/>
          <source file="/var/lib/libvirt/images/win10-normal.qcow2"/>
          <target dev="sda" bus="sata"/>
          <boot order="1"/>
        </disk>
        <interface type="network">
          <mac address="52:54:00:ab:cd:ef"/>
          <source network="default"/>
          <model type="e1000e"/>
        </interface>
        <serial type="pty">
          <target type="isa-serial" port="0">
            <model name="isa-serial"/>
          </target>
        </serial>
        <console type="pty">
          <target type="serial" port="0"/>
        </console>
        <channel type="spicevmc">
          <target type="virtio" name="com.redhat.spice.0"/>
        </channel>
        <input type="mouse" bus="virtio"/>
        <input type="keyboard" bus="virtio"/>
        <graphics type="spice" autoport="yes" listen="127.0.0.1">
          <listen type="address" address="127.0.0.1"/>
          <image compression="off"/>
        </graphics>
        <sound model="ich9"/>
        <audio id="1" type="spice"/>
        <hostdev mode="subsystem" type="pci" managed="yes">
          <source>
            <address domain="0x0000" bus="0x09" slot="0x00" function="0x0"/>
          </source>
        </hostdev>
        <hostdev mode="subsystem" type="pci" managed="yes">
          <source>
            <address domain="0x0000" bus="0x09" slot="0x00" function="0x1"/>
          </source>
        </hostdev>
        <memballoon model="none"/>
      </devices>
      <qemu:commandline>
        <qemu:arg value="-object"/>
        <qemu:arg value="input-linux,id=mouse1,evdev=/dev/input/by-id/usb-Logitech_USB_Receiver-event-mouse"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="input-linux,id=kbd1,evdev=/dev/input/by-id/usb-Lenovo_Lenovo_Traditional_USB_Keyboard-event-kbd,grab_all=on,repeat=on,grab-toggle=ctrl-ctrl"/>
        <qemu:arg value="-device"/>
        <qemu:arg value="{'driver':'ivshmem-plain','id':'shmem0','memdev':'looking-glass'}"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="{'qom-type':'memory-backend-file','id':'looking-glass','mem-path':'/dev/kvmfr0','size':33554432,'share':true}"/>
      </qemu:commandline>
    </domain>
  '';
in
{
  systemd.services.libvirt-create-win10-normal-disk = {
    description = "Create win10-normal 100GB disk image";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    path = [ pkgs.qemu ];
    script = ''
      mkdir -p /var/lib/libvirt/images
      if [ ! -f /var/lib/libvirt/images/win10-normal.qcow2 ]; then
        qemu-img create -f qcow2 /var/lib/libvirt/images/win10-normal.qcow2 100G
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.services.libvirtd-config = {
    serviceConfig.ExecStartPre = [
      "${pkgs.coreutils}/bin/rm -rf /var/cache/libvirt/qemu/capabilities"
    ];
  };

  systemd.services.libvirt-define-win10-nvme = {
    description = "Declaratively define the win10-nvme VM";
    wantedBy = [ "multi-user.target" ];
    after = [ "libvirtd.service" "libvirtd-config.service" ];
    requires = [ "libvirtd.service" "libvirtd-config.service" ];
    path = [ pkgs.libvirt ];

    script = ''
      virsh define ${win10nvmeXml}
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  systemd.services.libvirt-define-win10-normal = {
    description = "Declaratively define the win10-normal VM";
    wantedBy = [ "multi-user.target" ];
    after = [ "libvirtd.service" "libvirtd-config.service" "libvirt-create-win10-normal-disk.service" ];
    requires = [ "libvirtd.service" "libvirtd-config.service" ];
    path = [ pkgs.libvirt ];

    script = ''
      virsh define ${win10normalXml}
    '';

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };
}

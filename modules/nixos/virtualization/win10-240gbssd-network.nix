{ physicalInterface }:

''
  <interface type="direct">
    <mac address="a8:5e:46:9b:2c:14"/>
    <source dev="${physicalInterface}" mode="bridge"/>
    <model type="e1000e"/>
    <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
  </interface>
''

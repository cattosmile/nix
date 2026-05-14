{ pkgs, ... }:

# Generate Hased Password
# echo "mypassword" | mkpasswd -s
#
# Edit Secrets:
# nix run nixpkgs#sops -- hosts/<hostname>/secrets.yaml
#
# Add new host:
# 1. On the new host: cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
# 2. Add the age public key to .sops.yaml
# 3. Create hosts/<hostname>/secrets.yaml with sops
# 4. Run: nix run nixpkgs#sops updatekeys hosts/<hostname>/secrets.yaml

{
  sops = {
    age.keyFile = "/var/lib/sops-nix/key.txt";

    secrets = {
      user_password = {
        neededForUsers = true;
      };
      root_password = {
        neededForUsers = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    age
    sops
  ];
}

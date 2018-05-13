rec {
  preview1 = import ./preview1;
  rc1 = import ./rc1;
  "*" = import ./rc1;
  meta = import ./meta.nix;
}
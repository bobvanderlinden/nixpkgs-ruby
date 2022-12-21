{
  versions.sources = {
    "2.6.14" = {
      url = "http://production.cf.rubygems.org/rubygems/rubygems-2.6.14.tgz";
      hash = "sha256-QGpF0lhwf1IkGEPpx5Arvc8A5+3D6IzbecRmWbR4Uew=";
    };
    "2.7.6" = {
      url = "http://production.cf.rubygems.org/rubygems/rubygems-2.7.6.tgz";
      sha256 = "1sqy6z1kngq91nxmv1hw4xhw1ycwx9s76hfbpcdlgkm9haji9xv7";
    };
    "3.2.33" = {
      url = "http://production.cf.rubygems.org/rubygems/rubygems-3.2.33.tgz";
      hash = "sha256-bIQIzS4F3IdwwxdmH0jVnNKcrLzRji8K7V1LqoibkC0=";
    };
  };
  versions.aliases = {
    "" = "3.2.33";
    "2_6" = "2.6.14";
    "2_7" = "2.7.6";
    "3_0" = "3.2.33";
  };
  packageFn = ./package-fn.nix;
  overridesFn = ./overrides.nix;
}

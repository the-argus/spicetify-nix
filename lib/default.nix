{ pkgs, lib, ... }:
let
  customToINI = lib.generators.toINI {
    # specifies how to format a key/value pair
    mkKeyValue = lib.generators.mkKeyValueDefault
      {
        # specifies the generated string for a subset of nix values
        mkValueString = v:
          if v == true then "1"
          else if v == false then "0"
          # else if isString v then ''"${v}"''
          # and delegates all other values to the default generator
          else lib.generators.mkValueStringDefault { } v;
      } "=";
  };
in
{
  types = import ./types.nix { inherit pkgs lib; };

  createXpuiINI = xpui: (customToINI xpui);
}

{ 
  lib,
  stdenv,
  fetchurl,
  unzip,
  zip,
  zulu17,
  which
}: let 

  pname = "sonicwall";
  version = "12.42.00673";
  short_version = "12.4.2";

  meta = with lib; {
    description = "SonicWall ConnectTunnel VPN";
    homepage = "https://www.sonicwall.com";
    downloadPage = "https://www.sonicwall.com/products/remote-access/vpn-clients/";
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };

in stdenv.mkDerivation {
    inherit pname version short_version meta;

    src = fetchurl {
      url =  "https://software.sonicwall.com/CT-NX-VPNClients/CT-${short_version}/ConnectTunnel_Linux64-${version}.tar";
      hash = "sha256-QC8FWyDUU1AWvf8yU/+8cbmZaDcXBYFVt413yz38B1Q=";
    };

    buildInputs = [
      unzip
      zip
    ];    

    unpackPhase = ''
      tar -xf $src
    '';

    installPhase = ''

      # Extracting binaries
      ls . | grep ConnectTunnel*.tar.bz2 | xargs tar -xf

      cd usr/local/Aventail

      # Jar "patch" start (Hacky as heck, but I have no idea on how to do this properly)
      unzip nui/nui.jar -d nuiPatch >/dev/null

      #   /bin/bash -> ///bin/sh (keep string len)
      sed -e "s/\/bin\/bash/\/\/\/bin\/sh/" nuiPatch/com/sonicwall/nixconnect/dao/PlatformInfo.class > nuiPatch/com/sonicwall/nixconnect/dao/PlatformInfo__.class
      mv nuiPatch/com/sonicwall/nixconnect/dao/PlatformInfo__.class nuiPatch/com/sonicwall/nixconnect/dao/PlatformInfo.class

      sed -e "s/\/bin\/bash/\/\/\/bin\/sh/" nuiPatch/com/sonicwall/connect/util/NixScriptExecutor.class > nuiPatch/com/sonicwall/connect/util/NixScriptExecutor__.class
      mv nuiPatch/com/sonicwall/connect/util/NixScriptExecutor__.class nuiPatch/com/sonicwall/connect/util/NixScriptExecutor.class

      #   /usr/local/Aventail/AvConnect -> /run/wrappers/bin/AvConnect (needs suid wrapper anyway)
      sed -e "s/\/usr\/local\/Aventail/\/\/\/run\/wrappers\/bin/" nuiPatch/com/sonicwall/nixconnect/util/Util.class > nuiPatch/com/sonicwall/nixconnect/util/Util__.class
      mv nuiPatch/com/sonicwall/nixconnect/util/Util__.class nuiPatch/com/sonicwall/nixconnect/util/Util.class

      cd nuiPatch
      zip ../nui/nui__.jar . -r >/dev/null
      # Jar "patch" end

      cd ..

      install -Dm 644 nui/nui__.jar $out/usr/local/Aventail/nui/nui.jar
      install -Dm 644 man/ct.5 $out/usr/local/Aventail/man/ct.5
      install -Dm 755 startct.sh $out/usr/local/Aventail/startct.sh
      install -Dm 755 startctui.sh $out/usr/local/Aventail/startctui.sh
      install -Dm 755 AvConnect $out/usr/local/Aventail/AvConnect


      substituteInPlace \
        $out/usr/local/Aventail/startct.sh \
        --replace-warn /usr/ $out/usr/ \
        --replace-warn "java -version" "${zulu17}/bin/java -version" \
        --replace-warn "which java" "${which}/bin/which ${zulu17}/bin/java" \
        --replace-warn "java \$XG_DEBUG" "${zulu17}/bin/java $XG_DEBUG"

      substituteInPlace \
        $out/usr/local/Aventail/startctui.sh \
        --replace-warn /usr/ $out/usr/ \
        --replace-warn "java -version" "${zulu17}/bin/java -version" \
        --replace-warn "which java" "${which}/bin/which ${zulu17}/bin/java" \
        --replace-warn "java \$XG_DEBUG" "${zulu17}/bin/java $XG_DEBUG"

      mkdir -p $out/bin/
      ln -s $out/usr/local/Aventail/startct.sh $out/bin/startct
      ln -s $out/usr/local/Aventail/startctui.sh $out/bin/startctui
    '';

    postInstall = ''
      installManPage $out/usr/local/Aventail/man/ct.5
    '';

    preFixup = let
      libPath = lib.makeLibraryPath [
        stdenv.cc.cc.lib # libstdc++.so.6
      ];
    in ''
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "${libPath}" \
        $out/usr/local/Aventail/AvConnect
    '';
}
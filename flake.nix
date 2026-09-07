{
  description = "Protokol flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux"; 
      pkgs = import nixpkgs { inherit system; };

      # All necessary libraries
      ProtokolLibs = with pkgs; [
        glib            
        
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav
        
        xorg.libXxf86vm  
        xorg.libX11
        xorg.libXext
        xorg.libXrender
        xorg.libXtst
        xorg.libXi
        
        libGL         
        alsa-lib     
        
        freetype
      ];

      Protokol-pkg = pkgs.stdenv.mkDerivation {
        pname = "Protokol";
        version = "latest"; 

        src = ./.;

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
          pkgs.makeWrapper
        ];

        # Provides libraries to autoPatchelfHook at build time
        buildInputs = ProtokolLibs;

        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          cp Protokol $out/bin/Protokol
          chmod +x $out/bin/Protokol

          # Wrap the binary with ALL required runtime dependencies locked in
          wrapProgram $out/bin/Protokol \
            --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath ProtokolLibs}" \
            --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
              gstreamer
              gst-plugins-base
              gst-plugins-good
              gst-plugins-bad
              gst-plugins-ugly
              gst-libav
            ])}"

          runHook postInstall
        '';

        meta = with pkgs.lib; {
          description = "Protokol Midi Logging and more";
          homepage = "https://hexler.net/Protokol";
          platforms = platforms.linux;
        };
      };

    in
    {
      packages.${system}.default = Protokol-pkg;

      devShells.${system}.default = pkgs.mkShell {
        # The package is fully self-contained now; no shellHooks needed.
        packages = [ Protokol-pkg ];
      };
    
      apps.${system} = {
        default = {
          type = "app";
          program = "${Protokol-pkg}/bin/Protokol";
          meta.description = "Explore your midi logs with Protokol";
        };
      };
    };
}

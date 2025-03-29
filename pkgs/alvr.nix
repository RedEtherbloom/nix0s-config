{
  lib,
  rustPlatform,
  fetchFromGitHub,
  replaceVars,
  nix-update-script,
  pkg-config,
  autoAddDriverRunpath,
  alsa-lib,
  brotli,
  bzip2,
  celt,
  jack2,
  lame,
  libX11,
  libXi,
  libXrandr,
  libXcursor,
  libdrm,
  libglvnd,
  libogg,
  libpng,
  libtheora,
  libunwind,
  libva,
  libvdpau,
  libxkbcommon,
  openssl,
  openvr,
  pipewire,
  rust-cbindgen,
  soxr,
  vulkan-headers,
  vulkan-loader,
  vulkan-tools,
  wayland,
  xvidcore,
  curl,
  coreutils,
  findutils,
  diffutils,
  gnused,
  gnugrep,
  gawk,
  gnutar,
  gzip,
  gnumake,
  bashNonInteractive,
  patch,
  xz,
  file,
  pkgs,
  nv-codec-headers-12,
}: let
  version = "20.12.0";

  src = fetchFromGitHub {
    owner = "alvr-org";
    repo = "ALVR";
    tag = "v${version}";
    fetchSubmodules = true; #TODO devendor openvr
    hash = "sha256-4tilgZCUY5PehR0SQDOBahLaPVH4n5cgE7Ghw+SCgQk=";
  };
  x264 = pkgs.x264.overrideAttrs (_: _: {
    configureFlags = [
      "--enable-static"
      "--disable-cli"
      "--enable-pic"
    ];
  });
  ffmpeg_6_with_x264 = pkgs.ffmpeg_6.override {inherit x264;};
  ffmpeg_6 = ffmpeg_6_with_x264.overrideAttrs (_: prevAttrs: {
    configureFlags = [
      "--enable-gpl"
      "--enable-version3"
      "--enable-static"
      "--disable-programs"
      "--disable-doc"
      "--disable-avdevice"
      "--disable-avformat"
      "--disable-swresample"
      "--disable-swscale"
      "--disable-postproc"
      "--disable-network"
      "--disable-everything"
      "--enable-encoder=h264_vaapi"
      "--enable-encoder=hevc_vaapi"
      "--enable-encoder=av1_vaapi"
      "--enable-hwaccel=h264_vaapi"
      "--enable-hwaccel=hevc_vaapi"
      "--enable-hwaccel=av1_vaapi"
      "--enable-filter=scale_vaapi"
      "--enable-vulkan"
      "--enable-libdrm"
      "--enable-pic"
      "--enable-rpath"
      "--fatal-warnings"
    ];
    # Missing the ldso magic we don't quite get yet

    # patches =
    #   prevAttrs.patches
    #   # Fetch custom ALVR patches
    #   ++ lib.filesystem.listFilesRecursive "${src}/alvr/xtask/patches/";
  });
in
  rustPlatform.buildRustPackage rec {
    pname = "alvr";
    inherit version src;

    useFetchCargoVendor = true;
    cargoHash = "sha256-ocwNVdozZeF0hYDhYMshSbRHKfBFawIcO7UbTwk10xc=";

    patches = [
      (replaceVars ./fix-finding-libs.patch {
        ffmpeg_6 = lib.getDev ffmpeg_6;
        x264 = lib.getDev x264;
      })
      ./alvr-enable-encoder-debug.patch
    ];

    env = {
      NIX_CFLAGS_COMPILE = toString [
        "-lbrotlicommon"
        "-lbrotlidec"
        "-lcrypto"
        "-lpng"
        "-lssl"
      ];
    };

    RUSTFLAGS = map (a: "-C link-arg=${a}") [
      "-Wl,--push-state,--no-as-needed"
      "-lEGL"
      "-lwayland-client"
      "-lxkbcommon"
      "-Wl,--pop-state"
    ];

    nativeBuildInputs = [
      rust-cbindgen
      pkg-config
      rustPlatform.bindgenHook
      autoAddDriverRunpath
      vulkan-tools
      curl

      coreutils
      findutils
      diffutils
      gnused
      gnugrep
      gawk
      gnutar
      gzip
      bzip2.bin
      gnumake
      bashNonInteractive
      patch
      xz.bin

      # The `file` command is added here because an enormous number of
      # packages have a vendored dependency upon `file` in their
      # `./configure` script, due to libtool<=2.4.6, or due to
      # libtool>=2.4.7 in which the package author decided to set FILECMD
      # when running libtoolize.  In fact, file-5.4.6 *depends on itself*
      # and tries to invoke `file` from its own ./configure script.
      file

      nv-codec-headers-12
    ];

    buildInputs = [
      alsa-lib
      brotli
      bzip2
      celt
      curl
      ffmpeg_6
      jack2
      lame
      libX11
      libXcursor
      libXi
      libXrandr
      libdrm
      libglvnd
      libogg
      libpng
      libtheora
      libunwind
      libva
      libvdpau
      libxkbcommon
      openssl
      openvr
      pipewire
      soxr
      vulkan-headers
      vulkan-loader
      vulkan-tools
      wayland
      x264
      xvidcore

      coreutils
      findutils
      diffutils
      gnused
      gnugrep
      gawk
      gnutar
      gzip
      bzip2.bin
      gnumake
      bashNonInteractive
      patch
      xz.bin

      # The `file` command is added here because an enormous number of
      # packages have a vendored dependency upon `file` in their
      # `./configure` script, due to libtool<=2.4.6, or due to
      # libtool>=2.4.7 in which the package author decided to set FILECMD
      # when running libtoolize.  In fact, file-5.4.6 *depends on itself*
      # and tries to invoke `file` from its own ./configure script.
      file

      nv-codec-headers-12
    ];

    buildType = "debug";
    dontStrip = true;
    postBuild = ''
      # Build SteamVR driver ("streamer")
      # cargo xtask build-streamer --release
      # cargo xtask prepare-deps --platform linux
      cargo xtask build-streamer
    '';

    postInstall = ''
      install -Dm755 ${src}/alvr/xtask/resources/alvr.desktop $out/share/applications/alvr.desktop
      install -Dm644 ${src}/resources/ALVR-Icon.svg $out/share/icons/hicolor/scalable/apps/alvr.svg

      # Install SteamVR driver
      mkdir -p $out/{libexec,lib/alvr,share}
      cp -r ./build/alvr_streamer_linux/lib64/. $out/lib
      cp -r ./build/alvr_streamer_linux/libexec/. $out/libexec
      cp -r ./build/alvr_streamer_linux/share/. $out/share
      ln -s $out/lib $out/lib64
    '';

    passthru.updateScript = nix-update-script {};

    meta = with lib; {
      description = "Stream VR games from your PC to your headset via Wi-Fi";
      homepage = "https://github.com/alvr-org/ALVR/";
      changelog = "https://github.com/alvr-org/ALVR/releases/tag/v${version}";
      license = licenses.mit;
      mainProgram = "alvr_dashboard";
      maintainers = with maintainers; [
        luNeder
        jopejoe1
      ];
      platforms = platforms.linux;
    };
  }

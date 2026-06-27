{
  lib,
  python3Packages,
  fetchFromGitHub,
  nix-update-script,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "voxd";
  version = "1.7.0";
  pyproject = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "jakovius";
    repo = "voxd";
    tag = "v${finalAttrs.version}";
    hash = "sha256-A02lNyBO0XkDL7rSG3rgTW/q6R4SqBkyTLr1GZV2NW8=";
  };

  build-system = [
    python3Packages.hatchling
  ];

  dependencies = with python3Packages; [
    numpy
    platformdirs
    psutil
    pyperclip
    pyqt6
    pyqtgraph
    pyyaml
    requests
    sounddevice
    tqdm
  ];

  # Broken as it attempts to run main, which cannot access the user config in the nix build environment
  # pythonImportsCheck = [
  #   "voxd"
  # ];

  patchPhase = ''
    substituteInPlace ./pyproject.toml \
      --replace-fail "mr.batman" "${finalAttrs.version}"
  '';

passthru = {
  # pythonImportsCheckHook = "";
  updateScript = nix-update-script { };
};

  meta = {
    description = "VOXD is a speech-to-text, voice-typing, dictation software for linux distributions. It is an open-source, free of charge, USER-FRIENDLY software, for as many linux distros as possible";
    homepage = "https://github.com/jakovius/voxd";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
    mainProgram = "voxd";
  };
})

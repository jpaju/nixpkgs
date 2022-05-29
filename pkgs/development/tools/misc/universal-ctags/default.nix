{ lib, stdenv, buildPackages, fetchFromGitHub, autoreconfHook, coreutils, pkg-config, perl, python3Packages, libiconv, jansson }:

stdenv.mkDerivation rec {
  pname = "universal-ctags";
  version = "5.9.20220529.0";

  src = fetchFromGitHub {
    owner = "universal-ctags";
    repo = "ctags";
    rev = "p${version}";
    sha256 = "sha256-Lu4eYMA5Uf/A8r11W6v7xTAnj0gtCjKQ4aX5IbV0dbo=";
  };

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ autoreconfHook pkg-config python3Packages.docutils ];
  buildInputs = [ jansson ] ++ lib.optional stdenv.isDarwin libiconv;

  # to generate makefile.in
  autoreconfPhase = ''
    ./autogen.sh
  '';

  configureFlags = [ "--enable-tmpdir=/tmp" ];

  postPatch = ''
    # Remove source of non-determinism
    substituteInPlace main/options.c \
      --replace "printf (\"  Compiled: %s, %s\n\", __DATE__, __TIME__);" ""

    substituteInPlace Tmain/utils.sh \
      --replace /bin/echo ${coreutils}/bin/echo

    # Remove git-related housekeeping from check phase
    substituteInPlace makefiles/testing.mak \
      --replace "check: tmain units tlib man-test check-genfile" \
                "check: tmain units tlib man-test"
  '';

  postConfigure = ''
    sed -i 's|/usr/bin/env perl|${perl}/bin/perl|' misc/optlib2c
  '';

  doCheck = true;

  meta = with lib; {
    description = "A maintained ctags implementation";
    homepage = "https://ctags.io/";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
    # universal-ctags is preferred over emacs's ctags
    priority = 1;
    maintainers = [ maintainers.mimame ];
  };
}

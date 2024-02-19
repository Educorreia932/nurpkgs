{ stdenv, pkgs, lib }:

with pkgs;
let
  userDir = "~/.config/slex";
  binPath = lib.makeBinPath [ coreutils less ];
in
stdenv.mkDerivation {
  pname = "slex";
  version = "2.9.0";
  src = fetchFromGitHub {
    owner = "SLASHEM-Extended";
    repo = "SLASHEM-Extended";
    rev = "slex-2.9.0";
    sha256 = "sha256-QVLHULUy+Wu3dkLfeLsVoqSYPV18p/ffbBrTb++5SV4=";
    leaveDotGit = true;
  };
  hardeningDisable = [ "all" ];
  buildInputs = [ ncurses ];
  nativeBuildInputs = [ flex bison ];
  propagateBuildInputs = [ ncurses ];
  preBuild = ''
    sh sys/unix/setup.sh
    cd util && bison -d dgn_comp.y && cp dgn_comp.tab.h dgn.tab.h && cd ..
    cd util && bison -d lev_comp.y && cp lev_comp.tab.h lev.tab.h && cd ..
  '';
  makeFlags = [ "PREFIX=$(out)" ];
  makefile = "sys/unix/GNUmakefile";
  enableParallelBuilding = true;
  postInstall = ''
    mkdir -p $out/slex-2.9.0/slexuserdir

    for i in xlogfile logfile perm record livelog; do
      mv $out/slex-2.9.0/$i $out/slex-2.9.0/slexuserdir
    done

    mkdir -p $out/bin

    cat <<EOF >$out/bin/slex
    #! ${stdenv.shell} -e
          
    PATH=${binPath}:\$PATH

    if [ ! -d ${userDir} ]; then
      mkdir -p ${userDir}
      cp -r $out/slex-2.9.0/slexuserdir/* ${userDir}
      chmod -R +w ${userDir}
    fi

    RUNDIR=\$(mktemp -d)

    cleanup() {
      rm -rf \$RUNDIR
    }

    trap cleanup EXIT

    cd \$RUNDIR

    for i in ${userDir}/*; do
      ln -s \$i \$(basename \$i)
    done

    for i in $out/slex-2.9.0/*; do
      ln -s \$i \$(basename \$i)
    done

    $out/slex-2.9.0/slex
    EOF

    chmod +x $out/bin/slex
  '';
}
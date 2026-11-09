# ptvencoder patch sets (synced, do not edit)

Mirrored from ffmpeg-enhancements `patches/ptv/` by the transcoder repo's `deploy/build.sh patches`,
committed on the Mac, pushed to GitHub, then pulled on the build box. Never edit these files here: a
published set is immutable, and a change is a new version in ffmpeg-enhancements.

    dev                      one line: the current development version (pre/rc)
    stable                   one line: the current release version (X.Y.Z)
    <version>/MANIFEST       version, tag, source commit, branches, verified upstream sha
    <version>/<branch>/      NNNN-*.patch + SHA256SUMS, one folder per FFmpeg branch (master, release/9.0)

`build.sh` uses them only when asked: `PTV=dev|stable|<version> ./build.sh linux64 nonfree [debug]`
builds `...-linux64-nonfree[-debug]-ptv<version>`. Without `PTV` the build is vanilla.

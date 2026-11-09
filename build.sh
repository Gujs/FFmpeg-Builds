#!/bin/bash
set -xe
shopt -s globstar
cd "$(dirname "$0")"
source util/vars.sh

source "variants/${TARGET}-${VARIANT}.sh"

for addin in ${ADDINS[*]}; do
    source "addins/${addin}.sh"
done

if docker info -f "{{println .SecurityOptions}}" | grep rootless >/dev/null 2>&1; then
    UIDARGS=()
else
    UIDARGS=( -u "$(id -u):$(id -g)" )
fi

rm -rf ffbuild
mkdir ffbuild

FFMPEG_REPO="${FFMPEG_REPO:-https://github.com/FFmpeg/FFmpeg.git}"
FFMPEG_REPO="${FFMPEG_REPO_OVERRIDE:-$FFMPEG_REPO}"
GIT_BRANCH="${GIT_BRANCH:-master}"
GIT_BRANCH="${GIT_BRANCH_OVERRIDE:-$GIT_BRANCH}"

# ptv fork: which ptvencoder patch set to build. Default PTV=none = vanilla, upstream FFmpeg as-is,
# named exactly like an upstream build.
#   PTV=dev | PTV=stable   the version named in patches/ffmpeg/ptv/dev or .../stable
#   PTV=<version>          an exact published version, e.g. PTV=2.2.0-rc3
# The sets in patches/ffmpeg/ptv/<version>/<branch>/ are published by ffmpeg-enhancements (patches/ptv/)
# and synced here - never edited by hand. A ptv build applies <version>/<GIT_BRANCH>/*.patch in order,
# checked against that folder's SHA256SUMS, and is named ...-ptv<version>. A version without a set for
# GIT_BRANCH (e.g. a 9.0 build) fails here: it never comes out as an unmarked vanilla build.
# PTV is an env var, not an addin, so ptv and vanilla builds share one image (IMAGE includes the addins).
PTV="${PTV:-none}"
PTV_DIR=""
BUILD_TAG=""
if [[ "$PTV" != none ]]; then
    PTV_ROOT="patches/ffmpeg/ptv"
    PTV_VERSION="$PTV"
    if [[ "$PTV" == dev || "$PTV" == stable ]]; then
        [[ -f "$PTV_ROOT/$PTV" ]] || { echo "PTV=$PTV: no $PTV_ROOT/$PTV pointer - sync the patch sets first" >&2; exit 1; }
        PTV_VERSION="$(tr -d '[:space:]' < "$PTV_ROOT/$PTV")"
    fi
    if ! [[ "$PTV_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-(pre|rc)[0-9]+)?$ ]]; then
        echo "PTV=$PTV: '$PTV_VERSION' is not a version (X.Y.Z, X.Y.Z-preN or X.Y.Z-rcN)" >&2; exit 1
    fi
    PTV_DIR="ptv/$PTV_VERSION/$GIT_BRANCH"
    if ! [[ -f "patches/ffmpeg/$PTV_DIR/SHA256SUMS" ]]; then
        echo "PTV=$PTV: ptvencoder $PTV_VERSION has no patch set for FFmpeg branch '$GIT_BRANCH' (patches/ffmpeg/$PTV_DIR)" >&2; exit 1
    fi
    # every patch in the folder must be listed and must verify - nothing extra, nothing changed
    if ! ( cd "patches/ffmpeg/$PTV_DIR" && sha256sum --quiet -c SHA256SUMS \
           && [[ "$(ls -1 *.patch 2>/dev/null)" == "$(awk '{sub(/^\*/, "", $2); print $2}' SHA256SUMS | sort)" ]] \
           && [[ -n "$(ls -1 *.patch 2>/dev/null)" ]] ); then
        echo "PTV=$PTV: patches/ffmpeg/$PTV_DIR does not match its SHA256SUMS - re-sync it" >&2; exit 1
    fi
    BUILD_TAG="-ptv$PTV_VERSION"
fi

BUILD_SCRIPT="$(mktemp)"
trap "rm -f -- '$BUILD_SCRIPT'" EXIT

RPATH_LDEXEFLAGS=''
if [[ $TARGET == linux* && $VARIANT == *shared* ]]; then
    RPATH_LDEXEFLAGS=' -Wl,-rpath,\\\$\$ORIGIN/../lib'
fi

cat <<EOF >"$BUILD_SCRIPT"
    set -xe
    cd /ffbuild
    rm -rf ffmpeg prefix

    git clone --filter=blob:none --branch='$GIT_BRANCH' '$FFMPEG_REPO' ffmpeg
    cd ffmpeg

	shopt -s nullglob
    PATCHES=()
    [[ -n '$PTV_DIR' ]] && PATCHES=('/patches/$PTV_DIR'/*.patch)
    # the host checked the set; if the container cannot see it (mount failure, SELinux label, rootless
    # path mapping) refuse - never package an unpatched build under a -ptv name
    if [[ -n '$PTV_DIR' && "\${#PATCHES[@]}" = 0 ]]; then
        echo 'PTV build but no patches visible at /patches/$PTV_DIR inside the container - refusing'
        exit 1
    fi
    if [[ "\${#PATCHES[@]}" = 0 ]]; then
        echo 'Vanilla build: no patches applied'
    fi
    for patch in "\${PATCHES[@]}"; do
        echo "Applying \$patch"
        git apply "\$patch"
    done

    ./configure --prefix=/ffbuild/prefix --pkg-config-flags="--static" \$FFBUILD_TARGET_FLAGS \$FF_CONFIGURE \
        --extra-cflags="\$FF_CFLAGS" --extra-cxxflags="\$FF_CXXFLAGS" --extra-libs="\$FF_LIBS" \
        --extra-ldflags="\$FF_LDFLAGS" --extra-ldexeflags="\$FF_LDEXEFLAGS"'$RPATH_LDEXEFLAGS' \
        --cc="\$CC" --cxx="\$CXX" --ar="\$AR" --ranlib="\$RANLIB" --nm="\$NM" \
        --extra-version="\$(date +%Y%m%d)" || { cat ffbuild/config.log; exit 1; }
    make -j\$(nproc) V=1
    make install install-doc
EOF

[[ -t 1 ]] && TTY_ARG="-t" || TTY_ARG=""

docker run --rm -i $TTY_ARG "${UIDARGS[@]}" -v "$PWD/ffbuild":/ffbuild -v "$PWD/patches/ffmpeg/":/patches -v "$BUILD_SCRIPT":/build.sh "$IMAGE" bash /build.sh

if [[ -n "$FFBUILD_OUTPUT_DIR" ]]; then
    mkdir -p "$FFBUILD_OUTPUT_DIR"
    package_variant ffbuild/prefix "$FFBUILD_OUTPUT_DIR"
    [[ -n "$LICENSE_FILE" ]] && cp "ffbuild/ffmpeg/$LICENSE_FILE" "$FFBUILD_OUTPUT_DIR/LICENSE.txt"
    rm -rf ffbuild
    exit 0
fi

mkdir -p artifacts
ARTIFACTS_PATH="$PWD/artifacts"
BUILD_NAME="ffmpeg-$(./ffbuild/ffmpeg/ffbuild/version.sh ffbuild/ffmpeg)-${TARGET}-${VARIANT}${ADDINS_STR:+-}${ADDINS_STR}${BUILD_TAG}"

mkdir -p "ffbuild/pkgroot/$BUILD_NAME"
package_variant ffbuild/prefix "ffbuild/pkgroot/$BUILD_NAME"

[[ -n "$LICENSE_FILE" ]] && cp "ffbuild/ffmpeg/$LICENSE_FILE" "ffbuild/pkgroot/$BUILD_NAME/LICENSE.txt"

cd ffbuild/pkgroot
if [[ "${TARGET}" == win* ]]; then
    OUTPUT_FNAME="${BUILD_NAME}.zip"
    docker run --rm -i $TTY_ARG "${UIDARGS[@]}" -v "${ARTIFACTS_PATH}":/out -v "${PWD}/${BUILD_NAME}":"/${BUILD_NAME}" -w / "$IMAGE" zip -9 -r "/out/${OUTPUT_FNAME}" "$BUILD_NAME"
else
    OUTPUT_FNAME="${BUILD_NAME}.tar.xz"
    docker run --rm -i $TTY_ARG "${UIDARGS[@]}" -v "${ARTIFACTS_PATH}":/out -v "${PWD}/${BUILD_NAME}":"/${BUILD_NAME}" -w / "$IMAGE" tar -I "xz -T0" -cf "/out/${OUTPUT_FNAME}" "$BUILD_NAME"
fi
cd -

rm -rf ffbuild

if [[ -n "$GITHUB_ACTIONS" ]]; then
    echo "build_name=${BUILD_NAME}" >> "$GITHUB_OUTPUT"
    echo "${OUTPUT_FNAME}" > "${ARTIFACTS_PATH}/${TARGET}-${VARIANT}${ADDINS_STR:+-}${ADDINS_STR}${BUILD_TAG}.txt"
fi

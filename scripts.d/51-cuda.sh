#!/bin/bash

# Archives URL
# https://developer.nvidia.com/cuda-toolkit-archive

# CUDA version URLs and SHA512 checksums
URL="https://developer.download.nvidia.com/compute/cuda/12.9.1/local_installers/cuda_12.9.1_575.57.08_linux.run"
URL_SHA512="fc29c5fc1121fb6634f1fe396abe7f34d351686454516269e9143e678ea178f906a35b916b8bb2d96ecfcfc705dda7d0f4547f7e7f00d36e392d981a766b6a56"

URL2="https://developer.download.nvidia.com/compute/cuda/13.0.0/local_installers/cuda_13.0.0_580.65.06_linux.run"
URL2_SHA512="fc29c5fc1121fb6634f1fe396abe7f34d351686454516269e9143e678ea178f906a35b916b8bb2d96ecfcfc705dda7d0f4547f7e7f00d36e392d981a766b6a56"

URL4="https://developer.download.nvidia.com/compute/cuda/12.2.2/local_installers/cuda_12.2.2_535.104.05_linux.run"
URL4_SHA512="e39e7134231b7a5132cd7bb46d26774246d83ab98b4d49a83212dc7440219ae20e4da06587c0351f525a2c847e8ad0ea06147709f243b53bd588faee4b123bb6"

URL5="https://developer.download.nvidia.com/compute/cuda/12.6.3/local_installers/cuda_12.6.3_560.35.05_linux.run"
URL5_SHA512="a93d9d812d3a3f5823622e2274d1d6dbe17a298b33463fdf9f6d211d38766eab76608f9d545e312b2be2b86b3c59fcd92c37c54b38b0e8206191563d00546d62"

URL6="https://developer.download.nvidia.com/compute/cuda/12.4.1/local_installers/cuda_12.4.1_550.54.15_linux.run"
URL6_SHA512="340fab9aad2f3e03fb773c2ec1d4f2c3b1428b350c2072b02263f68f3c521b7ec42086ae7b5e66594a0b91862cc165d8519e4c92e428268bc1e98adcfe106d42"


ffbuild_enabled() {
    [[ $VARIANT == nonfree* ]] || return -1
    return 0
}

ffbuild_dockerdl() {
    cat <<EOF
check-wget "cuda-12.9.1.run" "$URL" "$URL_SHA512"
chmod +x cuda-12.9.1.run
./cuda-12.9.1.run --silent --extract="\$(pwd)/cuda-12.9.1"
rm -f cuda-12.9.1.run

check-wget "cuda-12.2.2.run" "$URL4" "$URL4_SHA512"
chmod +x cuda-12.2.2.run
./cuda-12.2.2.run --silent --extract="\$(pwd)/cuda-12.2.2"
rm -f cuda-12.2.2.run

check-wget "cuda-12.4.1.run" "$URL6" "$URL6_SHA512"
chmod +x cuda-12.4.1.run
./cuda-12.4.1.run --silent --extract="\$(pwd)/cuda-12.4.1"
rm -f cuda-12.4.1.run

check-wget "cuda-12.6.3.run" "$URL5" "$URL5_SHA512"
chmod +x cuda-12.6.3.run
./cuda-12.6.3.run --silent --extract="\$(pwd)/cuda-12.6.3"
rm -f cuda-12.6.3.run

find cuda-12.2.2 cuda-12.4.1 cuda-12.6.3 cuda-12.9.1 -mindepth 1 -maxdepth 1 \\
    ! -name 'cuda_cudart' \\
    ! -name 'cuda_nvcc' \\
    ! -name 'libnpp' \\
    ! -name 'bin' \\
    -exec echo '51-cuda: Deleting: {}' \\; -exec rm -rf {} +
EOF
}

ffbuild_dockerbuild() {
    export PRESERVE_PKG=1
    if [[ $ADDINS_STR == *4.4* || $ADDINS_STR == *5.0* || $ADDINS_STR == *5.1* || $ADDINS_STR == *6.0* || $ADDINS_STR == *6.1* ]]; then
        cd cuda-12.2.2
    else
        cd cuda-12.4.1
    fi

    mkdir -p "$FFBUILD_PREFIX/include" "$FFBUILD_PREFIX/lib" "$FFBUILD_PREFIX/bin" "$FFBUILD_PREFIX/nvvm/bin"

    cp -r libnpp/include/* $FFBUILD_PREFIX/include
    cp -r cuda_cudart/include/* $FFBUILD_PREFIX/include
    cp -r cuda_nvcc/include/* $FFBUILD_PREFIX/include

    cp -r libnpp/lib64/*.a $FFBUILD_PREFIX/lib
    cp -r cuda_cudart/lib64/*.a $FFBUILD_PREFIX/lib
    cp -r cuda_nvcc/lib64/*.a $FFBUILD_PREFIX/lib

    # need this for nvcc compiler
    cp -r cuda_cudart/include/* $FFBUILD_PREFIX/include
    cp -r cuda_nvcc/bin/* $FFBUILD_PREFIX/bin
    cp -r cuda_nvcc/nvvm/bin/* $FFBUILD_PREFIX/bin
    cp -r cuda_nvcc/nvvm/bin/* $FFBUILD_PREFIX/nvvm/bin

}

ffbuild_configure() {
    echo --enable-cuda-nvcc --enable-libnpp
}

ffbuild_unconfigure() {
    echo --disable-cuda-nvcc --disable-libnpp
}

ffbuild_cflags() {
    return 0
}

ffbuild_ldflags() {
    return 0
}

ffbuild_libs() {
    echo -lnppif_static -lnppig_static -lnppicc_static -lnppc_static -lnppidei_static -lnppisu_static -lnppitc_static -lnppim_static -lnppial_static -lnppist_static -lcudart_static -lculibos -lstdc++ -lpthread
}
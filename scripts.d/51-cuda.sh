#!/bin/bash

# Archives URL
# https://developer.nvidia.com/cuda-toolkit-archive

URL="https://developer.download.nvidia.com/compute/cuda/12.9.1/local_installers/cuda_12.9.1_575.57.08_linux.run"
URL_SHA512="fc29c5fc1121fb6634f1fe396abe7f34d351686454516269e9143e678ea178f906a35b916b8bb2d96ecfcfc705dda7d0f4547f7e7f00d36e392d981a766b6a56"
URL2="https://developer.download.nvidia.com/compute/cuda/12.0.1/local_installers/cuda_12.0.1_525.85.12_linux.run"
URL2_SHA512="edd73c6e989e8469d73a8a8c4c927aa0654c1c299eff77c8b30dafd5da6e4e368626cec48978785f8e94fe8d1b7b73f1df6d5d03a80a6f58a07fa2d1f15c7f86"
URL3="https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda_12.1.1_530.30.02_linux.run"
URL3_SHA512="2f5b07b6253a7268afa81345acc8be9fc3ab80f7f5c565d199f72ac74467d562eb83b72f87f33bafa90c88612b16366c3e209cbec1cb0b5907839e5823520323"
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
    echo "check-wget \"cuda-12.9.1.run\" \"$URL\" \"$URL_SHA512\""
    echo "check-wget \"cuda-12.0.1.run\" \"$URL2\" \"$URL2_SHA512\""
    echo "check-wget \"cuda-12.1.1.run\" \"$URL3\" \"$URL3_SHA512\""
    echo "check-wget \"cuda-12.2.2.run\" \"$URL4\" \"$URL4_SHA512\""
    echo "check-wget \"cuda-12.4.1.run\" \"$URL5\" \"$URL5_SHA512\""
    echo "chmod +x cuda-12.9.1.run"
    echo "./cuda-12.9.1.run --silent --extract=cuda-12.9.1"
    echo "rm -f cuda-12.9.1.run"
    echo "chmod +x cuda-12.0.1.run"
    echo "./cuda-12.0.1.run --silent --extract=cuda-12.0.1"
    echo "rm -f cuda-12.0.1.run"
    echo "chmod +x cuda-12.1.1.run"
    echo "./cuda-12.1.1.run --silent --extract=cuda-12.1.1"
    echo "rm -f cuda-12.1.1.run"
    echo "chmod +x cuda-12.2.2.run"
    echo "./cuda-12.2.2.run --silent --extract=cuda-12.2.2"
    echo "rm -f cuda-12.2.2.run"
    echo "chmod +x cuda-12.4.1.run"
    echo "./cuda-12.4.1.run --silent --extract=cuda-12.4.1"
    echo "rm -f cuda-12.4.1.run"
}

ffbuild_dockerbuild() {
    if [[ $ADDINS_STR == *4.4* || $ADDINS_STR == *5.0* || $ADDINS_STR == *5.1* || $ADDINS_STR == *6.0* || $ADDINS_STR == *6.1* ]]; then
        cd cuda-12.0.1
    elif [[ $ADDINS_STR == *7.0* ]]; then
        cd cuda-12.1.1
    elif [[ $ADDINS_STR == *7.1* ]]; then
        cd cuda-12.2.2
    else
        cd cuda-12.9.1
    fi

	cp -r libnpp/include/* $FFBUILD_PREFIX/include
	cp -r cuda_cudart/include/* $FFBUILD_PREFIX/include
    cp -r cuda_nvcc/include/* $FFBUILD_PREFIX/include

	cp -r libnpp/lib64/*.a $FFBUILD_PREFIX/lib
    cp -r cuda_cudart/lib64/*.a $FFBUILD_PREFIX/lib
	cp -r cuda_nvcc/lib64/*.a $FFBUILD_PREFIX/lib

	mkdir -p $FFBUILD_PREFIX/bin
    cp -r cuda_nvcc/bin/* $FFBUILD_PREFIX/bin
	export PATH="$FFBUILD_PREFIX/bin:$PATH"
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
### Build dtb spliter using NDK
export $HOST_TAG and $NDK

ABI	        三元组
armeabi-v7a	armv7a-linux-androideabi
arm64-v8a	aarch64-linux-android
x86	        i686-linux-android
x86-64	        x86_64-linux-android

#### Cross compile
statically linked:
```
make CC=$NDK/toolchains/llvm/prebuilt/$HOST_TAG/bin/aarch64-linux-android21-clang CFLAGS=-static -s
```

dynamically linked:
```
make CC=$NDK/toolchains/llvm/prebuilt/$HOST_TAG/bin/aarch64-linux-android21-clang
```

minimal android version android21
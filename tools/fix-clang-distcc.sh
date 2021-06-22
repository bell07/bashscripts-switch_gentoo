#!/bin/sh
cd /usr/lib/distcc/
for i in clang*; do ln -v -s /usr/bin/distccd aarch64-unknown-linux-gnu-"$i"; done

cd bin
for i in clang*; do ln -v -s /usr/bin/distccd aarch64-unknown-linux-gnu-"$i"; done


cd /usr/lib/llvm/

for VER in *; do
	cd "$VER"/bin
    for CLANGFILE in clang clang++ clang-cl clang-cpp; do
    
        ln -v -s aarch64-unknown-linux-gnu-"$CLANGFILE" aarch64-unknown-linux-gnu-"$CLANGFILE"-"$VER"
        ln -v -s "$CLANGFILE"-"$VER" aarch64-unknown-linux-gnu-"$CLANGFILE"
	done
	cd ../..
done

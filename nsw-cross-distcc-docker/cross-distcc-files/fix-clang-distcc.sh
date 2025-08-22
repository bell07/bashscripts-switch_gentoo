#!/bin/sh
cd /usr/lib/distcc/
for i in clang*; do ln -v -s /usr/bin/distccd aarch64-unknown-linux-gnu-"$i"; done

cd /usr/lib/llvm/
for VER in *; do
	cd "$VER"/bin
	if [ -f clang ]; then
		for CLANGFILE in clang clang++ clang-cl clang-cpp; do
			ln -v -s "$CLANGFILE"-"$VER" aarch64-unknown-linux-gnu-"$CLANGFILE"-"$VER"
			ln -v -s aarch64-unknown-linux-gnu-"$CLANGFILE"-"$VER" aarch64-unknown-linux-gnu-"$CLANGFILE"
		done
	fi
	cd ../..
done

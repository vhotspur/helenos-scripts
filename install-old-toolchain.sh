#!/bin/bash

#
# Copyright (c) 2012 Vojtech Horky
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# - The name of the author may not be used to endorse or promote products
#   derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

LEGACY_CROSS_PREFIX=/usr/local/cross-legacy/
BUILD_TARGET=amd64

download_check() {
	(
		cd toolchain;
		wget -c "$1" || exit 2
	)
	if [ $? -ne 0 ]; then
		echo "Failed to download $1."
		exit 2
	fi
	_filename=`basename "$1"`
	_md5=`md5sum toolchain/$_filename | cut '-d ' -f 1`
	if [ "$_md5" != "$2" ]; then
		echo "Failed to download $_filename properly.";
		exit 2;
	fi
}

countdown() {
	if [ "$1" -eq 0 ]; then
		echo
		return
	fi
	echo -n " $1"
	sleep 1
	countdown $(( $1 - 1 ))
}

build_toolchain() {
	_target="$1"
	_revno="$2"
	shift 2
	(
		export CROSS_PREFIX="$LEGACY_CROSS_PREFIX/$_target"
		export CFLAGS=-Wno-error
		cd toolchain;
		./$_revno.sh "$@" || exit 2
	)
	if [ $? -ne 0 ]; then
		echo "Failed to build $_target."
		echo "CROSS_PREFIX=$CROSS_PREFIX"
		echo "CFLAGS=$CFLAGS"
		echo "./toolchain/$_revno.sh" "$@"
		exit 2
	fi
}


# See what we have to build
WHAT_TO_BUILD=toolchain/install
[ -f "$WHAT_TO_BUILD" ] || WHAT_TO_BUILD=toolchain/versions

if ! [ -f "$WHAT_TO_BUILD" ]; then
	echo "Don't know what to build."
	exit 2
fi



# Inform user, give him time to abort
echo "Toolchains versions to build:"
while read id revno xxx; do
	echo "$id" | grep '^#' -q && continue
	echo "  -> $id (used since rev. $revno)"
done<"$WHAT_TO_BUILD"
echo "Installed into: $LEGACY_CROSS_PREFIX"
echo "  (separate directories for each version)."
echo "Target architecture: $BUILD_TARGET"
echo
countdown 5




# Old binutils are no longer available in the ftp.gnu.org site
download_check \
	http://mirrors.usc.edu/pub/gnu/binutils/binutils-2.20.tar.bz2 \
	ee2d3e996e9a2d669808713360fa96f8
download_check \
	http://mirrors.usc.edu/pub/gnu/binutils/binutils-2.21.tar.bz2 \
	c84c5acc9d266f1a7044b51c85a823f5
download_check \
	http://mirrors.usc.edu/pub/gnu/gdb/gdb-7.2.tar.bz2 \
	64260e6c56979ee750a01055f16091a5


# Do the actual build
while read id revno xxx; do
	echo "$id" | grep '^#' -q && continue
	build_toolchain "$id" "$revno" "$BUILD_TARGET"
done<"$WHAT_TO_BUILD"

echo
echo
echo "Everything looks good. Toolchains installed."
echo


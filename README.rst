HelenOS helper scripts
======================

This repository contains scripts that could be useful when developing or
running HelenOS.
These scripts are not inside the official repository because they lack the
proper documentation, are dangerous or simply too specific for concrete
hosting environment.

You are free to use these scripts but at your own risk!

Below is a short description of what each of the scripts does.


add-to-grub.sh
--------------
This script copies currently compiled HelenOS into existing GRUB on your
real harddisk.
For details see my
`blogpost <http://vhotspur.blogspot.cz/2011/02/adding-helenos-to-existing-grub.html>`_
(currently, HelenOS uses GRUB 2 so some information is out-dated).


configure-for-helenos.sh
------------------------
This script prepares variables such as CC, LD or CFLAGS to launch a configure
script of some program that shall be cross-compiled to HelenOS.

For example, it is possible to build `zlib <http://www.zlib.net/>`_
with following command::

	~/bin/configure-for-helenos.sh \
		-d /path/to/HelenOS/root/directory \
		--run-with-env \
		--link-with-cc \
		--ldflags-ignored \
		--verbose \
		-- \
			./configure \
				--static

The created ``minigzip`` actually works when copied to HelenOS image!

Quick explanation of used arguments follows.

``-d``
	* path to HelenOS root directory
	* HelenOS shall be already configured (i.e. ``Makefile.config`` shall be present)
``--run-with-env``
	* launch the program as ``env CC=... ./configure`` instead of ``./configure CC=...``
``--link-with-cc``
	* the program is linked with call to compiler (not linker directly)
``--ldflags-ignored``
	* not only linking is done with ``CC`` (see ``link-with-cc``) but the script completely ignores ``LDFLAGS``
	* this appends the ``LDFLAGS`` to normal ``CFLAGS`` (and prepend them with ``-Wl,``)
``--verbose``
	* be a bit more verbose on what the script is doing
``-- ./configure --static``
	* the program to call (we are interested only in static ``libz.a``)


Compiling `GMP <http://gmplib.org/>`_ (a prerequisite for GCC)
is also possible but following patch has to be applied first::

	--- gmp-5.1.0/gmp-h.in	2012-12-18 20:05:09.000000000 +0100
	+++ gmp-5.1.0/gmp-h.in	2013-01-18 18:27:45.965852213 +0100
	@@ -24,6 +24,8 @@
	 #if defined (__cplusplus)
	 #include <iosfwd>   /* for std::istream, std::ostream, std::string */
	 #include <cstdio>
	+#else
	+#include <stdio.h>
	 #endif

To actually configure GMP run::

	~/bin/configure-for-helenos.sh \
		-d /path/to/HelenOS/root/directory \
		--link-with-cc --ldflags-ignored \
		--cflags="-D_STDIO_H -DHAVE_STRCHR -Wl,--undefined=longjmp" \
		-- \
		./configure \
			--host=i686-pc-linux-gnu \
			--disable-shared

Explanation for individual flags:

``_STDIO_H``
	* first of all, ``stdio.h`` is not included for plain C compilation (see patch)
	* next, presence of ``stdio.h`` is guessed from a list of known names for guard macros
	* HelenOS uses different guard naming, we have to add one of the known ones
``HAVE_STRCHR``
	* ``configure`` is not able to recognise HelenOS ``strchr()``
``--undefined=longjmp``
	* somehow the ``longjmp`` is dropped from the static library when linking
	* alternative solution is to put the ``libc`` as the last library (probably impossible to achive through ``configure``)
	* probably not needed when not running ``make check``



install-old-toolchain.sh
------------------------
Install older versions of HelenOS toolchain (GCC, binutils, ...) in
order to correctly compile older revisions of HelenOS.

Available versions are in ``toolchain/versions``, to select only specific
versions, create copy ``toolchain/install`` and leave only relevant lines.

The tools are installed into ``/usr/local/cross-legacy/`` where for each
version combination new directory is created.
Changing this directory is possible by overwriting the ``LEGACY_CROSS_PREFIX``
variable in the script.

Currently, ``amd64`` is built only.
To choose a different target, overwrite the ``BUILD_TARGET`` in the script.
Do not use ``parallel`` or ``2-way`` as older toolchain builders do
not support this.


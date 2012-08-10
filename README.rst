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


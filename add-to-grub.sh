#!/bin/sh
# Copyright (c) 2011-2012 Vojtech Horky
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

#
# This script install HelenOS to existing GRUB configuration
# (e.g. to GRUB on the Linux box where HelenOS was compiled).
#
# For usage, run with "-h" or "--help" argument.
#


my_abort() {
	echo "$@" >&2
	exit 1
}

my_msg() {
	echo "==>" "$@"
}

my_run() {
	__action_title="$1"
	shift
	
	my_msg "$__action_title" "..."
	
	echo '  -->' "$@"
	
	if "$@"; then
		: echo okay
	else
		echo "    ... failed."
		my_abort 'Running `'"$@""' failed."
	fi
}

show_usage() {
	if [ "$grub_family" = "1" ]; then
		__grub2="no"
	else
		__grub2="yes"
	fi
cat <<EOF_USAGE
$1 -- adding HelenOS to existing GRUB

Usage: $1 [options]
  where [options] can be

 -h --help
        Display this help and exit

 -g --grubconf path
        Path to GRUB menu
        Guess: "$grub_conf"
 -d device
        Disk device where is the boot partition
        Guess: "$grub_hdd"
 -o dir
        Where to copy HelenOS kernel and modules
        Default: "$grub_helenos_dir_real"
 -O dir
        GRUB path to HelenOS kernel and modules
        Guess: "$grub_helenos_dir"
 -t --title text
        Set title in GRUB menu
        Default: "$grub_title"
 -2 --grub2
        Prepare menu script for GRUB2
        Guess: $__grub2

 -c --clean
        Clean previous copy of HelenOS in GRUB directory
        Default: off
 -r --replace
        Replace entry in GRUB menu (only GRUB1).
        The GRUB menu file must be prepared as described below
        Default: off

 -b --bootdir dir
        Where is prepared boot/ dir of compiled HelenOS
        Overwritten by -s
        Guess: "$helenos_boot_dir"
 -s --repo dir
        Root dir of HelenOS repository clone
        Overwritten by -b
        Guess: "$PWD"

Preparation of GRUB menu config file
    If you do not want to actually add entry to GRUB but to update
    previous install, add following two lines to your GRUB configuration
    file.

    ### HelenOS automatic install start
    ### HelenOS automatic install end

    The text between them will be deleted and replaced with HelenOS
    booting configuration.

Warning
    You will probably need to run this script as root. Be careful.
    Do not run when you do not understand implications this script may
    have on your operating system. Really, this is not fun.
EOF_USAGE
}

make_menu_grub1() {
	echo "#"
	echo "# HelenOS"
	echo "# originated at $helenos_boot_dir"
	echo "#"
	echo "title $grub_title"
	echo "    root $grub_hdd"
	cat "$grub_helenos_dir_real/boot/$helenos_grub_conf" | \
		sed -n -e 's#[\t ]*\(kernel\|module\) /#    \1 '"$grub_helenos_dir"'/#p' | \
		sed 's#//#/#g'
	echo
}

make_menu_grub2() {
	__kernel=`cat "$grub_helenos_dir_real/boot/$helenos_grub_conf" | \
		sed -n -e 's#[\t ]*kernel /\(.*\)#/'"$grub_helenos_dir"'/\1#p' | \
		sed 's#//#/#g'`
	cat <<EOF_GRUB2_BEGIN_SCRIPT
#!/bin/sh
#
# HelenOS
# originated at $helenos_boot_dir
#
#
helenos_kernel="$__kernel"

[ -f "\$helenos_kernel" ] || exit

echo "Found HelenOS: \$helenos_kernel" >&2

echo 'menuentry "$grub_title" {'
echo "    set root='$grub_hdd'"
echo "    multiboot \$helenos_kernel"
cat <<EOF_HELENOS_MODULES
EOF_GRUB2_BEGIN_SCRIPT
	cat "$grub_helenos_dir_real/boot/$helenos_grub_conf" | \
		sed -n -e 's#[\t ]*module /#    module /'"$grub_helenos_dir"'/#p' | \
		sed 's#//#/#g'
	echo "EOF_HELENOS_MODULES"
	cat <<EOF_GRUB2_END_SCRIPT
echo '}'


EOF_GRUB2_END_SCRIPT
}


#
# Configuration variables
#
# Title in GRUB menu
grub_title='HelenOS'

# GRUB family (version)
grub_family=1

# GRUB configuration file (try to guess it)
grub_conf='/boot/grub/menu.lst'
[ -e '/boot/grub/grub.conf' ] && grub_conf='/boot/grub/grub.conf'
if [ -e '/boot/grub/grub.cfg' -o -d '/etc/grub.d' ]; then
	grub_conf='/etc/grub.d/35_helenos'
	grub_family=2
fi

# GRUB menufile (needed for guessing hard disk drive)
if [ "$grub_family" = "1" ]; then
	grub_menufile="$grub_conf"
else
	grub_menufile='/boot/grub/grub.cfg'
fi

# Device to boot from (guess from existing config)
grub_hdd="`sed -n '/^\([ \t]*set\)\?[ \t]*root[ \t=].*\((.*)\).*/{s//\2/p;q}' \"$grub_menufile\" 2>/dev/null`"
[ -z "$grub_hdd" ] && grub_hdd='(hd0,0)'

# Where to install HelenOS modules and kernel
grub_helenos_dir_real='/boot/helenos'

# Path to HelenOS kernel and modules as seen by GRUB
# If we found only /vmlinuz in GRUB conf, we will shorten it ;-)
grub_helenos_dir='/boot/helenos'
grep -q '[ \t]*\(kernel\|linux\)[ \t]*/vmlinuz' "$grub_conf" 2>/dev/null \
	&& grub_helenos_dir='/helenos'

# Where to get compiled kernel and modules from
helenos_boot_dir="$PWD/boot/distroot/boot"

# HelenOS grub config
helenos_grub_conf='grub/menu.lst'

# Temporary HelenOS config
helenos_new_grub_conf='grub/menu.new'

# Clean previous run?
extra_clean_grub_helenos_dir=false

# Append to the end of the GRUB?
extra_append_to_grub=true

# For testing
# grub_conf='/tmp/helenos_grub/grub/menu.lst'
# grub_helenos_dir='/tmp/helenos_grub/helenos'

cmd_opts="-o h2t:b:crs:g:o:d:O: -l help,grub2,title:,bootdir:,clean,replace,grubconf:"
getopt -Q $cmd_opts -- "$@" || exit 1
eval set -- `getopt -q $cmd_opts -- "$@"`

while [ $# -gt 0 ]; do
	case $1 in
		-h|--help)
			show_usage "$0"
			exit
			;;
		-2|--grub2)
			grub_family="2"
			;;
		-t|--title)
			grub_title="$2"
			shift
			;;
		-b|--bootdir)
			helenos_boot_dir="$2"
			shift
			;;
		-s|--repo)
			helenos_boot_dir="$2/boot/distroot/boot"
			shift
			;;
		-g|--grubconf)
			grub_conf="$2"
			shift
			;;
		-o)
			grub_helenos_dir_real="$2"
			shift
			;;
		-O)
			grub_helenos_dir="$2"
			shift
			;;
		-d)
			grub_hdd="$2"
			shift
			;;
		-c|--clean)
			extra_clean_grub_helenos_dir=true
			;;
		-r|--replace)
			extra_append_to_grub=false
			;;
		--)
			shift
			break
			;;
		*)
			echo "EINVAL"
			exit 1
			;;
	esac
	shift
done

#
# Verify variables has some values
#
if [ -z "$grub_conf" ]; then
	my_abort "Error: GRUB menu file not set"
fi
if [ -z "$helenos_boot_dir" ]; then
	my_abort "Error: HelenOS boot dir not set"
fi

#my_msg "Taking HelenOS from $helenos_boot_dir"
#my_msg "GRUB menu file is $grub_conf"
#my_msg "HelenOS will be installed into $grub_helenos_dir"

if $extra_clean_grub_helenos_dir; then
	if [ -d "$grub_helenos_dir_real" ]; then
		my_run "Cleaning previous install" rm -rf "$grub_helenos_dir_real"
	fi
fi

my_run "Creating GRUB HelenOS directory" mkdir -p "$grub_helenos_dir_real"

my_run "Installing HelenOS kernel and modules" \
	cp -R "$helenos_boot_dir" "$grub_helenos_dir_real"


my_msg "Updating HelenOS GRUB menu ..."
(
	
	case "$grub_family" in
		1)
			make_menu_grub1
			;;
		2)
			make_menu_grub2
			;;
		*)
			exit 3
			;;
	esac

) > "$grub_helenos_dir_real/boot/$helenos_new_grub_conf"

if [ "$grub_family" = "1" ]; then
	my_run "Backing-up current GRUB menu" cp "$grub_conf" "$grub_conf.bak"
fi

case "$grub_family" in
	1)
		if $extra_append_to_grub; then
			my_msg "Appending HelenOS entry to GRUB menu ..."
			cat "$grub_conf.bak" "$grub_helenos_dir_real/boot/$helenos_new_grub_conf" > "$grub_conf"
		else
			my_msg "Replacing HelenOS entry in GRUB menu ..."
			cat "$grub_conf.bak" | \
				sed '/^[\t ]*### HelenOS automatic install start/,/^[\t ]*### HelenOS automatic install end/{/^[\t ]*###/p;d}' | \
				sed '/^[\t ]*### HelenOS automatic install start/r '"$grub_helenos_dir_real/boot/$helenos_new_grub_conf" \
				> "$grub_conf"
		fi
		my_msg "Adding HelenOS to GRUB completed."
		;;
	2)
		my_run "Inserting HelenOS to GRUB" cp "$grub_helenos_dir_real/boot/$helenos_new_grub_conf" "$grub_conf"
		chmod +x "$grub_conf"
		my_msg "HelenOS menu entry prepared."
		my_msg "Do not forget to run update-grub."
		;;
	3)
		exit 3
esac



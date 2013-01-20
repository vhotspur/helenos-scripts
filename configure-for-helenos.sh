#!/bin/sh

die() {
	echo "$@" >&2
	exit 1
}

usage() {
	echo Usage: $1 [options] -- program-to-launch
	cat <<EOF_USAGE
 where options is combination of the following
    --base-dir=DIR, -d DIR   [MANDATORY]
        DIR is path to HelenOS root directory (must be specified).
    --cflags=FLAGS
        Extra C flags to pass to the C compiler.
    --link-with-cc
        Expect that linking is done with compiler (i.e. linker is not
        called explicitly).
    --ldflags-ignored
        Use this if the application apparently uses CC for linking
        (see --link-with-cc) and, additionally, does not obey the LDFLAGS
        variable at all.
    --run-with-env
        Pass CC, AR, ... settings through environment variables.
        Normal behaviour is to call
            ./configure CC=gcc
        this option will change this to
            env CC=gcc ./configure
    --verbose, -v
        Be verbose about what the script is doing.
    --help, -h
        Display this help and exit.
           
EOF_USAGE
	exit $2
}

# get_var_from_makefile CC Makefile.common
get_var_from_makefile() {
	# echo "make -C `dirname "$2"` -f - -s __armagedon_" >&2
	(
		echo "$3"
		echo "$4"
		echo "$5"
		echo "__genesis__:"
		echo
		echo "CONFIG_DEBUG=n"
		echo include `basename "$2"`
		echo "CONFIG_DEBUG=n"
		echo
		echo "__armagedon__:"
		echo "	echo \$($1)"
		echo
	)  | make -C `dirname "$2"` -f - -s __armagedon__
}

get_var_from_uspace() {
	if [ -z "$2" ]; then
		get_var_from_makefile "$1" "$HELENOS_HOME/uspace/Makefile.common" "USPACE_PREFIX=$HELENOS_HOME/uspace"
	else
		get_var_from_makefile "$1" "$HELENOS_HOME/uspace/$2" "USPACE_PREFIX=$HELENOS_HOME/uspace" "$3" "$4"
	fi
}

run_and_echo() {
	echo "[RUN]:" "$@" >&2
	"$@"
}

print_var() {
	echo -n "    $1=\""
	echo -n "$2" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
	if [ "$3" = "--last" ]; then
		echo '"'
	else
		echo '" \'
	fi
}


HELENOS_HOME=""
LINK_WITH_CC=false
LDFLAGS_IGNORED=false
BE_VERBOSE=false
BE_SILENT=false
RUN_WITH_ENV=false
EXTRA_CFLAGS=""
DISABLED_CFLAGS="-Werror -Werror-implicit-function-declaration"
ARCH_ARGS=""
EXTRA_ARGS=""

opts="-o hvsd: -l help,verbose,silent,base-dir:,link-with-cc,run-with-env,ldflags-ignored,arch-arg:,cflags:"
getopt -Qq $opts -- "$@" || usage "$0" 1
eval set -- `getopt -q $opts -- "$@"`

while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help)
			usage $0 0
			;;
		-v|--verbose)
			BE_VERBOSE=true
			;;
		-s|--silent)
			BE_SILENT=true
			;;
		-d|--base-dir)
			HELENOS_HOME="$2"
			shift
			;;
		--cflags)
			EXTRA_CFLAGS="$2"
			shift
			;;
		--arch-arg)
			ARCH_ARGS="$ARCH_ARGS $2"
			shift
			;;
		--link-with-cc)
			LINK_WITH_CC=true
			;;
		--ldflags-ignored)
			LDFLAGS_IGNORED=true
			;;
		--run-with-env)
			RUN_WITH_ENV=true
			;;
		--)
			shift
			break
			;;
		*)
			die "Unknown option $1"
			;;
	esac
	shift
done


# Check that HelenOS is actually configured
if [ -z "$HELENOS_HOME" ]; then
	die "You have to specify HelenOS root directory. Try $0 --help."
fi

if ! [ -f "$HELENOS_HOME/Makefile.config" ]; then
	die "It looks that HelenOS is not configured (Makefile.config missing)."
fi

# Check that some command was acually specified
if [ $# -eq 0 ]; then
	die "You have to specify command to run. Try $0 --help."
fi

# Set-up verbose mode
if $BE_SILENT; then
	RUN=""
else
	RUN="run_and_echo"
fi


# Get path to the tools
CC=`get_var_from_uspace CC`
AS=`get_var_from_uspace AS`
LD=`get_var_from_uspace LD`
AR=`get_var_from_uspace AR`
STRIP=`get_var_from_uspace STRIP`
OBJCOPY=`get_var_from_uspace OBJCOPY`
OBJDUMP=`get_var_from_uspace OBJDUMP`
# HelenOS do not use ranlib or nm but some applications require it
RANLIB=`echo "$AR" | sed 's/-ar$/-ranlib/'`
NM=`echo "$AR" | sed 's/-ar$/-nm/'`

# Get the flags
CFLAGS=`get_var_from_uspace CFLAGS`
LDFLAGS=`get_var_from_uspace LFLAGS`
LINKER_SCRIPT=`get_var_from_uspace LINKER_SCRIPT`



# We need to specify some libposix specific flags

# Include paths
POSIX_INCLUDES="-I$HELENOS_HOME/uspace/lib/posix/include/posix -I$HELENOS_HOME/uspace/lib/posix/include"
# Paths to libraries
POSIX_LIBS_LFLAGS="-L$HELENOS_HOME/uspace/lib/posix/ -L$HELENOS_HOME/uspace/lib/c -L$HELENOS_HOME/uspace/lib/softint"
# Actually used libraries
# The --whole-archive is used to allow correct linking of static libraries
# (otherwise, the ordering is crucial and we usally cannot change that in the
# application Makefiles).
POSIX_LINK_LFLAGS="--whole-archive --start-group -lposix -lsoftint --end-group --no-whole-archive -lc"
POSIX_BASE_LFLAGS="-n -T $LINKER_SCRIPT"


# Update LDFLAGS
LDFLAGS="$LD_FLAGS $POSIX_LIBS_LFLAGS $POSIX_LINK_LFLAGS $POSIX_BASE_LFLAGS"

# The LDFLAGS might be used through CC, thus prefixing with -Wl is required
LDFLAGS_FOR_CC=""
for flag in $LDFLAGS; do
	LDFLAGS_FOR_CC="$LDFLAGS_FOR_CC -Wl,$flag"
done

if $LINK_WITH_CC; then
	LDFLAGS="$LDFLAGS_FOR_CC"
fi

# Update the CFLAGS
CFLAGS="$POSIX_INCLUDES $CFLAGS $EXTRA_CFLAGS"
if $LDFLAGS_IGNORED; then
	CFLAGS="$CFLAGS $LDFLAGS_FOR_CC"
	LDFLAGS=""
fi


# Get rid of the disable CFLAGS
CFLAGS_OLD="$CFLAGS"
CFLAGS=""
for flag in $CFLAGS_OLD; do
	disabled=false
	for disabled_flag in $DISABLED_CFLAGS; do
		if [ "$disabled_flag" = "$flag" ]; then
			disabled=true
			break
		fi
	done
	if ! $disabled; then
		CFLAGS="$CFLAGS $flag"
	fi
done


# Determine the architecture
UARCH=`get_var_from_uspace UARCH`
TARGET=""
case $UARCH in
	ia32)
		TARGET="i686-pc-linux-gnu"
		;;
	amd64)
		TARGET="amd64-linux-gnu"
		;;
	*)
		die "Unknown userspace architecture $UARCH."
		;;
esac

# Set the architecture for given arguments
for arg in $ARCH_ARGS; do
	EXTRA_ARGS="$EXTRA_ARGS ${arg}${TARGET}"
done


if $BE_VERBOSE; then
	print_var AR "$AR"
	print_var AS "$AS"
	print_var NM "$NM"
	print_var OBJCOPY "$OBJCOPY"
	print_var OBJDUMP "$OBJDUMP"
	print_var RANLIB "$RANLIB"
	print_var STRIP "$STRIP"
	print_var CC "$CC"
	print_var CFLAGS "$CFLAGS"
	print_var LD "$LD"
	print_var LDFLAGS "$LDFLAGS"
	print_var "extra arguments" "$EXTRA_ARGS" --last
fi

# Now, just run it
if $RUN_WITH_ENV; then
	$RUN env \
		AR="$AR" \
		AS="$AS" \
		NM="$NM" \
		OBJCOPY="$OBJCOPY" \
		OBJDUMP="$OBJDUMP" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		LD="$LD" \
		LDFLAGS="$LDFLAGS" \
		CC="$CC" \
		CFLAGS="$CFLAGS" \
		"$@" $EXTRA_ARGS
else
	$RUN \
		"$@" \
		$EXTRA_ARGS \
		AR="$AR" \
		AS="$AS" \
		NM="$NM" \
		OBJCOPY="$OBJCOPY" \
		OBJDUMP="$OBJDUMP" \
		RANLIB="$RANLIB" \
		STRIP="$STRIP" \
		LD="$LD" \
		LDFLAGS="$LDFLAGS" \
		CC="$CC" \
		CFLAGS="$CFLAGS"
fi

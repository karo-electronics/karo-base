#!/bin/bash
#
# Ka-Ro Yocto Project Build Environment Setup Script
#
# Copyright (C) 2022 Lothar Waßmann <LW@KARO-electronics.de>
#   based on imx-setup-release.sh Copyright (C) 2011-2016 Freescale Semiconductor
#                                 Copyright 2017 NXP
#

CWD=`pwd`
BASENAME="karo-setup-release.sh"
PROGNAME="setup-environment"
SRCDIR=layers

exit_message () {
    echo "To return to this build environment later please run:"
    echo -e "\tsource setup-environment <build_dir>"
}

usage() {
    echo "Usage: MACHINE=<machine> [DISTRO=<distro>] [KARO_BASEBOARD=<baseboard>] source $BASENAME [-b <build-dir>] [-h]"

    echo "Optional parameters:
* [-b <build-dir>]: Build directory, where <build-dir> is a sensible name of a
                    directory to be created.
                    If unspecified script uses 'build' as output directory.
* [-h]: help
"
}

clean_up() {
    unset CWD BUILD_DIR KARO_DISTRO
    unset usage clean_up
    unset ARM_DIR
    exit_message
}

layer_exists() {
    for l in $layers;do
	[ "$1" = "$l" ] && return
    done
    false
}

add_layer() {
    layer_exists && return
    layers="$layers $1 "
    echo "BBLAYERS += \"\${BSPDIR}/${SRCDIR}/$1\"" >> "conf/bblayers.conf"
}

# get command line options
OLD_OPTIND=$OPTIND
unset KARO_DISTRO

while getopts b:h: opt; do
    case ${opt} in
	b)
	    BUILD_DIR="$OPTARG"
	    echo "Build directory is: $BUILD_DIR"
	    ;;
	h)
	    setup_help=true
	    ;;
	*)
	    setup_error=true
	    ;;
    esac
done
shift $((OPTIND-1))

if [ $# -ne 0 ]; then
    setup_error=true
    echo "Unexpected positional parameters: '$@'" >&2
fi
OPTIND=$OLD_OPTIND
if test $setup_help;then
    usage && clean_up && return 1
elif test $setup_error;then
    clean_up && return 1
fi

if [ -z "$DISTRO" ]; then
    if [ -z "$KARO_DISTRO" ]; then
	KARO_DISTRO='karo-wayland'
    fi
    export DISTRO="$KARO_DISTRO"
else
    KARO_DISTRO="$DISTRO"
fi

if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR='build-karo'
fi

if [ -z "$MACHINE" ]; then
    :
fi

layers=""

# Backup CWD value as it's going to be unset by upcoming external scripts calls
CURRENT_CWD="$CWD"

# Set up the basic yocto environment
DISTRO=${KARO_DISTRO:-DISTRO} MACHINE=$MACHINE KARO_BASEBOARD=${KARO_BASEBOARD} . ./$PROGNAME $BUILD_DIR

# Set CWD to a value again as it's being unset by the external scripts calls
[ -z "$CWD" ] && CWD="$CURRENT_CWD"

if [ ! -e "conf/local.conf" ]; then
    return 1
fi

# On the first script run, backup the local.conf file
# Consecutive runs, it restores the backup and changes are appended on this one.
if [ ! -e conf/local.conf.org ]; then
    cp conf/local.conf conf/local.conf.org
else
    cp conf/local.conf.org conf/local.conf
fi

if [ ! -e "$BUILD_DIR/conf/bblayers.conf.org" ]; then
    cp conf/bblayers.conf conf/bblayers.conf.org
else
    cp conf/bblayers.conf.org conf/bblayers.conf
fi

echo "" >> "conf/bblayers.conf"
echo "# Ka-Ro Yocto Project Release layers" >> "conf/bblayers.conf"
add_layer meta-karo
add_layer meta-karo-distro

case $KARO_DISTRO in
    karo-custom-*)
	if [ -d "${BSPDIR}/${SRCDIR}/meta${KARO_DISTRO#karo-custom}" ];then
	    add_layer "meta${KARO_DISTRO#karo-custom}"
	else
	    echo "No custom layer found for distro: '$KARO_DISTRO'" >&2
	fi
	;;
    *)
	if [ "$KARO_DISTRO" != "karo-minimal" ];then
	    add_layer meta-qt6
	fi
esac

echo "BSPDIR='$(cd "$BSPDIR";pwd)'"
echo "BUILD_DIR='$(pwd -P)'"

clean_up

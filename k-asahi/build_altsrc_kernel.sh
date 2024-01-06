#!/bin/bash

###############################################################################
# Script : slackwareaarch64-<ver>/source/k/build_altsrc_kernel.sh
# Purpose: Build Slackware AArch64 Kernel packages from an alternate Kernel
#          source, such as the Raspberry Pi's Kernel fork.
# Author : Stuart Winter <mozes@slackware.com>
# Date...: 07-May-2023
# Version: 1.00
###############################################################################
#
# Copyright 2023  Stuart Winter, Earth, Milky Way, "".
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###############################################################################
#
# See this documentation for more information on the customisation of the
# Slackware Kernel, and the use of the Raspberry Pi Kernel fork:
#
# https://docs.slackware.com/slackwarearm:cstmz_kernel_rpi
# https://docs.slackware.com/slackwarearm:cstmz_kernel
#
# For this script in particular:
# https://docs.slackware.com/slackwarearm:cstmz_kernel_rpi_selfbuild
###############################################################################

CWD=$PWD

# Settings:

# Directory locations for temp storage and resulting packages:
export alt_tmpdir=/tmp/altkernelpkgs
export alt_pkgstore=$alt_tmpdir/pkg
export alt_srcstore=$alt_tmpdir/src
# This directory may contain local patches/kernel config, source archives, etc.
# It can be overridden by -A,--altsrc-base
export alt_base=$CWD/build_altsrc_kernel.basedir

# Default options:
savekernelheaders=No
hardwaremodel=$CWD/build_altsrc_kernel.conf/default

# Sanity checks:
[ $( id -u ) -ne 0 ] && \
   { echo "ERROR: You must run this script as the 'root' user" ; exit 1 ;}
[ ! -f /var/lib/pkgtools/packages/slackkit* -o ! -f /usr/share/slackdev/buildkit.sh ] && \
   { echo "ERROR: Slackware ARM development kit (package 'slackkit') must be installed." ; exit 1 ;}
# Ensure we're in the Kernel directory and can find the 'arm/build' script:
[ ! -x ./arm/build ] && \
   { echo "ERROR: cannot find './arm/build' script" ; exit 1;}

# Load in the Slackware ARM build kit:
. /usr/share/slackdev/buildkit.sh

# More sanity checks:
[ -z "${SLACKWAREVERSION}" ] && \
   { echo "ERROR: Slackware version is not configured in the slackkit package" ; exit 1 ;}

########################## Functions #########################################################

# Display help:
function display_help() {
cat << 'EOF'
 -h,  --help
   Display this help text.

 -D, --discover-altkernel-version
   Discover the version of the Linux Kernel source from the 'Makefile'
   within the online repository.  This saves downloading the source in its entirety.

 -t, --tmpdir
   Override the default temporary working directory.

 -s, --srcdir
   Override the default directory in which the Kernel source resides.

 -P, --pkgstore
   Override the default directory in which the resulting Kernel packages are stored.

 -A, --altsrc-base
   Override the default base directory in which your local patches/config files
   may reside.

 -b, --kernel-branch
   Override the default Kernel branch.  By default this is set statically within
   the Hardware Model's helper script.

 -g, --git-repo
   Override the default git repo containing the alternate Kernel source.
   By default this is set statically within the Hardware Model's helper script.

 -w, --git-web-repo
   Override the default git web repo containing the alternate Kernel source.
   By default this is set statically within the Hardware Model's helper script.

 -t, --pkg-build-tag
   Override the default Slackware package name build suffix.
   By default this is set statically within the Hardware Model's helper script.

 -H, --hardwaremodel
   By default the configuration for this script is held within the Hardware Model's
   helper script, within the 'build_altsrc_kernel.conf' directory.
   You can specify this parameter to use a helper script other than the 'default'.

 -W, --write-kernel-ver
   Store the Kernel version number (extracted from the 'Makefile') in a text file.

 -S, --save-kernel-headers
   By default the Kernel headers packages are deleted because they are not required.
   Use this option to preserve them.

EOF

}

# Determine whether the Hardware Model's helper script has a particular function defined:
function fnexists() {
   local estat=1
   type -t $1 >/dev/null && { [ $( type -t $1 ) = "function" ] && estat=0 ;}
   return $estat
}

# Determine the Kernel version from the downloaded and prepared fork source:
function determine_kernelver() {
     pushd $alt_srcstore/linux-*/ > /dev/null || exit 1
     [ ! -f Makefile ] && return 1
     echo "$(sed -ne's/^VERSION *= *//p' Makefile).$(sed -ne's/^PATCHLEVEL *= *//p' Makefile).$(sed -ne's/^SUBLEVEL *= *//p' Makefile)"
     popd > /dev/null ;}

# Other functions are defined within the Hardware Model's helper script.
##############################################################################################

# Parse any command line operators:
PARAMS="$( getopt -qn "$( basename $0 )" -o WhDSs:A:H:P:t:b:g:w:t: -l help,discover-altkernel-version,save-kernel-headers,write-kernel-ver,srcdir:,pkgstore:,altsrc-base:,tmpdir:,kernel-branch:,git-repo:,git-web-repo:,pkg-build-tag:hardwaremodel: -- "$@" )"
if [ $? -gt 0 ]; then display_help >&2 ; exit 2 ; fi
eval set -- "${PARAMS}"
for param in $*; do
  case "$param" in

     -h|--help)
        display_help ; exit 0
        shift 1;;

     -D|--discover-altkernel-version)
        discover_altkernel_version=Yes
        shift 1 ;;

     -s|--srcdir)
        export alt_srcstore="$2"
        [ ! -d "${alt_srcstore}" ] && { echo "ERROR: Cannot find source repo '${alt_srcstore}" ; exit 1;}
        shift 2;;

     -P|--pkgstore)
        export alt_pkgstore="$2"
        [ ! -d "${alt_pkgstore}" ] && { echo "ERROR: Cannot find package store directory '${alt_pkgstore}" ; exit 1;}
        shift 2;;

     -A|--altsrc-base)
        export alt_base="$2"
        [ ! -d "${alt_base}" ] && { echo "ERROR: Cannot find alternate Kernel source base directory '${alt_base}" ; exit 1;}
        shift 2;;

     -t|--tmpdir)
        export alt_tmpdir="$2"
        [ ! -d "${alt_tmpdir}" ] && { echo "ERROR: Cannot find temporary directory '${alt_tmpdir}" ; exit 1;}
        shift 2;;

     -b|--kernel-branch)
        export altkernelbranch="$2"
        shift 2;;

     -g|--git-repo)
        export alt_git_repo="$2"
        shift 2;;

     -w|--git-web-repo)
        export alt_web_repo="$2"
        shift 2;;

     -t|--pkg-build-tag)
        export pkgbuildtag="$2"
        shift 2;;

     -H|--hardwaremodel)
        export hardwaremodel="${CWD}/build_altsrc_kernel.conf/${2}"
        [ -f "${2}" ] && export hardwaremodel="${2}"
        shift 2;;

     -W|--write-kernel-ver)
        export write_kernelver_file="Yes"
        shift 1;;

     -S|--save-kernel-headers)
        export savekernelheaders=Yes
        shift 1;;

     --) shift; break;;
  esac
done

# Set up temporary space:
rm -rf $alt_tmpdir
mkdir -pm755 ${alt_pkgstore} ${alt_srcstore} || exit 1

# Load the Hardware Model's helper script.
[ ! -f "${hardwaremodel}" ] && {
   echo "ERROR: Unable to locate Hardware Model's helper script '${hardwaremodel}'" ; exit 1;}
. ${hardwaremodel} || { echo "ERROR: Unable to load Hardware Model helper script" ; exit 1;}

# Display the parameters:
cat << EOF

---------------------------
Temporary directory.........: ${alt_tmpdir}
Kernel source directory.....: ${alt_srcstore}
Package store directory.....: ${alt_pkgstore}
Build asset storage dir.....: ${alt_base}

GIT repository..............: ${alt_git_repo}
Kernel branch...............: ${altkernelbranch}
Slackware package build tag : ${pkgbuildtag}
Save Kernel headers package : ${savekernelheaders}

Hardware Model helper script: ${hardwaremodel}
---------------------------

EOF

# Set permissions to enable the git pull to not run as the 'root' user:
chown -R nobody:nobody $alt_tmpdir

# If requested, discover the version of the online repo without downloading it all:
[ ! -z "${discover_altkernel_version}" ] && {
   errmsg="ERROR: Unable to determine the Kernel version for the Kernel branch ${altkernelbranch}"
   fnexists determine_kernelver_online && { determine_kernelver_online || { echo "$errmsg" ; exit 1 ;} ;}
   # This is a single operation, not compatible with building.
   exit ;}

# Ensure we have at least 2GB free to hold the Kernel source and the
# resulting packages.
reqsize=2GB
fallocate -l ${reqsize} ${alt_tmpdir}/test-available-space > /dev/null 2>&1
exitval=$?
rm -f ${alt_tmpdir}/test-available-space
[ ${exitval} -ne 0 ] && { echo "ERROR: insufficient space in ${alt_tmpdir}. At least ${reqsize} is required." ; exit 1;}

# Main routines:
fnexists place_altkernel_fork_repo && { place_altkernel_fork_repo || exit 1 ;}
fnexists prepare_altkernel_fork_repo && { prepare_altkernel_fork_repo || exit 1 ;}
fnexists configure_altkernel_fork_repo && { configure_altkernel_fork_repo || exit 1 ;}
fnexists patch_altkernel_fork_repo && { patch_altkernel_fork_repo || exit 1 ;}
export VERSION=$( determine_kernelver )
export BUILD=$pkgbuildtag # override the arm/build script
echo "Building alt Kernel fork, Linux version: *${VERSION}*"

# Call the build system to build the packages:
# If the Slackware ARM x-toolchain helper 'dbuild' is found, use that otherwise
# build entirely natively:
build=./arm/build
which dbuild > /dev/null && build=dbuild
${build} \
   ${alt_kernelslackbuild_opts} \
   --srcdir ${alt_srcstore} \
   --pkgstoreoverride ${alt_pkgstore} || exit 1

# Store the Kernel version number as a text file.
# This is used by the update script to determine the current version available
# online without having to parse file names and so on.
[ ! -z "${write_kernelver_file}" -a ! -z "${kver}" ] && echo "${kver}" > ${alt_pkgstore}/a/version

# The official Slackware 'd/kernel-headers' package should not be replaced
# so we'll delete the one created from the alt Kernel fork.
[ "${savekernelheaders}" = "No" ] && {
   rm -rf ${alt_pkgstore}/d/kernel-headers*
   rmdir ${alt_pkgstore}/d ;}

exit

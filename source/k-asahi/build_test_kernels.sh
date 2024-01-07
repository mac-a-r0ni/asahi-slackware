#!/bin/bash

###########################################################################
# Create the Kernel packages and Slackware Installer outside of the
# main tree.  This facilitates easier testing.
#
# The 'PKGSTORE_OVERRIDE' variable is detected by kernel.SlackBuild which
# sets $PKGSTORE accordingly.
# PKGSERIES_K_OVERRIDE variable is used by the Installer build script
# wrapper to select the experimental Kernel packages from outside the tree.
#
# mozes@slackware.com
# 26-Aug-2022
###########################################################################

# Usage:
# 1) Normal run: $ dbuild
# 2) Merging in Kernel configuration options for a new Hardware Model during
#    the development phase:
#    $ dbuild --mergeconfig /path/to/kernel-options-file
# 3) If you don't want to build the Slackware Installer and SD Card images,
#    set the environment variable 'BT_NOINST' before calling this script:
#    $ BT_NOINST=1 dbuild

# Load the Slackware ARM devkit:
source /usr/share/slackdev/buildkit.sh

tmpdir=/tmp/SLKtestbuilds
rm -rf $tmpdir

# All-in-One build script:
AIOTOOL=$SLACKPLATFORMDIR/bootware/src/PRIVATE_aio.build

export PKGSTORE_OVERRIDE=$tmpdir/packages/
# We'll just use the root of the tmp dir to represent 'slackwareaarch64-current/':
export ROOTDIR_OVERRIDE=$tmpdir
mkdir -vpm755 $PKGSTORE_OVERRIDE/{a,d,k}
# For the Installer which writes to $PKGSTORE/../installer
# and kernel.SlackBuild also copies the Kernel and DTBs to the 'kernels' directory.
mkdir -vpm755 $ROOTDIR_OVERRIDE/{installer,kernels}

# Set the Kernel package's source "PKGSERIES" as the WIP (Work In Progress)
# so that some of the other build processes such as the Installer ('mk-arm.sh')
# can pull the latest assets from it, such as the Kernel Module Loader.
#export PKGSERIES_K_OVERRIDE="k-wip"
export PKGSERIES_K_OVERRIDE="${PWD##*/}"
[ ! -d $PORTROOTDIR/source/$PKGSERIES_K_OVERRIDE ] && {
   echo "Override source directory $PKGSERIES_K_OVERRIDE does not exist"
   exit 1 ;}
#   echo "Using normal 'k' series directory"
#   unset PKGSERIES_K_OVERRIDE ;}

# Sanity check:
[ ! -d $SLACKPLATFORMDIR/bootware ] && {
   echo "Error: cannot find platform bootware directory"
   exit 1 ;}

# Standard build:
dbuild $@ || exit 1

# If we want to build without patches:
#dbuild --nopatches || exit 1

# Build the installer and SD card images?
[ -z "$BT_NOINST" -a -d "$PORTSRC/source/installer" ] && {
   cd $PORTSRC/source/installer
   dbuild || exit 1
   # Populate the TFTP boot scripts for non-destructive testing:
   [ -x ./populate_tftpboot_onprisere ] && ./populate_tftpboot_onprisere

   echo "*** Building SD card images ***"
   echo "*** Copying platform installer directory into $tmpdir"
   # The SD card builders work with relative paths, so it's easiest to copy
   # the whole directory to a temporary location and build there.
   cp -fa $SLACKPLATFORMDIR/bootware $tmpdir/

   pushd $tmpdir/bootware/src/ || exit 1
      ./sdcards.build
   popd ;}

# Organise it ready for publishing:
cd $tmpdir
mkdir -vpm755 publish/experimental/{bootware/installer,slackware}
# The Installer may not have been created:
[ -d bootware/installer/$SLACKWAREVERSION ] && {
   # Move the SD card images containing the bootable Slackware Installer:
   mv -fv bootware/installer/$SLACKWAREVERSION publish/experimental/bootware/installer/ ;}
# Move the Slackware packages into place:
mv -fv packages/* publish/experimental/slackware/
# Move the Kernels into place:
mv -fv $ROOTDIR_OVERRIDE/kernels publish/experimental/
# Move the bare Slackware Installer InitRD into place.
# This is for TFTP booting:
mv -fv $ROOTDIR_OVERRIDE/installer publish/experimental/installer-bare
# Clean up to include only the assets we care about.
# Now empty:
rmdir packages
# Not required - installer SD cards have been moved already:
rm -rf bootware

# Build the AiO installers:
mkdir -vpm755 publish/experimental/bootware/installer-aio
[ -x $AIOTOOL ] && {
   $AIOTOOL \
      -s $tmpdir/publish/experimental/bootware/installer \
      -d $tmpdir/publish/experimental/bootware/installer-aio ;}

echo "Experimental packages available in: $tmpdir/publish/experimental"

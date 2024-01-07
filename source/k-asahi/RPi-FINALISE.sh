#!/bin/bash

# Build RPi Kernel fork packages and deposit them within the correct
# directory ready for publishing.
# mozes@slackware.com, July 2023.

source /usr/share/slackdev/buildkit.sh

publishdir=${publishdir:-$HOME/armedslack/experimental/${SLACKWAREVERSION}/rpi-kernel-fork/}
[ ! -d "${publishdir}" ] && { echo "ERROR: can't find ${publishdir}" ; exit 1 ;}
echo "Publishing dir: ${publishdir}"

tmpdir=$TMP/packages-rpi/rpi-kernel-fork
rm -rf $tmpdir
mkdir -vpm755 $tmpdir
./build_altsrc_kernel.sh -WP ${tmpdir} || exit 1

# Move new packages in to place unless instructed otherwise:
[ -z "$1" ] && {
   rm -rf "${publishdir}"
   mkdir -vpm755 "${publishdir}"
   cd ${tmpdir} || exit 1
   find . -path './kernels' -prune -o -type f -print0 | xargs -0i mv -fv '{}' ${publishdir}/ ;}

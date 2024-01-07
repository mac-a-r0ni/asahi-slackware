#############################################################
# Document: /boot/platform/aarch64/helper/README.txt
# Purpose : Document the purpose of the helper scripts
# Author..: Stuart Winter <mozes@slackware.com>
# Date....: 21-Dec-2021 
#############################################################
# NOTICE ####################################################
# Do not edit these files - they are managed by the Slackware
# packages.  Any changes here may be deleted or modified
# without warning!
#############################################################

This directory contains helper scripts used during the Kernel
and Bootware upgrade processes.

Since the Slackware Linux Kernel package supports all Hardware
Models, the Slackware Kernel package makes provision for custom
actions to be performed during the post-installation phase of
the Kernel package installation/upgrade.
This provides for the handling of the idiosyncrasies found
across the various Hardware Models.

All Kernel package helper scripts must be named
'pkg-kernel-<name>'
For example, 'pkg-kernel-rpi'

In the case of the Raspberry Pi, the Hardware Model helper
script duplicates the Linux Kernel et al on to the
Hardware Model's Boot Ware partition, /boot/platform/hwm_bw

This enables seamless Kernel upgrades for users who prefer to
use the RPi's native Boot Loader, over U-Boot.


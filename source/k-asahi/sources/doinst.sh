
# The OS InitRD ships with a minimal set of firmware that's required
# for the supported Hardware Models, but we don't ship an inventory
# file.  This is because not all Hardware Models require firmware
# (in particular 32bit ARM doesn't for the supported Hardware Models
# without externally connected peripherals).
# Additionally the firmware that *is* included may not be loaded
# on the Hardware Model you're using - e.g. the firmware for the Pinebook Pro's
# LCD panel is never loaded on the Raspberry Pi, yet it's included
# within the generic OS InitRD so that it's available for the Pinebook.
# Supplying a default inventory in this case would always cause a mismatch
# between the running OS and the OS InitRD when os-initrd-mgr is first
# run.
# This is why we don't ship an inventory cache within the Kernel package.
#
# However, we do need to delete any existing inventories because the
# newly placed OS InitRD will not contain any extra firmware/local user
# customisations that may have been incorporated by os-initrd-mgr.
# Deleting this inventory cache will enable os-initrd-mgr to re-scan the
# system and re-incorporate any extra firmware/local customisations
# once the Kernel package upgrade completes (i.e. now!)
#
# Inventory caches from the previous invocations of os-initrd-mgr are
# now null and void.
# Firmware inventory cache:
rm -f boot/.os-initrd-fw-inventory
# Kernel module inventory cache (used for --sync-loaded-kmods)
# This contains the Kernel module file name and a hash to use for comparison
# (to know whether to refresh the modules when re-packing the OSInitRD)
rm -f boot/.os-initrd-kmod-inventory
# List of the loaded Kernel module names:
# (used for --sync-loaded-kmods and --modprobe-synced-kmods)
rm -f boot/.os-initrd-kmod-names-inventory

# Local customisations inventory cache:
rm -f boot/.os-initrd-custs-inventory

# Short-term migration of config file to /etc:
# To be removed after a few releaes.
[ -f boot/local/os-initrd-mgr.conf ] && mv -f boot/local/os-initrd-mgr.conf etc/

# Call the OS InitrRD manager to reincorporate any locally
# held user modifications, to load modules and so on and to syncronise
# the firmware.
chroot . /usr/sbin/os-initrd-mgr -q

# To make default the synchronization of the OS InitRD's Kernel modules with
# those within the running OS (-S|--sync-loaded-kmods)
# Need to change messages around defaults within os-initrd-mgr if this changes,
# and how to unset it.
# This can be overridden locally within os-initrd-mgr's config file:
# /boot/os-initrd-mgr.conf
# chroot . /usr/sbin/os-initrd-mgr -Sq

# Collapse all 32bit ARM & x86 variants of 'i?86' into a single
# platform: 'x86' and 'arm' respectively.
export ARCH=$( uname -m | sed -e 's%i[0-9]86%x86%g' -e 's?arm.*?arm?g' )

# Execute any helper scripts found for this platform.
# This enables the Raspberry Pi's Hardware Model bootware partition
# to receive the latest Kernel, OS InitRD, DTBs et al in addition to
# the standard location, /boot.
# This may be useful for other Hardware Models that need to perform
# post installation actions, to accommodate idiosyncrasies.
[ -d /boot/platform/$ARCH/helper/ ] && {
   for helper in $( find /boot/platform/$ARCH/helper/ -name 'pkg-kernel-*' -type f ) ; do
      [ -x ${helper} ] && ${helper}
   done }

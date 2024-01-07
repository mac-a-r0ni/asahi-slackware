############################################################
# Document: /boot/local/README.txt
# Purpose : Explain the OS Initial RAM Disk ('OS InitRD')
#           user-serviceable module loader helper scripts
#           and configuration options.
# Author..: Stuart Winter <mozes@slackware.com>
# Date....: 15-May-2021
############################################################

Slackware ARM / AArch64 enables user serviceable scripts to
be run within the OS InitRD at three key stages of the 
boot process.

The scripts provided here are samples and they must be renamed
prior to use.

0.0 Operating System Initial RAM Disk Manager Configuration file
    ------------------------------------------------------------

    /etc/os-initrd-mgr.conf
    Configuration file for os-initrd-mgr.  This overrides all default
    settings and any command line operators.  It can also be used to
    set up user-defined hooks to control parts of os-initrd-mgr's
    execution.

    By default no active configuration file is supplied, instead you must
    rename a sample file.
    See /etc/os-initrd-mgr.conf.sample

    Note: the Slackware Package Management tools presently do not touch
    /etc/os-initrd-mgr.conf, so it's incumbent upon the user (you) to
    merge in any particular changes in the new sample file.

1.0 Stages and Scripts 
    ------------------

Stage 1:
   Prior to setting of the list of Linux Kernel Modules required
   to support the Platform and Hardware Model
   `````````````````````````````````````````````````````````````

   Script: /boot/local/load_kernel_modules.pre

   Typically, users will not need to use this script.

Stage 2:

   Subsequent to the setting of the aforementioned list, but
   prior to loading the Linux Kernel Modules into the Kernel
   ``````````````````````````````````````````````````````````

   Script: /boot/local/load_kernel_modules.pre-modload

   Typically, users should only use this script if the module
   lists contain modules that cause system instability or
   crashes (usually immediately upon the load event).
   
   For details about managing such situations, refer to the
   sample script:

    /boot/local/load_kernel_modules.pre-modload.sample

   Typically, users will not need to use this script.

Stage 3:
   Subsequent to loading the Linux Kernel Modules into the Kernel
   ```````````````````````````````````````````````````````````````
   Script: /boot/local/load_kernel_modules.post

   If users require a particular Linux Kernel Module to be
   loaded during the initial boot in order to light up a
   particular sub system for some hardware that is attached
   to their Hardware Model, they should add it to this script.

   In most cases these scripts will consist of 'modprobe'
   lines.

   For examples, refer to the sample script:

     /boot/local/load_kernel_modules.post.sample



2.0 OS InitRD environment runtime configuration Options
    ---------------------------------------------------

    The following files may also be present within /boot/local and will be
    reincorported into the OS InitRD.

* Important note: *

      By default, the Slackware ARM / AArch64 Kernel package ships these
      files as empty, as the principal configurations are stored within
      the Boot Loader configuration (/boot/extlinux/extlinux.conf on Slackware
      AArch64).  These options are passed to the Kernel via its command line
      interface (/proc/cmdline).

      Users are at liberty to set the configuration via either method, but
      must be aware that options supplied via the Kernel command line interface
      take precedence over the file-based configuration options.

 rootdev        Contains the name of the root device, such as: /dev/hda1
                [ Default: Set within the Boot Loader configuration ]

 rootfs         Contains the root filesystem type, such as: xfs
                [ Default: Set within the Boot Loader configuration ]

 wait-for-root  Contains a number - the init script will wait this amount
                of seconds before creating device nodes.
                [ Default: Set within the Boot Loader configuration ]

 resumedev      Contains the name of the device to resume from hibernation.

 luksdev        Contains colon separated list of luks encrypted devices to
                be unlocked.

 lukstrim       Contains colon separated list of luks encrypted devices to
                pass '--allow-discards' when unlocking

 lukskey        Contains the path to a LUKS key-file for automatic unlock
                Format: LABEL=<partition_label>:/path/to/file
                        UUID=<partition_uuid>:/path/to/file

 keymap         Contains the name for a custom keyboard map

 initrd-name    Contains the name of the initrd file.



3.0 Handling firmware
    -----------------

The OS InitRD contains firmware required at boot for the supported
Hardware Models. os-initrd-mgr will automatically syncronise the firmware
at runtime.

Note that the 'kernel-firmware' package will also run os-initrd-mgr
upon installation and upgrade, to enable any fresh firmware to be
included within the OS InitRD.

4.0 Updating the OS InitRD
    -----------------------

    /boot/local is a holding area for the scripts to be managed
    locally; each script must be incorporated into the OS InitRD
    image in order for them to be found during boot.

    To do this, run

    /usr/sbin/os-initrd-mgr

    This will take several minutes to re-pack the OS InitRD.

5.0 Feeding back
    ------------

   If there are any particular modules that users think would
   benefit the Slackware ARM / AArch64 community at large, please
   email mozes@slackware.com


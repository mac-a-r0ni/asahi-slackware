Config file: config-rpikernel-fork-5.18

This is the result of :
 - applying the patch set Slackware ARM uses to the RPi kernel fork.
 - copying the Slackware ARM Linux Kernel config
 - make oldconfig
 - Removing a Rockchip module which caused build failure.

Presently at least these things are broken with it:
 - serial console doesn't work - probably because a module isn't loaded
   or the settings have become broken.
 - RTC module isn't built

Probably many others, but it's a start and it works for the most part.


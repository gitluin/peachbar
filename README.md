sbar-lemon
-----
This is a collection of shell scripts that were written for use with [sara v3.0+](https://github.com/gitluin/sara). Each script acquires a lock, writes to a shared file to update the bar name, cats out the contents of this file, releases the lock, and then exits (or sleeps in the case of the loop).

To start, I symlink the files from this directory to my custom `/ibin` directory (which is added to `$PATH`) with the prefix `sbar_` and then add `/ibin/start_sbar.sh &` to my `~/.xinitrc` **before** the `exec sara` line. Make sure you change the directory names, etc. to match your system. To properly integrate with `sara` and `lemonbar`, adjust the `barpx` variable in `config.h` to the size that you want, and then replace any call in `~/.xinitrc` to `exec sara` with a call to the `start_sara.sh` script. This creates an instance of [lemonbar with Xft support](https://github.com/krypt-n/bar) that is identical to the bar that was originally in v1.0. You will have to install `lemonbar` separately for this to work.

`lemonbar` has a **lot** of customization options, so go hog-wild here. At the very least, make sure the height of the bar matches the `barpx` you allotted for it! The script has what's probably crude support for multihead, and you might have to muck about with it to get it to work. Make sure you comb through the shell scripts to verify that everything matches your system.

## Why It's Cool
Only time, network status, and battery level are updated every 15 seconds. Volume and battery status are updated when they are updated - push notifications effectively. Less system usage!

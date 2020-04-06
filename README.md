sbar-lemon
-----
This is a collection of shell scripts that were written for use with [sara v3.0+](https://github.com/gitluin/sara). Each script acquires a lock, writes to a shared file to update the bar name, cats out the contents of this file, releases the lock, and then exits (or sleeps in the case of the loop).

To start, create `~/.sbar/`. Then, I symlink the files from this repository to `/usr/local/bin/` with the prefix `sbar_` added to all but `startsbar.sh`, `startsara.sh`, and `saratagline.sh`. Then I add `startsbar.sh &` to `~/.xinitrc` **before** the `exec sara`/`startsara.sh` line. Make sure you change the directory names, etc. to match your system.

Place `battery.rules` in `/etc/udev/rules.d/`. Then, run `sudo udevadm control --reload` to ensure the rules take effect at the moment, or you could reboot. Per the [ArchWiki](https://wiki.archlinux.org/index.php/Udev): "However, the rules are not re-triggered automatically on already existing devices", and last I checked the battery is already existing.

To properly integrate with `sara` and `lemonbar`, adjust the `barpx` variable in `config.h` to the size that you want, and then in `~/.xinitrc`, use `exec startsara.sh` instead of `exec sara`. This creates an instance of [lemonbar with Xft support](https://github.com/krypt-n/bar) that is identical to the bar that was originally in v1.0. You will have to install `lemonbar-xft` separately for this to work.

`lemonbar` has a **lot** of customization options, so go hog-wild here. At the very least, make sure the height of the bar matches the `barpx` you allotted for it! The script has what's probably crude support for multihead, and you might have to muck about with it to get it to work. Make sure you comb through the shell scripts to verify that everything matches your system.

## Why It's Cool
Only time, network status, and battery level are updated every 15 seconds. Volume and battery status are updated when they are updated - push notifications effectively. Less system usage!

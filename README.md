peachbar
-----
 ,:.
(:::)
\`-'																		
							ascii.co.uk/art/fruit

This is a collection of shell scripts that were written for use with [sara v3.0+](https://github.com/gitluin/sara). `peachbar.sh` is the heavy-lifter: it currently contains the main loop, the modules, the graphical options, and all initialization tasks. By default, this set of scripts writes `amixer` volume info, `light` brightness info, `wpa_cli` network ssid, and battery info. The script is modular, and all it requires to add different information to the status text is making a new module function in `peachbar.sh` and then adding it to the `MODULES` variable.

## Installation
You should use an `sxhkdrc` like the example in the `sara` repository for amixer controls, etc. to properly signal `peachbar` to update.

To start, symlink the files from this repository to `/usr/local/bin/`. Then add `peachbar-start.sh &` to `~/.xinitrc` **before** ending the file with `exec sara` or `exec peachbar-startsara.sh`.

Place `peachbar-battery.rules` in `/etc/udev/rules.d/`. Then, run `sudo udevadm control --reload` to ensure the rules take effect at the moment, or you could reboot. Per the [ArchWiki](https://wiki.archlinux.org/index.php/Udev): "However, the rules are not re-triggered automatically on already existing devices", and last I checked the battery is already existing. Make sure to replace the `/home/` location in this file with yours.

To properly integrate with `sara` and `lemonbar`, adjust the `barpx` variable in `config.h` to the size that you want, and then in `~/.xinitrc`, use `exec peachbar-startsara.sh` instead of `exec sara`. This creates an instance of [lemonbar with Xft support](https://github.com/krypt-n/bar) that is identical to the bar that was originally in v1.0. You will have to install `lemonbar-xft` separately for this to work.

`lemonbar` has a **lot** of customization options, so go hog-wild here. At the very least, make sure the height of the bar matches the `barpx` you allotted for it! The script has what's probably crude support for multihead, and you might have to muck about with it to get it to work. Make sure you comb through the shell scripts to verify that everything matches your system.

## Why It's Cool
Everything is updated every 10 seconds, unless `peachbar.sh` receives `SIGUSR1`, in which case it updates the status text immediately. This means that audio status, brightness, and battery status are always up-to-date, but without excessive polling.

## To-Do:
	* `peachbar-battery.rules` does not work. Surprise.
	* Config file?
	* Command line options like reloading config?
	* Status text lags behind if you hold down keys like brightness, etc. (changes too fast).

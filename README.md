peachbar
-----
This is a collection of shell scripts that were written for use with [sara v3.0+](https://github.com/gitluin/sara). By default, this set of scripts writes `amixer` volume info, `light` brightness info, `wpa_cli` network ssid, and battery info. The script is modular, and all it requires to add different information to the status text is making a new module function in `peachbar-modules.conf` and then adding it to the `MODULES` variable in `peachbar.conf`.

This is a collection of shell scripts that manages output to [lemonbar](https://github.com/LemonBoy/bar). The information string is constructed modularly from shell functions specified in `peachbar-modules.conf`. There is support for asynchronous updating, immediate updating *without* high-frequency polling (useful for getting immediate response when you change your audio), and a lot of customization.

By default, there are modules for my local machine included. These are:
 * `Audio`, which outputs `amixer` statistics.
 * `Bright`, which outputs `light` statistics.
 * `Network`, which outputs `wpa_cli` statistics.
 * `Battery`, which outputs statistics from `sys/power_supply/`.
 * `Sara`, which outputs `sara` tag statistics.

This setup can be made to work with any window manager pretty easily, as long as you can write a shell script to get its output.

## Installation
### Prerequisites
 * [lemonbar](https://github.com/LemonBoy/bar), though I prefer to use [lemonbar-xft](https://github.com/krypt-n/bar) for Xfont support (and thus symbols).
 * [GNU coreutils](https://www.gnu.org/software/coreutils/) and [GNU sed](https://www.gnu.org/software/sed/).
 * `sxhkd` and `sara` if you want sara integration.
 * `udev` and `udevadm` if you want signaling on battery state changes.

### Setting up peachbar
You should use an `sxhkdrc` like the example if you want the support of the immediate module signaling that makes audio/brightness/etc. so snappy.
 * `sudo ./install.sh "$HOME"` installs the scripts to `/usr/local/bin/` and config files to `$HOME/.config/peachbar/`. You will also be asked if you would like to install the `udev` battery.rules.
 * To use peachbar with any window manager, add `peachbar.sh &` to your `~/.xinitrc` before you `exec my-window-manager`.
 * To use peachbar with sara, add `sara-interceptor.sh $SARAFIFO $PEACHFIFO &` to `peachbar.sh` before the `peachbar-sys.sh | lemonbar | sh &` line. Naturally, this means your `~/.xinitrc` should end with `exec sara > $SARAFIFO`.
 * To properly integrate with any window manager that uses lemonbar, adjust `barpx` or the equivalent variable for your window manger and match this with `BARH` in `peachbar.conf`. A similar approach for `BARX` and `BARY`.
 * The modules are not designed to be super portable, since they are specific to pulling information from my machine. Make sure you go over them and tweak them so that they work with your system. Or write your own. Or take them from another bar. Whatever works!

## Personalization
There are a **lot** of customization options.

## Uninstallation
 * `sudo ./uninstall.sh "$HOME"` removes the scripts and config files.
 * If you installed the `battery.rules`:
  * `sudo rm /etc/udev/rules.d/peachbar-battery.rules`
  * `sudo udevadm control --reload` or `sudo reboot`.

## Bugs
 * When a module fails to return, the entire `sys` area fails.
 * BARBG only changes in the middle part of the bar when relaunching lemonbar. Maybe replace with a "middle" section instead of setting -B?

## To-Do:
* Option to separate layout symbol from tags (i.e. if you want tags center, layout on side).
* Custom layout symbols.
* Better wal integration.
* Command line options like reloading config?
* Alternative approach to coloring battery: acpi event sets a bash variable.
* Separate square for icons, followed by status ([see here](https://i.redd.it/wzba8omwrdi51.png)).
* Theming guide.
* Explain examples.

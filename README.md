peachbar
-----
This is a collection of shell scripts that were written for use with [sara v3.0+](https://github.com/gitluin/sara). `peachbar.sh` is the heavy-lifter for the status text: it contains the main status text loop, the modules, their graphical options, and all initialization tasks. By default, this set of scripts writes `amixer` volume info, `light` brightness info, `wpa_cli` network ssid, and battery info. The script is modular, and all it requires to add different information to the status text is making a new module function in `peachbar.sh` and then adding it to the `MODULES` variable.

## Installation
### Prerequisites
* [lemonbar-xft](https://github.com/krypt-n/bar) or some other bar software that you can pipe the output to.
* `sxhkd` and `sara` if you want sara integration.

### Setting up peachbar
You should use an `sxhkdrc` like the example in the sara repository for amixer controls, etc. to properly signal peachbar to update.
* `sudo ./install.sh "$HOME"` installs the scripts to `/usr/local/bin` and config files to `$HOME/.config/peachbar/`.
* To use the peachbar information modules with other window managers, add `peachbar.sh &` to `~/.xinitrc`. This will require removing the lemonbar syntax in the modules.
* To use peachbar with sara, end `~/.xinitrc` with `exec peachbar-startsara.sh`, which will start sara and an instance of `lemonbar` (by default expecting the xft fork).
* `sudo cp peachbar-battery.rules /etc/udev/rules.d/` *after* changing all `/home/ishmael/` references to `/home/your-name/`.
* Run `sudo udevadm control --reload` or `sudo reboot` to ensure the battery rules take effect. 
* To properly integrate with sara and lemonbar, adjust the `barpx` variable in `sara/config.h` as desired and match this with `BARH`.
* Make sure you go over the shell scripts to verify that everything matches your system (particularly the module functions in `peachbar.sh` in case, for example, you use something other than amixer or light for audio or brightness).

## Personalization
lemonbar has a **lot** of customization options, so go hog-wild here. `peachbar-startsara.sh` has crude multihead support, so you might have to muck about with it. 

## Why It's Cool
Everything is updated every 10 seconds, unless `peachbar.sh` receives `SIGUSR1`, in which case it updates the status text immediately. This means that audio status, brightness, and battery status are always up-to-date, but without excessive polling.

## Uninstallation
* `sudo ./uninstall.sh "$HOME"` removes the scripts and config files.
* `sudo rm /etc/udev/rules.d/peachbar-battery.rules`
* `sudo udevadm control --reload` or `sudo reboot`.

## To-Do:
* Command line options like reloading config?
* Status text lags behind if you hold down keys like brightness, etc. (changes too fast).

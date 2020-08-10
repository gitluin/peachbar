peachbar
-----
This is a collection of shell scripts that were written for use with [sara v3.0+](https://github.com/gitluin/sara). `peachbar.sh` is the heavy-lifter for the status text: it contains the main status text loop, the modules, their graphical options, and all initialization tasks. By default, this set of scripts writes `amixer` volume info, `light` brightness info, `wpa_cli` network ssid, and battery info. The script is modular, and all it requires to add different information to the status text is making a new module function in `peachbar.sh` and then adding it to the `MODULES` variable.

## Installation
### Prerequisites
* `lemonbar` or some other bar software that you can pipe the output to.
* `sxhkd` and `sara` if you want sara integration.

### Setting up peachbar
You should use an `sxhkdrc` like the example in the sara repository for amixer controls, etc. to properly signal peachbar to update.
* Running `sudo install.sh` from the repo directory should put all the files, save the `udev` rules, where they belong.
* To use the peachbar information modules with other window managers, add `peachbar.sh &` to `~/.xinitrc`.
* To use peachbar with sara, end `~/.xinitrc` with `exec peachbar-startsara.sh`, which will start sara and an instance of [lemonbar with Xft support](https://github.com/krypt-n/bar).
* `sudo cp peachbar-battery.rules /etc/udev/rules.d/` *after* changing all `/home/ishmael/` references to `/home/your-name/`.
* Run `sudo udevadm control --reload` (or reboot) to ensure the battery rules take effect. 
* To properly integrate with sara and lemonbar, adjust the `barpx` variable in `sara/config.h` as desired and match this with `BARH`.
	* You will have to install `lemonbar-xft` separately for this to work.
* Make sure you go over the shell scripts to verify that everything matches your system (particularly the module functions in `peachbar.sh` in case, for example, you use something other than amixer or light for audio or brightness).

## Personalization
lemonbar has a **lot** of customization options, so go hog-wild here. `peachbar-startsara.sh` has crude multihead support, so you might have to muck about with it. 

## Why It's Cool
Everything is updated every 10 seconds, unless `peachbar.sh` receives `SIGUSR1`, in which case it updates the status text immediately. This means that audio status, brightness, and battery status are always up-to-date, but without excessive polling.

## To-Do:
* Command line options like reloading config?
* Status text lags behind if you hold down keys like brightness, etc. (changes too fast).

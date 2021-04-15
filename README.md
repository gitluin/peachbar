peachbar
-----
This is a collection of shell scripts that manages output to [lemonbar](https://github.com/LemonBoy/bar). The information string is constructed modularly from shell functions specified in `peachbar-modules.conf`. There is support for asynchronous updating, immediate updating *without* high-frequency polling (useful for getting immediate response when you change your audio), and a lot of customization.

By default, there are modules for my local machine included. These are:
| Module     | Information source	       |
| :----:     | :----:       		       |
| Audio      | amixer       		       |
| Bluetooth  | bluetoothctl		       |
| Bright     | light        		       |
| Network    | wpa\_cli     		       |
| Battery    | Output from `sys/power_supply/` |
| Sara       | sara			       |

This setup can be made to work with any window manager pretty easily, as long as you can write a shell script to get its output.

## Installation
### Prerequisites
 * [lemonbar](https://github.com/LemonBoy/bar), though I prefer to use [lemonbar-xft](https://github.com/krypt-n/bar) for Xfont support (and thus symbols).
 * [GNU coreutils](https://www.gnu.org/software/coreutils/) and [GNU sed](https://www.gnu.org/software/sed/). This is basically a huge learning exercise in sed.
 * `sxhkd` and `sara` if you want sara integration.
 * `udev` and `udevadm` if you want signaling on battery state changes.
 * Any of the relevant programs for the modules listed above.

### Setting up peachbar
Look at `examples/sxhkdrc` for a demonstration on how to use `peachbar-signal.sh` to get super snappy bar updating.
 * `sudo ./install.sh "$HOME"` installs the scripts to `/usr/local/bin/` and config files to `$HOME/.config/peachbar/`. You will also be asked if you would like to install the `udev` battery.rules.
 * To use peachbar with any window manager, add `peachbar.sh &` to your `~/.xinitrc` before you `exec my-window-manager`.
 * To use peachbar with sara, add `sara-interceptor.sh $SARAFIFO $PEACHFIFO &` to `peachbar.sh` before the `peachbar-sys.sh | lemonbar | sh &` line. Naturally, this means your `~/.xinitrc` should end with `exec sara > $SARAFIFO`.
 * To properly integrate with any window manager that uses lemonbar, adjust `barh`, `barx`, `bary`, etc. or the equivalent variables for your window manger and match this with `BARH`, `BARX`, `BARY` in `peachbar.conf`.
 * The modules are not designed to be super portable, since they are specific to pulling information from my machine. Tweak them for your system, yoink shell scripts from other bars, whatever works for you!

## Personalization
There are a **lot** of customization options.

### `peachbar.conf`
| Variable   	| Explanation									|
| :----:     	| :----:       		        						|
| PEACHFIFO  	| Name of the FIFO you would like peachbar to use.       		        |
| MODULES    	| A lemonbar-flavored string that determines the location of the modules in your bar. Supports %{S#} and %{lcr} formatters. If you have multiple monitors, but only specify for one, the layout will be  copied across all of them. However, if your modules support monitor-dependent output, this will still work. 				|
| ASYNC      	| A string that tells peachbar whether a module should be run asynchronously or not. If yes, peachbar will only update the module if it receives its name in $PEACHFIFO, or if it receives "All" in $PEACHFIFO. If no, then the specified module will be set on a default timer. If unspecified, it is assumed that the module is not asynchronous.        		        												|
| DEFINTERVAL	| The timer for synchronous module updating. Defaults to 10s if not specified.	|
| USEWAL    	| If you have [wal](https://github.com/dylanaraps/pywal) installed, use a default colorscheme derived from `colors.sh`. Will silently fail if you have not already generated a colorscheme using `wal`, so do that first! Any colors manually assigned in `peachbar.conf` will override those set by `wal`.  					|
| BARX		| The x coordinate you would like `lemonbar` to start at.			|
| BARY		| The y coordinate you would like `lemonbar` to start at.			|
| BARW		| The width in pixels you would like `lemonbar` to be.				|
| BARH		| The height in pixels you would like `lemonbar` to be.				|


### `peachbar-modules.conf`
Note that these are module-specific!
| Variable   	| Explanation										|
| :----:     	| :----       		        							|
| AUDIOBG  	| `Audio`: Default background for the symbol.				       		|
| MUTEBG  	| `Audio`: Background when amixer detects that `Master` output is muted.		|
| CHRBG  	| `Battery`: Background when the power supply is charging.				|
| LOWBG  	| `Battery`: Background when the power supply is between 10% and 20% capacity.		|
| PANICBG  	| `Battery`: Background when the power supply is below 10% capacity.			|
| BATSTATFILE  	| `Battery`: Location of the system file that determines charging state.		|
| BATCAPFILE  	| `Battery`: Location of the system file that determines current capacity.		|

## Uninstallation
 * `sudo ./uninstall.sh "$HOME"` removes the scripts and config files.
 * If you installed the `battery.rules`:
  * `sudo rm /etc/udev/rules.d/peachbar-battery.rules`
  * `sudo udevadm control --reload` or `sudo reboot`.

## Bugs
 * BARBG only changes in the middle part of the bar when relaunching lemonbar. Maybe replace with a "middle" section instead of setting -B?

## To-Do:
 * Explanation of customization options.
 * Explain examples.
 * Option to separate layout symbol from tags (i.e. if you want tags center, layout on side).
 * Custom layout symbols.
 * Command line options like reloading config?
 * Separate square for icons, followed by status ([see here](https://i.redd.it/wzba8omwrdi51.png)).

peachbar
-----
This is a collection of shell scripts that manages output to [lemonbar](https://github.com/LemonBoy/bar). The information string is constructed modularly from shell functions specified in `peachbar-modules.conf`. There is support for asynchronous updating, immediate updating *without* high-frequency polling (useful for getting immediate response when you change your audio), synchronous updating, and a lot of customization.

By default, there are modules for my local machine included. These are:
| Module     | Information source	       |
| :----:     | :----:       		       |
| Audio      | amixer       		       |
| Bluetooth  | bluetoothctl		       |
| Brightness | light        		       |
| Network    | wpa\_cli     		       |
| Battery    | Output from `sys/power_supply/` |
| Sara       | sara			       |

This setup can be made to work with any window manager pretty easily, as long as you can write a shell script to get its output.

## Installation
### Prerequisites
 * [lemonbar](https://github.com/LemonBoy/bar), though I prefer to use [lemonbar-xft](https://github.com/krypt-n/bar) for Xfont support (and thus symbols). I should probably migrate away from this at some point, now that LemonBoy has started updating lemonbar again!
 * [GNU coreutils](https://www.gnu.org/software/coreutils/) and [GNU sed](https://www.gnu.org/software/sed/). This is basically a huge learning exercise in sed.
 * [Material Design Icons](http://google.github.io/material-design-icons/) if you plan to use the default module symbols.
 * [sxhkd](https://github.com/baskerville/sxhkd) and [sara](https://github.com/gitluin/sara) if you want sara integration.
 * Any of the relevant programs for the modules listed above.

### Setting up peachbar
Look at `examples/sxhkdrc` for a demonstration on how to use `peachbar-signal.sh` to get super snappy bar updating.
 * `sudo ./install.sh "$HOME"` installs the scripts to `/usr/local/bin/` and config files to `$HOME/.config/peachbar/`.
 * To use peachbar with any window manager, add `peachbar.sh &` to your `~/.xinitrc` before you `exec my-window-manager`.
 * To use peachbar with sara, add `sara-interceptor.sh $SARAFIFO $PEACHFIFO &` to `peachbar.sh` before the `peachbar-sys.sh < $PEACHFIFO | lemonbar | sh` line and make sure the `NUMTAGS=...` line is uncommented. Naturally, this means your `~/.xinitrc` should end with `exec sara > $SARAFIFO`.
 * To properly integrate with any window manager that uses lemonbar, adjust `barh`, `barx`, `bary`, etc. or the equivalent variables for your window manger and match this with `BARH`, `BARX`, `BARY` in `peachbar.conf`.
 * The modules are not designed to be super portable, since they are specific to pulling information from my machine. Tweak them for your system, yoink shell scripts from other bars, whatever works for you!

## Customization
There are a **lot** of customization options.

### `peachbar.conf`
| Variable   	| Explanation										|
| :----:     	| :----:       		        							|
| PEACHFIFO  	| Name of the FIFO you would like peachbar to use.       		        	|
| MODULES    	| A lemonbar-flavored string of the format `"%{l}Module1 %{c}%{r}Module2"`, etc. that determines the location of the modules in your bar. Supports %{S#} and %{lcr} formatters. If you have multiple monitors, but only specify for one, the layout will be  copied across all of them. However, if your modules support monitor-dependent output, this will still work. Per the example, you can have empty sections, and you can also exclude them completely (i.e. `"%{l}Module1 %{r}Module2"` is valid). 														|
| ASYNC      	| A string of the format `"Module1:Y Module2:N"`, etc. that tells peachbar whether a module should be run asynchronously or not. If yes, peachbar will only update the module if it receives its name in $PEACHFIFO, or if it receives "All" in $PEACHFIFO. This is good for modules that read from a fifo. If no, then the specified module will be set on a default timer. If unspecified, it is assumed that the module is not asynchronous.     										|
| BARALPHA  	| A string of the format `"[0-99]"` that I use as an easy way to toggle lemonbar's alpha setting. You could just as easily set the `"AA"` field in `BARBG` and `BARFG`.					|
| BARBG  	| A color code string `"#AARRGGBB"`, `"#RRGGBB"`, or `"RGB"` that sets the background color for lemonbar.      	|
| BARFG  	| A color code string `"#AARRGGBB"`, `"#RRGGBB"`, or `"RGB"` that sets the foreground color for lemonbar.      	|
| COLORS  	| A lemonbar-flavored string of the format `"%{l}%{F#AARRGGBB}%{B#AARRGGBB}%{c}"`, etc. (color specifications match options for `BARBG`, `BARFG`) that allows you to specify the color of each alignment area of the bar. When the end of an area is reached, the colors are reset to those specified by`BARBG` and `BARFG`. If you also provide the `"%{F-}"`, etc. formatters, you won't get any colors, so don't do that!       														|
| DEFINTERVAL	| The timer for synchronous module updating. Defaults to 10s if not specified.		|
| USEWAL    	| If you have [wal](https://github.com/dylanaraps/pywal) installed, use a default colorscheme derived from `.cache/wal/colors.sh`. Will silently fail if you have not already generated a colorscheme using `wal`, so do that first! Any colors manually assigned in `peachbar.conf` will override those set by `wal`. Sets `BARBG` and `BARFG` if not specified by user.  						|
| BARFONT	| The font you wish to use for bar text. Currently only supports specifying one. If you don't use `lemonbar-xft`, then this better not be an Xfont! For XFT fonts, specified with `"Font Name:size=XX"`. You can find a list of your installed fonts and their names by running `fc-list`.								|
| ICONFONT	| The font you wish to use for loading icons in bar text. Same `lemonbar-xft` disclaimer applies.															|
| BARX		| The x coordinate you would like `lemonbar` to start at.				|
| BARY		| The y coordinate you would like `lemonbar` to start at.				|
| BARW		| The width in pixels you would like `lemonbar` to be.					|
| BARH		| The height in pixels you would like `lemonbar` to be.					|

### `peachbar-modules.conf`
Note that this is all module-specific!

There are only three limitations to what your modules can output:
 * You shouldn't output lemonbar formatting strings like %{S#} and %{lcr} from modules, since that will be set in the `MODULES` variable (see below) already. It will likely result in some fantastic parsing errors.
 * You shouldn't output anything formatted like `{{.*}}` or with newlines from your modules. How peachbar keeps track of things internally depends on this formatting being reserved.
 * You shouldn't output `"{{PEACHBAR}}"` from modules. Part of how the custom alignment color-resetting formatters are resolved involves this regex.

Other than that, modules can output any kind of lemonbar formatting string (color, font, etc.).

`peachbar` adds its own custom lemonbar-flavored string formatters, `"%{FA}"` and `"%{BA}"`, which are used to set the foreground and background color to the foreground and background color for the alignment area that the outputting module finds itself in. For example, if the output of `Audio` ends with `"%{FA}%{BA}"`, and `MODULES` contains `"%{l}Audio"`, and `COLORS` contains `"%{l}%{B$COLOR1}%{F$COLOR2}"`, then `"%{FA}%{BA}"` becomes `"%{F$COLOR2}%{B$COLOR1}"`.

Module symbols are specified within the module with escaped unicode characters.

| Variable   	| Explanation										|
| :----:     	| :----       		        							|
| AUDIOBG  	| `Audio`: Background for the symbol.				       			|
| MUTEBG  	| `Audio`: Background for the symbol when amixer detects that `Master` output is muted.	|
| CHRBG  	| `Battery`: Background for the symbol when the power supply is charging.				|
| LOWBG  	| `Battery`: Background for the symbol when the power supply is between 10% and 20% capacity.		|
| PANICBG  	| `Battery`: Background for the symbol when the power supply is below 10% capacity.			|
| BATSTATFILE  	| `Battery`: Location of the system file that determines charging state.		|
| BATCAPFILE  	| `Battery`: Location of the system file that determines current capacity.		|
| BTUPBG  	| `Bluetooth`: Background for the symbol when bluetoothctl detects the device is powered on.		|
| BTDOWNBG  	| `Bluetooth`: Background for the symbol when bluetoothctl detects the device is powered off.		|
| BRIGHTBG  	| `Brightness`: Background for the symbol.						|
| NTUPBG  	| `Network`: Background for the symbol when wpa\_cli detects the device is connected to a network.	|
| NTDOWNBG  	| `Network`: Background for the symbol when wpa\_cli detects the device is not connected to a network.	|
| TAGS  	| `Sara`: A string of the format `"1:2:3:4:5:6:7:8:9"` that determines the text used for `sara` tags. If you want to use symbols from one of the fonts, escape them here like `"\ue836"` (same goes for `OTAGS` and `STAGS`).																|
| OTAGS  	| `Sara`: A string of the same format as `TAGS` that determines the text used for `sara` tags that are occupied but not currently in view. If not specified, defaults to the same value as `TAGS`.		|
| STAGS  	| `Sara`: A string of the same format as `TAGS` that determines the text used for `sara` tags that are currently in view ("selected"). If not specified, defaults to the same value as `TAGS`.				|
| TAGDELIMF	| `Sara`: A string that will be placed in front of every tag character. Defaults to two whitespace characters.														|
| TAGDELIMB	| `Sara`: A string that will be placed after every tag character. Defaults to two whitespace characters.														|
| LTDELIMF	| `Sara`: A string that will be placed in front of the layout symbol. Defaults to two whitespace characters.														|
| LTDELIMB	| `Sara`: A string that will be placed after the layout symbol. Defaults to two whitespace characters.															|
| OCCFG		| `Sara`: Foreground for the occupied tag text. Defaults to the foreground color for the module's alignment.						|
| OCCBG		| `Sara`: Background for the occupied tag text. Defaults to the background color for the module's alignment.						|
| SELFG		| `Sara`: Foreground for the selected tag text. Defaults to the foreground color for the module's alignment.						|
| SELBG		| `Sara`: Background for the selected tag text. Defaults to the background color for the module's alignment.						|

## Uninstallation
 * `sudo ./uninstall.sh "$HOME"` removes the scripts and config files.

## Bugs

## To-Do:
 * Explain examples.
 * Separate `Sara` and `SaraLayout` modules.
 * Custom layout symbols.

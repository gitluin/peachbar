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

### \[[Installation/Uninstallation](https:/github.com/gitluin/peachbar/wiki/Installation)\]\[[Customization](https:/github.com/gitluin/peachbar/wiki/Customization)\]

## Bugs

## To-Do:
 * Explain examples.
 * Separate `Sara` and `SaraLayout` modules.
 * Custom layout symbols.

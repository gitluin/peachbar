peachbar-sys.sh reads from a fifo that tells it what needs updating. If receives "All", entire bar is updated. Otherwise, it only updates the specified module. Empty fifo, nothing to do!

`sara-interceptor.sh $SARAFIFO $PEACHFIFO &
peachbar-sys.sh < $PEACHFIFO | lemonbar | sh &
exec sara > $SARAFIFO`

Each module has a sleep that forks off and then writes the module name to $PEACHFIFO when done.
Each module gets its own fifo, i.e. "peachbar-ModuleAudio.fifo", and writes it sleep pid there when on a timer.
peachbar-signal.sh reads sleep pid from peachbar-ModuleName.fifo, and kills it. killing it will trigger the subsequent echo. the bar update will automatically set a new timer.

Modules are specified by the user with lemonbar syntax in a string:
      "%{S0}%{l}Audio Network%{c}Sara%{r}Battery%{S1}%{l}Audio Network%{c}Sara Layout%{r}"
Modules may be specified without screen syntax, and the layout will be duplicated across screens (if the module supports monitor- dependent output, that will still happen).

Module text is saved by peachbar in this format as MODULE_CONTENTS:
      %{S0}
      %{l}
      {{ModuleAudio}}xxx{{ModuleAudio-}}
      %{r}
      {{ModuleNetwork}}yyy{{ModuleNetwork-}}
      %{S1}
      %{l}
      {{ModuleBattery}}zzz{{ModuleBattery-}}
      %{r}
      {{ModuleBright}}uuu{{ModuleBright-}}

End goal is to output a fully lemonbar-prepped STATUSLINE

Async status is "Y" if the module likes to update only when it has new information (like reading from a fifo), and "N" if it should be run on a timer (DEFINTERVAL). This should have no impact on performance, just on currentness of information if it *is* async.

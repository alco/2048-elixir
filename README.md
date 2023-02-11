# 2048

This is a sliding tile puzzle game implemented in Elixir.

_#Elixir_ _#Phoenix_ _#LiveView_ _#SVG_

## Single-player mode

_Not yet implemented._

## Multi-player mode

_Not yet implemented._

## Interactive shell mode

Launch the Elixir interactive shell with `iex -S mix` and start a local game session with `SN.start_local(<grid size>)`:

```
iex(1)> SN.start_local(4)
[0, 0, 0, 0]
[0, 0, 0, 0]
[0, 1, 0, 0]
[0, 0, 0, 0]
Enter a direction for the next move and press ENTER (r/l/u/d): r
[0, 0, 0, 0]
[0, 0, 0, 0]
[1, 0, 0, 1]
[0, 0, 0, 0]
Enter a direction for the next move and press ENTER (r/l/u/d): l
[0, 0, 1, 0]
[0, 0, 0, 0]
[2, 0, 0, 0]
[0, 0, 0, 0]
Enter a direction for the next move and press ENTER (r/l/u/d): u
[2, 0, 1, 0]
[0, 0, 0, 0]
[0, 0, 1, 0]
[0, 0, 0, 0]
Enter a direction for the next move and press ENTER (r/l/u/d): d
[0, 1, 0, 0]
[0, 0, 0, 0]
[0, 0, 0, 0]
[2, 0, 2, 0]
Enter a direction for the next move and press ENTER (r/l/u/d): l
[1, 1, 0, 0]
[0, 0, 0, 0]
[0, 0, 0, 0]
[4, 0, 0, 0]

...
```
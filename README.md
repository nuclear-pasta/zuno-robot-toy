# Toy Robot Simulator

A toy robot roams a 5x5 tabletop. Commands come from a file or from standard
input, one per line, and `REPORT` prints the robot's position.

## Product choice

This is a toy robot, so the most important thing is that it never breaks and
never falls off the table. When an instruction is unclear, the robot does not
stop: it skips that line and carries on with the next instruction. The skipped
line is never silent, though. It is reported as a warning on stderr, so the
problem can be debugged.

A different product could choose differently. If the robot controlled real
hardware, or the input had to be trusted, a stricter option would fit better:
stop at the first unclear line and exit with an error (see Future improvements).

## Setup and run

Written and tested with Ruby 2.7.8. The app uses only the standard library.
Bundler and RSpec are needed for the tests only.

```sh
bundle install
ruby main.rb spec/fixtures/walk_and_turn.txt          # read a file
cat spec/fixtures/walk_and_turn.txt | ruby main.rb    # read standard input
ruby main.rb --verbose spec/fixtures/early_commands_then_place.txt  # also log discarded commands
ruby main.rb --help
```

When typing commands by hand, finish with Ctrl+D on an empty line.

`REPORT` output goes to stdout. Warnings and the `--verbose` log go to stderr.
Exit status: `0` success, `1` the input could not be read, `2` bad usage.
Skipped lines never change the exit status.

## Commands and rules

| Command | Effect |
|---|---|
| `PLACE X,Y,F` | put the robot at X,Y facing `NORTH`, `EAST`, `SOUTH` or `WEST` |
| `MOVE` | move one unit forward |
| `LEFT` / `RIGHT` | turn 90 degrees without moving |
| `REPORT` | print `X,Y,F` |

(0,0) is the south-west corner. Valid coordinates are 0 to 4.

**Discarded, as the PDF says.** These are valid commands that cannot be carried
out. They are silent, and `--verbose` explains each one.

- Everything before the first valid `PLACE`, including `REPORT`.
- A `PLACE` off the table. A robot that was already placed stays where it was.
- A `MOVE` that would fall off the table.

**Skipped with a warning (our assumption).** The PDF does not cover lines that
are not valid commands, so we follow the product choice above.

- An unknown command, a wrong number of `PLACE` arguments, a non-integer
  coordinate (`+1`, `1.5`), a trailing comma, an unknown direction,
  arguments on `MOVE`/`LEFT`/`RIGHT`/`REPORT`, or text that is not valid UTF-8.
- Example: `warning: line 3: ignored (unknown command "JUMP")`.

**Accepted forms.** Commands and directions are case-insensitive. Extra
whitespace, tabs, CRLF line endings, blank lines and a missing final newline are
fine. There are no comments: a line starting with `#` is an unknown command.

## Sample inputs and tests

`spec/fixtures/` holds small input files for each rule. The PDF's three scenarios are
`place_move_report.txt` (`0,1,NORTH`), `place_rotate_report.txt` (`0,0,WEST`) and
`walk_and_turn.txt` (`3,3,NORTH`). `garbage_lines.txt` prints `1,1,NORTH` plus
eight warnings on stderr.

```sh
bundle exec rspec
```

Each class has its own specs. The `CLI` specs call `CLI#run` with stdout and
stderr stubbed, and check what was written and the exit status.
`spec/fixtures_spec.rb` runs every sample file through the `CLI` and checks its
reports, warnings and `--verbose` log.

## Approach

```
CLI -> CommandRunner -> CommandParser -> Command
            |
            +-> Robot -> Table
```

| Class | Responsibility |
|---|---|
| `CLI` | options, file or stdin, exit codes |
| `CommandRunner` | reads lines, runs commands, writes reports, warns and logs |
| `CommandParser` | turns one line of text into a `Command`, or raises. Text only, never touches the robot |
| `Robot` | position and facing. It refuses an unknown direction or an off-table position |
| `Table` | knows which positions are on the table, and why one is not |
| `Directions` | the one place that defines directions, their movement and the turn names |

Decisions:

1. **One owner per rule.** The parser decides what the text says, `Robot`
   decides what the robot can be, and the runner decides what happens next.
2. **Two kinds of "cannot do this".** A valid command that cannot be carried out
   is discarded and logged. An unclear line raises an error that the runner turns
   into a warning, then carries on.
3. **Input is streamed.** One line is read at a time, so memory stays flat: about
   13 MB for a 33 MB, 6-million-line file, the same as for a tiny one.
4. **Simple number check.** A regular expression allows digits only (with an
   optional minus). `Integer()` would read `010` as octal, which is surprising.
5. **`Table.new(4, 4)` is a 5x5 table.** The arguments are the highest valid
   coordinates, not a size.

## Trade-offs

- Adding a command means editing the parser's command list and
  `CommandRunner#execute`. A command-object design would avoid that, but it is
  too much for five commands.
- Skipped lines do not change the exit status, so a script cannot tell that one
  was skipped.
- Discarded commands are written as text. They are not collected, so a caller
  cannot count them afterwards.
- A lone carriage return (old Mac line endings) does not split lines.

## Future improvements

- `--strict` flag: stop at the first unclear line and exit non-zero.
- `--size WxH` option. `CommandRunner` already accepts any `Table`.
- Better argument validation. Today X and Y are checked with one simple regular
  expression, and the other rules grew around it. A fuller design would
  validate each argument in one place, with clearer messages.
- A reporter object in place of the log stream, for error counts or other formats.
- Command objects, if more than a few commands are added.
- Obstacles: `Robot` only asks its table whether a position is valid.
- Coverage measurement and RuboCop.

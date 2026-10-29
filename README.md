# 🗣️ krisp-stats

Shows how long each participant talked in a [Krisp](https://krisp.ai) transcript, as time and as a percentage.

It runs on the Ruby that ships with macOS (`/usr/bin/ruby`), so there's nothing to install.

```
$ ./krisp-stats transcript2.txt

  transcript2.txt · 26:27 · 4 participants · 102 turns

  Participant   Time   Share
  Alessio      13:42   51.8%  ██████████████████████████████
  Jeff         10:23   39.3%  ██████████████████████▊
  Tom           1:29    5.6%  ███▎
  Mark          0:53    3.3%  █▉
  ──────────────────────────
  Total        26:27  100.0%
```

## Usage

```
./krisp-stats meeting.txt [more.txt ...]   # one report per file
pbpaste | ./krisp-stats                    # read from stdin
./krisp-stats                              # no args: read the clipboard
./krisp-stats -v meeting.txt               # also show words, turns, words/minute
```

Options: `-v/--verbose`, `--no-color` (setting `NO_COLOR` also works), `-h/--help`.

To run it from anywhere, copy or symlink it into your `PATH`, for example `ln -s "$PWD/krisp-stats" /usr/local/bin/`.

## How time is estimated

Krisp only records when each turn *starts*, so the length of each turn has to be estimated:

1. A turn lasts until the next turn starts. These meetings have few silences, so this is accurate most of the time.
2. Each speaker's typical rate is the median words per minute across their turns with at least 5 words.
3. Sometimes a gap is much longer than the words in that turn could take: more than 1.5× the expected time plus 3 seconds. This usually means silence, screen sharing or a pause, so the turn is shortened to its word-based estimate. The report says how many turns were shortened.
4. The last turn has no next timestamp, so its length comes from its word count.

Percentages are each speaker's share of the total estimated talk time. You can change the thresholds with the constants at the top of `krisp-stats`.

## Tests

```
/usr/bin/ruby test/test_krisp_stats.rb
```

# nana mac RAM / CPU monitor

A lightweight native macOS menu bar app with two compact rows: a RAM alert index above and CPU utilization below. White percentages appear on green, yellow, or red backgrounds at 50% opacity. The status item occupies just 36 pt of menu bar space.

## Download and install

Download the Apple Silicon ZIP from [Releases](https://github.com/snape77/nana-mac-ram-cpu-monitor/releases/latest), unzip it, and move **RAM Monitor.app** to Applications. Requires macOS 13 or later.

The app is ad-hoc signed and is not notarized by Apple. macOS may block the first launch. After verifying the source, use **System Settings → Privacy & Security → Open Anyway**, or build it yourself from source.

Quit any previous version before updating. Version 0.2.2 uses a generic application identifier, so refresh preferences from earlier private builds are not migrated; the first launch defaults to 5 seconds. The app's menu text is currently in Chinese.

## Display and settings

| Item | Meaning and colors |
| --- | --- |
| Top row: RAM | An alert index; 100% is a warning reference and values can exceed 100% |
| RAM background | Follows macOS normal / warning / critical memory-pressure states independently of the displayed number |
| Bottom row: CPU | System-wide CPU utilization from 0–100%, averaged between samples |
| CPU background | Green at ≤80%, yellow above 80%, red above 90%; thresholds use unrounded values |
| Gray --% | Data is unavailable or CPU is waiting for its second sample |

Click the status item to view used memory, compressed memory, swap usage, and CPU utilization. Choose a refresh interval of **1, 5 (default), 10, or 15 seconds**. The choice is saved locally and restored on the next launch. The menu also provides Refresh Now, Open Activity Monitor, and Quit.

The RAM number is a transparent estimate based on memory compression. It is neither the percentage of RAM in use nor an official percentage supplied by Activity Monitor:

```text
raw estimate = round(100 × compressed / (active + inactive + free + speculative + compressed))
displayed alert index = raw estimate × 2
```

Colors are read separately from the system pressure state. The 100% mark is a chosen warning reference; system hysteresis and other factors mean a color change need not occur at that exact value. This is not a prediction of future memory pressure.

## Lightweight and private

- Native Swift / AppKit with system statistics APIs; no third-party runtime dependencies, WebView, or persistent child processes.
- One sampling timer, with redraws only when the displayed values or colors change; the default interval is 5 seconds.
- No networking, telemetry, account, advertising, or automatic updater.
- Reads aggregate memory and CPU statistics; does not read personal files, browser data, or other apps' contents.
- Saves only the selected refresh interval.
- Published files exclude live system samples, personal paths, machine configuration, and development acceptance logs. Actual resource usage depends on the system environment.

See [PRIVACY.md](PRIVACY.md) for details.

## Build from source

Requires an Apple Silicon Mac, macOS 13+, and Xcode Command Line Tools.

```sh
bash test.sh
bash build.sh
open "build/RAM Monitor.app"
```

The output is `build/RAM Monitor.app`. No third-party packages are required. Tests cover RAM scaling, system pressure mapping, CPU interval deltas, counter wraparound, thresholds, and recovery after sleep.

Optional local diagnostics:

```sh
"build/RAM Monitor.app/Contents/MacOS/RAMMonitor" --sample
"build/RAM Monitor.app/Contents/MacOS/RAMMonitor" --render-previews build/previews
```

`--sample` prints live aggregate statistics to standard output; inspect the output before sharing it. Preview mode uses synthetic values only.

## License

[MIT](LICENSE)

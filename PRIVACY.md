# Privacy

RAM Monitor runs entirely on your Mac. It makes no network requests and contains no analytics, crash-reporting service, account system, or automatic updater.

The app reads aggregate virtual-memory counters, the system memory-pressure level, swap usage, physical memory size, and aggregate CPU tick counters through macOS APIs. It does not inspect individual processes, documents, browser history, credentials, or application contents.

Only the chosen refresh interval is stored in local UserDefaults. Monitoring samples are not saved by the normal menu-bar app. The optional `--sample` command prints aggregate statistics to standard output; the user controls any redirection or sharing of that output. `--render-previews` writes synthetic demonstration images to the directory supplied by the user.

The app may ask macOS to open Activity Monitor when you choose that menu item. macOS itself can maintain ordinary system diagnostics outside the app's control.

Public source and release packages exclude development logs, local acceptance records, live samples, private paths, and credentials.

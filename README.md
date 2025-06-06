# dmenu-mac

dmenu inspired application launcher.

![dmenu-mac demo](./demo.gif)

## Who is it for
Anyone that needs a quick and intuitive keyboard-only application launcher that does not rely on spotlight indexing.

## Why
If you are like me and have a shit-ton of files on your computer, and spotlight keeps your CPU running like crazy.

1. [Disable spotlight](https://www.google.com/search?q=disable+spotlight+completely) completely and its global shortcut (recommended but not necessary).
2. Download and run dmenu-mac.

## How to use
1. Open the app, use option-d to bring it to front.
2. Type the application you want to open, hit enter to run the one selected.
3. Change the settings by clicking the tray icon in the menu bar (optional).

### Pipes
You can make dmenu-mac part of your scripting toolbox, use it to prompt the user for options:
```
echo "Yes\nNo" | dmenu-mac -p "Are you sure?"
Yes
```

## Installation

dmenu-mac can be installed with [brew](https://brew.sh/) running:

```
brew install datwinz/formulae-and-casks/dmenu-mac
```

Optionally, you can download it [here](https://github.com/datwinz/dmenu-mac/releases).

NOTES: This app is not sandboxed, because it accesses binaries in your path.

_Mac OS X 10.12 or greater required_

## Features

- Uses fuzzy search
- Configurable global hotkey
- Multi-display support
- Not dependant on spotlight indexing

# Pull requests
Any improvement/bugfix is welcome.

# Authors

[@onaips](https://twitter.com/onaips)

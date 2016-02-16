<h1>Neovim<sup>e</sup>: Electron UI for Neovim</h1>

- Install Neovim, Electron, grunt-cli
- `apm install . && grunt && electron . <nvim arguments>`

# User Config

User configuration may be specified in [userDataDir](https://github.com/atom/electron/blob/master/docs/api/app.md#appgetpathname)/config.cson

Valid options are listed [here](https://github.com/coolwanglu/neovim.as/blob/master/src/nvim/config.coffee)

Example

```
# Location
# %APPDATA%/Neovim-e/config.cson for Windows
# %XDG_CONFIG_HOME/Neovim-e/config.cson OR ~/.config/Neovim-e/config.cson for Linux
# ~/Library/Application Support/Neovim-e/config.cson for OS X
font: '13px monospace'
row: 60
```

## [Demo Video](http://youtu.be/zgNJnBKMRNw)

# Atom Shell UI for Neovim

- Install Neovim, Atom Shell, grunt-cli
- `apm install . && grunt && atom-shell -- . <nvim arguments>`

# User Config

User configuration may be specified in [userDataDir](https://github.com/atom/atom-shell/blob/master/docs/api/app.md#appgetpathname)/config.cson

Valid options are listed [here](https://github.com/coolwanglu/neovim.as/blob/master/src/nvim/config.coffee)

Example

```
# Location
# %APPDATA%/Neovim.AS/config.cson for Windows
# %XDG_CONFIG_HOME/Neovim.AS/config.cson OR ~/.config/Neovim.AS/config.cson for Linux
# ~/Library/Application Support/Neovim.AS/config.cson for OS X
font: '13px monospace'
row: 60
```

## [Demo Video](http://youtu.be/zgNJnBKMRNw)

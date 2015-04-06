# helper.coffee from atom-keymap
#
# Copyright (c) 2014 GitHub Inc.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Copyright (c) 2015 Lu Wang

KeyboardEventModifiers = new Set
KeyboardEventModifiers.add(modifier) for modifier in ['Control', 'Alt', 'Shift', 'Meta']

SpecificityCache = {}

WindowsAndLinuxKeyIdentifierTranslations =
  'U+00A0': 'Shift'
  'U+00A1': 'Shift'
  'U+00A2': 'Control'
  'U+00A3': 'Control'
  'U+00A4': 'Alt'
  'U+00A5': 'Alt'
  'Win': 'Meta'

WindowsAndLinuxCharCodeTranslations =
  48:
    shifted: 41    # ")"
    unshifted: 48  # "0"
  49:
    shifted: 33    # "!"
    unshifted: 49  # "1"
  50:
    shifted: 64    # "@"
    unshifted: 50  # "2"
  51:
    shifted: 35    # "#"
    unshifted: 51  # "3"
  52:
    shifted: 36    # "$"
    unshifted: 52  # "4"
  53:
    shifted: 37    # "%"
    unshifted: 53  # "5"
  54:
    shifted: 94    # "^"
    unshifted: 54  # "6"
  55:
    shifted: 38    # "&"
    unshifted: 55  # "7"
  56:
    shifted: 42    # "*"
    unshifted: 56  # "8"
  57:
    shifted: 40    # "("
    unshifted: 57  # "9"
  186:
    shifted: 58    # ":"
    unshifted: 59  # ";"
  187:
    shifted: 43    # "+"
    unshifted: 61  # "="
  188:
    shifted: 60    # "<"
    unshifted: 44  # ","
  189:
    shifted: 95    # "_"
    unshifted: 45  # "-"
  190:
    shifted: 62    # ">"
    unshifted: 46  # "."
  191:
    shifted: 63    # "?"
    unshifted: 47  # "/"
  192:
    shifted: 126   # "~"
    unshifted: 96  # "`"
  219:
    shifted: 123   # "{"
    unshifted: 91  # "["
  220:
    shifted: 124   # "|"
    unshifted: 92  # "\"
  221:
    shifted: 125   # "}"
    unshifted: 93  # "]"
  222:
    shifted: 34    # '"'
    unshifted: 39  # "'"

NumPadToASCII =
  79: 47 # "/"
  74: 42 # "*"
  77: 45 # "-"
  75: 43 # "+"
  78: 46 # "."
  96: 48 # "0"
  65: 49 # "1"
  66: 50 # "2"
  67: 51 # "3"
  68: 52 # "4"
  69: 53 # "5"
  70: 54 # "6"
  71: 55 # "7"
  72: 56 # "8"
  73: 57 # "9"

exports.keystrokeForKeyboardEvent = (event) ->
  keyIdentifier = event.keyIdentifier
  if process.platform is 'linux' or process.platform is 'win32'
    keyIdentifier = translateKeyIdentifierForWindowsAndLinuxChromiumBug(keyIdentifier)

  unless KeyboardEventModifiers.has(keyIdentifier)
    charCode = charCodeFromKeyIdentifier(keyIdentifier)

    if charCode?
      if process.platform is 'linux' or process.platform is 'win32'
        charCode = translateCharCodeForWindowsAndLinuxChromiumBug(charCode, event.shiftKey)

      if event.location is KeyboardEvent.DOM_KEY_LOCATION_NUMPAD
        # This is a numpad number
        charCode = numpadToASCII(charCode)

      charCode = event.which if not isASCII(charCode) and isASCII(event.keyCode)
      key = keyFromCharCode(charCode)
    else
      key = if keyIdentifier.length == 1 then keyIdentifier.toLowerCase() else keyIdentifier

  if not key?
    ''
  else
    keystroke = ''
    keystroke += 'C-' if event.ctrlKey
    keystroke += 'A-' if event.altKey
    if event.shiftKey
      # Don't push 'shift' when modifying symbolic characters like '{'
      keystroke += 'S-' if key.length > 1
      # Only upper case alphabetic characters like 'a'
      key = key.toUpperCase() if /^[a-z]$/.test(key)
    else
      key = key.toLowerCase() if /^[A-Z]$/.test(key)
    keystroke += 'D-' if event.metaKey
    key = "lt" if key == "<" and not keystroke.length
    keystroke += key
    if keystroke.length == 1 then keystroke else '<' + keystroke + '>'

charCodeFromKeyIdentifier = (keyIdentifier) ->
  parseInt(keyIdentifier[2..], 16) if keyIdentifier.indexOf('U+') is 0

# Chromium includes incorrect keyIdentifier values on keypress events for
# certain symbols keys on Window and Linux.
#
# See https://code.google.com/p/chromium/issues/detail?id=51024
# See https://bugs.webkit.org/show_bug.cgi?id=19906
translateKeyIdentifierForWindowsAndLinuxChromiumBug = (keyIdentifier) ->
  WindowsAndLinuxKeyIdentifierTranslations[keyIdentifier] ? keyIdentifier

translateCharCodeForWindowsAndLinuxChromiumBug = (charCode, shift) ->
  if translation = WindowsAndLinuxCharCodeTranslations[charCode]
    if shift then translation.shifted else translation.unshifted
  else
    charCode

keyFromCharCode = (charCode) ->
  # See :help key-notation
  switch charCode
    when 0 then 'Nul'
    when 8 then 'BS'
    when 9 then 'Tab'
    when 10 then 'NL'
    when 12 then 'FF'
    when 13 then 'Enter'
    when 27 then 'Esc'
    when 32 then 'Space'
    when 92 then 'Bslash'
    when 124 then 'Bar'
    when 127 then 'Del'
    else String.fromCharCode(charCode)

isASCII = (charCode) ->
  0 <= charCode <= 127

numpadToASCII = (charCode) ->
  NumPadToASCII[charCode] ? charCode

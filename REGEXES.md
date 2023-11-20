Refactoring regexes
===================

At several points, I've had to make enormous global changes to code style in various
projects. They are usually applied with the vi regex engine, since it contains advanced
features like non-greedy searches unavailable in sed and awk. They can be applied
interactively or in *bulk* as follows:

```sh
find . -name '*.ext' -exec vi -u NONE -c '%s/regex/replacement/ge | wq' {} \;
```

This page documents some of the more complicated regexes I've had to use.

Fortran
-------

Try to convert fixed format line continuation indicators to Fortran 90.
```vim
%s/\(\s*!.*\)\?\n\(\s*\)\(&\)\(\S*\)\s*/\4 \3\1\r  \2/ge
```

Markdown
--------

Add a space between markdown headers indicators and the header text.
```vim
%s/#\([a-zA-Z0-9]\)/# \1/ge
```

Vimscript
---------

Surround assignments in vi script with spaces.
```vim
%s/\<let\>\s\+\S\{-1,}\zs\([.^+%-]\?=\)/ \1 /ge
```

Prepend a space to vi comments. The comment character is so small that I used to write comments without a space, but no one else on the planet seems to do this.
```vim
%s/\(^[ \t:]*"\(\zs\ze\)[^ #].*$\|^[^"]*\s"\(\zs\ze\)[^_\-:.%#=" ][^"]*$\)/ \2/ge
```

Surround comparison operators with spaces, accounting for `<Tab>` style keystroke indicators in vim script.
```vim
%s/\_s[^ ,\-<>@!&=\\]\+\zs\(<=\|>=\|==\|^C|>\)\ze[^ ,!\-<>&=\\]\+\_s/ \1 /ge
```

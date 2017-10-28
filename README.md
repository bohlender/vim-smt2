# Extended SMT-LIB2 support for VIM
![Example](/example.png?raw=true "Example")

## What is this?
A VIM plugin that adds syntax highlighting for the [SMT-LIB2](http://smtlib.cs.uiowa.edu/) format, i.e. `*.smt2` files.

Although SMT-LIB is the standard language, supported by most [SMT](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories) solvers, **many solvers introduce custom extensions** of this language.
Such extensions may range from syntactical sugar to fine-grained control of the underlying solver-procedure.
Besides the base SMT-LIB2 language, this plugin **supports the extensions used by the [Z3](https://github.com/Z3Prover/z3) SMT solver**.

*Note: Unlike other syntax highlighters for VIM, this one is **derived directly from the source** of [Z3's online demo](https://rise4fun.com/Z3/).*

The plugin **also provides shortcuts** for passing the files to Z3:
* `<localleader>r` calls Z3 for the current file (on the terminal)
* `<localleader>R` calls Z3 for the current file and puts the output in a new split with syntax highlighting

*Note: Unless you've set `<localleader>` to a custom key, it is `\` (VIM default).*

Here you can see it in action:
[![asciicast](https://asciinema.org/a/4LP65uSchEbciwnRsdTImwzqW.png)](https://asciinema.org/a/4LP65uSchEbciwnRsdTImwzqW)

## Installation
| Plugin Manager | Instructions |
| ------------- | ------------- |
| [Vundle](https://github.com/VundleVim/Vundle.vim) | Add `Plugin 'bohlender/vim-z3-smt2'` to your `~/.vimrc` file (*before `call vundle#end()`*) and run `:PluginInstall` in VIM|
| manual | Drop the contents of this repository into your `~/.vim/` directory |

If you only care about the syntax highlighting and don't need shortcuts for calling Z3, you're done.
Otherwise, to use the shortcuts, you have to either:
* have `z3` in your `$PATH`, or
* set `g:smt2_z3_command` in your `~/.vimrc` to the command for running `z3` on your system.

## FAQ
> Why does VIM  not show any syntax highlighting - neither for `*.smt2` files nor for others?

Most likely syntax highlighting is simply disabled.
You can enable syntax highlighting by typing `:syntax on` in VIM or adding `syntax on` to your `~/.vimrc` file.

> What do you use to get the look shown on the screenshot?

The screenshot was made with the VIM colorscheme [monokai](https://github.com/crusoexia/vim-monokai) and the [airline](https://github.com/vim-airline/vim-airline) standard theme `dark`.

## Contribute
You can always create an issue if you find bugs or think that something could be improved.
If you want to tackle an issue or contribute to the plugin feel free to create a pull request.

# Extended SMT-LIB2 support for VIM
![Example](/example.png?raw=true "Example")

## What is this?
A VIM plugin that adds syntax highlighting for the [SMT-LIB2](http://smtlib.cs.uiowa.edu/) format, i.e. `*.smt2` files.

Although SMT-LIB is the standard language, supported by most [SMT](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories) solvers, **many solvers introduce custom extensions** of this language.
Such extensions may range from syntactical sugar to fine-grained control of the underlying solver-procedure.
Besides the base SMT-LIB2 language, this plugin **supports the extensions used by the [Z3](https://github.com/Z3Prover/z3) SMT solver**.

*Note: Unlike other syntax highlighters for VIM, this one is **directly derived from the source** of the [Z3's online demo](https://rise4fun.com/Z3/).*

## Installation
| Plugin Manager | Instructions |
| ------------- | ------------- |
| [Vundle](https://github.com/VundleVim/Vundle.vim) | Add `Plugin 'bohlender/vim-z3-smt2'` to your `~/.vimrc` file (*before `call vundle#end()`*) and run `:PluginInstall` in VIM|
| manual | Drop the contents of this repository into your `~/.vim/` directory |

## FAQ
**Q**: VIM does not show any syntax highlighting - neither for `*.smt2` files nor for others
**A**: You can enable syntax highlighting by typing `:syntax on` in VIM or adding `syntax on` to the `~/.vimrc` file.

**Q**: What do you run to get the look shown on the screenshot?
**A**: The screenshot was made in `gnome-terminal` with the VIM colorscheme [monokai](https://github.com/crusoexia/vim-monokai) and the [airline](https://github.com/vim-airline/vim-airline) standard theme `dark`.

## Contribute
You can always create an issue if you find bugs or think that something could be improved.
If you want to tackle an issue or contribute to the plugin, feel free to create a pull request.

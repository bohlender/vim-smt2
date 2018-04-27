# Extended SMT-LIB2 support for VIM
![Example](/example.png?raw=true "Example")

## What is this?
A VIM plugin that adds syntax highlighting for the [SMT-LIB2](http://smtlib.cs.uiowa.edu/) format, i.e. `*.smt2` files.

Although SMT-LIB2 is the standard language supported by most [SMT](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories) solvers, some of them introduce **custom language extensions**.
Such extensions may range from syntactical sugar to fine-grained control over the underlying solver-procedure.
Besides the base SMT-LIB2 language, this plugin **supports the extensions used by the [Z3](https://github.com/Z3Prover/z3) SMT solver**.

*Note: Unlike other SMT-LIB2 syntax highlighters for VIM, this one is **derived directly from the source** of [Z3's online demo](https://rise4fun.com/Z3/).*

The plugin also provides **shortcuts for evaluating the current file**, using a SMT solver of your choice (**defaults to [Z3](https://github.com/Z3Prover/z3) or [boolector](http://fmv.jku.at/boolector)**):
* `<localleader>r` evaluates the current file (in a terminal)
* `<localleader>R` evaluates the current file and puts the output in a new split with syntax highlighting
* `<localleader>v` prints the solver's version (handy if you switch often)

*Note: Unless you've set `<localleader>` to a custom key, it is `\` (VIM default).*

Here you can see it in action:
[![asciicast](https://asciinema.org/a/4LP65uSchEbciwnRsdTImwzqW.png)](https://asciinema.org/a/4LP65uSchEbciwnRsdTImwzqW)

## Installation

| Plugin Manager | Instructions |
| ------------- | ------------- |
| [Pathogen](https://github.com/tpope/vim-pathogen) | <ol><li>`cd ~/.vim/bundle`</li><li>`git clone https://github.com/bohlender/vim-smt2`</li></ol> |
| [Vundle](https://github.com/VundleVim/Vundle.vim) | <ol><li>add `Plugin 'bohlender/vim-smt2'` to your `~/.vimrc` file (*before `call vundle#end()`*)</li><li>reload your `~/.vimrc` or restart VIM</li><li>run `:PluginInstall` in VIM</li></ol> |
| manual (discouraged) | Extract the archive or clone the repository into a directory in your `runtimepath` (e.g. `~/.vim/`): <ol><li>`cd ~/.vim/`</li><li>`curl -L https://github.com/bohlender/vim-smt2/tarball/master \| tar xz --strip 1`</li></ol> |

## Configuration
**If you only care about the syntax highlighting** and don't need shortcuts for calling a solver, **you're done**.

Otherwise, you need to:
* have `z3` or `boolector` in your `$PATH`, **or**
* set `g:smt2_solver_command` in your `~/.vimrc` to the command for calling the solver of your choice (e.g. `let g:smt2_solver_command="boolector -m"`) and also
* set `g:smt2_solver_version_switch` to the solver's command line switch for printing it's version (default: `--version`).

## FAQ
> Why does VIM  not show any syntax highlighting - neither for `*.smt2` files nor for others?

Most likely syntax highlighting is simply disabled.
You can enable syntax highlighting by typing `:syntax on` in VIM or adding `syntax on` to your `~/.vimrc` file.

> Why does the ending of a file, e.g. `*.smt2`, not affect the plugins loaded by VIM?

Make sure that you have filetype plugins enabled. See **|filetype-plugin-on|** for details, or simply add the following to your `~/.vimrc`:
```
filetype plugin on
```

> What do you use to get the look shown on the screenshot?

The screenshot was made with the VIM colorscheme [monokai](https://github.com/crusoexia/vim-monokai) and the [airline](https://github.com/vim-airline/vim-airline) standard theme `dark`.

## Contribute
You can always create an issue if you find bugs or think that something could be improved.
If you want to tackle an issue or contribute to the plugin feel free to create a pull request.

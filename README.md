# Translator Backend

OCaml REST backend to the PureScript Translator frontend.

Run with:

```
opam install --deps-only --yes .
dune exec bin/main.exe
```
You can also pass `--watch` to `dune exec` so it automatically picks up changes (and `--root .` if you need to specify it).

To initialize the database, you can run:

```
sqlite3 db.sqlite -init structure.sql
```

### `ocamlformat`

```
=> This package requires additional configuration for use in editors. Install package 'user-setup', or manually:

   * for Emacs, add these lines to ~/.emacs:
     (add-to-list 'load-path "/home/vendethiel/.opam/default/share/emacs/site-lisp")
     (require 'ocp-indent)

   * for Vim, add this line to ~/.vimrc:
     set rtp^="/home/vendethiel/.opam/default/share/ocp-indent/vim"
```

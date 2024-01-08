# Translator Backend

OCaml REST backend to the PureScript Translator frontend.

Run with:

```
opam install --deps-only --yes .
dune exec --root . ./translator.exe
```
You can also pass `--watch` to `dune exec` so it automatically picks up changes.

To initialize the database, you can run:

```
sqlite3 db.sqlite -init structure.sql
```

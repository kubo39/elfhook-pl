# elfhook

`elfhook` is a library for monkey-patching a shared object.

`elfhook` is pre-alpha quality, not production ready yet.

## Why not `LD_PRELOAD` ?

`LD_PRELOAD` always override any symbols, I want to override certain library.

## prerequirements

* Need dmd compiler and libphobos2.so

## Try

```
$ ./build.sh
```

Check return `1` at last statement.

## development

### gdb

Need gdb often for SIGSEGV.

```
gdb --quiet --args `plenv which perl` xxx.pl
...
(gdb) set environment LD_PRELOAD=./libphobos2.so
```

### Run with valgrind

valgrind is very useful for detect double-free or memory-leak.

```
valgrind --tool=memcheck --trace-children=yes ./run-with-valgrind.sh
```

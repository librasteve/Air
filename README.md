NAME
====

Air - blah blah blah

SYNOPSIS
========

```raku
use Air;
```

DESCRIPTION
===========

Air is ...

AUTHOR
======

librasteve <librasteve@furnival.net>

COPYRIGHT AND LICENSE
=====================

Copyright 2025 librasteve

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

There are two patterns in use in BaseLib:

1. Tag Pattern

role Tag furnishes a class with `multi method HTML {}`.

A call to `.HTML` will produce an html tag with the name of the class and populated with any `%.attrs` and `$.inner`
value provided.

The HTML method can be overridden by a consuming class lke this:

```raku
multi method HTML {
    self.defaults unless $loaded++;

    opener($.name, |%.attrs) ~
    $!head.HTML              ~
    $!body.HTML              ~
    closer($.name)           ~ "\n"
}
```

2. Component Pattern

role Component provides a set of services to a class, namely:
- a class variable `%holder` which holds all the instances of a particular component
- an attribute `$.id` which allocates a unique id to new instances of a particular component
- a set of overridable methods to load, create, delete and update a component
- a trait `is routable` that, applied to a method, will autogenerate Cro routes via `^add-routes`


make the tree
- html
  - body
    - header
    - main
    - footer

show the tree
load the tree

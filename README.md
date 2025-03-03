[![Actions Status](https://github.com/librasteve/Air/actions/workflows/test.yml/badge.svg)](https://github.com/librasteve/Air/actions)

### WORK IN PROGRESS ###

Please raise an Issue if you would like to feedback or assist.

NAME
====

Air - A way create web sites without cro templates

SYNOPSIS
========

```raku
use Air::Functional :BASE;
use Air::Base;


my &index = &page.assuming( #:REFRESH(1),
    title       => 'hÅrc',
    description => 'HTMX, Air, Raku, Cro',
    footer      => footer p ['Aloft on ', b safe '&Aring;ir'],
    );


my &planets = &table.assuming(
    :thead[["Planet", "Diameter (km)",
            "Distance to Sun (AU)", "Orbit (days)"],],
    :tbody[["Mercury",  "4,880", "0.39",  "88"],
           ["Venus"  , "12,104", "0.72", "225"],
           ["Earth"  , "12,742", "1.00", "365"],
           ["Mars"   ,  "6,779", "1.52", "687"],],
    :tfoot[["Average",  "9,126", "0.91", "341"],],
    );


sub SITE is export {
    site #:bold-color<blue>,
        index
        main
            div [
                h3 'Planetary Table';
                planets;
            ]
}
```

DESCRIPTION
===========

blah blah

AUTHOR
======

Steve Roe <librasteve@furnival.net>

The `Air::Component` module provided is based on an early version of the raku `Cromponent` module, author Fernando Corrêa de Oliveira <fco@cpan.com>.

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Steve Roe

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


Air
===

This raku module provides the glue for the **HARC stack** (HTMX, Air, Raku|Red, Cro).

**HARC** websites are written in functional code. This puts the emphasis firmly onto the content and layout of the site, rather than boilerplate markup that can often obscure the intention.

The result is a compact, legible and easy-to-maintain website codebase.

SYNOPSIS
========

```raku
#!/usr/bin/env raku

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

GETTING STARTED
===============

Install raku - eg. from [rakubrew](https://rakubrew.org), then:

```bash
### Install Air, Cro & Red
- zef install --/test cro
- zef install Red --exclude="pq:ver<5>"
- zef install Air, Air::Play

### Run and view it
- export WEBSITE_HOST="0.0.0.0" && export WEBSITE_PORT="3000"
- raku -Ilib service.raku
- Open a browser and go to http://localhost:3000
```

Cro has many other options as documented at [Cro](https://cro.raku.org) for deployment to a production server.

DESCRIPTION
===========

Air is not a framework, but a set of libraries. Full control over the application loop is retained by the coder.

Air does not provide an HTML templating language, instead each HTML tag is written as a subroutine call where the argument is a list of `@inners` and attributes are passed via the raku Pair syntax `:name<value>`. [Cro templates](https://cro.raku.org/docs/reference/cro-webapp-template-syntax) are great if you prefer that approach.

Reusability is promoted by the structure of the libraries - individuals and teams can create and install your own libraries to encapsulate design themes, re-usable web components and best practice.

Air is comprised of three core libraries:

  * Air::Functional - wraps HTML tags as functions

  * Air::Base - a set of handy prebuilt components

  * Air::Component - make your own components

**[Air::Play](https://raku.land/zef:librasteve/Air::Play)** is a companion raku module with various **Air** website examples.

The Air documentation is at [https://librasteve.github.io/Air](https://librasteve.github.io/Air)

AUTHOR
======

Steve Roe <librasteve@furnival.net>

The `Air::Component` module provided is based on an early version of the raku `Cromponent` module, author Fernando Corrêa de Oliveira <fco@cpan.com>, however unlike Cromponent this module does not use Cro Templates.

COPYRIGHT AND LICENSE
=====================

Copyright 2025 Steve Roe

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


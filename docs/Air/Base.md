Air::Base
=========

This raku module is one of the core libraries of the raku **Air** distribution.

It provides a Base library of functional Tags and Components that can be composed into web applications.

Air::Base uses Air::Functional for standard HTML tags expressed as raku subs. Air::Base uses Air::Component for scaffolding for library Components.

Architecture
------------

Here's a diagram of the various Air parts. (Air::Examples is a separate raku module with several examples of Air websites.)

                             +----------------+
                             |  Air::Example  |    <-- Web App
                             +----------------+
                                     |
                        +--------------------------+
                        |   Air::Example::Site     |  <-- Site Lib
                        +--------------------------+
                           /                    \
                  +----------------+   +-----------------+
                  |    Air::Base   |   |    Air::Form    |  <-- Base Lib
                  +----------------+   +----------------+
                          |          \          |
                  +----------------+   +-----------------+
                  | Air::Component |   | Air::Functional | <-- Services
                  +----------------+   +-----------------+

The general idea is that there will a small number of Base libraries, typically provided by raku module authors that package code that implements a specific CSS package and/or site theme. Then, each user of Air - be they an individual or team - can create and selectively load their own Site library modules that extend and use the lower modules. All library Tags and Components can then be composed by the Web App.

This facilitates an approach where Air users can curate and share back their own Tag and Component libraries. Therefore it is common to find a Base Lib and a Site Lib used together in the same Web App.

In many cases Air::Base will consume a standard HTML tag (eg. `table`), customize and then re-export it with the same sub name. Therefore two export packages `:CRO` and `:BASE` are included to prevent namespace conflict.

The current Air::Base package is unashamedly opionated about CSS and is based on [Pico CSS](https://picocss.org). Pico was selected for its semantic tags and very low level of HTML attribute noise. Pico SASS is used to control high level theme variables at the Site level.

#### Notes

  * Higher layers also use Air::Functional and Air::Component services directly

  * Externally loadable packages such as Air::Theme are on the development backlog

  * Other CSS modules - Air::Base::TailWind? | Air::Base::Bootstrap? - are anticipated

SYNOPSIS
========

The synopsis is split so that each part can be annotated.

### Content

```raku
use Air::Functional :BASE;
use Air::Base;

my %data =
    :thead[["Planet", "Diameter (km)", "Distance to Sun (AU)", "Orbit (days)"],],
    :tbody[
        ["Mercury",  "4,880", "0.39",  "88"],
        ["Venus"  , "12,104", "0.72", "225"],
        ["Earth"  , "12,742", "1.00", "365"],
        ["Mars"   ,  "6,779", "1.52", "687"],
    ],
    :tfoot[["Average", "9,126", "0.91", "341"],];

my $Content1 = content [
    h3 'Content 1';
    table |%data, :class<striped>;
];

my $Content2 = content [
    h3 'Content 2';
    table |%data;
];

my $Google = external :href<https://google.com>;
```

Key features shown are:

  * application of the `:BASE` modifier on `use Air::Functional` to avoid namespace conflict

  * definition of table content as a Hash `%data` of Pairs `:name[[2D Array],]`

  * assignment of two functional `content` tags and their arguments to vars

  * assignment of a functional `external` tag with attrs to a var

### Page

The template of an Air website (header, nav, logo, footer) is applied by making a custom `page` ... here `index` is set up as the template page. In this SPA example navlinks dynamically update the same page content via HTMX, so index is only used once, but in general multiple instances of the template page can be cookie cuttered. Any number of page template can be set up in this way and can reuse custom Components.

```raku
my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Red, Cro',
    nav         => nav(
        logo    => safe('<a href="/">h<b>&Aring;</b>rc</a>'),
        items   => [:$Content1, :$Content2, :$Google],
        widgets => [lightdark],
    ),
    footer      => footer p ['Aloft on ', b 'Åir'],
);
```

Key features shown are:

  * set the `index` functional tag as a modified Air::Base `page` tag

  * use of `.assuming` for functional code composition

  * use of => arrow Pair syntax to set a custom page theme with title, description, nav, footer

  * use of `nav` functional tag and passing it attrs of the `NavItems` defined

  * use of `:$Content1` Pair syntax to pass in both nav link text (ie the var name as key) and value

  * Nav routes are automagically generated and HTMX attrs are used to swap in the content inners

  * use of `safe` functional tag to suppress HTML escape

  * use of `lightdark` widget to toggle theme according to system and user preference

### Site

```raku
sub SITE is export {
    site
        index
            main $Content1
}
```

Key features shown are:

  * use of `site` functional tag - that sets up the site Cro routes and Pico SASS theme

  * `site` takes the `index` page as positional argument

  * `index` takes a `main` functional tag as positional argument

  * `main` takes the initial content

DESCRIPTION
===========

In general, items defined in Air::Base are exported as both roles or classes (title case) and as subroutines (lower case).

So, after `use`ing the relevant module you can code in OO or functional style:

``` my $t = Title.new: 'sometext'; ```

Is identical to writing:

``` my $t = title 'sometext'; ```

The Air::Base library is implemented over a set of Raku modules, which are then used in the main Base module and re-exported as both classes and functions:

  * [Air::Base::Tags](Base/Tags.md) - HTML, Semantic & Safe Tags

  * [Air::Base::Elements](Base/Elements.md) - Layout, Active & Markdown Elements

  * [Air::Base::Tools](Base/Tools.md) - Tools for site-wide deployment

  * [Air::Base::Widgets](Base/Widgets.md) - Widgets use anywhere, esp Nav

All items are re-exported by the top level module, so you can just `use Air::Base;` near the top of your code.

Page Tags
---------

A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient and opinionated set of defaults for `html`, `head`, `body`, `header`, `nav`, `main` & `footer`. Several of the page tags offer shortcut attrs that are populated up the DOM immediately prior to first use.

### role Head does Tag[Regular] {...}

Singleton pattern (ie. same Head for all pages)

### has Tags::Title $.title

title

### has Tags::Meta $.description

description

### has Positional[Tags::Meta] @.metas

metas

### has Positional[Tags::Script] @.scripts

scripts

### has Positional[Tags::Link] @.links

links

### has Positional[Tags::Style] @.styles

style

### method HTML

```raku
method HTML() returns Mu
```

.HTML method calls .HTML on all inners

### role Header does Tag[Regular] {...}

### has Nav $.nav

nav

### has Tags::Safe $.tagline

tagline

### role Main does Tag[Regular] {...}

### role Footer does Tag[Regular] {...}

head
====

3 role Body does Tag[Regular] {...}

### has Header $.header

header

### has Main $.main

main

### has Footer $.footer

footer

### has Positional[Tags::Script] @.scripts

scripts

### role Html does Tag[Regular] {...}

### has Head $.head

head

### has Body $.body

body

Nav, Page and Site
------------------

These are the central parts of Air::Base

### subset NavItem of Pair where .value ~~ Internal | External | Content | Page;

class Nav
---------

Nav does Component to do multiple instances with distinct NavItem and Widget attrs

### has Str $.hx-target

HTMX attributes

### has Air::Functional::Markup $.logo

logo

### has Positional[NavItem] @.items

NavItems

### has Positional[Widgets::Widget] @.widgets

Widgets

### method make-routes

```raku
method make-routes() returns Mu
```

makes routes for Content NavItems (eg. SPA links that use HTMX) must be called from within a Cro route block

### method nav-items

```raku
method nav-items() returns Mu
```

renders NavItems

### method HTML

```raku
method HTML() returns Mu
```

applies Style and Script for Hamburger reactive menu

class Page
----------

Page does Component to do multiple instances with distinct content and attrs

### has Int $.REFRESH

auto refresh browser every n secs in dev't

page implements several shortcuts that are populated up the DOM, for example `page :title('My Page")` will go `self.html.head.title = Title.new: $.title with $.title;`

### has Str $.title

shortcut self.html.head.title

### has Str $.description

shortcut self.html.head.description

### has Nav $.nav

shortcut self.html.body.header.nav -or-

### has Header $.header

shortcut self.html.body.header [nav wins if both attrs set]

### has Main $.main

shortcut self.html.body.main

### has Footer $.footer

shortcut self.html.body.footer

### has Html $.html

build page DOM by calling Air tags

### method shortcuts

```raku
method shortcuts() returns Mu
```

set all provided shortcuts on first use

### multi method new

```raku
multi method new(
    Main $main,
    *%h
) returns Mu
```

.new positional with main only

### multi method new

```raku
multi method new(
    Header $header,
    Main $main,
    *%h
) returns Mu
```

.new positional with header & main only

### multi method new

```raku
multi method new(
    Main $main,
    Footer $footer,
    *%h
) returns Mu
```

.new positional with main & footer only

### multi method new

```raku
multi method new(
    Header $header,
    Main $main,
    Footer $footer,
    *%h
) returns Mu
```

.new positional with header, main & footer only

### method HTML

```raku
method HTML() returns Mu
```

issue page

### subset Redirect of Pair where .key !~~ /\// && .value ~~ /^ \//;

class Site
----------

Site is a holder for pages, performs setup of Cro routes, gathers styles and scripts, and runs SASS

### has Positional[Page] @.pages

Page holder -or-

### has Page $.index

index Page ( otherwise $!index = @!pages[0] )

### has Page $.html404

404 page (otherwise bare 404 is thrown)

### has Positional @.register

Register for route setup; default = [Nav.new]

### has Positional[Tools::Tool] @.tools

Tools for sitewide behaviours

### has Positional[Redirect] @.redirects

Redirects

### has Bool $.scss-off

use :scss-off to disable the SASS compiler run

### has Str $.theme-color

pick from: amber azure blue cyan fuchsia green indigo jade lime orange pink pumpkin purple red violet yellow (pico theme)

### has Str $.bold-color

pick from:- aqua black blue fuchsia gray green lime maroon navy olive purple red silver teal white yellow (basic css)

### multi method new

```raku
multi method new(
    Page $index,
    *%h
) returns Mu
```

.new positional with index only

### method enqueue-all

```raku
method enqueue-all() returns Mu
```

enqueued items are rendered in order, avoid interdependencies

### method build

```raku
method build() returns Mu
```

run the SCSS compiler vendor all default packages fixme

### method serve

```raku
method serve() returns Mu
```

build application and start server

### method start

```raku
method start(
    :$port = 3000,
    :$host = "localhost"
) returns Mu
```

start the server (ie skip build)

Defaults
--------

role Defaults provides a central place to set the various website defaults across Head, Html and Site roles

On installation, the file `~/.rair-config/.air.yaml` is placed in the home directory (ie copied from `resources/.air.yaml`. By default, role Defaults loads the information specified in this file intio the appropriate part of each page:

    Html:
      attrs:
        lang: "en"
        data-theme: "dark"

    Head:
      metas:
        - charset: "utf-8"
        - name: "viewport"
          content: "width=device-width, initial-scale=1"

      links:
        - rel: "icon"
          href: "/img/favicon.ico"
          type: "image/x-icon"
        - rel: "stylesheet"
          href: "/css/styles.css"

      scripts:
        - src: "https://unpkg.com/htmx.org@1.9.5"
          crossorigin: "anonymous"
          integrity: "sha384-xcuj3WpfgjlKF+FXhSQFQ0ZNr39ln+hwjN3npfM9VBnUskLolQAcN80McRIVOPuO"

These values can be customised as follows: copy this file from `~/.rair-config/.air.yaml` to `bin/.air.yaml` where `bin` is the dir where you run your website script (see Air::Examples for a working version). Note that, until we add Air::Theme support, many of the Air features and examples are HTMX centric, so only remove this if you are confident. Other fields (such as the site url and admin email) will be added here as the codebase evolves. Also, this is the basis for vendoring support to be implemented in a future release.

package EXPORT::DEFAULT
-----------------------

gather all the base and child module classes and roles put in all the @combined-exports as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}

### sub EXPORT

```raku
sub EXPORT() returns Mu
```

also just re-export them as vanilla classes and roles

AUTHOR
======

Steve Roe <librasteve@furnival.net>

COPYRIGHT AND LICENSE
=====================

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


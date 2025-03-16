Air::Base
=========

This raku module is one of the core libraries of the raku **Air** distribution.

It provides a Base library of functional Tags and Components that can be composed into web applications.

Air::Base uses Air::Functional for standard HTML tags expressed as raku subs. Air::Base uses Air::Component for scaffolding for library Components.

Architecture
------------

Here's a diagram of the various Air parts. (Air::Play is a separate raku module with several examples of Air websites.)

                +----------------+
                |    Air::Play   |    <-- Web App
                +----------------+
                        |
              +-------------------+
              |  Air::Play::Site  |   <-- Site Lib
              +-------------------+
                        |
                +----------------+
                |    Air::Base   |    <-- Base Lib
                +----------------+
                   /           \
      +----------------+  +----------------+
      | Air::Functional|  | Air::Component |  <-- Services
      +----------------+  +----------------+

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

Each feature of Air::Base is set out below:

role Tagged[Singular|Regular] does Tag
--------------------------------------



consuming class behaves like a standard HTML tag from Air::Functional

### has Associative[Attr(Any)] %.attrs

can be provided with attrs

### has Positional @.inners

can be provided with inners

### method new

```raku
method new(
    *@inners,
    *%attrs
) returns Mu
```

ok to call .new with @inners as Positional

### method HTML

```raku
method HTML() returns Mu
```

provides default .HTML method used by tag render

Basic Tags
----------

A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient set of elements for the Page Tags.

### role Safe does Tagged[Regular] {...}

### method HTML

```raku
method HTML() returns Mu
```

avoids HTML escape

### role Script does Tagged[Regular] {...}

### method HTML

```raku
method HTML() returns Mu
```

no html escape

### role Style does Tagged[Regular] {...}

### method HTML

```raku
method HTML() returns Mu
```

no html escape

### role Meta does Tagged[Singular] {}

### role Title does Tagged[Regular] {}

### role Link does Tagged[Regular] {}

### role A does Tagged[Regular] {...}

Page Tags
---------

A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient and opinionated set of defaults for `html`, `head`, `body`, `header`, `nav`, `main` & `footer`. Several of the page tags offer shortcut attrs that are populated up the DOM immediately prior to first use.

### role Head does Tagged[Regular] {...}

Singleton pattern (ie. same Head for all pages)

### has Title $.title

title

### has Meta $.description

description

### has Positional[Meta] @.metas

metas

### has Positional[Script] @.scripts

scripts

### has Positional[Link] @.links

links

### has Style $.style

style

### method defaults

```raku
method defaults() returns Mu
```

set up common defaults (called on instantiation)

### method HTML

```raku
method HTML() returns Mu
```

.HTML method calls .HTML on all attrs

### role Header does Tagged[Regular] {...}

### has Nav $.nav

nav

### has Safe $.tagline

tagline

### role Main does Tagged[Regular] {...}

### role Footer does Tagged[Regular] {...}

head
====

3 role Body does Tagged[Regular] {...}

### has Header $.header

header

### has Main $.main

main

### has Footer $.footer

footer

### role Html does Tagged[Regular] {...}

### has Head $.head

head

### has Body $.body

body

### has Associative[Attr] %.lang

default :lang<en>

### has Associative[Attr] %.mode

default :data-theme<dark>

Semantic Tags
-------------

These are re-published with minor adjustments and align with Pico CSS semantic tags

### role Content does Tagged[Regular] {...}

### role Section does Tagged[Regular] {}

### role Article does Tagged[Regular] {}

### role Article does Tagged[Regular] {}

### role Time does Tagged[Regular] {...}

In HTML the time tag is typically of the form < time datetime="2025-03-13" > 13 March, 2025 < /time > . In Air you can just go time(:datetime < 2025-02-27 > ); and raku will auto format and fill out the inner human readable text.

optionally specify mode => [time | datetime], mode => date is default

Widgets
-------

Active tags that can be used eg in Nav, typically load in some JS behaviours

### role LightDark does Tagged[Regular] {...}

### has Str $.show

set to icon(default) or buttons

Site Tags
---------

These are the central elements of Air::Base

First we set up the NavItems = Internal | External | Content | Page

### role External does Tagged[Regular] {...}

### role Internal does Tagged[Regular] {...}

class Nav
---------

Nav does Component in order to support multiple nav instances with distinct NavItem and Widget attributes. Also does Tag so that nav tags can be placed anywhere on a page.

### has Safe $.logo

logo

### has Positional[NavItem] @.items

NavItems

### has Positional[Widget] @.widgets

Widgets

### method make-routes

```raku
method make-routes() returns Mu
```

makes routes for Content NavItems (SPA links that use HTMX), must be called from within a Cro route block

### method nav-items

```raku
method nav-items() returns Mu
```

renders NavItems [subset NavItem of Pair where .value ~~ Internal | External | Content | Page;]

### multi method HTML

```raku
multi method HTML() returns Mu
```

applies Style and Script for Hamburger reactive menu

class Page
----------

Page does Component in order to support multiple page instances with distinct content and attributes.

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

### has Bool $.styled-aside-on

set to True with :styled-aside-on to apply self.html.head.style with right hand aside block

### has Html $.html

build page DOM by calling Air tags

### method defaults

```raku
method defaults() returns Mu
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

### multi method HTML

```raku
multi method HTML() returns Mu
```

issue page DOM

class Site
----------

Site is a holder for pages, performs setup of Cro routes and offers high level controls for style via Pico SASS.

### has Positional[Page] @.pages

Page holder

### has Page $.index

index Page [defaults to @!pages[0]

### has Positional[Component] @.components

Components for route setup; default = [Nav.new]

### has Bool $.scss

use :!scss to disable SASS compiler run

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

Pico Tags
---------

The Air roadmap is to provide a full set of pre-styled tags as defined in the Pico [docs](https://picocss.com/docs). Did we say that Air::Base implements Pico CSS?

### role Table does Tag

Attrs thead, tbody and tfoot can each be a 2D Array [[values],] that iterates to row and columns or a Tag|Component - if the latter then they are just rendered via their .HTML method. This allow for multi-row thead and tfoot.

Table applies col and row header tags as required for Pico styles.

Attrs provided as Pairs via tbody are extracted and applied. This is needed for :id<target> where HTMX is targetting the table body.

### has Mu $.tbody

default = [] is provided

### has Mu $.thead

optional

### has Mu $.tfoot

optional

### has Mu $.class

class for table

### method new

```raku
method new(
    *@tbody,
    *%h
) returns Mu
```

.new positional takes tbody [[]]

### role Table does Tag

### has Positional @.items

list of items to populate grid, each item is wrapped in a span tag

### method new

```raku
method new(
    *@items,
    *%h
) returns Mu
```

.new positional takes @items

package EXPORT::DEFAULT
-----------------------

put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}

AUTHOR
======

Steve Roe <librasteve@furnival.net>

COPYRIGHT AND LICENSE
=====================

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


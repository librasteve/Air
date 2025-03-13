Air::Base
=========

This raku module is one of the core libraries of the raku **Air** module.

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

### Theme

```raku
my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Raku, Cro',
    nav         => nav(
        logo    => safe('<a href="/">h<b>&Aring;</b>rc</a>'),
        items   => [:$Content1, :$Content2, :$Google],
        widgets => [lightdark],
    ),
    footer      => footer p ['Aloft on ', b 'Åir'],
);
```

Key features shown are:

  * definition of `index` functional tag as a modified `page` tag from Air::Base

  * use of `.assuming` for functional code composition

  * use of => arrow Pair syntax to set a custom page theme with title, description, nav, footer

  * note that the theme is implemented as a custom `page` ... `index` is set up as the template page

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

Widgets
-------

Active tags that can be used eg in Nav, typically load in some JS behaviours

### role LightDark does Tagged[Regular] {...}

### has Str $.show

<icon buttons>

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

Site Tags
---------

These are the central elements of Air::Base

First we set up the NavItems = Internal | External | Content | Page

### role External does Tagged[Regular] {...}

### role Internal does Tagged[Regular] {...}

class Nav
---------

Nav is specified as a class since it does Component, also does Tag

### has Safe $.logo

logo

### has Positional[NavItem] @.items

NavItems

### has Positional[Widget] @.widgets

Widgets

### multi method HTML

```raku
multi method HTML() returns Mu
```

applies Style and Script for Hamburger reactive menu

class Page
----------

Page is specified as a class since it does Component iamerejh

### has Str $.theme-color

<amber azure blue cyan fuchsia green indigo jade lime orange pink pumpkin purple red violet yellow> (pico theme)

### has Str $.bold-color

one from <aqua black blue fuchsia gray green lime maroon navy olive purple red silver teal white yellow> (basic css)

### method style

```raku
method style() returns Mu
```

optional grid style from https://cssgrid-generator.netlify.app/

package EXPORT::DEFAULT
-----------------------

put in all the @components as functions viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing


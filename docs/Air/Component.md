Air::Component
==============

This raku module is one of the core libraries of the raku **Air** distribution.

It is a scaffold to build dynamic, reusable web components.

SYNOPSIS
========

The synopsis is split so that each part can be annotated. First, we import the Air core libraries.

```raku
use Air::Functional :BASE;      # import all HTML tags as raku subs
use Air::Base;					# import Base components (site, page, nav...)
use Air::Component;
```

### HTMX functions

Predeclares some custom HTMX functions. This declutters `class Todo`, one nice part of using an HLL to generate HTML.

```raku
sub hx-create($url --> Hash()) {
    :hx-post("$url"),
    :hx-target<table>,
    :hx-swap<beforeend>,
    :hx-on:htmx:after-request<this.reset()>,
}
sub hx-toggle($url, $id --> Hash()) {
    :hx-get("$url/$id/toggle"),
    :hx-target<closest tr>,
    :hx-swap<outerHTML>,
}
sub hx-delete($url, $id --> Hash()) {
    :hx-delete("$url/$id"),
    :hx-confirm<Are you sure?>,
    :hx-target<closest tr>,
    :hx-swap<delete>,
}
```

Key features are:

  * sub names `hx-toggle` echo standard HTMX attributes such as `hx-get`

  * return values are coerced to a raku `Hash` containing HTMX attrs

### class Todo

The core of our synopsis. It `does role Component` to bring in the scaffolding.

The general idea is that a raku class implements a web Component, multiple instances of the Component are represented by objects of the class and the methods of the class represent actions that can be performed on the Component in the browser.

```raku
class Todo does Component {
    has Bool $.checked is rw = False;
    has Str  $.text;

    method toggle is routable {
        $!checked = !$!checked;
        fragment self;
    }

    multi method HTML {
        tr
            td( input :type<checkbox>, |hx-toggle($.url,$.id), :$!checked ),
            td( $!checked ?? del $!text !! $!text),
            td( button :type<submit>, |hx-delete($.url,$.id), :style<width:50px>, '-'),
    }
}
```

Key features of `class Todo` are:

  * Todo objects have state `$.checked` and `$.text`

  * `method toggle` takes the trait `is routable` - this makes a corfragmenting Cro route

  * `method toggle` adjusts the state and ends with the `fragment` sub (which calls `.HTML`)

  * `class Todo` provides a `multi method HTML` which uses functional HTML tags

The result is a concise, legible and easy-to-maintain component implementation.

### sub SITE

Now, we can export a website as follows:

```raku
my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Raku, Cro',
    footer      => footer p ['Aloft on ', b 'Åir'],
);

my @todos = do for <one two> -> $text { Todo.new: :$text };

sub SITE is export {
    site :components(@todos),
        index
            main [
                h3 'Todos';
                table @todos;
                form  |hx-create("todo"), [
                    input  :name<text>;
                    button :type<submit>, '+';
                ];
            ]
}
```

Key features of `sub SITE` are:

  * we make our own function `&index` that

    * (i) uses `.assuming` to preset some attributes (title, description, footer) and

    * (ii) then calls the `page` function provided by Air::Base

  * we set up our list of Todo components calling `Todo.new`

  * we use the Air::Base `site` function to make our website

  * the call chain `site(index(main(...))` then makes our website

  * `site` is passed `:components(@todos)` to make the component cro routes

Run Cro service.raku
--------------------

Component automagically creates some cro routes for Todo when we start our website...

    > raku -Ilib service.raku
    theme-color=azure
    bold-color=red
    adding GET todo/<id>
    adding POST todo
    adding DELETE todo/<id>
    adding PUT todo/<id>
    adding GET todo/<id>/toggle
    Listening at http://0.0.0.0:3000

DESCRIPTION
===========

The rationale for Air Components is rooted in the powerful raku code composition capabilities. It builds on the notion of Locality of Behaviour (aka [LOB](https://htmx.org/essays/locality-of-behaviour/)) and the intent is that a Component can represent and render every aspect of a piece of website behaviour.

  * Content

  * Layout

  * Theme

  * Data Model

  * Actions

As Air evolves, it is expected that common code idioms will emerge to make each dimensions independent (ie HTML, CSS and JS relating to Air::Theme::Font would be local, and distinct from HTML, CSS and JS for Air::Theme::Nav).

Air is an integral part of the HARC stack (HTMX, Air, Red, Cro). The Synopsis shows how a Component can externalize and consume HTMX attributes for method actions, perhaps even a set of Air::HTMX libraries can be anticipated. One implication of this is that each Component can use the [hx-swap-oob](https://htmx.org/attributes/hx-swap-oob/) attribute to deliver Content, Style and Script anywhere in the DOM (except the `html` tag). An instance of this could be a blog website where a common Red `model Post` could be harnessed to populate each blog post, a total page count calculation for paging and a post summary list in an `aside`.

In the Synopsis, both raku class inheritance and role composition provide coding dimensions to greatly improve code clarity and evolution. While simple samples are shown, raku has comprehensive encapsulation and type capabilities in a friendly and approachable language.

Raku is a multi-paradigm language for both Functional and Object Oriented (OO) coding styles. OO is a widely understood approach to code and state encapsulation - suitable for code evolution across many aspects - and is well suited for Component implementations. Functional is a surprisingly good paradigm for embedding HTML standard and custom tags into general raku source code. The example below illustrates the power of Functional tags inline when used in more intricate stanzas.

While this kind of logic can in theory be delivered in a web app using web template files, as the author of the Cro Template language [comments](https://cro.raku.org/docs/reference/cro-webapp-template-syntax#Conditionals) *Those wishing for more are encouraged to consider writing their logic outside of the template.*

```raku
    method nav-items {
        do for @.items.map: *.kv -> ($name, $target) {
            given $target {
                when * ~~ External | Internal {
                  $target.label = $name;
                  li $target.HTML
                }
                when * ~~ Content {
                    li a(:hx-get("$.url-part/$.id/" ~ $name), safe $name)
                }
                when * ~~ Page {
                    li a(:href("/{.url-part}/{.id}"), safe $name)
                }
            }
        }
    }

    multi method HTML {
        self.style.HTML ~ (

        nav [
            { ul li :class<logo>, :href</>, $.logo } with $.logo;

            button( :class<hamburger>, :id<hamburger>, safe '&#9776;' );

            ul( :$!hx-target, :class<nav-links>,
                self.nav-items,
                do for @.widgets { li .HTML },
            );

            ul( :$!hx-target, :class<menu>, :id<menu>,
                self.nav-items,
            );
        ]

        ) ~ self.script.HTML
    }
```

From the implementation of the Air::Base::Nav component.

TIPS & TRICKS
=============

When writing components:

  * custom `multi method HTML` inners must be explicitly rendered with .HTML or wrapped in a tag eg. `div` since being passed as AN inner will call `trender` which will, in turn, call `.HTML`

role Component
--------------

### has UInt $.id

assigns and tracks instance ids

### has Str $.base

optional attr to specify url base

### method holder

```raku
method holder() returns Hash
```

populates an instance holder [class method], may be overridden for external instance holder

### method all

```raku
method all() returns Mu
```

get all instances in holder

### method url-part

```raku
method url-part() returns Str
```

get url part

### method url

```raku
method url() returns Str
```

get url (ie base/part)

### method LOAD

```raku
method LOAD(
    $id
) returns Mu
```

Default load action (called on GET) - may be overridden

### method CREATE

```raku
method CREATE(
    *%data
) returns Mu
```

Default create action (called on POST) - may be overridden

### method DELETE

```raku
method DELETE() returns Mu
```

Default delete action (called on DELETE) - may be overridden

### method UPDATE

```raku
method UPDATE(
    *%data
) returns Mu
```

Default update action (called on PUT) - may be overridden

### method add-routes

```raku
method add-routes(
    $component is copy,
    :$url-part = Code.new
) returns Mu
```

Meta Method ^add-routes typically called from Air::Base::Site in a Cro route block

### multi sub fragment

```raku
multi sub fragment(
    $comp
) returns Mu
```

calls Cro: content 'text/html', $comp.HTML

### multi sub fragment

```raku
multi sub fragment(
    Str $html
) returns Mu
```

calls Cro: content 'text/html', $html

AUTHOR
======

Steve Roe <librasteve@furnival.net>

The `Air::Component` module provided is based on an early version of the raku `Cromponent` module, author Fernando Corrêa de Oliveira <fco@cpan.com>, however unlike Cromponent this module does not use Cro Templates.

COPYRIGHT AND LICENSE
=====================

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


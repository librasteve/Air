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

We prepare some custom HTMX actions for our Todo component. This declutters `class Todo` and keeps our `hx-attrs` tidy and local.

```raku
role HxTodo {
    method hx-create(--> Hash()) {
        :hx-post("todo"),
        :hx-target<table>,
        :hx-swap<beforeend>,
    }
    method hx-delete(--> Hash()) {
        :hx-delete($.url-id),
        :hx-confirm<Are you sure?>,
        :hx-target<closest tr>,
        :hx-swap<delete>,
    }
    method hx-toggle(--> Hash()) {
        :hx-get("$.url-id/toggle"),
        :hx-target<closest tr>,
        :hx-swap<outerHTML>,
    }
}
```

Key features are:

  * these are packaged in a raku role which is then consumed by `class Todo`

  * method names `hx-toggle` echo standard HTMX attributes such as `hx-get`

  * return values are coerced to a raku `Hash` containing HTMX attrs

### class Todo

The core of our synopsis. It `does Component` to bring in the scaffolding.

The general idea is that a raku class implements a web Component, multiple instances of the Component are represented by objects of the class and the methods of the class represent actions that can be performed on the Component in the browser.

```raku
class Todo does Component {
    also does HxTodo;

    has Bool $.checked is rw = False;
    has Str  $.text;

    method toggle is controller {
        $!checked = !$!checked;
        respond self;
    }

    multi method HTML {
        tr
            td( input :type<checkbox>, |$.hx-toggle, :$!checked ),
            td( $!checked ?? del $!text !! $!text),
            td( button :type<submit>, |$.hx-delete, :style<width:50px>, '-'),
    }
}
```

Key features of `class Todo` are:

  * Todo objects have state `$.checked` and `$.text` with suitable defaults

  * `method toggle` takes the trait `is controller` - this makes a corresponding Cro route

  * `method toggle` adjusts the state and ends with the `respond` sub (which calls `.HTML`)

  * `class Todo` provides a `multi method HTML` which uses functional HTML tags `tr`, `td` and so on

  * we call our HxTodo methods eg `|$.hx-toggle` with the *call self* shorthand `$.`

  * the Hash is flattened into individual attrs with `|`

  * a smattering of style (or any HTML attr) can be added as needed

The result is a concise, legible and easy-to-maintain component implementation.

### sub SITE

Now, we can make a website as follows:

```raku
my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Red, Cro',
    footer      => footer p ['Aloft on ', b 'Åir'],
);

my @todos = do for <one two> -> $text { Todo.new: :$text };

sub SITE is export {
    site :components(@todos),
        index
            main [
                h3 'Todos';
                table @todos;
                form  |Todo.hx-create, [
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

  * `site` is passed `:components(@todos)` to make the component Cro routes

Run Cro service.raku
--------------------

Component automagically creates some cro routes for Todo when we start our website...

    > raku -Ilib service.raku
    theme-color=green
    bold-color=red
    adding GET todo/<#>
    adding POST todo
    adding DELETE todo/<#>
    adding PUT todo/<#>
    adding GET todo/<#>/toggle
    adding GET page/<#>
    Build time 0.67 sec
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

Air is an integral part of the hArc stack (HTMX, Air, Red, Cro). The Synopsis shows how a Component can externalize and consume HTMX attributes for method actions, perhaps even a set of Air::HTMX libraries can be anticipated. One implication of this is that each Component can use the [hx-swap-oob](https://htmx.org/attributes/hx-swap-oob/) attribute to deliver Content, Style and Script anywhere in the DOM (except the `html` tag). An instance of this could be a blog website where a common Red `model Post` could be harnessed to populate each blog post, a total page count calculation for paging and a post summary list in an `aside`.

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
                    li a(:hx-get("$.name/$.serial/" ~ $name), safe $name)
                }
                when * ~~ Page {
                    li a(:href("/{.name}/{.serial}"), safe $name)
                }
            }
        }
    }

    multi method HTML {
        self.style.HTML ~ (

        nav [
            { ul li :class<logo>, :href</>, $.logo } with $.logo;

            button( :class<hamburger>, :serial<hamburger>, safe '&#9776;' );

            ul( :$!hx-target, :class<nav-links>,
                self.nav-items,
                do for @.wserialgets { li .HTML },
            );

            ul( :$!hx-target, :class<menu>, :serial<menu>,
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

  * custom `multi method HTML` inners must be explicitly rendered with .HTML or wrapped in a tag eg. `div` since being passed as AN inner will call `render-tag` which will, in turn, call `.HTML`



attributes and methods shared between Component and Component::Red roles

### has Str $!base

optional attr to specify url base

### method url-name

```raku
method url-name() returns Mu
```

get url safe name of class doing Component role

### method url

```raku
method url() returns Str
```

get url (ie base/name)

### method url-path

```raku
method url-path() returns Str
```

get url-id (ie base/name/id)

### method html-id

```raku
method html-id() returns Str
```

get html-id (ie url-name-id), intended for HTML id attr

### method Str

```raku
method Str() returns Mu
```

In general Cromponent::MetaCromponentRole calls .Str on a Cromponent when returning it this method substitutes .HTML for .Str



Component is for non-Red classes

### has UInt $!id

assigns and tracks instance ids

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

### method make-methods

```raku
method make-methods() returns Mu
```

adapt component to perform LOAD, UPDATE, DELETE, ADD action(s) called by role Site



Component::Red is for Red models

### method make-methods

```raku
method make-methods() returns Mu
```

adapt component to perform LOAD, UPDATE, DELETE, ADD action(s) called by role Site

AUTHOR
======

Steve Roe <librasteve@furnival.net>

The `Air::Component` module integrates with the Cromponent module, author Fernando Corrêa de Oliveira <fco@cpan.com>, however unlike Cromponent this module does not use Cro Templates.

COPYRIGHT AND LICENSE
=====================

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


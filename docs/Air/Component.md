Air::Component
==============

This raku module is one of the core libraries of the raku **Air** module.

It is a scaffold to build dynamic, reusable web components.

SYNOPSIS
========

The synopsis is split so that each part can be annotated. First, we import the Air core libraries.

```raku
use Air::Functional :BASE;      # import all HTML tags as raku subs
use Air::Base;					# import Base components (site, page, nav...)
use Air::Component;
```

#### role HxTodo

Predeclares some custom HTMX actions. This declutters `class Todo` and `class Frame`.

```raku
role HxTodo {
    method hx-toggle(--> Hash()) {
        :hx-get("$.url/$.id/toggle"),
        :hx-target<closest tr>,
        :hx-swap<outerHTML>,
    }
    method hx-create(--> Hash()) {
        :hx-post("$.url"),
        :hx-target<table>,
        :hx-swap<beforeend>,
        :hx-on:htmx:after-request<this.reset()>,
    }
    method hx-delete(--> Hash()) {
        :hx-delete("$.url/$.id"),
        :hx-confirm<Are you sure?>,
        :hx-target<closest tr>,
        :hx-swap<delete>,
    }
}
```

Key features of `role HxTodo` are:

  * uses a standard raku `role` for code separation

  * method names `hx-toggle` are chosen to echo standard HTMX attributes such as `hx-get`

  * attributes `$.url` and `.id` are provided by `role Component`

  * return values are coerced to a raku `Hash` containing HTMX attrs

#### class Todo

The core of our synopsis. It `does role Component` to bring in the scaffolding.

The general idea is that a raku class implements a web Component, multiple instances of the Component are represented by objects of the class and the methods of the class represent actions that can be performed on the Component in the browser.

```raku
class Todo does Component {
    also does HxTodo;

    has Bool $.checked is rw = False;
    has Str  $.text;

    method toggle is routable {
        $!checked = !$!checked;
        respond self;
    }

    multi method HTML {
        tr
            td(input :type<checkbox>, :$!checked, |$.hx-toggle),
            td($!checked ?? del $!text !! $!text),
            td(button :type<submit>, :style<width:50px>, |$.hx-delete, '-'),
    }
}
```

Key features of `class Todo` are:

  * Todo objects have state `$.checked` and `$.text`

  * `method toggle` takes the trait `is routable`

  * `method toggle` adjusts the state and ends with the `respond` sub (which calls `.HTML`)

  * `class Todo` provides a `multi method HTML`

  * `method HTML` uses functional HTML tags and brings in HxTodo actions

The result is a concise, legible and easy-to-maintain component implementation.

#### class Frame

Provides a frame our Todo components and a form to add new ones.

```raku
class Frame does Tag {
    also does HxTodo;

    has Todo @.todos;
    has $.url = "todo";

    multi method HTML {
        div [
            h3 'Todos';
            table @!todos;
            form  |$.hx-create, [
                input  :name<text>;
                button :type<submit>, '+';
            ];
        ]
    }
}
```

Key features of `class Frame` are:

  * `does Tag` to suppress HTML escape

  * maintains our `@.todos` list state

  * uses functional tags to make HTML

  * `multi method HTML` is called when rendered

#### sub SITE

Finally, we can export a webite as follows:

```raku
my &index = &page.assuming(
        title       => 'hÅrc',
        description => 'HTMX, Air, Raku, Cro',
        footer      => footer p ['Aloft on ', b 'Åir'],
    );

my @todos = do for <one two> -> $text { Todo.new: :$text };

sub SITE is export {
    site :components(@todos), #:theme-color<azure>,
        index
            main
                Frame.new: :@todos;
}
```

Key features of `sub SITE` are:

  * we make our own function `&index` that

    * (i) uses `.assuming` to preset some attributes (title, description, footer) and

    * (ii) then calls the `page` function provided by Air::Base

  * we set up our list of Todo components calling `Todo.new`

  * we use the Air::Base `site` function to make our website

  * the call chain `site(index(main(Frame.new: :@todos;)))` then makes our website

  * `site` is passed `:components(@todos)` to make the component cro routes

  * `site` may optionally be passed theme settings also

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

---

TIPS & TRICKS
=============

When writing components:

  * custom multi method HTML inners must be explicitly rendered with .HTML or wrapped in a tag eg. `div` since being passed as inner will call `trender` which will, in turn, call `.HTML`

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

### multi sub respond

```raku
multi sub respond(
    $comp
) returns Mu
```

calls Cro: content 'text/html', $comp.HTML

### multi sub respond

```raku
multi sub respond(
    Str $html
) returns Mu
```

calls Cro: content 'text/html', $html


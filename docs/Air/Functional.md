Air::Functional
===============

This raku module is one of the core libraries of the raku **Air** distribution.

It exports HTML tags as raku subs that can be composed as functional code within a raku program.

It replaces the HTML::Functional module by the same author.

SYNOPSIS
========

Here's a regular HTML page:

```html
<div class="jumbotron">
  <h1>Welcome to Dunder Mifflin!</h1>
  <p>
    Dunder Mifflin Inc. (stock symbol <strong>DMI</strong>) is
    a micro-cap regional paper and office supply distributor with
    an emphasis on servicing small-business clients.
  </p>
</div>
```

And here is the same page using Air::Functional:

```raku
use Air::Functional;

div :class<jumbotron>, [
    h1 "Welcome to Dunder Mifflin!";
    p  [
        "Dunder Mifflin Inc. (stock symbol "; strong 'DMI'; ") ";
        q:to/END/;
            is a micro-cap regional paper and office
            supply distributor with an emphasis on servicing
            small-business clients.
        END
    ];
];
```

DESCRIPTION
===========

Key features shown are:

  * HTML tags are implemented as raku functions: `div, h1, p` and so on

  * parens `()` are optional in raku function calls

  * HTML tag attributes are passed as raku named arguments

  * HTML tag inners (e.g. the Str in `h1`) are passed as raku positional arguments

  * the raku Pair syntax is used for each attribute i.e. `:name<value>`

  * multiple `@inners` are passed as a literal Array `[]` – div contains h1 and p

  * the raku parser looks at functions from the inside out, so `strong` is evaluated before `p`, before `div` and so on

  * semicolon `;` is used as the Array literal separator to suppress nesting of tags

Normally the items in a raku literal Array are comma `,` separated. Raku precedence considers that `div [h1 x, p y];` is equivalent to `div( h1(x, p(y) ) );` … so the p tag is embedded within the h1 tag unless parens are used to clarify. But replace the comma `,` with a semi colon `;` and predisposition to nest is reversed. So `div [h1 x; p y];` is equivalent to `div( h1(x), p(y) )`. Boy that Larry Wall was smart!

The raku example also shows the power of the raku **Q-lang** at work:

  * double quotes `""` interpolate their contents

  * curlies denote an embedded code block `"{fn x}"`

  * tilde `~` is for Str concatenation

  * the heredoc form `q:to/END/;` can be used for verbatim text blocks

This module generally returns `Str` values to be string concatenated and included in an HTML content/text response.

It also defines a programmatic API for the use of HTML tags for raku functional coding and so is offered as a basis for sister modules that preserve the API, but have a different technical implementation such as a MemoizedDOM.

Declare Constants
-----------------

All of the HTML tags listed at [https://www.w3schools.com/tags/default.asp](https://www.w3schools.com/tags/default.asp) are covered ...

... of which empty (Singular) tags from [https://www.tutsinsider.com/html/html-empty-elements/](https://www.tutsinsider.com/html/html-empty-elements/)

HTML Escape
-----------

### sub escape

```raku
sub escape(
    Str:D(Any):D $s
) returns Str
```

Explicitly HTML::Escape inner text

### multi sub prefix:<^>

```raku
multi sub prefix:<^>(
    Str:D(Any):D $s
) returns Str
```

also a shortcut ^ prefix

Tag Rendering
-------------

### role Attr is Str {} - type for Attribute values, use Attr() for coercion

### subset Inner where Str | Tag | Taggable | Markup - type union for Inner elements

role Tag [TagType Singular|Regular] {} - basis for Air functions
----------------------------------------------------------------

### has Str $.name

tag name is the unqualified (ie the last) part of the class name in lower case

### has Associative[Air::Functional::Attr] %.attrs

can be provided with attrs

### has Positional[Air::Functional::Inner] @.inners

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

### Custom Elements

Use eg. `el "simple-greeting", :name<John>, @inners` to issue HTML custom element `simple-greeting name="John">@inners</simple-greeting`

### sub el

```raku
sub el(
    Str $element-name,
    *@inners,
    *%attrs
) returns Mu
```

issue an HTML custom-element tag

### Low Level API

This level is where users want to mess around with the parts of a tag for customizations

### sub attrs

```raku
sub attrs(
    %h
) returns Str
```

convert from raku Pair syntax to HTML tag attributes

### sub merge

```raku
sub merge(
    %a,
    %b
) returns Hash
```

merge two attr hashes so that two styles are Str concatenated

### sub opener

```raku
sub opener(
    $tag,
    *%h
) returns Str
```

open a custom tag

### sub inner

```raku
sub inner(
    @inners
) returns Str(Any)
```

convert from an inner list to HTML tag inner string

### sub closer

```raku
sub closer(
    $tag,
    :$nl
) returns Str
```

close a custom tag (unset :!nl to suppress the newline)

### High Level API

This level is for general use from custom tags that behave like regular/singular tags

### sub do-regular-tag

```raku
sub do-regular-tag(
    Str $tag,
    *@inners,
    *%h
) returns Air::Functional::Markup(Any)
```

do a regular tag (ie a tag with @inners)

### sub do-singular-tag

```raku
sub do-singular-tag(
    Str $tag,
    *%h
) returns Air::Functional::Markup(Any)
```

do a singular tag (ie a tag without @inners)

Tag Export Options
------------------

Exports all the tags programmatically

package Air::Functional::EXPORT::DEFAULT
----------------------------------------

export all HTML tags viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

package Air::Functional::EXPORT::CRO
------------------------------------

use :CRO as package to avoid collisions with Cro::Router names

package Air::Functional::EXPORT::BASE
-------------------------------------

use :BASE as package to avoid collisions with Cro::Router, Air::Base & Air::Component names NB the HTML description list tags <dl dd dt> are also excluded to avoid conflict with the raku `dd` command

AUTHOR
======

Steve Roe <librasteve@furnival.net>

COPYRIGHT AND LICENSE
=====================

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


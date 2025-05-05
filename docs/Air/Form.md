Air::Form
=========

This raku module is one of the core libraries of the raku **Air** distribution.

It provides a Form class that integrates Air with the Cro::WebApp::Form module to provide a simple,yet rich declarative abstraction for web forms.

Air::Form uses Air::Functional for the FormTag role so that Forms can be employed within Air code. Air::Form is an alternative to Air::Component.

SYNOPSIS
========

The synopsis is split so that each part can be annotated.

### Page

The template of an Air website (header, nav, logo, footer) is applied by making a custom `page` ... here `index` is set up as the template page. [Check out the Base.md docs for more on this].

```raku
use Air::Functional :BASE;
use Air::Base;

my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Red, Cro',

    nav => nav(
        logo    => safe('<a href="/">h<b>&Aring;</b>rc</a>'),
        widgets => [lightdark],
    ),

    footer      => footer p ['Aloft on ', b 'åir'],
);
```

Key features shown are:

  * the lightdark widget is applicable to Form styles

### Form

An Air::Form is defined declaratively via the standard raku OO syntax, specifically form input fields are set by the public attributes of the class `has Str $.email` and so on.

```raku
use Air::Form;
use Cro::WebApp::Form;

class Contact does Form {
    has Str    $.first-names is validated(%va<names>)  is required;
    has Str    $.last-name   is validated(%va<name>)   is required;
    has Str    $.email       is validated(%va<email>)  is email;

    method form-routes {
        use Cro::HTTP::Router;

        self.prep;

        post -> Str $ where self.form-url, {
            form-data -> Contact $form {
                if $form.is-valid {
                    note "Got form data: $form.form-data()";
                    content 'text/plain', 'Contact info received!'
                }
                else {
                    self.retry: $form
                }
            }
        }
    }
}

my $contact-form = Contact.empty;
```

Key features shown are:

  * Form input properties are set by traits on the public attrs - for example `is email` specifies that this input field wants an email address, `is required` specifies that this field requires a value and so on.

  * We `use Air::Form;` to load the `role Form {...}` and then apply it to our new form class with `does Form`

  * The class name is used as the name of the form

  * Each input field name is converted to a label for the form by splitting on a `-` and then applying to the words `tclc` (title case, lower case)

  * Input field traits are imported directly from the `Cro::WebApp::Form` module and follow the relevant Cro documentation page [Air::Play](https://raku.land/zef:librasteve/Air::Play) iamerejh

```raku
sub SITE is export {
    site :components[$contact-form], :theme-color<blue>, :bold-color<green>,
        index
            main
                content [
                    h2 'Contact Form';
                    $contact-form;
                ];
}
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

Each feature of Air::Form is set out below:

Basics
------

A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient set of elements for the Page Tags.

Form does not do Air::Component due to namespace overlap
--------------------------------------------------------

Form is never functional (since this parent class never has fields)
-------------------------------------------------------------------



provides some standard validation checks checks can be overridden in user code

### has Str $!form-base

optionally specify form url base

### method form-name

```raku
method form-name() returns Mu
```

get url safe name of class doing Form role

### method form-url

```raku
method form-url() returns Str
```

get url (ie base/name)

### has Associative %!form-attrs

optional form attrs for prelude.crotmp settings

AUTHOR
======

Steve Roe <librasteve@furnival.net>

COPYRIGHT AND LICENSE
=====================

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


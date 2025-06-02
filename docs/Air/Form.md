Air::Form
=========

This raku module is one of the core libraries of the raku **Air** distribution.

It provides a Form class that integrates Air with the Cro::WebApp::Form module to provide a simple,yet rich declarative abstraction for web forms.

Air::Form uses Air::Functional for the Taggable role so that Forms can be employed within Air code. Air::Form is an alternative to Air::Component.

SYNOPSIS
========

An Air::Form is declared as a regular raku Object Oriented (OO) class. Specifically form input fields are set up via public attributes of the class ... `has Str $.email` and so on. Check out the [primer](https://docs.raku.org/language/objects) on raku OO basics.

#### Form Declaration

```raku
use Air::Form;

class Contact does Form {
    has Str    $.first-names is validated(%va<names>);
    has Str    $.last-name   is validated(%va<name>)   is required;
    has Str    $.email       is validated(%va<email>)  is required is email;
    has Str    $.city        is validated(%va<text>);

    method form-routes {
        self.init;

        self.controller: -> Contact $form {
            if $form.is-valid {
                note "Got form data: $form.form-data()";
                self.finish: 'Contact info received!'
            }
            else {
                self.retry: $form
            }
        }
    }
}

my $contact-form = Contact.empty;
```

Declaration Class and Attributes:

  * `use Air::Form` and then `does Form` in the class declaration

  * each public attribute such as `has Str $.email` declares a form input

  * attribute traits such as `is email` control the form behaviour

  * the trait `is required` is a regular class trait, and also marks the input

  * see below for details on `is validated(...)` and other traits

  * `novalidate` is set for the browser, since validation is done on the server

Form Routes:

  * `method form-routes {}` is called by `site` to set up the form post route

  * the form uses HTMX `"hx-post="$form-url" hx-swap=\"outerHTML\"`

  * `self.init` initializes the form HTML with styles, validations and so on

  * `self.controller` takes a `&handler`

  * the handler is called by Cro, form field data is passed in the `$form` parameter

Essential Methods:

  * `$form.is-valid` checks the form data against defined validations

  * `$form.form-data` returns the form data as a Hash

  * `self.finish` returns HTML to the client (for the HTMX swap)

  * `self.retry: $form` returns the partially validated form data with errors

  * `Contact.empty` prepares an empty form for the first use in a page (use instead of `Contact.new` to avoid validation errors)

Several other Air::Form methods are described below.

#### Form Consumption

Forms can then be used in an Air application like this:

```raku
my $contact-form = Contact.empty;  #repeated from above

use Air::Functional :BASE;
use Air::Base;

# define custom page properties
my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Red, Cro',

    nav => nav(
        logo    => safe('<a href="/">h<b>&Aring;</b>rc</a>'),
        widgets => [lightdark],
    ),

    footer      => footer p ['Aloft on ', b 'åir'],
);

# use the $contact-form in an Air website
sub SITE is export {
    site :register[$contact-form],
        index
            main
                content [
                    h2 'Contact Form';
                    $contact-form;
                ];
}
```

Note:

  * `:register[$contact-form]` tells the site to make the form route

  * `$contact-form` does the role `Taggable` so it can be used within Air::Functional code

DESCRIPTION
===========

`Air::Form`s do the `Cro::WebApp::Form` role. Therefore many of the features are set out in tne [Cro docs](https://cro.raku.org/docs/reference/cro-webapp-form).

Form Controls
-------------

Re-exported from `Cro::WebApp::Form`, per the [Cro docs](https://cro.raku.org/docs/reference/cro-webapp-form#Form_controls)

Traits are used to describe the kinds of controls that will be used on a form. The full set of HTML5 control types are available. Remember to check browser support for them is sufficient if needing to cater to older browsers. They mostly follow the HTML 5 control names, however in a few cases alternative names are offered for convenience. Taking care to use is email and is telephone is especially helpful for mobile users.

  * is password - a password input

  * is number - a number input (set implicitly if a numeric type is used)

  * is color - a color input

  * is date - a date input

  * is datetime-local / is datetime - a datetime-local input

  * is email - an email input

  * is month - a month input

  * is multiline - a multiline text input (rendered as a text area); can have the number of rows and columns specified as named arguments, such as is multiline(:5rows, :60cols)

  * is tel / is telephone - a tel input for a phone number

  * is search - a search input

  * is time - a time input

  * is url - a url input

  * is week - a week input

  * will select { ... } - a select input, offering the options specified in the block, for example will select { 1..5 }. If the sigil of the attribute is @, then it will render a multi-select box. While self is not available in such a trait, it is passed as the topic of the block, so one can write a method get-options() { ... } and then do will select { .get-options }. Note that currently there is no assistance with handling situations where the options should depend on another form field.

  * is file - a file upload input; the attribute will be populated with an instance of Cro::HTTP::Body::MultiPartFormData::Part, which has properties filename, body-blob (binary upload) ond body-text (decodes the body-blob to a Str)

  * is hidden - a hidden input There is no trait for checkboxes; use the Bool type instead.

### Labels, help texts, and placeholders

By default, the label for the control is formed by:

Taking the attribute name Replacing each - with a space Calling tclc to title case it

Use the `is label('Name')` trait in order to explicitly set a label.

For text inputs, one can also set a placeholder using the is placeholder('Text') trait. This text is rendered in the textbox prior to the user filling it.

Finally, one may use the `is help('...')` trait in order to provide help text. This is displayed beneath the form field.

Validation
----------

```raku
our %va = (
text     => ( /^ <[A..Za..z0..9\s.,_#-]>+ $/,
              'In text, only ".,_-#" punctuation characters are allowed' ),
name     => ( /^ <[A..Za..z.'-]>+ $/,
              'In a name, only ".-\'" punctuation characters are allowed' ),
names     => ( /^ <[A..Za..z\s.'-]>+ $/,
               'In names, only ".-\'" punctuation characters are allowed' ),
words    => ( /^ <[A..Za..z\s]>+ $/,
              'In words, only text characters are allowed' ),
notes    => ( /^ <[A..Za..z0..9\s.,:;_#!?()%$£-]>+ $/,
              'In notes, only ".,:;_-#!?()%$£" punctuation characters are allowed' ),
postcode => ( /^ <[A..Za..z0..9\s]>+ $/,
              'In postcode, only alphanumeric characters are allowed' ),
url      => ( /^ <[a..z0..9:/.-]>+ $/,
              'Only valid urls are allowed' ),
tel      => ( /^ <[0..9+()\s#-]>+ $/,
              'Only valid tels are allowed' ),
email    => ( /^ <[a..zA..Z0..9._%+-]>+ '@' <[a..zA..Z0..9.-]>+ '.' <[a..zA..Z]> ** 2..6 $/,
              'Only valid email addresses are allowed' ),
password => ( ( /^ <[A..Za..z0..9!@#$%^&*()\-_=+{}\[\]|:;"'<>,.?/]> ** 8..* $/ & / <[A..Za..z]> / & /<[0..9]> /),
              'Passwords must have minimum 8 characters with at least one letter and one number.' ),
);
```

### role Form does Cro::WebApp::Form does Taggable {}

This role has only private attrs to avoid creating form fields, get/set methods are provided instead.

The `%!form-attrs` are the same as `Cro::WebApp::Form`.

Air::Form currently supports these attrs:

  * `submit-button-text` - the text placed on the form submit button

  * `form-errors-text` - text that comes before form-level errors are rendered

Here is an example of customizing the submit button text (ie place this method in your Contact form (or whatever you choose to call it).

```raku
method do-form-attrs{
    self.form-attrs: {:submit-button-text('Save Contact Info')}
}
```

Air::Form code should avoid direct manipulation of the method and class styles detailed at [Cro docs](https://cro.raku.org/docs/reference/cro-webapp-form#Rendering) - instead override the `method styles {}`.

Development Roadmap
-------------------

The Air::Form module will be extended to perform full CRUD operations on a Red table by the selective grafting of Air::Component features over to Air::Form, for example:

  * `LOAD` method to load a form with values from a specific table row

  * `ADD` method to add a new table row with form values provided

  * `UPDATE` method to update table row with form value modifications

  * `DELETE` method to delete table row

Other potential features include:

  * a table list view [with row/col filters]

  * an item list view [with edit/save loop]

Technically it is envisaged that ::?CLASS.HOW does Cromponent::MetaCromponentRole; will be brought over from Cromponent with suitable controller methods. If you want to go model XXX does Form does Component, then there is a Taggable use conflict.

### has Str $!form-base

optionally specify form url base (with get/set methods)

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

optional form attrs (with get/set methods)

### method HTML

```raku
method HTML() returns Air::Functional::Markup(Any)
```

called when used as a Taggable, returns self.empty

### method HTML

```raku
method HTML(
    Form $form
) returns Air::Functional::Markup(Any)
```

when passed a $form field set, returns populated form

### method retry

```raku
method retry(
    Form $form
) returns Mu
```

return partially complete form

### method finish

```raku
method finish(
    Str $msg
) returns Mu
```

return message (typically used when self.is-valis

### method submit

```raku
method submit(
    &handler
) returns Mu
```

make a route to handle form submit

### method form-styles

```raku
method form-styles() returns Mu
```

get form-styles (may be overridden)

### method SCRIPT

```raku
method SCRIPT(
    $suffix = "*"
) returns Mu
```

get form-scripts, pass in a custom $suffix for required labels (may be overridden)

AUTHOR
======

Steve Roe <librasteve@furnival.net>

COPYRIGHT AND LICENSE
=====================

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


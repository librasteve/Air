=begin pod

=head1 Air::Form

This raku module is one of the core libraries of the raku B<Air> distribution.

It provides a Form class that integrates Air with the Cro::WebApp::Form module to provide a simple,yet rich declarative abstraction for web forms.

Air::Form uses Air::Functional for the Taggable role so that Forms can be employed within Air code. Air::Form is an alternative to Air::Component.

=head1 SYNOPSIS

An Air::Form is declared as a regular raku Object Oriented (OO) class. Specifically form input fields are set up via public attributes of the class ... C<has Str $.email> and so on. Check out the L<primer|https://docs.raku.org/language/objects> on raku OO basics.

=head4 Form Declaration

=begin code :lang<raku>
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
=end code

Declaration Class and Attributes:
=item C<use Air::Form> and then C<does Form> in the class declaration
=item each public attribute such as C<has Str $.email> declares a form input
=item attribute traits such as C<is email> control the form behaviour
=item the trait C<is required> is a regular class trait, and also marks the input
=item see below for details on C<is validated(...)> and other traits
=item C<novalidate> is set for the browser, since validation is done on the server

Form Routes:
=item C<method form-routes {}> is called by C<site> to set up the form post route
=item the form uses HTMX C<"hx-post="$form-url" hx-swap=\"outerHTML\">
=item C<self.init> initializes the form HTML with styles, validations and so on
=item C<self.submit> takes a C<&handler>
=item the handler is called by Cro, form field data is passed in the C<$form> parameter

Essential Methods:
=item C<$form.is-valid> checks the form data against defined validations
=item C<$form.form-data> returns the form data as a Hash
=item C<self.finish> returns HTML to the client (for the HTMX swap)
=item C<self.retry: $form> returns the partially validated form data with errors
=item C<Contact.empty> prepares an empty form for the first use in a page (use instead of C<Contact.new> to avoid validation errors)

Several other Air::Form methods are described below.

=head4 Form Consumption

Forms can then be used in an Air application like this:

=begin code :lang<raku>
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
=end code

Note:
=item C<:register[$contact-form]> tells the site to make the form route
=item C<$contact-form> does the role C<Taggable> so it can be used within Air::Functional code


=head1 DESCRIPTION

C<Air::Form>s do the C<Cro::WebApp::Form> role. Therefore many of the features are set out in tne L<Cro docs|https://cro.raku.org/docs/reference/cro-webapp-form>.

=head2 Form Controls

=para Re-exported from C<Cro::WebApp::Form>, per the L<Cro docs|https://cro.raku.org/docs/reference/cro-webapp-form#Form_controls>

Traits are used to describe the kinds of controls that will be used on a form. The full set of HTML5 control types are available. Remember to check browser support for them is sufficient if needing to cater to older browsers. They mostly follow the HTML 5 control names, however in a few cases alternative names are offered for convenience. Taking care to use is email and is telephone is especially helpful for mobile users.

=item is password - a password input
=item is number - a number input (set implicitly if a numeric type is used)
=item is color - a color input
=item is date - a date input
=item is datetime-local / is datetime - a datetime-local input
=item is email - an email input
=item is month - a month input
=item is multiline - a multiline text input (rendered as a text area); can have the number of rows and columns specified as named arguments, such as is multiline(:5rows, :60cols)

=item is tel / is telephone - a tel input for a phone number
=item is search - a search input
=item is time - a time input
=item is url - a url input
=item is week - a week input
=item will select { ... } - a select input, offering the options specified in the block, for example will select { 1..5 }. If the sigil of the attribute is @, then it will render a multi-select box. While self is not available in such a trait, it is passed as the topic of the block, so one can write a method get-options() { ... } and then do will select { .get-options }. Note that currently there is no assistance with handling situations where the options should depend on another form field.

=item is file - a file upload input; the attribute will be populated with an instance of Cro::HTTP::Body::MultiPartFormData::Part, which has properties filename, body-blob (binary upload) ond body-text (decodes the body-blob to a Str)

=item is hidden - a hidden input
There is no trait for checkboxes; use the Bool type instead.

=head3 Labels, help texts, and placeholders

By default, the label for the control is formed by:

Taking the attribute name
Replacing each - with a space
Calling tclc to title case it

Use the C<is label('Name')> trait in order to explicitly set a label.

For text inputs, one can also set a placeholder using the is placeholder('Text') trait. This text is rendered in the textbox prior to the user filling it.

Finally, one may use the C<is help('...')> trait in order to provide help text. This is displayed beneath the form field.

=head2 Validation

=begin code :lang<raku>
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
=end code

=head3 role Form does Cro::WebApp::Form does Taggable {}

=para This role has only private attrs to avoid creating form fields, get/set methods are provided instead.

=para The C<%!form-attrs> are the same as C<Cro::WebApp::Form>.

=para Air::Form currently supports these attrs:

=item C<submit-button-text> - the text placed on the form submit button
=item C<form-errors-text> - text that comes before form-level errors are rendered

=para Here is an example of customizing the submit button text (ie place this method in your Contact form (or whatever you choose to call it).

=begin code :lang<raku>
method do-form-attrs{
    self.form-attrs: {:submit-button-text('Save Contact Info')}
}
=end code

=para Air::Form code should avoid direct manipulation of the method and class styles detailed at L<Cro docs|https://cro.raku.org/docs/reference/cro-webapp-form#Rendering> - instead override the C<method styles {}>.

=head2 Development Roadmap

=para The Air::Form module will be extended to perform full CRUD operations on a Red table by the selective grafting of Air::Component features over to Air::Form, for example:

=item C<LOAD> method to load a form with values from a specific table row
=item C<ADD> method to add a new table row with form values provided
=item C<UPDATE> method to update table row with form value modifications
=item C<DELETE> method to delete table row

=para Other potential features include:

=item a table list view [with row/col filters]
=item an item list view [with edit/save loop]

=para Technically it is envisaged that ::?CLASS.HOW does Cromponent::MetaCromponentRole; will be brought over from Cromponent with suitable controller methods. If you want to go model XXX does Form does Component, then there is a Taggable use conflict.

=end pod

use Air::Functional :CRO;

use Cro::WebApp::Form;
use Cro::WebApp::Template;
use Cro::WebApp::Template::Repository;
use Cro::HTTP::Router;

constant %va = (
text     => ( /^ <[A..Za..z0..9\s.,_#-]>+ $/,
              'In text, only .,_-# punctuation characters are allowed' ),
name     => ( /^ <[A..Za..z.'-]>+ $/,
              'In a name, only .-\' punctuation characters are allowed' ),
names    => ( /^ <[A..Za..z\s.'-]>+ $/,
               'In names, only .-\' punctuation characters are allowed' ),
words    => ( /^ <[A..Za..z\s]>+ $/,
              'In words, only text characters are allowed' ),
notes    => ( /^ <[A..Za..z0..9\s.,:;_#!?()%$£'"-]>+ $/,
              'In notes, only .,:;_-#!?()%$£\'" punctuation characters are allowed' ),
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

role Form does Cro::WebApp::Form does Taggable {
    #| optionally specify form url base (with get/set methods)
    has Str  $!form-base = '';
    multi method form-base         {$!form-base}
    multi method form-base($value) {$!form-base = $value}

    #| get url safe name of class doing Form role
    method form-name { ::?CLASS.^name.subst('::','-').lc }

    #| get url (ie base/name)
    method form-url(--> Str) {
        do with self.form-base { "$_/" } ~ self.form-name
    }

    #| optional form attrs (with get/set methods)
    has %!form-attrs;
    multi method form-attrs     { %!form-attrs }
    multi method form-attrs(%h) { %!form-attrs{.key} = .value for %h }

    method init {
        self.do-form-styles;
        self.?do-form-scripts;
        self.do-form-defaults;
        self.?do-form-attrs;
        self.do-form-tmpl;
    }

    my $formtmp //= Q|%FORM-STYLES%<&form( .form, %FORM-ATTRS% )>|;

    method do-form-styles {
        $formtmp .= subst: /'%FORM-STYLES%'/, self.form-styles
    }

    method do-form-defaults {
        %!form-attrs = (
            submit-button-text     => 'Submit ' ~ ::?CLASS.^name,
            invalid-feedback-class => 'invalid-feedback-class',
            form-errors-class      => 'form-errors-class',
        )
    }

    method do-form-tmpl {
        $formtmp .= subst: /'%FORM-ATTRS%'/,
            self.form-attrs.map({":{.key}('{.value}')"}).join(',')
    }

    sub adjust($form-html, $form-url) {
        $form-html.subst(
            / 'method="post"' /, "hx-post=\"$form-url\" hx-swap=\"outerHTML\" novalidate"
        )
    }

    #| called when used as a Taggable, returns self.empty
    multi method HTML(--> Markup()) {
        parse-template($formtmp)
            andthen .render( {form => self.empty} ).&adjust(self.form-url);
    }

    #| when passed a $form field set, returns populated form
    multi method HTML(Form $form --> Markup()) {
        parse-template($formtmp)
            andthen .render( {:$form} ).&adjust(self.form-url)
    }

    #| return partially complete form
    method retry(Form $form) is export {   #!
        content 'text/plain', self.HTML($form)
    }

    #| return message (typically used when self.is-valis
    method finish(Str $msg) {
        content 'text/plain', $msg
    }

    #| make a route to handle form submit
    method submit(&handler) {
        post -> Str $ where self.form-url, {
            form-data &handler;
        }
    }

    #| get form-styles (may be overridden)
    method form-styles { q:to/END/
        <style>
            input[required] {
                border: calc(var(--pico-border-width) * 2) var(--pico-border-color) solid;
            }
            .invalid-feedback-class {
                margin-top: -10px;
                margin-bottom: 10px;
                color: var(--pico-del-color);
            }
            .form-errors-class > * > li {
                color: var(--pico-del-color);
            }
        </style>
        END
    }

    #| get form-scripts, pass in a custom $suffix for required labels (default '*')
    method SCRIPT($suffix = '*') {
        my $javascript = q:to/END/;

            function appendRequiredSuffixToLabels() {
                const requiredInputs = document.querySelectorAll("input[required]");

                requiredInputs.forEach(input => {
                    const id = input.id;
                    if (!id) return; // skip inputs without an ID

                    const label = document.querySelector(`label[for="${id}"]`);
                    if (label && !label.textContent.includes("(required)")) {
                        label.textContent += "%SUFFIX%";
                    }
                });
            }

            function scrollFormErrorsIntoView(evt) {
                //console.log('htmx:afterSwap fired', evt);
                const errorDiv = evt.target.querySelector('.form-errors-class');
                if (errorDiv && errorDiv.innerText.trim() !== '') {
                    errorDiv.focus();
                    errorDiv.scrollIntoView({ behavior: 'smooth', block: 'center' });
                }
            }

            document.addEventListener('htmx:afterSwap', function(evt) {
                scrollFormErrorsIntoView(evt);
                appendRequiredSuffixToLabels();
            });

            document.addEventListener("DOMContentLoaded", function() {
                appendRequiredSuffixToLabels();
            });
            END

        $javascript ~~ s:g/'%SUFFIX%'/$suffix/;
        $javascript;
    }

}

# Re-export is traits

multi trait_mod:<is>(Attribute:D $attr, :$label! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$label)
}
multi trait_mod:<is>(Attribute:D $attr, :$placeholder! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$placeholder)
}
multi trait_mod:<is>(Attribute:D $attr, :$help! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$help)
}
multi trait_mod:<is>(Attribute:D $attr, :$hidden! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$hidden)
}
multi trait_mod:<is>(Attribute:D $attr, :$file! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$file)
}
multi trait_mod:<is>(Attribute:D $attr, :$password! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$password)
}
multi trait_mod:<is>(Attribute:D $attr, :$number! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$number)
}
multi trait_mod:<is>(Attribute:D $attr, :$color! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$color)
}
multi trait_mod:<is>(Attribute:D $attr, :$date! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$date)
}
multi trait_mod:<is>(Attribute:D $attr, :datetime(:$datetime-local)! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$datetime-local)
}
multi trait_mod:<is>(Attribute:D $attr, :$email! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$email)
}
multi trait_mod:<is>(Attribute:D $attr, :$month! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$month)
}
multi trait_mod:<is>(Attribute:D $attr, :telephone(:$tel)! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$tel)
}
multi trait_mod:<is>(Attribute:D $attr, :$search! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$search)
}
multi trait_mod:<is>(Attribute:D $attr, :$time! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$time)
}
multi trait_mod:<is>(Attribute:D $attr, :$url! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$url)
}
multi trait_mod:<is>(Attribute:D $attr, :$week! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$week)
}
multi trait_mod:<is>(Attribute:D $attr, :$multiline! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$multiline)
}
multi trait_mod:<is>(Attribute:D $attr,  Int :min-length(:$minlength)! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :min-length(:$minlength))
}
multi trait_mod:<is>(Attribute:D $attr,  Int :max-length(:$maxlength)! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :max-length(:$maxlength))
}
multi trait_mod:<is>(Attribute:D $attr, Real :$min! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$min)
}
multi trait_mod:<is>(Attribute:D $attr, Real :$max! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$max)
}
multi trait_mod:<will>(Attribute:D $attr, &block, :$select! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<will>($attr, :$select)
}
multi trait_mod:<is>(Attribute:D $attr, :$validated! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<will>($attr, :$validated)
}


=begin pod
=head1 AUTHOR

Steve Roe <librasteve@furnival.net>


=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
=end pod

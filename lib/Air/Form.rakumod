=begin pod

=head1 Air::Form

This raku module is one of the core libraries of the raku B<Air> distribution.

It provides a Form class that integrates Air with the Cro::WebApp::Form module to provide a simple,yet rich declarative abstraction for web forms.

Air::Form uses Air::Functional for the FormTag role so that Forms can be employed within Air code. Air::Form is an alternative to Air::Component.

=head1 SYNOPSIS

The synopsis is split so that each part can be annotated.

=head3 Page

=para Here we start with a simple custom index page, same as a non-form app. [Check out the Base.md docs for more on this].

=begin code :lang<raku>
use Air::Functional :BASE;
use Air::Base;
use Air::Form;

my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Red, Cro',

    nav => nav(
        logo    => safe('<a href="/">h<b>&Aring;</b>rc</a>'),
        widgets => [lightdark],
    ),

    footer      => footer p ['Aloft on ', b 'åir'],
);
=end code

Key features shown are:
=item the use statements are similar to a non-form app, now also with C<use Air::Form>
=item the lightdark widget is also applicable to Form styling

=head3 Form

=para An Air::Form is defined declaratively via the standard raku Object Oriented (OO) syntax. Specifically form input fields are set us as public attributes of the class ... C<has Str $.email> and so on.

=begin code :lang<raku>
class Contact does Form {
    has Str    $.first-names is validated(%va<names>)  is required;
    has Str    $.last-name   is validated(%va<name>)   is required;
    has Str    $.email       is validated(%va<email>)  is email;

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

Key features shown are:
=item Form input properties are set by traits on the public attrs - for example C<is email> specifies that this input field wants an email address, C<is required> specifies that this field must have a value and so on.
=item We C<use Air::Form;> to load the C<role Form {...}> and then apply it to our new form class with C<does Form>
=item The class name is used as the name of the form
=item Each input field name is converted to a label for the form by splitting on a C<-> and then applying to the words C<tclc> (title case, lower case)
=item Input field traits are imported directly from the C<Cro::WebApp::Form> module and follow the relevant Cro documentation page L<Air::Play|https://raku.land/zef:librasteve/Air::Play> iamerejh

=head3 Site

=begin code :lang<raku>
sub SITE is export {
    site :components[$contact-form], :theme-color<blue>, :bold-color<green>,
        index
            main
                content [
                    h2 'Contact Form';
                    $contact-form;
                ];
}
=end code

Key features shown are:
=item application of the C<:BASE> modifier on C<use Air::Functional> to avoid namespace conflict
=item definition of table content as a Hash C<%data> of Pairs C<:name[[2D Array],]>
=item assignment of two functional C<content> tags and their arguments to vars
=item assignment of a functional C<external> tag with attrs to a var

=head3 Page

=para The template of an Air website (header, nav, logo, footer) is applied by making a custom C<page> ... here C<index> is set up as the template page. In this SPA example navlinks dynamically update the same page content via HTMX, so index is only used once, but in general multiple instances of the template page can be cookie cuttered. Any number of page template can be set up in this way and can reuse custom Components.

=begin code :lang<raku>
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
=end code

Key features shown are:
=item set the C<index> functional tag as a modified Air::Base C<page> tag
=item use of C<.assuming> for functional code composition
=item use of => arrow Pair syntax to set a custom page theme with title, description, nav, footer
=item use of C<nav> functional tag and passing it attrs of the C<NavItems> defined
=item use of C<:$Content1> Pair syntax to pass in both nav link text (ie the var name as key) and value
=item Nav routes are automagically generated and HTMX attrs are used to swap in the content inners
=item use of C<safe> functional tag to suppress HTML escape
=item use of C<lightdark> widget to toggle theme according to system and user preference

=head3 Site

=begin code :lang<raku>
sub SITE is export {
    site
        index
            main $Content1
}
=end code

Key features shown are:
=item use of C<site> functional tag - that sets up the site Cro routes and Pico SASS theme
=item C<site> takes the C<index> page as positional argument
=item C<index> takes a C<main> functional tag as positional argument
=item C<main> takes the initial content

=head1 DESCRIPTION

Each feature of Air::Form is set out below:
=end pod

use Air::Functional :CRO;

use Cro::WebApp::Form;
use Cro::WebApp::Template;
use Cro::WebApp::Template::Repository;

use Cro::HTTP::Router;

=head2 Basics

=para A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient set of elements for the Page Tags.

=head2 Form does not do Air::Component due to namespace overlap

=head2 Form is never functional (since this parent class never has fields)

=head2 https://cro.raku.org/docs/reference/cro-webapp-form


#| provides some standard validation checks
#| checks can be overridden in user code
our %va = (
    text     => ( /^ <[A..Za..z0..9\s.,_#-]>+ $/,
                'In text, only ".,_-#" punctuation characters are allowed' ),
    name     => ( /^ <[A..Za..z.'-]>+ $/,
                'In a name, only only ".-\'" punctuation characters are allowed' ),
    names     => ( /^ <[A..Za..z\s.'-]>+ $/,
                'In names, only only ".-\'" punctuation characters are allowed' ),
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


role Form does Cro::WebApp::Form does FormTag {
    #| optionally specify form url base
    has Str  $!form-base = '';
    multi method form-base         {$!form-base}
    multi method form-base($value) {$!form-base = $value}

    #| get url safe name of class doing Form role
    method form-name { ::?CLASS.^name.subst('::','-').lc }

    #| get url (ie base/name)
    method form-url(--> Str) {
        do with self.form-base { "$_/" } ~ self.form-name
    }

    #| optional form attrs for prelude.crotmp settings
    has %!form-attrs;
    multi method form-attrs     { %!form-attrs }
    multi method form-attrs(%h) { %!form-attrs{.key} = .value for %h }

    method init {
        self.do-form-styles;
        self.do-form-scripts;
        self.do-form-defaults;
        self.?do-form-attrs;
        self.do-form-tmpl;
    }

    my $formtmp = Q|%FORM-STYLES%<&form( .form, %FORM-ATTRS% )>%FORM-SCRIPTS%|;

    method do-form-styles {
        $formtmp .= subst: /'%FORM-STYLES%'/, self.form-styles
    }

    method do-form-scripts {
        $formtmp .= subst: /'%FORM-SCRIPTS%'/, self.form-scripts
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
            / 'method="post"' /, "hx-post=\"$form-url\" novalidate"
        )
    }

    multi method HTML(--> Markup()) {
        parse-template($formtmp)
            andthen .render( {form => self.empty} ).&adjust(self.form-url)
    }

    multi method HTML(Form $form --> Markup()) {
        parse-template($formtmp)
            andthen .render( {:$form} ).&adjust(self.form-url)
    }

    method retry(Form $form) is export {   #!
        content 'text/plain', self.HTML($form)
    }

    method finish(Str $msg) {
        content 'text/plain', $msg
    }

    method controller(&handler) {
        post -> Str $ where self.form-url, {
            form-data &handler;
        }
    }

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

    method form-scripts($suffix = '*') {
        my $javascript = q:to/END/;
        <script>
            // scroll form errors into view
            document.body.addEventListener('htmx:afterSwap', function(evt) {
                if (evt.target.querySelector('form')) {
                    //console.log('htmx:afterSwap fired', evt);
                    const errorDiv = evt.target.querySelector('.form-errors-class');
                    if (errorDiv && errorDiv.innerText.trim() !== '') {
                        errorDiv.focus();
                        errorDiv.scrollIntoView({ behavior: 'smooth', block: 'center' });
                    }
                }
            });

            // mark labels of required inputs with *
            document.addEventListener("DOMContentLoaded", () => {
                const requiredInputs = document.querySelectorAll("input[required]");

                requiredInputs.forEach(input => {
                    const id = input.id;
                    if (!id) return; // skip inputs without an ID

                    const label = document.querySelector(`label[for="${id}"]`);
                    if (label && !label.textContent.includes("(required)")) {
                        label.textContent += "%SUFFIX%";
                    }
                });
            });
        </script>
        END

        $javascript.subst: /'%SUFFIX%'/, $suffix;
    }

}

=head2 re-export form class attribute `is` traits

#| Customize the label for the form field (without this, the attribute name will be used
#| to generate a label).
multi trait_mod:<is>(Attribute:D $attr, :$label! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$label)
}

#| Provide placeholder text for a form field.
multi trait_mod:<is>(Attribute:D $attr, :$placeholder! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$placeholder)
}

#| Provide help text for a form field.
multi trait_mod:<is>(Attribute:D $attr, :$help! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$help)
}

#| Indicate that this is a hidden form field
multi trait_mod:<is>(Attribute:D $attr, :$hidden! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$hidden)
}

#| Indicate that this is a file form field
multi trait_mod:<is>(Attribute:D $attr, :$file! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$file)
}

#| Indicate that this is a password form field
multi trait_mod:<is>(Attribute:D $attr, :$password! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$password)
}

#| Indicate that this is a number form field
multi trait_mod:<is>(Attribute:D $attr, :$number! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$number)
}

#| Indicate that this is a color form field
multi trait_mod:<is>(Attribute:D $attr, :$color! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$color)
}

#| Indicate that this is a date form field
multi trait_mod:<is>(Attribute:D $attr, :$date! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$date)
}

#| Indicate that this is a local date/time form field
multi trait_mod:<is>(Attribute:D $attr, :datetime(:$datetime-local)! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$datetime-local)
}

#| Indicate that this is an email form field
multi trait_mod:<is>(Attribute:D $attr, :$email! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$email)
}

#| Indicate that this is a month form field
multi trait_mod:<is>(Attribute:D $attr, :$month! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$month)
}

#| Indicate that this is a telephone form field
multi trait_mod:<is>(Attribute:D $attr, :telephone(:$tel)! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$tel)
}

#| Indicate that this is a search form field
multi trait_mod:<is>(Attribute:D $attr, :$search! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$search)
}

#| Indicate that this is a time form field
multi trait_mod:<is>(Attribute:D $attr, :$time! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$time)
}

#| Indicate that this is a URL form field
multi trait_mod:<is>(Attribute:D $attr, :$url! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$url)
}

#| Indicate that this is a week form field
multi trait_mod:<is>(Attribute:D $attr, :$week! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$week)
}

#| Indicate that this is a multi-line form field. Optionally, the number of
#| rows and cols can be provided.
multi trait_mod:<is>(Attribute:D $attr, :$multiline! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$multiline)
}

#| Set the minimum length of an input field
multi trait_mod:<is>(Attribute:D $attr,  Int :min-length(:$minlength)! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :min-length(:$minlength))
}

#| Set the maximum length of an input field
multi trait_mod:<is>(Attribute:D $attr,  Int :max-length(:$maxlength)! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :max-length(:$maxlength))
}

#| Set the minimum numeric value of an input field
multi trait_mod:<is>(Attribute:D $attr, Real :$min! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$min)
}

#| Set the maximum numeric value of an input field
multi trait_mod:<is>(Attribute:D $attr, Real :$max! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<is>($attr, :$max)
}

#| Provide code that will be run in order to produce the values to select from. Should
#| return a list of Pair objects, where the key is the selected value and the value is
#| the text to display. If non-Pairs are in the list, a Pair with the same key and value
#| will be formed from them.
multi trait_mod:<will>(Attribute:D $attr, &block, :$select! --> Nil) is export {
    Cro::WebApp::Form::trait_mod:<will>($attr, :$select)
}

#| Describe how a field is validated. Two arguments are expected to the
#| trait: something the value will be smart-matched against, and the
#| error message for if the validation fails.
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

=begin pod

=head1 Air::Form

This raku module is one of the core libraries of the raku B<Air> distribution.

It provides a Form class that integrates Air with the Cro::WebApp::Form module to provide a simple,yet rich declarative abstraction for web forms.

Air::Form uses Air::Functional for the FormTag role so that Forms can be employed within Air code. Air::Form is an alternative to Air::Component.

=head1 SYNOPSIS

The synopsis is split so that each part can be annotated.

=head3 Page

=para The template of an Air website (header, nav, logo, footer) is applied by making a custom C<page> ... here C<index> is set up as the template page. [Check out the Base.md docs for more on this].

=begin code :lang<raku>
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
=end code

Key features shown are:
=item the lightdark widget is applicable to Form styles

=head3 Form

=para An Air::Form is defined declaratively via the standard raku OO syntax, specifically form input fields are set by the public attributes of the class C<has Str $.email> and so on.

=begin code :lang<raku>
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
=end code

Key features shown are:
=item Form input properties are set by traits on the public attrs - for example C<is email> specifies that this input field wants an email address, C<is required> specifies that this field requires a value and so on.
=item We C<use Air::Form;> to load the C<role Form {...}> and then apply it to our new form class with C<does Form>
=item The class name is used as the name of the form
=item Each input field name is converted to a label for the form by splitting on a C<-> and then applying to the words C<tclc> (title case, lower case)
=item Input field traits are imported directly from the C<Cro::WebApp::Form> module and follow the relevant Cro documentation page L<Air::Play|https://raku.land/zef:librasteve/Air::Play> iamerejh

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
        self.do-form-defaults;
        self.?do-form-attrs;
        self.do-form-tmpl;
    }

    my $formtmp = Q|%FORM-STYLES%<&form( .form, %FORM-ATTRS% )>|;

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
             .invalid-feedback-class {
                margin-top: -10px;
                margin-bottom: 10px;
                color: var(--pico-del-color);
            }
             .form-errors-class > * > li {
                color: var(--pico-del-color);
            }
        </style>
        <script>
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
        </script>
        END
    }
}


=begin pod
=head1 AUTHOR

Steve Roe <librasteve@furnival.net>


=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
=end pod

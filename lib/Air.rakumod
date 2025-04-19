use v6.d;

unit module Air;

=begin pod

=head1 Air

Breathing life into the raku B<hArc stack> (HTMX, Air, Red, Cro).

B<Air> aims to be the purest possible expression of L<HTMX|https://htmx.org>.

B<hArc> websites are written in functional code. This puts the emphasis firmly onto the content and layout of the site,
rather than boilerplate markup that can often obscure the intention.

B<Air> is basically a set of libraries that produce HTML code and serve it using Cro.

The result is a concise, legible and easy-to-maintain website codebase.


=head1 SYNOPSIS

=begin code :lang<raku>
#!/usr/bin/env raku

use Air::Functional :BASE;
use Air::Base;

my &index = &page.assuming( #:REFRESH(1),
    title       => 'hÅrc',
    description => 'HTMX, Air, Red, Cro',
    footer      => footer p ['Aloft on ', b safe '&Aring;ir'],
);


my &planets = &table.assuming(
    :thead[["Planet", "Diameter (km)",
            "Distance to Sun (AU)", "Orbit (days)"],],
    :tbody[["Mercury",  "4,880", "0.39",  "88"],
           ["Venus"  , "12,104", "0.72", "225"],
           ["Earth"  , "12,742", "1.00", "365"],
           ["Mars"   ,  "6,779", "1.52", "687"],],
    :tfoot[["Average",  "9,126", "0.91", "341"],],
);


sub SITE is export {
    site #:bold-color<blue>,
        index
            main
                div [
                    h3 'Planetary Table';
                    planets;
                ]
}
=end code


=head1 GETTING STARTED

Install raku - eg. from L<rakubrew|https://rakubrew.org>, then:

=begin code
Install Air, Cro & Red
- zef install --/test cro
- zef install Red --exclude="pq:ver<5>"
- zef install Air

Run and view some examples
- git clone https://github.com/librasteve/Air-Play.git && cd Air-Play
- export WEBSITE_HOST="0.0.0.0" && export WEBSITE_PORT="3000"
- raku -Ilib service.raku
- browse to http://localhost:3000
=end code

Cro has many other options as documented at L<Cro|https://cro.raku.org> for deployment to a production server.


=head1 DESCRIPTION

Air is not a framework, but a set of libraries. Full control over the application loop is retained by the coder.

Air does not provide an HTML templating language, instead each HTML tag is written as a subroutine call where the argument is a list of C<@inners> and attributes are passed via the raku Pair syntax C<:name<value>>. L<Cro templates|https://cro.raku.org/docs/reference/cro-webapp-template-syntax> are great if you would rather take the template approach.

Reusability is promoted by the structure of the libraries - individuals and teams can create and install your own libraries to encapsulate design themes, re-usable web components and best practice.

Air is comprised of three core libraries:

=item Air::Functional - wraps HTML tags as functions
=item Air::Base - a set of handy prebuilt components
=item Air::Component - make your own components

B<L<Air::Play|https://raku.land/zef:librasteve/Air::Play>> is a companion raku module with various B<Air> website examples.

The Air documentation is at L<https://librasteve.github.io/Air>


=head1 TIPS & TRICKS

=item When debugging, use the raku C<note> sub to out put debuggin info to stderr (ie in the Cro Log stream)
=item When passing a 2D Array to a tag function, make sure that there is a trailing comma C<:tbody[["Mercury",  "4,880", "0.39",  "88"],]>
=item An error message like I<insufficient arguments> is often caused by separating two tag functions with a comma C<,> instead of a semicolon C<;>
=item In development set CRO_DEV=1 in the L<environment|https://cro.services/docs/reference/cro-webapp-template#Template_auto-reload>


=head1 AUTHOR

Steve Roe <librasteve@furnival.net>

The `Air::Component` module provided is based on an early version of the raku `Cromponent` module, author Fernando Corrêa de Oliveira <fco@cpan.com>, however unlike Cromponent this module does not use Cro Templates.


=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

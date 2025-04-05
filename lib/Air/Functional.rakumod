=begin pod

=head1 Air::Functional

This raku module is one of the core libraries of the raku B<Air> distribution.

It exports HTML tags as raku subs that can be composed as functional code within a raku program.

It replaces the HTML::Functional module by the same author.


=head1 SYNOPSIS

Here's a regular HTML page:

=begin code :lang<html>
<div class="jumbotron">
  <h1>Welcome to Dunder Mifflin!</h1>
  <p>
    Dunder Mifflin Inc. (stock symbol <strong>DMI</strong>) is
    a micro-cap regional paper and office supply distributor with
    an emphasis on servicing small-business clients.
  </p>
</div>
=end code

And here is the same page using Air::Functional:

=begin code :lang<raku>
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
=end code


=head1 DESCRIPTION

Key features shown are:
=item HTML tags are implemented as raku functions: C<div, h1, p> and so on
=item parens C<()> are optional in raku function calls
=item HTML tag attributes are passed as raku named arguments
=item HTML tag inners (e.g. the Str in C<h1>) are passed as raku positional arguments
=item the raku Pair syntax is used for each attribute i.e. C<:name<value>>
=item multiple C<@inners> are passed as a literal Array C<[]> – div contains h1 and p
=item the raku parser looks at functions from the inside out, so C<strong> is evaluated before C<p>, before C<div> and so on
=item semicolon C<;> is used as the Array literal separator to suppress nesting of tags

Normally the items in a raku literal Array are comma C<,> separated. Raku precedence considers that C<div [h1 x, p y];> is equivalent to C<div( h1(x, p(y) ) );> … so the p tag is embedded within the h1 tag unless parens are used to clarify. But replace the comma C<,> with a semi colon C<;> and predisposition to nest is reversed. So C<div [h1 x; p y];> is equivalent to C<div( h1(x), p(y) )>. Boy that Larry Wall was smart!

The raku example also shows the power of the raku B<Q-lang> at work:

=item double quotes C<""> interpolate their contents
=item curlies denote an embedded code block C<"{fn x}">
=item tilde C<~> is for Str concatenation
=item the heredoc form C<q:to/END/;> can be used for verbatim text blocks

This module generally returns C<Str> values to be string concatenated and included in an HTML content/text response.

It also defines a programmatic API for the use of HTML tags for raku functional coding and so is offered as a basis for sister modules that preserve the API, but have a different technical implementation such as a MemoizedDOM.

=end pod

unit class Air::Functional;

use HTML::Escape;

=head2 Declare Constants

=para All of the HTML tags listed at L<https://www.w3schools.com/tags/default.asp> are covered ...

constant @all-tags = <a abbr address area article aside audio b base bdi bdo blockquote body br
    button canvas caption cite code col colgroup data datalist dd del details dfn dialog div
    dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup
    hr html i iframe img input ins kbd label legend li link main map mark menu meta meter nav
    noscript object ol optgroup option output p param picture pre progress q rp rt ruby s samp
    script search section select small source span strong style sub summary sup svg table tbody
    td template textarea tfoot th thead time title tr track u ul var video wbr>;

=para ... of which empty (Singular) tags from L<https://www.tutsinsider.com/html/html-empty-elements/>

constant @singular-tags = <area base br col embed hr img input link meta param source track wbr>;

=head2 HTML Escape

#| Explicitly HTML::Escape inner text
sub escape(Str:D() $s --> Str) is export {
    escape-html($s)
}

#| also a shortcut ^ prefix
multi prefix:<^>(Str:D() $s --> Str) is export {
    escape-html($s)
}

=head2 Tag Rendering

role   Tag            is export(:MANDATORY) {...}
enum   TagType        is export(:MANDATORY) <Singular Regular>;

=head3 role Attr is Str {} - type for Attribute values, use Attr() for coercion

role   Attr    is Str is export(:MANDATORY) {}

=head3 subset Inner where Str | Tag | Markup - type union for Inner elements

role   Markup  is Str {}
subset Inner   where Str | Tag | Markup;

=head2 role Tag [TagType Singular|Regular] {} - basis for Air functions

role   Tag[TagType $tag-type?] is export(:MANDATORY) {
    has Str    $.name = ::?CLASS.^name.lc;

    #| can be provided with attrs
    has Attr() %.attrs is rw;

    #| can be provided with inners
    has Inner  @.inners;

    #| ok to call .new with @inners as Positional
    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, :%attrs
    }

    #| provides default .HTML method used by tag render
    multi method HTML {
        samewith $tag-type
    }
    multi method HTML(Singular) {
        do-singular-tag( $!name, |%.attrs )
    }
    multi method HTML(Regular) {
        do-regular-tag( $!name, @.inners, |%.attrs )
    }
}

=head3 Low Level API

=para This level is where users want to mess around with the parts of a tag for customizations

#| convert from raku Pair syntax to HTML tag attributes
sub attrs(%h --> Str) is export {
    #| Discard attrs with False or undefined values
    my @discards = %h.keys.grep: {
        %h{$_} === False     ||
        %h{$_}.defined.not
    };
    @discards.map: { %h{$_}:delete };

    #| Special case Bool attrs eg <input type="checkbox" checked>
    my @attrs = %h.keys.grep: { %h{$_} eq 'True' };
    @attrs.map: { %h{$_}:delete };

    #| Attrs as key-value pairs
    @attrs.append: %h.map({.key ~ '="' ~ .value ~ '"'});
    @attrs ?? ' ' ~ @attrs.join(' ') !! '';
}

#| open a custom tag
sub opener($tag, *%h -->Str) is export {
    "\n" ~ '<' ~ $tag ~ attrs(%h) ~ '>'
}

multi sub render-tag(Tag    $inner) {
    $inner.HTML
}
multi sub render-tag(Markup $inner) {
    $inner
}
multi sub render-tag(Str()  $inner) {
    escape-html($inner)
}

#| convert from an inner list to HTML tag inner string
sub inner(@inners --> Str) is export {
    given @inners {
        when * == 0 {   ''   }
        when * == 1 { .first.&render-tag }
        when * >= 2 { .map(*.&render-tag).join }
    }
}

#| close a custom tag (unset :!nl to suppress the newline)
sub closer($tag, :$nl --> Str) is export {
    ($nl ?? "\n" !! '') ~ '</' ~ $tag ~ '>'
}

=head3 High Level API

=para This level is for general use from custom tags that behave like regular/singular tags

#| do a regular tag (ie a tag with @inners)
sub do-regular-tag(Str $tag, *@inners, *%h --> Markup() ) is export(:MANDATORY)  {
    my $nl = @inners >= 2;
    opener($tag, |%h) ~ inner(@inners) ~ closer($tag, :$nl)
}

#| do a singular tag (ie a tag without @inners)
sub do-singular-tag(Str $tag, *%h --> Markup() ) is export(:MANDATORY)  {
    "\n" ~ '<' ~ $tag ~ attrs(%h) ~ ' />'
}

=head2 Tag Export Options

=para Exports all the tags programmatically

my @regular-tags = (@all-tags (-) @singular-tags).keys;  #Set difference (-)

#| export all HTML tags
#| viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing
my package EXPORT::DEFAULT {
    for @regular-tags -> $tag {
        OUR::{'&' ~ $tag} := sub (*@inners, *%h) { do-regular-tag( "$tag", @inners, |%h ) }
    }

    for @singular-tags -> $tag {
        OUR::{'&' ~ $tag} := sub (*%h) { do-singular-tag( "$tag", |%h ) }
    }
}

my @exclude-cro = <header table template>;

my @regular-cro  = @regular-tags.grep:  { $_ ∉ @exclude-cro };
my @singular-cro = @singular-tags.grep: { $_ ∉ @exclude-cro };

#| use :CRO as package to avoid collisions with Cro::Router names
my package EXPORT::CRO {
    for @regular-cro -> $tag {
        OUR::{'&' ~ $tag} := sub (*@inners, *%h) { do-regular-tag( "$tag", @inners, |%h ) }
    }

    for @singular-cro -> $tag {
        OUR::{'&' ~ $tag} := sub (*%h) { do-singular-tag( "$tag", |%h ) }
    }
}


my @exclude-base  = <dl dd dt section article aside time a body main header content footer nav table grid>;

my @regular-base  = @regular-tags.grep:  { $_ ∉ @exclude-base };
my @singular-base = @singular-tags.grep: { $_ ∉ @exclude-base };

#| use :BASE as package to avoid collisions with Cro::Router, Air::Base & Air::Component names
#| NB the HTML description list tags <dl dd dt> are also excluded to avoid conflict with the raku `dd` command
my package EXPORT::BASE {
    for @regular-base -> $tag {
        OUR::{'&' ~ $tag} := sub (*@inners, *%h) { do-regular-tag( "$tag", @inners, |%h ) }
    }

    for @singular-base -> $tag {
        OUR::{'&' ~ $tag} := sub (*%h) { do-singular-tag( "$tag", |%h ) }
    }
}

=begin pod
=head1 AUTHOR

Steve Roe <librasteve@furnival.net>


=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
=end pod
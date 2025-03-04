unit class Air::Functional;

use HTML::Escape;

##### Declare Constants #####

#| viz. https://www.w3schools.com/tags/default.asp
constant @all-tags = <a abbr address area article aside audio b base bdi bdo blockquote body br
    button canvas caption cite code col colgroup data datalist dd del details dfn dialog div
    dl dt em embed fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6 head header hgroup
    hr html i iframe img input ins kbd label legend li link main map mark menu meta meter nav
    noscript object ol optgroup option output p param picture pre progress q rp rt ruby s samp
    script search section select small source span strong style sub summary sup svg table tbody
    td template textarea tfoot th thead time title tr track u ul var video wbr>;

#| of which "empty" / "singular" tags from https://www.tutsinsider.com/html/html-empty-elements/
constant @singular-tags = <area base br col embed hr img input link meta param source track wbr>;

##### HTML Escape #####

multi prefix:<^>(Str:D() $s) is export {
    escape-html($s)
}

sub escape(Str:D() $s) is export {
    escape-html($s)
}

##### Tag Rendering #####

# the Escaped class is used to "label" html snippets as "not text" and thus disable HTML escape
class Tag is Str is export(:MANDATORY) {}

sub attrs(%h) is export {
    #| Discard attrs with False or undefined values
    my @discards = %h.keys.grep: {
        %h{$_} === False     ||
        %h{$_}.defined.not
    };
    @discards.map: { %h{$_}:delete };

    #| Bool attrs eg <input type="checkbox" checked>
    my @attrs = %h.keys.grep: { %h{$_} === True };
    @attrs.map: { %h{$_}:delete };

    #| Attrs as key-value pairs
    @attrs.append: %h.map({.key ~ '="' ~ .value ~ '"'});
    @attrs ?? ' ' ~ @attrs.join(' ') !! '';
}

sub opener($tag, *%h) is export {
    "\n" ~ '<' ~ $tag ~ attrs(%h) ~ '>'
}

multi sub trender(Str $inner) {
    escape-html($inner)
}
multi sub trender(Tag $inner) {
    $inner.?HTML // $inner
}

sub inner(@inners) is export {
    given @inners {
        when * == 0 {   ''   }
        when * == 1 { .first.&trender }
        when * >= 2 { .map(*.&trender).join }
    }
}

sub closer($tag, :$nl) is export(:MANDATORY)  {
    ($nl ?? "\n" !! '') ~
    '</' ~ $tag ~ '>'
}

sub do-regular-tag($tag, *@inners, *%h --> Tag() ) is export(:MANDATORY)  {
    my $nl = @inners >= 2;
    opener($tag, |%h) ~ inner(@inners) ~ closer($tag, :$nl)
}

sub do-singular-tag($tag, *%h --> Tag() ) is export(:MANDATORY)  {
    "\n" ~ '<' ~ $tag ~ attrs(%h) ~ ' />'
}

##### Tag Export #####

# put in all the tags programmatically
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

my @regular-tags = (@all-tags (-) @singular-tags).keys;  #Set difference (-)

my package EXPORT::DEFAULT {
    for @regular-tags -> $tag {
        OUR::{'&' ~ $tag} := sub (*@inners, *%h) { do-regular-tag( "$tag", @inners, |%h ) }
    }

    for @singular-tags -> $tag {
        OUR::{'&' ~ $tag} := sub (*%h) { do-singular-tag( "$tag", |%h ) }
    }
}

# exclude tags that overlap with Cro & Air::Component
my @exclude-cro = <header table template>;

my @regular-cro  = @regular-tags.grep:  { $_ ∉ @exclude-cro };
my @singular-cro = @singular-tags.grep: { $_ ∉ @exclude-cro };

my package EXPORT::CRO {
    for @regular-cro -> $tag {
        OUR::{'&' ~ $tag} := sub (*@inners, *%h) { do-regular-tag( "$tag", @inners, |%h ) }
    }

    for @singular-cro -> $tag {
        OUR::{'&' ~ $tag} := sub (*%h) { do-singular-tag( "$tag", |%h ) }
    }
}

# exclude tags that overlap with Cro & Air::Component & Base
my @exclude-base  = <a body main header content footer nav table>;

my @regular-base  = @regular-tags.grep:  { $_ ∉ @exclude-base };
my @singular-base = @singular-tags.grep: { $_ ∉ @exclude-base };

my package EXPORT::BASE {
    for @regular-base -> $tag {
        OUR::{'&' ~ $tag} := sub (*@inners, *%h) { do-regular-tag( "$tag", @inners, |%h ) }
    }

    for @singular-base -> $tag {
        OUR::{'&' ~ $tag} := sub (*%h) { do-singular-tag( "$tag", |%h ) }
    }
}

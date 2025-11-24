unit module Tags;

sub exports-air-base-tags is export {<Script Style Meta Title Link Internal External Content A Button Section Article Aside Time Spacer Safe>}

use Air::Functional :MANDATORY;

=head2 Air::Base::Tags

=para Air::Functional converts all HTML tags into raku functions. Air::Base overrides a subset of these HTML tags, providing them both as C<roles> and functions.

=para Air::Base::Tags often embed some code to provide behaviours. This can be simple - C<role Script {}> just marks JavaScript as exempt from HTML Escape. Or complex - C<role Body {}> has C<Header>, C<Main> and C<Footer> attributes with certain defaults and constructors.

=para Combine these tags in the same way as the overall layout of an HTML webpage. Note that they hide complexity to expose only relevant information to the fore. Override them with your own roles and classes to implement your specific needs.

=head2 Header Tags

=para These HTML Tags are re-published for Air::Base since we need to have roles declared for types anyway. Some have a few minor "improvements" via the setting of attribute defaults.

=head3 role Script does Tag[Regular] {...}

role Script  does Tag[Regular] is export {
    #| no html escape
    multi method HTML {
        opener($.name, |%.attrs) ~
        ( @.inners.first // '' ) ~
        closer($.name)           ~ "\n"
    }
}

=head3 role Style  does Tag[Regular] {...}

role Style   does Tag[Regular] is export  {
    #| no html escape
    multi method HTML {
        opener($.name, |%.attrs)  ~
        @.inners.first            ~
        closer($.name)            ~ "\n"
    }
}

=head3 role Meta   does Tag[Singular] {}

role Meta    does Tag[Singular] is export {}

=head3 role Title  does Tag[Regular]  {}

role Title   does Tag[Regular] is export {}

=head3 role Link   does Tag[Regular]  {}

role Link    does Tag[Singular] is export {}

=head2 NavItem Tags

=para The are newly construed Air Tags that are used in the Nav class.

=head3 role External  does Tag[Regular] {...}

role External does Tag[Regular] is export {
    has Str $.label is rw = '';
    has %.others = {:target<_blank>, :rel<noopener noreferrer>};

    multi method HTML {
        my %attrs = |%.others, |%.attrs;
        do-regular-tag( 'a', [$.label], |%attrs )
    }
}

=head3 role Internal  does Tag[Regular] {...}

role Internal does Tag[Regular] is export {
    has Str $.label is rw = '';

    multi method HTML {
        do-regular-tag( 'a', [$.label], |%.attrs )
    }
}

=head3 role Content does Tag[Regular] {}

role Content does Tag[Regular] is export {
    multi method HTML {
        my %attrs  = |%.attrs, :id<content>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head2 Semantic Tags

=para These are a mix of HTML Tags re-published (some with minor improvements) and of newly construed Air Tags for convenience. Generally they align with the Pico CSS semantic tags in use.

=head3 role A      does Tag[Regular] {}

role A       does Tag[Regular] is export  {}

=head3 role Button does Tag[Regular] {}

role Button  does Tag[Regular] is export {}

=head3 role Section   does Tag[Regular] {}

role Section does Tag[Regular] is export {}

=head3 role Article   does Tag[Regular] {}

role Article does Tag[Regular] is export {
    # Keep text ltr even when grid direction rtl
    multi method HTML {
        my %attrs = |%.attrs, :style("direction:ltr;");
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Aside     does Tag[Regular] {}

role Aside   does Tag[Regular] is export {
    method STYLE {
        q:to/END/
        /* Custom styles for aside layout */
        main {
            display: grid;
            grid-template-columns: 3fr 1fr;
            gap: 20px;
        }
        aside {
            background-color: aliceblue;
            opacity: 0.9;
            padding: 20px;
            border-radius: 5px;
        }
        END
    }
}

=head3 role Time      does Tag[Regular] {...}

=para In HTML the time tag is typically of the form E<lt> time datetime="2025-03-13" E<gt> 13 March, 2025 E<lt> /time E<gt> . In Air you can just go time(:datetime E<lt> 2025-02-27 E<gt> ); and raku will auto format and fill out the inner human readable text.

role Time    does Tag[Regular] is export {
    use DateTime::Format;

    multi method HTML {
        my $dt = DateTime.new(%.attrs<datetime>);

                =para Optionally specify mode => [time | datetime], mode => date is default

        sub inner {
            given %.attrs<mode> {
                when     'time' { strftime('%l:%M%P', $dt) }
                when 'datetime' { strftime('%l:%M%P on %B %d, %Y', $dt) }
                default         { strftime('%B %d, %Y', $dt) }
            }
        }

        do-regular-tag( $.name, [inner], |%.attrs )
    }
}

=head3 role Spacer does Tag[Regular] {}

role Spacer  does Tag[Regular] is export {
    has Str $.height = '1em';

    multi method HTML {
        do-regular-tag( 'div', :style("min-height:$!height;") )
    }
}

=head2 Safe Tag

=para The Air way to suppress HTML::Escape

=head3 role Safe   does Tag[Regular] {...}

role Safe    does Tag[Regular] is export {
    multi method HTML {
        @.inners.join
    }
}

##### Functions Export #####

#| put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

my package EXPORT::DEFAULT {

    for exports-air-base-tags() -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
                ::($name).new( |@a, |%h )
            }

    }
}


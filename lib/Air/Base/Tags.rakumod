unit module Tags;

use Air::Functional :MANDATORY;

=head2 Air::Base::Tags

=para Air::Functional converts all HTML tags into raku functions. Air::Base overrides a subset of these HTML tags, providing them both as C<roles> and functions.

=para Air::Base::Tags often embed some code to provide behaviours. This can be simple - C<role Script {}> just marks JavaScript as exempt from HTML Escape. Or complex - C<role Body {}> has C<Header>, C<Main> and C<Footer> attributes with certain defaults and constructors.

=para Combine these tags in the same way as the overall layout of an HTML webpage. Note that they hide complexity to expose only relevant information to the fore. Override them with your own roles and classes to implement your specific needs.

=head2 Utility Tags

=para These HTML Tags are re-published for Air::Base since we need to have roles declared for types anyway. Some have a few minor "improvements" via the setting of attribute defaults.

=head3 role Script does Tag[Regular] {...}

role Script does Tag[Regular] {
    #| no html escape
    multi method HTML {
        opener($.name, |%.attrs) ~
        ( @.inners.first // '' ) ~
        closer($.name)           ~ "\n"
    }
}

=head3 role Style  does Tag[Regular] {...}

role Style  does Tag[Regular]  {
    #| no html escape
    multi method HTML {
        opener($.name, |%.attrs)  ~
        @.inners.first            ~
        closer($.name)            ~ "\n"
    }
}

=head3 role Meta   does Tag[Singular] {}

role Meta    does Tag[Singular] {}

=head3 role Title  does Tag[Regular]  {}

role Title   does Tag[Regular] {}

=head3 role Link   does Tag[Regular]  {}

role Link    does Tag[Singular] {}

=head3 role A      does Tag[Regular] {}

=head2 Semantic Tags

=para These are a mix of HTML Tags re-published (some with minor improvements) and of newly construed Air Tags for convenience. Generally they are chosen to align with the Pico CSS semantic tags in use.

role A       does Tag[Regular]  {}

=head3 role Button does Tag[Regular] {}

role Button  does Tag[Regular] {}

=head3 role Section   does Tag[Regular] {}

role Section does Tag[Regular] {}

=head3 role Article   does Tag[Regular] {}

role Article does Tag[Regular] {
    # Keep text ltr even when grid direction rtl
    multi method HTML {
        my %attrs = |%.attrs, :style("direction:ltr;");
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Aside     does Tag[Regular] {}

role Aside   does Tag[Regular] {
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

role Time    does Tag[Regular] {
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

=head3 role Content does Tag[Regular] {}

role Content does Tag[Regular] {
    multi method HTML {
        my %attrs  = |%.attrs, :id<content>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Spacer does Tag[Regular] {}

role Spacer  does Tag[Regular] {
    has Str $.height = '1em';

    multi method HTML {
        do-regular-tag( 'div', :style("min-height:$!height;") )
    }
}

=head2 Safe Tag

=para The Air way to suppress HTML::Escape

=head3 role Safe   does Tag[Regular] {...}

role Safe   does Tag[Regular] {
    #| avoids HTML escape
    multi method HTML {
        @.inners.join
    }
}

##### Functions Export #####

my constant @exports-air-base-tags =
  A,
  Aside,
  Article,
  Button,
  Content,
  Link,
  Meta,
  Safe,
  Script,
  Section,
  Spacer,
  Style,
  Time,
  Title,
;

#| put in all the @components as functions sub name(|c) {Name.new(|c)}
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

my package EXPORT::DEFAULT {
    for @exports-air-base-tags -> $class {
        OUR::{'&' ~ $class.^shortname.lc} := my sub (|c) { $class.new(|c) }
    }
}

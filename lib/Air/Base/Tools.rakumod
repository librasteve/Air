unit module Tools;

sub exports-air-base-tools is export {<Tool Provider Analytics>}

use Air::Functional :TEMPIN2;
use Air::Base::Tags;

=head2 Air::Base::Tools

=para Tools are provided to the C<site()> function to provide a nugget of side-wide behaviour, services method defaults are distributed to all pages on server start.

role Tool is export {}

=head3 role Analytics does Tool {...}

enum Provider is export <Umami>;

role Analytics does Tool is export {
    #| may be [Umami] - others TBD
    has Provider $.provider;
    #| website ID from provider
    has Str      $.key;

    multi method inject($page) {
        given $!provider {
            when Umami {
                $page.html.head.scripts.append:
                    Script.new: :defer,
                        :src<https://cloud.umami.is/script.js>,
                        :data-website-id($!key);
            }
        }
    }
}

##### Functions Export #####

#| put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

my package EXPORT::DEFAULT {

    for exports-air-base-tools() -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
                ::($name).new( |@a, |%h )
            }

    }
}


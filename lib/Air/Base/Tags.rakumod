unit module Tags;

sub exports-air-base-tags is export {<Script Style Meta Title Link A Button Safe>}

use Air::Functional :MANDATORY;

=head2 Air::Base::Tags

=para Air::Functional converts all HTML tags into raku functions. Air::Base overrides a subset of these HTML tags, providing them both as C<roles> and functions.

=para Air::Base::Tags often embed some code to provide behaviours. This can be simple - C<role Script {}> just marks JavaScript as exempt from HTML Escape. Or complex - C<role Body {}> has C<Header>, C<Main> and C<Footer> attributes with certain defaults and constructors.

=para Combine these tags in the same way as the overall layout of an HTML webpage. Note that they hide complexity to expose only relevant information to the fore. Override them with your own roles and classes to implement your specific needs.

=head3 role Script does Tag[Regular] {...}

role Script does Tag[Regular] is export {
    #| no html escape
    multi method HTML {
        opener($.name, |%.attrs) ~
        ( @.inners.first // '' ) ~
        closer($.name)           ~ "\n"
    }
}

=head3 role Style  does Tag[Regular] {...}

role Style  does Tag[Regular] is export  {
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

=head3 role A      does Tag[Regular] {}

role A       does Tag[Regular] is export  {}

=head3 role Button does Tag[Regular] {}

role Button  does Tag[Regular] is export {}

=head3 role Section   does Tag[Regular] {}

#role Section does Tag[Regular] is export {}

=head3 role Article   does Tag[Regular] {}

#role Article   does Tag[Regular] {   #iamerejh
#    # Keep text ltr even when grid direction rtl
#    multi method HTML {
#        my %attrs  = |%.attrs, :style("direction:ltr;");
#        do-regular-tag( $.name, @.inners, |%attrs )
#    }
#}


#---

=head3 role Safe   does Tag[Regular] {...}

role Safe   does Tag[Regular] is export {
    #| avoids HTML escape
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


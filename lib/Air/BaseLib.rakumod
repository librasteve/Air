
#`[
Model page using OO
This has the superpowers of defaults and overrrides
Newline is inner to outer
#]

use Air::Functional;
use Air::Component;

my @components = <Script Page Table Grid>;

##### Export as Tag role #####

#| The Tag role provides an HTML method so that the consuming class behaves like a standard HTML tag that
#| can be provided with inner and attr attributes

enum TagType is export <Singular Regular>;
subset Attr of Str;

role Tag[TagType $tag-type] is export {
    has Str    $.name = ::?CLASS.^name.lc;
    has Attr() %.attrs;   #coercion is friendly to attr values with spaces
    has        $.inner;

    multi method HTML {
        samewith $tag-type
    }
    multi method HTML(Singular) {
        do-singular-tag( $!name, |%.attrs )
    }
    multi method HTML(Regular) {
        do-regular-tag( $!name, [$.inner // ''], |%.attrs )
    }
}

role Meta does Tag[Singular] { }

role Title does Tag[Regular] { }

role Script does Tag[Regular] does Component {
    has Str $.src;

    method attrs {
        { :$!src }
    }
}

role Link does Tag[Singular] { }

role Style does Tag[Regular] { }

role Head does Tag[Regular] {
    has Meta   @.metas;
    has Title  $.title is rw;
    has Script @.scripts;
    has Link   @.links;
    has Style  $.style is rw;

    #some basic defaults
    method defaults {
        self.metas.append: Meta.new: attrs => {:charset<utf-8>};
        self.metas.append: Meta.new: attrs => {:name<viewport>, :content<width=device-width, initial-scale=1>};
    }

    multi method HTML {
        opener($.name)                     ~
        "{ (.HTML for  @!metas   ).join }" ~
        "{ (.HTML with $!title   )}"       ~
        "{ (.HTML for  @!scripts ).join }" ~
        "{ (.HTML for  @!links   ).join }" ~
        "{ (.HTML with $!style   )}"       ~
        closer($.name)                     ~ "\n"
    }
}

role Body does Tag[Regular] { }

#[

role Html does Tag[Regular] {
    has Head $.head .= new;
    has Body $.body is rw;

    method defaults {
        self.head.defaults;
        %.attrs.push: :lang<en>;
    }

    multi method HTML {
        opener($.name, |%.attrs) ~
        $!head.HTML              ~
        $!body.HTML              ~
        closer($.name)           ~ "\n"
    }
}

role Page does Component {
    has $.doctype = 'html';
    has Html $.html .= new;

    has $.title;
    has $.description;

    method defaults {
        self.html.defaults;
        self.html.head.title = Title.new(inner => $!title);
        self.meta: { :name<description>, :content($!description) };
    }

    multi method HTML {
        "<!doctype $!doctype>" ~ $!html.HTML
    }

    method meta(%attrs) {
        self.html.head.metas.append: Meta.new(:%attrs)
    }

    method title($inner) {
        self.html.head.title = Title.new(inner => $!title)
    }

    method script(:$src) {
        self.html.head.scripts.append: Script.new(:$src);
    }

    method link(%attrs) {
        self.html.head.links.append: Link.new(:%attrs)
    }

    method style($inner) {
        self.html.head.style = Style.new(:$inner)
    }

    method body($inner) {
        self.html.body = Body.new(:$inner)
    }
}

role Container {

}

role Layout {

}

role Template {

}

role Site {

}

role Nav {

}

#| viz. https://picocss.com/docs/table
class Table does Component {
    has $.tbody = [];
    has $.thead = [];
    has $.tfoot = [];
    has $.class;

    multi method new(@tbody, *%h) {
        self.new: :@tbody, |%h;
    }

    sub part($part, :$head) {
        do for |$part -> @row {
            tr do for @row.kv -> $col, $cell {
                given    	$col, $head {
                    when   	  *,    *.so  { th $cell, :scope<col> }
                    when   	  0,    *     { th $cell, :scope<row> }
                    default               { td $cell }
                }
            }
        }
    }

    method thead { thead part($!thead, :head) }
    method tbody { tbody part($!tbody) }
    method tfoot { tfoot part($!tfoot) }

    method HTML {
        table |%(:$!class if $!class), [$.thead; $.tbody; $.tfoot;];
    }
}

#| viz. https://picocss.com/docs/grid
class Grid does Component {
    has @.items;

    multi method new(@items, *%h) {
        self.new: :@items, |%h;
    }

    #| example of optional grid style from
    #| https://cssgrid-generator.netlify.app/
    method style {
        q:to/END/
		<style>
			.grid {
				display: grid;
				grid-template-columns: repeat(5, 1fr);
				grid-template-rows: repeat(5, 1fr);
				grid-column-gap: 0px;
				grid-row-gap: 0px;
			}
		</style>
		END
	}

    method HTML {
        #		$.style ~
        div :class<grid>,
            do for @!items -> $item {
                div $item
            }
            ;
    }
}

#]


#`[
my $static = './static/index.html';
my %assets = ( js => './static/js', css => './static/js', images => './static/images' );
my $routes = './lib/Routes.rakumod';

spurt $page.HTML-static $static;
spurt $page.HTML-assets %assets;
spurt $page.HTML-routes $routes;
#]

##### HTML Functional Export #####

# put in all the tags programmatically
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing

my package EXPORT::DEFAULT {

    for @components -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
                ::($name).new( |@a, |%h ).HTML;
            }
    }
}

my package EXPORT::NONE { }



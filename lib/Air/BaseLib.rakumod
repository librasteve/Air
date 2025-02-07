
#`[
Model page using OO
This has the superpowers of defaults and overrrides
Newline is inner to outer
#]

use Air::Functional;
use Air::Component;

my @components = <Page Nav Table Grid>;

##### Tag Role #####

#| The Tag Role provides an HTML method so that the consuming class behaves like a standard HTML tag that
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

##### Site Roles #####

role Meta does Tag[Singular] {}

role Title does Tag[Regular] {}

role Script does Tag[Regular] {}

role Link does Tag[Singular] {}

role Style does Tag[Regular] {}

role Body does Tag[Regular] {}

role Head does Tag[Regular] {
    my $loaded = 0;
    has Meta   @.metas;
    has Title  $.title is rw;
    has Script @.scripts;
    has Link   @.links;
    has Style  $.style is rw;

    #some basic defaults
    method defaults {
        self.metas.append: Meta.new: attrs => {:charset<utf-8>};
        self.metas.append: Meta.new: attrs => {:name<viewport>, :content<width=device-width, initial-scale=1>};
        self.links.append: Link.new: attrs => {:rel<stylesheet>, :href<css/styles.css> };
        self.links.append: Link.new: attrs => {:rel<icon>, :href<img/favicon.ico>, :type<image/x-icon>};
        self.scripts.append: Script.new: attrs => {:src<https://kit.fontawesome.com/a425eec628.js'>, :crossorigin<anonymous>};
        self.scripts.append: Script.new: attrs => {:src<https://unpkg.com/htmx.org@1.9.5>, :crossorigin<anonymous>,
                                    :integrity<sha384-xcuj3WpfgjlKF+FXhSQFQ0ZNr39ln+hwjN3npfM9VBnUskLolQAcN80McRIVOPuO>};
    }

    multi method HTML {
        self.defaults unless $loaded++;

        opener($.name)                     ~
        "{ (.HTML for  @!metas   ).join }" ~
        "{ (.HTML with $!title   )}"       ~
        "{ (.HTML for  @!scripts ).join }" ~
        "{ (.HTML for  @!links   ).join }" ~
        "{ (.HTML with $!style   )}"       ~
        closer($.name)                     ~ "\n"
    }
}

role Html does Tag[Regular] {
    my $loaded = 0;

    has Head $.head .= new;
    has Body $.body is rw;

    has Attr %.lang is rw = :lang<en>;
    has Attr %.mode is rw = :data-theme<dark>;

    method defaults {
        self.head.defaults;
        %.attrs.append: %!lang, %!mode;

    }

    multi method HTML {
        self.defaults unless $loaded++;

        opener($.name, |%.attrs) ~
        $!head.HTML              ~
        $!body.HTML              ~
        closer($.name)           ~ "\n"
    }
}


role Header does Tag[Regular] {}
role Main   does Tag[Regular] {}
role Footer does Tag[Regular] {}

#iamerejh
role Fragment {}

role Page does Component {
    my $loaded = 0;
    has Int $.REFRESH;    #auto refresh every n secs during dev't

    has Str $.title       is required;
    has Str $.description is required;

    has Html $.html .= new;

    method defaults {
        self.html.defaults;
        self.html.head.title = Title.new: :inner($!title);
        self.meta: { :name<description>, :content($!description) };
        self.meta: { :http-equiv<refresh>, :content($!REFRESH) } if $!REFRESH;
    }

    multi method HTML {
        self.defaults unless $loaded++;
        '<!doctype html>' ~ $!html.HTML
    }

    #| Setter methods
    method meta(%attrs)   { self.html.head.metas.append: Meta.new(:%attrs) }
    method script(%attrs) { self.html.head.scripts.append: Script.new(:%attrs) }
    method link(%attrs)   { self.html.head.links.append: Link.new(:%attrs) }
    method style($inner)  { self.html.head.style = Style.new(:$inner) }
    method body($inner)   { self.html.body = Body.new(:$inner) }
}

role Site {
    has Page @.pages;
    has Page $.index is rw = @!pages[0];

    use Cro::HTTP::Router;

    method routes {
        route {
            get ->               { content 'text/html', $.index.HTML }
            get -> 'css', *@path { static 'static/css', @path }
            get -> 'img', *@path { static 'static/img', @path }
            get -> 'js',  *@path { static 'static/js',  @path }
            get ->        *@path { static 'static',     @path }
        }
    }
}

##### Roles TBD #####
role Container {}
role Layout {}
role Template {}

##### Tag Components #####
# viz. https://picocss.com/docs

class Nav does Component {
    has Str  $.hx-target = '#content';
    has Str  $.logo;
    has Pair @.items = [];

    multi method new(@items, *%h) {
        self.new: :@items, |%h;
    }

    submethod TWEAK {
        @!items .= map: { (.value === True) ?? (.key => .key) !! $_ };
    }

    multi method HTML {
        nav [
            { ul li :class<logo>, :href</>, $!logo } with $!logo;
            ul :$!hx-target, do for @!items
                { li a(:hx-get(.key), .value) };
        ]
    }
}

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




#`[
Model page using OO
This has the superpowers of defaults and overrrides
Newline is inner to outer
#]

use Air::Functional;
use Air::Component;

my @components = <External Content Page Nav Body Header Main Footer Table Grid>;

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

role A does Tag[Regular] {
    multi method new($inner, *%attrs) {
        self.new: :$inner, |%attrs
    }
}

role Meta does Tag[Singular] {}

role Title does Tag[Regular] {}

role Script does Tag[Regular] {}

role Link does Tag[Singular] {}

role Style does Tag[Regular] {
    multi method new($inner, *%attrs) {
        self.new: :$inner, |%attrs
    }
}

role Head does Tag[Regular] {

    # Singleton pattern (ie. same Head for all pages)
    my Head $instance;
    method new {self.instance}
    submethod instance {
        unless $instance {
            $instance = Head.bless;
            $instance.defaults;
        };
        $instance;
    }

    has Title  $.title is rw;
    has Meta   $.description is rw;
    has Meta   @.metas;
    has Script @.scripts;
    has Link   @.links;
    has Style  $.style is rw;

    method defaults {
        self.metas.append: Meta.new: attrs => {:charset<utf-8>};
        self.metas.append: Meta.new: attrs => {:name<viewport>, :content<width=device-width, initial-scale=1>};
        self.links.append: Link.new: attrs => {:rel<stylesheet>, :href</css/styles.css> };
        self.links.append: Link.new: attrs => {:rel<icon>, :href</img/favicon.ico>, :type<image/x-icon>};
        self.scripts.append: Script.new: attrs => {:src<https://kit.fontawesome.com/a425eec628.js'>, :crossorigin<anonymous>};
        self.scripts.append: Script.new: attrs => {:src<https://unpkg.com/htmx.org@1.9.5>, :crossorigin<anonymous>,
                                        :integrity<sha384-xcuj3WpfgjlKF+FXhSQFQ0ZNr39ln+hwjN3npfM9VBnUskLolQAcN80McRIVOPuO>};
    }

    multi method HTML {
        opener($.name)                     ~
        "{ (.HTML with $!title         )}" ~
        "{ (.HTML with $!description   )}" ~
        "{ (.HTML for  @!metas   ).join }" ~
        "{ (.HTML for  @!scripts ).join }" ~
        "{ (.HTML for  @!links   ).join }" ~
        "{ (.HTML with $!style         )}" ~
        closer($.name)                     ~ "\n"
    }
}

class Nav { ... }
class Page { ... }

role Header does Tag[Regular] {
    has Nav $.nav is rw .= new;

    multi method HTML {
        opener($.name, |%.attrs) ~
        $!nav.HTML               ~
        closer($.name)           ~ "\n"
    }
}

role Main does Tag[Regular] {
    multi method new($inner, *%attrs) {
        self.new: :$inner, |%attrs
    }
}

role Footer does Tag[Regular] {
    multi method new($inner, *%attrs) {
        self.new: :$inner, |%attrs
    }
}

role Body does Tag[Regular] {
    has Header $.header is rw .= new: :attrs{:class<container>};
    has Main   $.main   is rw .= new: :attrs{:class<container>};
    has Footer $.footer is rw .= new: :attrs{:class<container>};

    multi method new($inner, *%attrs) {
        self.new: :$inner, |%attrs
    }

    multi method HTML {
        opener($.name, |%.attrs) ~
        $!header.HTML            ~
        $!main.HTML              ~
        $!footer.HTML            ~
        closer($.name)           ~ "\n"
    }
}

role Html does Tag[Regular] {
    my $loaded = 0;

    has Head $.head .= new;
    has Body $.body is rw .= new;

    has Attr %.lang is rw = :lang<en>;
    has Attr %.mode is rw = :data-theme<dark>;

    method defaults {
        self.attrs = |%!lang, |%!mode;
    }

    multi method HTML {
        self.defaults unless $loaded++;

        opener($.name, |%.attrs) ~
        $!head.HTML              ~
        $!body.HTML              ~
        closer($.name)           ~ "\n"
    }
}

# More Roles TBD?
role Container {}
role Layout {}
role Template {}

##### Core Classes #####

class External does A {
    has %.others = {:target<_blank>, :rel<noopener noreferrer>};

    multi method HTML {   #iamerejh
        self.attrs = |self.attrs, |self.others;
        note self.raku;
        nextsame
    }
}

class Content does Component {
    has $.inner;

    multi method new($inner, *%attrs) {
        self.new: :$inner, |%attrs
    }

    method HTML {
        div :id<content>, [|$!inner]
    }
}

subset NavItem of Pair where .value ~~ External | Content | Page;

class Nav does Component {
    has Str  $.hx-target = '#content';
    has Str  $.logo;
    has NavItem @.items;

    method make-routes() {
        unless self.^methods.grep: * ~~ IsRoutable {
            for self.items.map: *.kv -> ($name, $target) {
                given $target {
                    when * ~~ Content {
                        my &new-method = method {respond $target};
                        trait_mod:<is>(&new-method, :routable, :$name);
                        self.^add_method($name, &new-method);
                    }
                }
            }
        }
    }

    multi method HTML {
        nav [
            { ul li :class<logo>, :href</>, $.logo } with $.logo;
            ul :$!hx-target, do for @.items.map: *.kv -> ($name, $target) {
                given $target {
                    when * ~~ External {
                        li $target.HTML
                    }
                    when * ~~ Content {
                        li a(:hx-get("$.url-part/$.id/" ~ $name), $name)
                    }
                    when * ~~ Page {
                        li a(:href("/{.url-part}/{.id}"), $name)
                    }
                }
            }
        ]
    }
}

class Page does Component {
    has $.loaded is rw = 0;
    has Int     $.REFRESH;    #auto refresh every n secs in dev't

    has Str     $.title;
    has Str     $.description;
    has Nav     $.nav is rw;
    has Footer  $.footer;

    has Html $.html .= new;

    method defaults {
        unless $.loaded++ {
            self.html.head.title = Title.new: :inner($.title)           with $.title;
            self.html.head.description = Meta.new: attrs =>
                        { :name<description>, :content($.description) } with $.description;
            self.html.head.metas.append: Meta.new: attrs =>
                        { :http-equiv<refresh>, :content($.REFRESH) }   with $.REFRESH;
            self.html.body.header.nav = $.nav                           with $.nav;
            self.html.body.footer = $.footer                            with $.footer;
        }
    }

    method main($inner) {
        self.html.body.main = Main.new: $inner, :attrs{:class<container>}
    }

    multi method HTML {
        self.defaults unless $.loaded;
        '<!doctype html>' ~ $!html.HTML
    }
}

class Site {
    has Page @.pages;
    has Page $.index is rw = @!pages[0];

    use Cro::HTTP::Router;

    method routes {
        route {
            Nav.^add-routes;
            get ->               { content 'text/html', $.index.HTML }
            get -> 'css', *@path { static 'static/css', @path }
            get -> 'img', *@path { static 'static/img', @path }
            get -> 'js',  *@path { static 'static/js',  @path }
            get ->        *@path { static 'static',     @path }

            for @!pages.map: {.url-part, .id} -> ($url-part, $id) {
                note "adding GET $url-part/$id";
                get -> Str $ where $url-part, $id { content 'text/html', @!pages[$id-1].HTML }
            }
        }
    }
}

##### Tag Classes #####
# viz. https://picocss.com/docs

class Table {
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

class Grid {
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



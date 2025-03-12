#unit module Air::Base;   #iamerejh

=begin pod

=head1 Air::Base

This raku module is one of the core libraries of the raku B<Air> module.

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

Key features of the module are:
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

use Air::Functional;
use Air::Component;

my @functions = <Site Page A External Internal Content Section Article Aside Time Nav LightDark Body Header Main Footer Table Grid Safe>;

##### Tagged Role #####

#| The Tagged Role provides an HTML method so that the consuming class behaves like a standard HTML tag that
#| can be provided with inner and attr attributes

enum TagType is export <Singular Regular>;
subset Attr of Str;

role Tagged[TagType $tag-type] is Tag is export {
    has Str     $.name = ::?CLASS.^name.lc;
    has Attr()  %.attrs is rw;   #coercion accepts multi-valued attrs with spaces
    has         @.inners;

    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, :%attrs
    }

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

##### Basic Tags #####

class Nav  { ... }
class Page { ... }

role Safe   does Tagged[Regular]  {
    #| Shun html escape even though inner is Str
    #| No opener, closer required
    multi method HTML {
        @.inners.join
    }
}
role Script does Tagged[Regular]  {
    # Shun html escape even though inner is Str
    multi method HTML {
        opener($.name, |%.attrs) ~
        (@.inners.first// '')    ~
        closer($.name)           ~ "\n"
    }
}
role Style  does Tagged[Regular]  {
    # Shun html escape even though inner is Str
    multi method HTML {
        opener($.name, |%.attrs)  ~
        @.inners.first            ~
        closer($.name)            ~ "\n"
    }
}

role Meta   does Tagged[Singular] {}
role Title  does Tagged[Regular]  {}
role Link   does Tagged[Singular] {}

role A      does Tagged[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :target<_blank>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

role Head   does Tagged[Regular]  {

    # Singleton pattern (ie. same Head for all pages)
    my Head $instance;
    multi method new {note "Please use Head.instance rather than Head.new!\n"; self.instance}
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
        self.metas.append: Meta.new: :charset<utf-8>;
        self.metas.append: Meta.new: :name<viewport>, :content<width=device-width, initial-scale=1>;
        self.links.append: Link.new: :rel<stylesheet>, :href</css/styles.css>;
        self.links.append: Link.new: :rel<icon>, :href</img/favicon.ico>, :type<image/x-icon>;
        self.scripts.append: Script.new: :src<https://unpkg.com/htmx.org@1.9.5>, :crossorigin<anonymous>,
                :integrity<sha384-xcuj3WpfgjlKF+FXhSQFQ0ZNr39ln+hwjN3npfM9VBnUskLolQAcN80McRIVOPuO>;
    }

    multi method HTML {
        opener($.name, |%.attrs)                    ~
        "{ .HTML with $!title          }" ~
        "{ .HTML with $!description    }" ~
        "{(.HTML for  @!metas   ).join }" ~
        "{(.HTML for  @!scripts ).join }" ~
        "{(.HTML for  @!links   ).join }" ~
        "{ .HTML with $!style          }" ~
        closer($.name)                    ~ "\n"
    }
}

role Header does Tagged[Regular]  {
    has Nav  $.nav is rw;
    has Safe $.tagline;

    multi method HTML {
        my %attrs  = |%.attrs, :class<container>;
        my @inners = |@.inners, $.nav // Empty, $.tagline // Empty;

        do-regular-tag( $.name, @inners, |%attrs )
    }
}
role Main   does Tagged[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :class<container>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}
role Footer does Tagged[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :class<container>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

role Body   does Tagged[Regular]  {
    has Header $.header is rw .= new;
    has Main   $.main   is rw .= new;
    has Footer $.footer is rw .= new;

    multi method HTML {
        opener($.name, |%.attrs) ~
        $!header.HTML            ~
        $!main.HTML              ~
        $!footer.HTML            ~
        closer($.name)           ~ "\n"
    }
}

role Html   does Tagged[Regular]  {
    my $loaded = 0;

    has Head $.head .= instance;
    has Body $.body is rw .= new;

    has Attr %.lang is rw = :lang<en>;
    has Attr %.mode is rw = :data-theme<dark>;

    method defaults {
        self.attrs = |%!lang, |%!mode, |%.attrs;
    }

    multi method HTML {
        self.defaults unless $loaded++;

        opener($.name, |%.attrs) ~
        $!head.HTML              ~
        $!body.HTML              ~
        closer($.name)           ~ "\n"
    }
}

##### Widgets #####

role LightDark does Tagged[Regular] {
    has $.show = 'icon';

    multi method HTML {
        given self.show {
            when 'buttons' { Safe.new: self.buttons }
            when 'icon'    { Safe.new: self.icon   }
        }
    }

    method buttons { Q:to/END/;
        <div role="group">
            <button class="contrast"  id="themeToggle">Toggle</button>
            <button                   id="themeLight" >Light</button>
            <button class="secondary" id="themeDark"  >Dark</button>
            <button class="outline"   id="themeSystem">System</button>
        </div>
        <script>
            function setTheme(mode) {
                const htmlElement = document.documentElement;
                let newTheme = mode;

                if (mode === "toggle") {
                    const currentTheme = htmlElement.getAttribute("data-theme") || "light";
                    newTheme = currentTheme === "dark" ? "light" : "dark";
                } else if (mode === "system") {
                    newTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
                }

                htmlElement.setAttribute("data-theme", newTheme);
                localStorage.setItem("theme", newTheme); // Save theme to localStorage
            }

            // Load saved theme on page load
            document.addEventListener("DOMContentLoaded", () => {
                const savedTheme = localStorage.getItem("theme") || "light";  //default to light
                const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                const initialTheme = savedTheme || (systemPrefersDark ? "dark" : "light");
                document.documentElement.setAttribute("data-theme", initialTheme);
            });

            // Listen for system dark mode changes and update the theme dynamically
            window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
                setTheme("system"); // Follow system setting
            });

            // Example: Attach to a button click
            document.getElementById("themeToggle").addEventListener("click", () => setTheme("toggle"));
            document.getElementById("themeDark").addEventListener("click", () => setTheme("dark"));
            document.getElementById("themeLight").addEventListener("click", () => setTheme("light"));
            document.getElementById("themeSystem").addEventListener("click", () => setTheme("system"));
        </script>
        END
    }

    method icon { Q:to/END/;
        <a style="font-variant-emoji: text" id ="sunIcon">&#9728;</a>
        <a style="font-variant-emoji: text" id ="moonIcon">&#9790;</a>
        <script>
            const sunIcon = document.getElementById("sunIcon");
            const moonIcon = document.getElementById("moonIcon");

            // Function to show/hide icons
            function updateIcons(theme) {
                if (theme === "dark") {
                    sunIcon.style.display = "none"; // Hide sun
                    moonIcon.style.display = "block"; // Show moon
                } else {
                    sunIcon.style.display = "block"; // Show sun
                    moonIcon.style.display = "none"; // Hide moon
                }
            }

            function setTheme(mode) {
                const htmlElement = document.documentElement;
                let newTheme = mode;

                if (mode === "toggle") {
                    const currentTheme = htmlElement.getAttribute("data-theme") || "light";
                    newTheme = currentTheme === "dark" ? "light" : "dark";
                } else if (mode === "system") {
                    newTheme = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
                }

                htmlElement.setAttribute("data-theme", newTheme);
                localStorage.setItem("theme", newTheme); // Save theme to localStorage
                updateIcons(newTheme);
            }

            // Load saved theme on page load
            document.addEventListener("DOMContentLoaded", () => {
                const savedTheme = localStorage.getItem("theme") || "light";  //default to light
                const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                const initialTheme = savedTheme || (systemPrefersDark ? "dark" : "light");

                updateIcons(initialTheme);
                document.documentElement.setAttribute("data-theme", initialTheme);
            });

            // Listen for system dark mode changes and update the theme dynamically
            window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
                setTheme("system"); // Follow system setting
            });

            // Example: Attach to a button click
            document.getElementById("sunIcon").addEventListener("click", () => setTheme("dark"));
            document.getElementById("moonIcon").addEventListener("click", () => setTheme("light"));
        </script>
        END
    }
}
subset Widget  of Any  where * ~~ LightDark;

# TODO Roles?
#role Theme {...}
#role Form  {...}

##### Semantic Tags #####

role Content   does Tagged[Regular] {
    multi method HTML {
#        div :id<content>, @.inners

        my %attrs  = |%.attrs, :id<content>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}
role Section   does Tagged[Regular] {}
role Article   does Tagged[Regular] {}
role Aside     does Tagged[Regular] {}

role Time      does Tagged[Regular] {
    use DateTime::Format;

    multi method HTML {
        my $dt = DateTime.new(%.attrs<datetime>);

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

##### Site Tags #####

role External  does Tagged[Regular] {
    has Str $.label is rw = '';
    has %.others = {:target<_blank>, :rel<noopener noreferrer>};

    multi method HTML {
        my %attrs = |self.others, |%.attrs;
        do-regular-tag( 'a', [$.label], |%attrs )
    }
}
role Internal  does Tagged[Regular] {
    has Str $.label is rw = '';

    multi method HTML {
        do-regular-tag( 'a', [$.label], |%.attrs )
    }
}
subset NavItem of Pair where .value ~~ Internal | External | Content | Page;

class Nav  does Component is Tag {
    has Str     $.hx-target = '#content';
    has Safe    $.logo;
    has NavItem @.items;
    has Widget  @.widgets;

    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    method make-routes() {
        unless self.^methods.grep: * ~~ IsRoutable {
            for self.items.map: *.kv -> ($name, $target) {
                given $target {
                    when * ~~ Content {
                        my &new-method = method {respond $target.?HTML};
                        trait_mod:<is>(&new-method, :routable, :$name);
                        self.^add_method($name, &new-method);
                    }
                }
            }
        }
    }

    method nav-items {
        do for @.items.map: *.kv -> ($name, $target) {
            given $target {
                when * ~~ External | Internal {
                  $target.label = $name;
                  li $target.HTML
                }
                when * ~~ Content {
                    li a(:hx-get("$.url-part/$.id/" ~ $name), Safe.new: $name)
                }
                when * ~~ Page {
                    li a(:href("/{.url-part}/{.id}"), Safe.new: $name)
                }
            }
        }
    }

    multi method HTML {
        self.style.HTML ~ (

        nav [
            { ul li :class<logo>, :href</>, $.logo } with $.logo;

            button( :class<hamburger>, :id<hamburger>, Safe.new: '&#9776;' );

            ul( :$!hx-target, :class<nav-links>,
                self.nav-items,
                do for @.widgets { li .HTML },
            );

            ul( :$!hx-target, :class<menu>, :id<menu>,
                self.nav-items,
            );
        ]

        ) ~ self.script.HTML
    }

    method style { Style.new: q:to/END/
        /* Custom styles for the hamburger menu */
        .menu {
            display: none;
            flex-direction: column;
            gap: 10px;
            position: absolute;
            top: 60px;
            right: 20px;
            background: rgba(128, 128, 128, .97);
            padding: 1rem;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(128, 128, 128, .2);
        }

        .menu a {
            display: block;
        }

        .menu.show {
            display: flex;
        }

        .hamburger {
            color: var(--pico-primary);
            display: none;
            cursor: pointer;
            font-size: 2.5rem;
            background: none;
            border: none;
            padding: 0.5rem;
        }

        @media (max-width: 768px) {
            .hamburger {
                display: block;
            }

            .nav-links {
                display: none;
            }
        }
    END
	}

    method script { Script.new: Q:to/END/;
        const hamburger = document.getElementById('hamburger');
        const menu = document.getElementById('menu');

        hamburger.addEventListener('click', () => {
            menu.classList.toggle('show');
        });

        document.addEventListener('click', (e) => {
            if (!menu.contains(e.target) && !hamburger.contains(e.target)) {
                menu.classList.remove('show');
            }
        });

        // Hide the menu when resizing the viewport to a wider width
        window.addEventListener('resize', () => {
            if (window.innerWidth > 768) {
                menu.classList.remove('show');
            }
        });
    END
    }
}

class Page does Component {
    has $.loaded is rw = 0;
    has Int     $.REFRESH;    #auto refresh every n secs in dev't

    has Str     $.title;
    has Str     $.description;
    has Nav     $.nav is rw;  #\ either or
    has Header  $.header;     #/ nav wins
    has Main    $.main is rw;
    has Footer  $.footer;

    has Bool    $.styled-aside-on = False;

    has Html    $.html .= new;

    method defaults {
        unless $.loaded++ {
            self.html.head.metas.append: Meta.new:
                         :http-equiv<refresh>, :content($.REFRESH)      with $.REFRESH;

            self.html.head.title = Title.new: $.title                   with $.title;

            self.html.head.description = Meta.new:
                         :name<description>, :content($.description)    with $.description;

            with   $.nav    { self.html.body.header.nav = $.nav }
            orwith $.header { self.html.body.header = $.header  }

            self.html.body.main   = $.main                              with $.main;
            self.html.body.footer = $.footer                            with $.footer;

            self.html.head.style  = $.styled-aside                      if $.styled-aside-on;
        }
    }

    multi method new(Main $main, *%h) {
        self.bless: :$main, |%h
    }
    multi method new(Main $main, Footer $footer, *%h) {
        self.bless: :$main, :$footer, |%h
    }
    multi method new(Header $header, Main $main, Footer $footer, *%h) {
        self.bless: :$header, :$main, :$footer, |%h
    }

    multi method HTML {
        self.defaults unless $.loaded;
        '<!doctype html>' ~ $!html.HTML
    }

    method styled-aside { Style.new: q:to/END/
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

class Site {
    has Page @.pages;
    has Page $.index is rw = @!pages[0];
    has Component @.components = [Nav.new];

    has Bool $.scss = True;  # run sass compiler

    #| <amber azure blue cyan fuchsia green indigo jade lime orange
    #| pink pumpkin purple red violet yellow> (pico theme)
    has Str  $.theme-color = 'green';

    #| one from <aqua black blue fuchsia gray green lime maroon navy
    #| olive purple red silver teal white yellow> (basic css)
    has Str  $.bold-color  = 'red';

    multi method new(Page $index, *%h) {
        self.bless: :$index, |%h;
    }

    use Cro::HTTP::Router;

    method routes {
        self.scss with $!scss;

        route {
            { .^add-routes } for @!components;

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

    method scss {
        my $css = self.css;

        note "theme-color=$!theme-color";
        $css ~~ s:g/'%THEME_COLOR%'/$!theme-color/;

        note "bold-color=$!bold-color";
        $css ~~ s:g/'%BOLD_COLOR%'/$!bold-color/;

        chdir "static/css";
        spurt "styles.scss", $css;
        qx`sass styles.scss styles.css 2>/dev/null`;  #sinks warnings to /dev/null
        chdir "../..";
    }

    method css { Q:to/END/;
        @use "node_modules/@picocss/pico/scss" with (
          $theme-color: "%THEME_COLOR%"
        );

        //some root overrides for scale https://github.com/picocss/pico/discussions/482

        :root {
          --pico-font-family-sans-serif: Inter, system-ui, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, Helvetica, Arial,
              "Helvetica Neue", sans-serif, var(--pico-font-family-emoji);
          --pico-font-size: 106.25%;
          /* Original: 100% */
          --pico-line-height: 1.25;
          /* Original: 1.5 */
          --pico-form-element-spacing-vertical: 0.5rem;
          /* Original: 1rem */
          --pico-form-element-spacing-horizontal: 1.0rem;
          /* Original: 1.25rem */
          --pico-border-radius: 0.375rem;
          /* Original: 0.25rem */
        }

        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
          --pico-font-weight: 600;
          /* Original: 700 */
        }

        article {
          border: 1px solid var(--pico-muted-border-color);
          /* Original doesn't have a border */
          border-radius: calc(var(--pico-border-radius) * 2);
          /* Original: var(--pico-border-radius) */
        }

        article>footer {
          border-radius: calc(var(--pico-border-radius) * 2);
          /* Original: var(--pico-border-radius) */
        }

        b {
          color: %BOLD_COLOR%;
        }

        .logo, .logo:hover {
          /* Remove underline by default and on hover */
          text-decoration: none;
          font-size:160%;
          font-weight:700;
        }

        body > footer > p {
          font-size:66%;
          font-style:italic;
        }
        END
    }
}

##### Element Tags #####
# viz. https://picocss.com/docs

class Table is Tag {
    has $.tbody = [];
    has $.thead;
    has $.tfoot;
    has $.class;
    has %!tbody-attrs;

    multi method new(*@tbody, *%h) {
        self.bless:  :@tbody, |%h;
    }

    submethod TWEAK {
        %!tbody-attrs = $!tbody.grep:   * ~~ Pair;
        $!tbody       = $!tbody.grep: !(* ~~ Pair);
    }

    multi sub do-part($part, :$head) { '' }
    multi sub do-part(@part where .all ~~ Tag|Component) {
        tbody @part.map(*.HTML)
    }
    multi sub do-part(@part where .all ~~ Array, :$head) {
        do for @part -> @row {
            tr do for @row.kv -> $col, $cell {
                given    	$col, $head {
                    when   	  *,    *.so  { th $cell, :scope<col> }
                    when   	  0,    *     { th $cell, :scope<row> }
                    default               { td $cell }
                }
            }
        }
    }

    multi method HTML {
        table |%(:$!class if $!class), [
            thead do-part($!thead, :head);
            tbody do-part($!tbody),  :attrs(|%!tbody-attrs);
            tfoot do-part($!tfoot);
        ]
    }
}

class Grid is Tag {
    has @.items;

    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    #| optional grid style from https://cssgrid-generator.netlify.app/
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

    multi method HTML {
        $.style ~

        div :class<grid>,
            do for @!items -> $item {
                div $item
            }
        ;
    }
}

##### Functions Export #####

#| put in all the @components as functions
#| viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing
my package EXPORT::DEFAULT {

    for @functions -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
                ::($name).new( |@a, |%h )
            }
    }
}

my package EXPORT::NONE { }

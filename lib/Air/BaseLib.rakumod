use Air::Functional;
use Air::Component;

my @components = <External Content Page Nav Body Header Main Footer Table Grid>;

##### Tag Role #####

#| The Tag Role provides an HTML method so that the consuming class behaves like a standard HTML tag that
#| can be provided with inner and attr attributes

enum TagType is export <Singular Regular>;
subset Attr of Str;

role Tag[TagType $tag-type] is Node is export {   #iamerejh
    has Str    $.name = ::?CLASS.^name.lc;
    has Attr() %.attrs is rw;   #coercion is friendly to attr values with spaces
    has        $.inner;

    multi method new($inner, *%attrs) {
        self.new: :$inner, |%attrs
    }

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

##### Tag Roles #####

role A does Tag[Regular] {
#    multi method new($inner, *%attrs) {
#        self.new: :$inner, |%attrs
#    }
}

role Meta does Tag[Singular] {}

role Title does Tag[Regular] {}

role Script does Tag[Regular] {}

role Link does Tag[Singular] {}

role Style does Tag[Regular] {
#    multi method new($inner, *%attrs) {
#        self.new: :$inner, |%attrs
#    }
}

role Head does Tag[Regular] {

    # Singleton pattern (ie. same Head for all pages)
    my Head $instance;
    multi method new {self.instance}
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
    has Nav $.nav is rw;
    has Str $.tagline = '';

    multi method HTML {
        %.attrs = |%.attrs, :class<container>;

        opener($.name, |%.attrs)    ~
        ($!nav ?? $!nav.HTML !! '') ~
        $!tagline                   ~
        closer($.name)              ~ "\n"
    }
}

role Main does Tag[Regular] {
#    multi method new($inner, *%attrs) {
#        self.new: :$inner, |%attrs
#    }

    multi method HTML {
        %.attrs = |%.attrs, :class<container>;

        opener($.name, |%.attrs) ~
        $.inner                  ~
        closer($.name)           ~ "\n"
    }
}

role Footer does Tag[Regular] {
#    multi method new($inner, *%attrs) {
#        self.new: :$inner, |%attrs
#    }

    multi method HTML {
        %.attrs = |%.attrs, :class<container>;

        opener($.name, |%.attrs) ~
        $.inner                  ~
        closer($.name)           ~ "\n"
    }
}

role Body does Tag[Regular] {
    has Header $.header is rw .= new;
    has Main   $.main   is rw .= new;
    has Footer $.footer is rw .= new: '';

#    multi method new($inner, *%attrs) {
#        self.new: :$inner, |%attrs
#    }

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

##### Widgets #####

role LightDark does Tag[Regular] {
    has $.show = 'icon';

    multi method HTML {
        given self.show {
            when 'buttons' { self.buttons }
            when 'icon'    { self.icon   }
        }
    }

    has $.buttons = Q:to/END/;
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
            }

            // Load saved theme on page load
            document.addEventListener("DOMContentLoaded", () => {
                const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                const initialTheme = systemPrefersDark ? "dark" : "light";
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

    has $.icon = Q:to/END/;
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
                updateIcons(newTheme);
            }

            // Load saved theme on page load
            document.addEventListener("DOMContentLoaded", () => {
                const savedTheme = localStorage.getItem("theme") || "light";  //default to light
                const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                const initialTheme = systemPrefersDark ? "dark" : "light";
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

# More Roles TBD?
role Theme {}

##### Site Classes #####

class External does A {
    has Str $!label;

    has $.href is required;
    has %!href = {:$!href};
    has %.others = {:target<_blank>, :rel<noopener noreferrer>};

    multi method label($_) {
        $!label = $_
    }

    multi method label {
        $!label // ''
    }

    multi method HTML {
        %.attrs = |self.others, |%!href;
        do-regular-tag( 'a', [$.label // ''], |%.attrs )
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
subset Widget of Any where * ~~ LightDark;

class Nav does Component {
    my $loaded = 0;

    has Str  $.hx-target = '#content';
    has Str  $.logo;
    has NavItem @.items;
    has Widget  @.widgets;

    method style { q:to/END/
        <style>
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
        </style>
    END
	}

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

    method nav-items {
        do for @.items.map: *.kv -> ($name, $target) {
            given $target {
                when * ~~ External {
                    $target.label: $name;
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
    }

    multi method HTML {
        self.style ~

        nav [
            { ul li :class<logo>, :href</>, $.logo } with $.logo;

            button( :class<hamburger>, :id<hamburger>, '&#9776;' );

            ul( :$!hx-target, :class<nav-links>,
                self.nav-items,
                do for @.widgets { li .HTML },
            );

            ul( :$!hx-target, :class<menu>, :id<menu>,
                self.nav-items,
            );
        ]

        ~ self.js;
    }

    method js { Q:to/END/;
        <script>
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
        </script>
        END
    }
}

class Page does Component {
    has $.loaded is rw = 0;
    has Int     $.REFRESH;    #auto refresh every n secs in dev't

    has Str     $.title;
    has Str     $.description;
    has Nav     $.nav is rw;  #\ either or
    has Header  $.header;     #/
    has         $.main is rw;
    has Footer  $.footer;

    has Html $.html .= new;

    method defaults {
        unless $.loaded++ {
            self.html.head.metas.append: Meta.new: attrs =>
                        { :http-equiv<refresh>, :content($.REFRESH) }   with $.REFRESH;

            self.html.head.title = Title.new: :inner($.title)           with $.title;
            self.html.head.description = Meta.new: attrs =>
                        { :name<description>, :content($.description) } with $.description;

            self.html.body.header.nav = $.nav                           with $.nav;
            self.html.body.header = $.header                            with $.header;
            self.html.body.main   = $.main                              if $.main ~~ Main;
            self.html.body.main   = Main.new: $.main                    if $.main ~~ Str;
            self.html.body.footer = $.footer                            with $.footer;
        }
    }

    multi method new($main) {
        self.new: :$main;
    }

    multi method HTML {
        self.defaults unless $.loaded;
        '<!doctype html>' ~ $!html.HTML
    }
}

class Site {
    has Page @.pages;
    has Page $.index is rw = @!pages[0];

    has Bool $.scss;  # run sass compiler

    #| <amber azure blue cyan fuchsia green indigo jade lime orange
    #| pink pumpkin purple red violet yellow> (pico theme)
    has Str  $.theme-color = 'green';

    #| one from <aqua black blue fuchsia gray green lime maroon navy
    # | olive purple red silver teal white yellow> (basic css)
    has Str  $.bold-color  = 'red';

    multi method new(Page $index, *%h) {
        self.new: :$index, |%h;
    }

    use Cro::HTTP::Router;

    method routes {
        self.scss with $!scss;

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

##### Functions Export #####

#| put in all the @components as functions
#| viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing
my package EXPORT::DEFAULT {

    for @components -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
#                ::($name).new( |@a, |%h )
                ::($name).new( |@a, |%h ).HTML
            }
    }
}

my package EXPORT::NONE { }

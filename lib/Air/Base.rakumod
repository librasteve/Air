=begin pod

=head1 Air::Base

This raku module is one of the core libraries of the raku B<Air> module.

It provides a Base library of functional Tags and Components that can be composed into web applications.

Air::Base uses Air::Functional for standard HTML tags expressed as raku subs. Air::Base uses Air::Component for scaffolding for library Components.


=head2 Architecture

Here's a diagram of the various Air parts. (Air::Play is a separate raku module with several examples of Air websites.)

=begin code
            +----------------+
            |    Air::Play   |    <-- Web App
            +----------------+
                    |
          +-------------------+
          |  Air::Play::Site  |   <-- Site Lib
          +-------------------+
                    |
            +----------------+
            |    Air::Base   |    <-- Base Lib
            +----------------+
               /           \
  +----------------+  +----------------+
  | Air::Functional|  | Air::Component |  <-- Services
  +----------------+  +----------------+
=end code

=para The general idea is that there will a small number of Base libraries, typically provided by raku module authors that package code that implements a specific CSS package and/or site theme. Then, each user of Air - be they an individual or team - can create and selectively load their own Site library modules that extend and use the lower modules. All library Tags and Components can then be composed by the Web App.

=para This facilitates an approach where Air users can curate and share back their own Tag and Component libraries. Therefore it is common to find a Base Lib and a Site Lib used together in the same Web App.

=para In many cases Air::Base will consume a standard HTML tag (eg. C<table>), customize and then re-export it with the same sub name. Therefore two export packages C<:CRO> and C<:BASE> are included to prevent namespace conflict.

=para The current Air::Base package is unashamedly opionated about CSS and is based on L<Pico CSS|https://picocss.org>. Pico was selected for its semantic tags and very low level of HTML attribute noise. Pico SASS is used to control high level theme variables at the Site level.

=head4 Notes

=item Higher layers also use Air::Functional and Air::Component services directly
=item Externally loadable packages such as Air::Theme are on the development backlog
=item Other CSS modules - Air::Base::TailWind? | Air::Base::Bootstrap? - are anticipated


=head1 SYNOPSIS

The synopsis is split so that each part can be annotated.

=head3 Content

=begin code :lang<raku>
use Air::Functional :BASE;
use Air::Base;

my %data =
    :thead[["Planet", "Diameter (km)", "Distance to Sun (AU)", "Orbit (days)"],],
    :tbody[
        ["Mercury",  "4,880", "0.39",  "88"],
        ["Venus"  , "12,104", "0.72", "225"],
        ["Earth"  , "12,742", "1.00", "365"],
        ["Mars"   ,  "6,779", "1.52", "687"],
    ],
    :tfoot[["Average", "9,126", "0.91", "341"],];

my $Content1 = content [
    h3 'Content 1';
    table |%data, :class<striped>;
];

my $Content2 = content [
    h3 'Content 2';
    table |%data;
];

my $Google = external :href<https://google.com>;
=end code

Key features shown are:
=item application of the C<:BASE> modifier on C<use Air::Functional> to avoid namespace conflict
=item definition of table content as a Hash C<%data> of Pairs C<:name[[2D Array],]>
=item assignment of two functional C<content> tags and their arguments to vars
=item assignment of a functional C<external> tag with attrs to a var

=head3 Page

=para The template of an Air website (header, nav, logo, footer) is applied by making a custom C<page> ... here C<index> is set up as the template page. In this SPA example navlinks dynamically update the same page content via HTMX, so index is only used once, but in general multiple instances of the template page can be cookie cuttered. Any number of page template can be set up in this way and can reuse custom Components.

=begin code :lang<raku>
my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Raku, Cro',
    nav         => nav(
        logo    => safe('<a href="/">h<b>&Aring;</b>rc</a>'),
        items   => [:$Content1, :$Content2, :$Google],
        widgets => [lightdark],
    ),
    footer      => footer p ['Aloft on ', b 'Åir'],
);
=end code

Key features shown are:
=item set the C<index> functional tag as a modified Air::Base C<page> tag
=item use of C<.assuming> for functional code composition
=item use of => arrow Pair syntax to set a custom page theme with title, description, nav, footer
=item use of C<nav> functional tag and passing it attrs of the C<NavItems> defined
=item use of C<:$Content1> Pair syntax to pass in both nav link text (ie the var name as key) and value
=item Nav routes are automagically generated and HTMX attrs are used to swap in the content inners
=item use of C<safe> functional tag to suppress HTML escape
=item use of C<lightdark> widget to toggle theme according to system and user preference

=head3 Site

=begin code :lang<raku>
sub SITE is export {
    site
        index
            main $Content1
}
=end code

Key features shown are:
=item use of C<site> functional tag - that sets up the site Cro routes and Pico SASS theme
=item C<site> takes the C<index> page as positional argument
=item C<index> takes a C<main> functional tag as positional argument
=item C<main> takes the initial content

=head1 DESCRIPTION

Each feature of Air::Base is set out below:
=end pod

# TODO items
#role Theme {...}
#role Form  {...}

use Air::Functional;
use Air::Component;

my @functions = <Site Page A External Internal Content Section Article Aside Time Nav LightDark Body Header Main Footer Table Grid Safe>;

enum TagType is export <Singular Regular>;
subset Attr of Str;

=head2 role Tagged[Singular|Regular] does Tag

#| consuming class behaves like a standard HTML tag from Air::Functional
role Tagged[TagType $tag-type] does Tag {
    has Str     $.name = ::?CLASS.^name.lc;

    #| can be provided with attrs
    has Attr()  %.attrs is rw;   #coercion accepts multi-valued attrs with spaces

    #| can be provided with inners
    has         @.inners;

    #| ok to call .new with @inners as Positional
    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, :%attrs
    }

    #| provides default .HTML method used by tag render
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

=head2 Basic Tags

=para A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient set of elements for the Page Tags.

class Nav  { ... }
class Page { ... }

=head3 role Safe   does Tagged[Regular] {...}

role Safe   does Tagged[Regular]  {
    #| avoids HTML escape
    multi method HTML {
        @.inners.join
    }
}

=head3 role Script does Tagged[Regular] {...}

role Script does Tagged[Regular]  {
    #| no html escape
    multi method HTML {
        opener($.name, |%.attrs) ~
        (@.inners.first// '')    ~
        closer($.name)           ~ "\n"
    }
}

=head3 role Style  does Tagged[Regular] {...}

role Style  does Tagged[Regular]  {
    #| no html escape
    multi method HTML {
        opener($.name, |%.attrs)  ~
        @.inners.first            ~
        closer($.name)            ~ "\n"
    }
}

=head3 role Meta   does Tagged[Singular] {}

role Meta   does Tagged[Singular] {}

=head3 role Title  does Tagged[Regular]  {}

role Title  does Tagged[Regular]  {}

=head3 role Link  does Tagged[Regular]  {}

role Link   does Tagged[Singular] {}

=head3 role A      does Tagged[Regular] {...}

role A      does Tagged[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :target<_blank>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head2 Page Tags

=para A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient and opinionated set of defaults for C<html>, C<head>, C<body>, C<header>, C<nav>, C<main> & C<footer>. Several of the page tags offer shortcut attrs that are populated up the DOM immediately prior to first use.

=head3 role Head   does Tagged[Regular] {...}

role Head   does Tagged[Regular]  {

    =para Singleton pattern (ie. same Head for all pages)

    my Head $instance;
    multi method new {note "Please use Head.instance rather than Head.new!\n"; self.instance}
    submethod instance {
        unless $instance {
            $instance = Head.bless;
            $instance.defaults;
        };
        $instance;
    }

    #| title
    has Title  $.title is rw;
    #| description
    has Meta   $.description is rw;
    #| metas
    has Meta   @.metas;
    #| scripts
    has Script @.scripts;
    #| links
    has Link   @.links;
    #| style
    has Style  $.style is rw;

    #| set up common defaults (called on instantiation)
    method defaults {
        self.metas.append: Meta.new: :charset<utf-8>;
        self.metas.append: Meta.new: :name<viewport>, :content<width=device-width, initial-scale=1>;
        self.links.append: Link.new: :rel<stylesheet>, :href</css/styles.css>;
        self.links.append: Link.new: :rel<icon>, :href</img/favicon.ico>, :type<image/x-icon>;
        self.scripts.append: Script.new: :src<https://unpkg.com/htmx.org@1.9.5>, :crossorigin<anonymous>,
                :integrity<sha384-xcuj3WpfgjlKF+FXhSQFQ0ZNr39ln+hwjN3npfM9VBnUskLolQAcN80McRIVOPuO>;
    }

    #| .HTML method calls .HTML on all attrs
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

=head3 role Header does Tagged[Regular] {...}

role Header does Tagged[Regular]  {
    #| nav
    has Nav  $.nav is rw;
    #| tagline
    has Safe $.tagline;

    multi method HTML {
        my %attrs  = |%.attrs, :class<container>;
        my @inners = |@.inners, $.nav // Empty, $.tagline // Empty;

        do-regular-tag( $.name, @inners, |%attrs )
    }
}

=head3 role Main   does Tagged[Regular] {...}

role Main   does Tagged[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :class<container>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Footer does Tagged[Regular] {...}

role Footer does Tagged[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :class<container>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head 3 role Body   does Tagged[Regular] {...}

role Body   does Tagged[Regular]  {
    #| header
    has Header $.header is rw .= new;
    #| main
    has Main   $.main   is rw .= new;
    #| footer
    has Footer $.footer is rw .= new;

    multi method HTML {
        opener($.name, |%.attrs) ~
        $!header.HTML            ~
        $!main.HTML              ~
        $!footer.HTML            ~
        closer($.name)           ~ "\n"
    }
}

=head3 role Html   does Tagged[Regular] {...}

role Html   does Tagged[Regular]  {
    my $loaded = 0;

    #| head
    has Head $.head .= instance;
    #| body
    has Body $.body is rw .= new;

    #| default :lang<en>
    has Attr %.lang is rw = :lang<en>;
    #| default :data-theme<dark>
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


=head2 Semantic Tags

=para These are re-published with minor adjustments and align with Pico CSS semantic tags

=head3 role Content   does Tagged[Regular] {...}

role Content   does Tagged[Regular] {
    multi method HTML {
        my %attrs  = |%.attrs, :id<content>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Section   does Tagged[Regular] {}

role Section   does Tagged[Regular] {}

=head3 role Article   does Tagged[Regular] {}

role Article   does Tagged[Regular] {}

=head3 role Article   does Tagged[Regular] {}

role Aside     does Tagged[Regular] {}

=head3 role Time      does Tagged[Regular] {...}

=para In HTML the time tag is typically of the form E<lt> time datetime="2025-03-13" E<gt> 13 March, 2025 E<lt> /time E<gt> . In Air you can just go time(:datetime E<lt> 2025-02-27 E<gt> ); and raku will auto format and fill out the inner human readable text.

role Time      does Tagged[Regular] {
    use DateTime::Format;

    multi method HTML {
        my $dt = DateTime.new(%.attrs<datetime>);

        =para optionally specify mode => [time | datetime], mode => date is default

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


=head2 Widgets

=para Active tags that can be used eg in Nav, typically load in some JS behaviours

=head3 role LightDark does Tagged[Regular] {...}

role LightDark does Tagged[Regular] {
    #| set to icon(default) or buttons
    has Str $.show = 'icon';

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

=head2 Site Tags

=para These are the central elements of Air::Base

=para First we set up the NavItems = Internal | External | Content | Page

=head3 role External  does Tagged[Regular] {...}

role External  does Tagged[Regular] {
    has Str $.label is rw = '';
    has %.others = {:target<_blank>, :rel<noopener noreferrer>};

    multi method HTML {
        my %attrs = |self.others, |%.attrs;
        do-regular-tag( 'a', [$.label], |%attrs )
    }
}

=head3 role Internal  does Tagged[Regular] {...}

role Internal  does Tagged[Regular] {
    has Str $.label is rw = '';

    multi method HTML {
        do-regular-tag( 'a', [$.label], |%.attrs )
    }
}
subset NavItem of Pair where .value ~~ Internal | External | Content | Page;

#| Nav does Component in order to support
#| multiple nav instances with distinct NavItem and Widget attributes.
#| Also does Tag so that nav tags can be placed anywhere on a page.
class Nav  does Component does Tag {
    has Str     $.hx-target = '#content';
    #| logo
    has Safe    $.logo;
    #| NavItems
    has NavItem @.items;
    #| Widgets
    has Widget  @.widgets;

    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    #| makes routes for Content NavItems (SPA links that use HTMX), must be called from within a Cro route block
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

    #| renders NavItems [subset NavItem of Pair where .value ~~ Internal | External | Content | Page;]
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

    #| applies Style and Script for Hamburger reactive menu
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

#| Page does Component in order to support
#| multiple page instances with distinct content and attributes.
class Page does Component {
    has $.loaded is rw = 0;

    #| auto refresh browser every n secs in dev't
    has Int     $.REFRESH;

    =para page implements several shortcuts that are populated up the DOM, for example C<page :title('My Page")> will go C<self.html.head.title = Title.new: $.title with $.title;>

    #| shortcut self.html.head.title
    has Str     $.title;
    #| shortcut self.html.head.description
    has Str     $.description;
    #| shortcut self.html.body.header.nav -or-
    has Nav     $.nav is rw;
    #| shortcut self.html.body.header [nav wins if both attrs set]
    has Header  $.header;
    #| shortcut self.html.body.main
    has Main    $.main is rw;
    #| shortcut self.html.body.footer
    has Footer  $.footer;

    #| set to True with :styled-aside-on to apply self.html.head.style with right hand aside block
    has Bool    $.styled-aside-on = False;

    #| build page DOM by calling Air tags
    has Html    $.html .= new;

    #| set all provided shortcuts on first use
    method defaults {
        unless $.loaded++ {
            self.html.head.scripts.append: $.scripted-refresh           with $.REFRESH;

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

    #| .new positional with main only
    multi method new(Main $main, *%h) {
        self.bless: :$main, |%h
    }
    #| .new positional with main & footer only
    multi method new(Main $main, Footer $footer, *%h) {
        self.bless: :$main, :$footer, |%h
    }
    #| .new positional with header, main & footer only
    multi method new(Header $header, Main $main, Footer $footer, *%h) {
        self.bless: :$header, :$main, :$footer, |%h
    }

    #| issue page DOM
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

    method scripted-refresh { Script.new: qq:to/END/
        function checkServer() \{
            console.log("Checking server...");

            fetch(window.location.href, \{ method: "GET", cache: "no-store" \})
                .then(response => \{
                    console.log("Server responded with status:", response.status);

                    if (response.ok) \{
                        console.log("Server is up! Refreshing now...");
                        location.reload(); // Refresh immediately when the server is back
                    \}
                \})
                .catch(error => \{
                    console.log("Server is down, not refreshing.");
                \});
        }

        setInterval(checkServer, {$!REFRESH*1000}); // Check every $!REFRESH seconds
        END
    }
}

#| Site is a holder for pages, performs setup
#| of Cro routes and offers high level controls for style via Pico SASS.
class Site {
    #| Page holder
    has Page @.pages;
    #| index Page [defaults to @!pages[0]
    has Page $.index is rw = @!pages[0];
    #| Components for route setup; default = [Nav.new]
    has Component @.components = [Nav.new];

    #| use :!scss to disable SASS compiler run
    has Bool $.scss = True;

    #| pick from: amber azure blue cyan fuchsia green indigo jade lime orange
    #| pink pumpkin purple red violet yellow (pico theme)
    has Str  $.theme-color = 'green';

    #| pick from:- aqua black blue fuchsia gray green lime maroon navy
    #| olive purple red silver teal white yellow (basic css)
    has Str  $.bold-color  = 'red';

    #| .new positional with index only
    multi method new(Page $index, *%h) {
        self.bless: :$index, |%h;
    }

    use Cro::HTTP::Router;

    method routes {
        self.scss with $!scss;

        route {
            { .^add-routes } for @!components.unique( as => *.^name );

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


=head2 Pico Tags

=para  The Air roadmap is to provide a full set of pre-styled tags as defined in the Pico L<docs|https://picocss.com/docs>. Did we say that Air::Base implements Pico CSS?

=head3 role Table does Tag

role Table does Tag {

    =para Attrs thead, tbody and tfoot can each be a 2D Array [[values],] that iterates to row and columns or a Tag|Component - if the latter then they are just rendered via their .HTML method. This allow for multi-row thead and tfoot.

    =para Table applies col and row header tags as required for Pico styles.

    =para Attrs provided as Pairs via tbody are extracted and applied. This is needed for :id<target> where HTMX is targetting the table body.

    #| default = [] is provided
    has $.tbody = [];
    #| optional
    has $.thead;
    #| optional
    has $.tfoot;
    #| class for table
    has $.class;

    has %!tbody-attrs;

    #| .new positional takes tbody [[]]
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

=head3 role Table does Tag

role Grid does Tag {
    #| list of items to populate grid, each item is wrapped in a span tag
    has @.items;

    #| .new positional takes @items
    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    # optional grid style from https://cssgrid-generator.netlify.app/
    # todo .... expose some of this as attrs
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
            do for @!items { span $_ };
    }
}

##### Functions Export #####

#| put in all the @components as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing
my package EXPORT::DEFAULT {

    for @functions -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
                ::($name).new( |@a, |%h )
            }
    }
}

my package EXPORT::NONE { }

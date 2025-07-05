=begin pod

=head1 Air::Base

This raku module is one of the core libraries of the raku B<Air> distribution.

It provides a Base library of functional Tags and Components that can be composed into web applications.

Air::Base uses Air::Functional for standard HTML tags expressed as raku subs. Air::Base uses Air::Component for scaffolding for library Components.


=head2 Architecture

Here's a diagram of the various Air parts. (Air::Examples is a separate raku module with several examples of Air websites.)

=begin code
                         +----------------+
                         |  Air::Example  |    <-- Web App
                         +----------------+
                                 |
                    +--------------------------+
                    |   Air::Example::Site     |  <-- Site Lib
                    +--------------------------+
                       /                    \
              +----------------+   +-----------------+
              |    Air::Base   |   |    Air::Form    |  <-- Base Lib
              +----------------+   +----------------+
                      |          \          |
              +----------------+   +-----------------+
              | Air::Component |   | Air::Functional | <-- Services
              +----------------+   +-----------------+
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
    description => 'HTMX, Air, Red, Cro',
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

use Air::Functional;
use Air::Component;
use Air::Form;

my @functions = <Safe Site Page A Button External Internal Content Section Article Aside Time Spacer Nav Background LightDark Body Header Main Footer Table Grid Flexbox Tab Tabs Markdown Dialog Lightbox>;

=head2 Basic Tags

=para Air::Functional converts all HTML tags into raku functions. Air::Base overrides a subset of these HTML tags, providing them both as raku roles and functions.

=para The Air::Base tags each embed some code to provide behaviours. This can be simple - C<role Script {}> just marks JavaScript as exempt from HTML Escape. Or complex - C<role Body {}> has C<Header>, C<Main> and C<Footer> attributes with certain defaults and constructors.

=para Combine these tags in the same way as the overall layout of an HTML webpage. Note that they hide complexity to expose only relevant information to the fore. Override them with your own roles and classes to implement your specific needs.

class Nav  { ... }
class Page { ... }

=head3 role Safe   does Tag[Regular] {...}

role Safe   does Tag[Regular]  {
    #| avoids HTML escape
    multi method HTML {
        @.inners.join
    }
}

=head3 role Script does Tag[Regular] {...}

role Script does Tag[Regular]  {
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

role Meta   does Tag[Singular] {}

=head3 role Title  does Tag[Regular]  {}

role Title  does Tag[Regular]  {}

=head3 role Link  does Tag[Regular]  {}

role Link   does Tag[Singular] {}

=head3 role A      does Tag[Regular] {...}

role A      does Tag[Regular]  {
    #| defaults to target="_blank"
    multi method HTML {
        my %attrs = |%.attrs;
        %attrs<target> = '_blank' without %attrs<target>;

        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Button does Tag[Regular] {}

role Button does Tag[Regular]  {}

=head2 Page Tags

=para A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient and opinionated set of defaults for C<html>, C<head>, C<body>, C<header>, C<nav>, C<main> & C<footer>. Several of the page tags offer shortcut attrs that are populated up the DOM immediately prior to first use.

=head3 role Head   does Tag[Regular] {...}

role Head   does Tag[Regular]  {

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
    has Style  @.styles;

    #| set up common defaults (called on instantiation)
    method defaults {
        self.metas.append: Meta.new: :charset<utf-8>;
        self.metas.append: Meta.new: :name<viewport>, :content('width=device-width, initial-scale=1');
        self.links.append: Link.new: :rel<icon>, :href</img/favicon.ico>, :type<image/x-icon>;
        self.links.append: Link.new: :rel<stylesheet>, :href</css/styles.css>;
        self.scripts.append: Script.new: :src<https://unpkg.com/htmx.org@1.9.5>, :crossorigin<anonymous>,
                :integrity<sha384-xcuj3WpfgjlKF+FXhSQFQ0ZNr39ln+hwjN3npfM9VBnUskLolQAcN80McRIVOPuO>;
    }

    #| .HTML method calls .HTML on all inners
    multi method HTML {
        opener($.name, |%.attrs)          ~
        "{ .HTML with $!title          }" ~
        "{ .HTML with $!description    }" ~
        "{(.HTML for  @!metas   ).join }" ~
        "{(.HTML for  @!scripts ).join }" ~
        "{(.HTML for  @!links   ).join }" ~
        "{(.HTML for  @!styles  ).join }" ~
        closer($.name)                    ~ "\n"
    }
}

=head3 role Header does Tag[Regular] {...}

role Header does Tag[Regular]  {
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

=head3 role Main   does Tag[Regular] {...}

role Main   does Tag[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :class<container>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Footer does Tag[Regular] {...}

role Footer does Tag[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :class<container>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head 3 role Body   does Tag[Regular] {...}

role Body   does Tag[Regular]  {
    #| header
    has Header $.header is rw .= new;
    #| main
    has Main   $.main   is rw .= new;
    #| footer
    has Footer $.footer is rw .= new;
    #| scripts
    has Script @.scripts;

    multi method HTML {
        opener($.name, |%.attrs)   ~
        $!header.HTML              ~
        $!main.HTML                ~
        $!footer.HTML              ~
        @!scripts.map(*.HTML).join ~
        closer($.name)             ~ "\n"
    }
}

=head3 role Html   does Tag[Regular] {...}

role Html   does Tag[Regular]  {
    has $!loaded = 0;

    #| head
    has Head   $.head .= instance;
    #| body
    has Body   $.body is rw .= new;

    #| default :lang<en>
    has Attr() %.lang is rw = :lang<en>;
    #| default :data-theme<dark>
    has Attr() %.mode is rw = :data-theme<dark>;

    method defaults {
        self.attrs = |%!lang, |%!mode, |%.attrs;
    }

    multi method HTML {
        self.defaults unless $!loaded++;

        opener($.name, |%.attrs) ~
        $!head.HTML              ~
        $!body.HTML              ~
        closer($.name)           ~ "\n"
    }
}


=head2 Semantic Tags

=para These are re-published with minor adjustments and align with Pico CSS semantic tags

=head3 role Content   does Tag[Regular] {...}

role Content   does Tag[Regular] {
    multi method HTML {
        my %attrs  = |%.attrs, :id<content>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Section   does Tag[Regular] {}

role Section   does Tag[Regular] {}

=head3 role Article   does Tag[Regular] {}

role Article   does Tag[Regular] {

    # Keep text ltr even when grid direction rtl
    multi method HTML {
        my %attrs  = |%.attrs, :style("direction:ltr;");
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Aside     does Tag[Regular] {}

role Aside     does Tag[Regular] {
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

role Time      does Tag[Regular] {
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

=head3 role Spacer does Tag

role Spacer    does Tag {
    has Str $.height = '1em';  #iamerejh

#    multi method new($height) {
#        self.bless: :$height;
#    }

    multi method HTML {
        note $!height;
        do-regular-tag( 'div', :style("min-height:$!height;") )
    }
}


=head2 Widgets

=para Active tags that can be used anywhere to provide a nugget of UI behaviour, default should be a short word (or a single item) that can be used in Nav

role Widget {}

=head3 role LightDark does Tag[Regular] does Widget {...}

role LightDark does Tag does Widget {
    #| attribute 'show' may be set to 'icon'(default) or 'buttons'
    multi method HTML {
        my $show = self.attrs<show> // 'icon';
        given $show {
            when 'buttons' { Safe.new: self.buttons }
            when 'icon'    { Safe.new: self.icon    }
        }
    }

    method buttons {
        Q|
        <div role="group">
            <button class="contrast"  id="themeToggle">Toggle</button>
            <button                   id="themeLight" >Light</button>
            <button class="secondary" id="themeDark"  >Dark</button>
            <button class="outline"   id="themeSystem">System</button>
        </div>
        <script>
        |

        ~ self.common ~

        Q|
            // Attach to a button click
            document.getElementById("themeToggle").addEventListener("click", () => setTheme("toggle"));
            document.getElementById("themeDark").addEventListener("click", () => setTheme("dark"));
            document.getElementById("themeLight").addEventListener("click", () => setTheme("light"));
            document.getElementById("themeSystem").addEventListener("click", () => setTheme("system"));
        </script>
        |;
    }

    method icon {
        Q|
        <a style="font-variant-emoji: text" id ="sunIcon">&#9728;</a>
        <a style="font-variant-emoji: text" id ="moonIcon">&#9790;</a>
        <script>
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
        |

        ~ self.common ~

        Q|
            const sunIcon = document.getElementById("sunIcon");
            const moonIcon = document.getElementById("moonIcon");

            // Attach to a icon click
            document.getElementById("sunIcon").addEventListener("click", () => setTheme("dark"));
            document.getElementById("moonIcon").addEventListener("click", () => setTheme("light"));
        </script>
        |;
    }

    method common {
        Q:to/END/
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
                const savedTheme = localStorage.getItem("theme") || "dark";  //default to dark
                const systemPrefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
                const initialTheme = savedTheme || (systemPrefersDark ? "dark" : "light");

                updateIcons(initialTheme);
                document.documentElement.setAttribute("data-theme", initialTheme);
            });

            // Listen for system dark mode changes and update the theme dynamically
            window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", () => {
                setTheme("system"); // Follow system setting
            });
        END
    }
}

=head2 Tools

=para Tools are provided to the site tag to provide a nugget of side-wide behaviour, services method defaults are distributed to all pages on server start

role Tool {}

=head3 role Analytics does Tool {...}

enum Provider is export <Umami>;

role Analytics does Tool {
    #| may be [Umami] - others TBD
    has Provider $.provider;
    #| website ID from provider
    has Str      $.key;

    multi method defaults($page) {
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

=head2 Site Tags

=para These are the central elements of Air::Base

=para First we set up the NavItems = Internal | External | Content | Page

=head3 role External  does Tag[Regular] {...}

role External  does Tag {
    has Str $.label is rw = '';
    has %.others = {:target<_blank>, :rel<noopener noreferrer>};

    multi method HTML {
        my %attrs = |self.others, |%.attrs;
        do-regular-tag( 'a', [$.label], |%attrs )
    }
}

=head3 role Internal  does Tag[Regular] {...}

role Internal  does Tag {
    has Str $.label is rw = '';

    multi method HTML {
        do-regular-tag( 'a', [$.label], |%.attrs )
    }
}

=head3 subset NavItem of Pair where .value ~~ Internal | External | Content | Page;

subset NavItem of Pair where .value ~~ Internal | External | Content | Page;

#| Nav does Component in order to support multiple nav instances
#| with distinct NavItem and Widget attributes
class Nav      does Component {
    has $!routed = 0;

    #| HTMX attributes
    has Str     $.hx-target = '#content';
    has Str     $.hx-swap   = 'outerHTML';
    #| logo
    has Markup  $.logo;
    #| NavItems
    has NavItem @.items;
    #| Widgets
    has Widget  @.widgets;

    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    #| makes routes for Content NavItems (eg. SPA links that use HTMX)
    #| must be called from within a Cro route block
    method make-routes() {
        return if $!routed++;
        do for self.items.map: *.kv -> ($name, $target) {
            given $target {
                when Content {
                    my &new-method = method {$target.?HTML};
                    trait_mod:<is>(&new-method, :controller{:$name, :returns-html});
                    self.^add_method($name, &new-method);
                }
                when Page {
                    my &new-method = method {$target.?HTML};
                    trait_mod:<is>(&new-method, :controller{:$name, :returns-html});
                    self.^add_method($name, &new-method);
                }
            }
        }
    }

    #| renders NavItems
    method nav-items {
        do for @.items.map: *.kv -> ($name, $target) {
            given $target {
                when External | Internal {
                    .label = $name;
                    li .HTML
                }
                when Content {
                    li a(:hx-get("$.url-path/$name"), Safe.new: $name)
                }
                when Page {
                    li a(:href("$.url-path/$name"), Safe.new: $name)
                }
            }
        }
    }

    #| applies Style and Script for Hamburger reactive menu
    method HTML {

        nav [
            { ul li :class<logo>, $.logo } with $.logo;

            button( :class<hamburger>, :id<hamburger>, Safe.new: '&#9776;' );

            #regular menu
            ul( :$!hx-target, :$!hx-swap, :class<nav-links>,
                self.nav-items,
                do for @.widgets { li .HTML },
            );

            #hamburger menu
            ul( :$!hx-target, :$!hx-swap, :class<menu>, :id<menu>,
                self.nav-items,
            );
        ]
    }

    method STYLE {
        q:to/END/
        /* Custom styles for the hamburger menu */
        .menu {
            display: none;
            flex-direction: column;
            gap: 10px;
            position: absolute;
            top: 60px;
            right: 20px;
            background: rgba(0, 0, 0, .85);
            padding: 1rem;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(128, 128, 128, .2);
            z-index: 800;
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

    method SCRIPT {
        Q:to/END/;
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

=head3 role Background  does Component

role Background does Component {
    #| top of background image (in px)
    has $.top = 140;
    #| height of background image (in px)
    has $.height = 320;
    #| url of background image
    has $.url = 'https://upload.wikimedia.org/wikipedia/commons/f/fd/Butterfly_bottom_PSF_transparent.gif';
    #| opacity of background image
    has $.opacity = 0.1;
    #| rotate angle of background image (in deg)
    has $.rotate = -9;

    method STYLE {
        my $scss = q:to/END/;
        #background {
            position: fixed;
            top: %TOP%px;
            left: 0;
            width: 100vw;
            height: %HEIGHT%px;
            background: url('%URL%');
            opacity: %OPACITY%;
            filter: grayscale(100%);
            transform: rotate(%ROTATE%deg);
            background-repeat: no-repeat;
            background-position: center center;
            z-index: -1;
            pointer-events: none;
            padding: 20px;
        }
        END

        $scss ~~ s:g/'%TOP%'/$!top/;
        $scss ~~ s:g/'%HEIGHT%'/$!height/;
        $scss ~~ s:g/'%URL%'/$!url/;
        $scss ~~ s:g/'%OPACITY%'/$!opacity/;
        $scss ~~ s:g/'%ROTATE%'/$!rotate/;
        $scss
    }

    method HTML {
        do-regular-tag( 'div', :id<background> )
    }
}

#| Page does Component in order to support
#| multiple page instances with distinct content and attributes.
class Page     does Component {
    has $!loaded;

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

    #| build page DOM by calling Air tags
    has Html    $.html .= new;

    #| set all provided shortcuts on first use
    method defaults {
        unless $!loaded++ {
            self.html.head.scripts.append: $.scripted-refresh           with $.REFRESH;
            self.html.head.title = Title.new: $.title                   with $.title;

            self.html.head.description = Meta.new:
                         :name<description>, :content($.description)    with $.description;

            with   $.nav    { self.html.body.header.nav = $.nav }
            orwith $.header { self.html.body.header = $.header  }

            self.html.body.main   = $.main                              with $.main;
            self.html.body.footer = $.footer                            with $.footer;
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

    #| issue page
    method HTML {
        self.defaults unless $!loaded;
        '<!doctype html>' ~ $!html.HTML
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
    my $loaded;

    #| Page holder -or-
    has Page @.pages;
    #| index Page ( otherwise $!index = @!pages[0] )
    has Page $.index;
    #| Register for route setup; default = [Nav.new]
    has      @.register;
    #| Tools for sitewide behaviours
    has Tool @.tools      = [];


    #| use :!scss to disable SASS compiler run
    has Bool $.scss-off;
    has Str  $!scss-gather;

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

    #| enqueued items will be rendered in order supplied
    #| this is deterministic
    #|  - each plugin can apply an internal order
    #|  - registration is performed in list order
    #| (please avoid interdependent js / css)
    method enqueue-all {
        return if $loaded++;

        for @!register.unique( as => *.^name ) -> $registrant {

            with $registrant.?SCSS {
                $!scss-gather ~= "\n\n" ~ $_;
            }

            #| SCRIPT default inserts at end of body
            for @!pages -> $page {
                with $registrant.?SCRIPT {
                    $page.html.body.scripts.append: Script.new($_)
                }
            }

            my $head = @!pages.first.html.head;  # NB. head is a singleton

            for $registrant.?JS-LINKS -> $src {
                next unless $src.defined;
                $head.scripts.append: Script.new( :$src );
            }

            #| SCRIPT-HEAD can be used if needed
            with $registrant.?SCRIPT-HEAD {
                $head.scripts.append: Script.new($_)
            }

            for $registrant.?CSS-LINKS -> $href {
                next unless $href.defined;
                $head.links.append: Link.new( :$href, :rel<stylesheet> );
            }

            with $registrant.?STYLE {
                $head.styles.append: Style.new($_)
            }
        }
    }

    submethod TWEAK {
        with    @!pages[0] { $!index = @!pages[0] }
        orwith  $!index    { @!pages[0] = $!index }
        else    { note "No pages or index found!" }

        #| always enqueue & route Nav
        @!register.push: Nav.new;

        self.enqueue-all;
        self.scss-run unless $!scss-off;

        for @!tools -> $tool {
            for @!pages -> $page {
                $tool.defaults($page)
            }
        }
    }

    method routes {
        use Cro::HTTP::Router;

        route {
            #| setup Cro routes
            for @!register.unique( as => *.^name ) {
                when Component::Common {
                    .make-methods;
                    .^add-cromponent-routes;
                }
                when Form {
                    .form-routes
                }
            }

            #| setup static Cro routes
            get ->               { content 'text/html', $.index.HTML }
            get -> 'css', *@path { static 'static/css', @path }
            get -> 'img', *@path { static 'static/img', @path }
            get -> 'js',  *@path { static 'static/js',  @path }
            get ->        *@path { static 'static',     @path }
        }
    }

    method scss-run {
        my $css = self.scss-theme ~ "\n\n";
        $css ~= $_ with $!scss-gather;

        note "theme-color=$!theme-color";
        $css ~~ s:g/'%THEME_COLOR%'/$!theme-color/;

        note "bold-color=$!bold-color";
        $css ~~ s:g/'%BOLD_COLOR%'/$!bold-color/;

        chdir "static/css";
        spurt "styles.scss", $css;
        qx`sass styles.scss styles.css 2>/dev/null`;  #sinks warnings to /dev/null
        chdir "../..";
    }

    method scss-theme { Q:to/END/;
        @use "node_modules/@picocss/pico/scss" with (
          $theme-color: "%THEME_COLOR%"
        );

        //some root overrides for scale https://github.com/picocss/pico/discussions/482

        :root {
          --pico-font-family-sans-serif: Inter, system-ui, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, Helvetica, Arial, "Helvetica Neue", sans-serif, var(--pico-font-family-emoji);
          --pico-font-size: 106.25%;                        /* Original: 100% */
          --pico-line-height: 1.25;                         /* Original: 1.5 */
          --pico-form-element-spacing-vertical: 0.5rem;     /* Original: 1rem */
          --pico-form-element-spacing-horizontal: 1.0rem;   /* Original: 1.25rem */
          --pico-border-radius: 0.375rem;                   /* Original: 0.25rem */
        }

        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
          --pico-font-weight: 600;                          /* Original: 700 */
        }

        article {
          border: 1px solid var(--pico-muted-border-color); /* Original doesn't have a border */
          border-radius: calc(var(--pico-border-radius) * 2); /* Original: var(--pico-border-radius) */
        }

        article>footer {
          border-radius: calc(var(--pico-border-radius) * 2); /* Original: var(--pico-border-radius) */
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


=head2 Component Library

=para  The Air roadmap is to provide a full set of pre-styled tags as defined in the Pico L<docs|https://picocss.com/docs>. Did we say that Air::Base implements Pico CSS?

=head3 role Table does Tag

role Table     does Component {

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

    multi sub do-part($part, :$head) { '' }
    multi sub do-part(@part where .all ~~ Tag|Taggable) {
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
        %!tbody-attrs = $!tbody.grep:   * ~~ Pair;
        $!tbody       = $!tbody.grep: !(* ~~ Pair);

        table |%(:$!class if $!class), [
            thead do-part($!thead, :head);
            tbody do-part($!tbody), :attrs(|%!tbody-attrs);
            tfoot do-part($!tfoot);
        ]
    }
}

=head3 role Grid does Component

role Grid      does Component {
    #| list of items to populate grid
    has @.items;

    has $.cols = 1;
    has $.grid-template-columns = "repeat($!cols, 1fr)";
    has $.rows = 1;
    has $.grid-template-rows    = "repeat($!rows, 1fr)";
    has $.gap = 0;
    has $.direction = 'ltr';


    #| .new positional takes @items
    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    # optional grid style from https://cssgrid-generator.netlify.app/
    method style {
        my $str = q:to/END/;
        <style>
            #%HTML-ID% {
                display: grid;
                grid-template-columns: %GTC%;
                grid-template-rows: %GTR%;
                gap: %GAP%em;
                direction: %DIR%;
            }

            @media (max-width: 1024px) {
                #%HTML-ID% {
                    grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
                    gap: 1px;
                }
            }
        </style>
        END

        $str ~~ s:g/'%HTML-ID%'/$.html-id/;
        $str ~~ s:g/'%GTC%'/$!grid-template-columns/;
        $str ~~ s:g/'%GTR%'/$!grid-template-rows/;
        $str ~~ s:g/'%GAP%'/$!gap/;
        $str ~~ s:g/'%DIR%'/$!direction/;
        $str
	}

    multi method HTML {
        $.style ~
        div :id($.html-id), @!items;
    }
}

=head3 role Flexbox does Component

role Flexbox   does Component {
    #| list of items to populate grid,
    has @.items;
    #| flex-direction (default row)
    has $.direction = 'row';
    #| gap between items in em (default 1)
    has $.gap = 1;

    #| .new positional takes @items
    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    method style {
        my $str = q:to/END/;
        <style>
            #%HTML-ID% {
                display: flex;
                flex-direction: %DIRECTION%; /* column row */
                justify-content: center;  /* centers horizontally */
                gap: %GAP%em;
            }

            /* Responsive layout - makes a one column layout instead of a two-column layout */
            @media (max-width: 768px) {
                #%HTML-ID% {
                    flex-direction: column;
                    gap: 0;
                }
            }
        </style>
        END

        $str ~~ s:g/'%HTML-ID%'/$.html-id/;
        $str ~~ s:g/'%DIRECTION%'/$!direction/;
        $str ~~ s:g/'%GAP%'/$!gap/;
        $str
    }

    multi method HTML {
        $.style ~
        div :id($.html-id), @!items;
    }
}

=head3 role Tab does Tag[Regular] {...}

role Tab       does Component {
    has @.inners;
    has %.attrs;

    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, |%attrs;
    }

    method HTML {
        my %attrs = |%.attrs, :class<tab>, :align<left>;
        do-regular-tag( 'div', @.inners, |%attrs )
    }
}

=head3 subset TabItem of Pair where .value ~~ Tab;

subset TabItem of Pair where .value ~~ Tab;

=head3 role Tabs does Component

#| Tabs does Component to control multiple tabs
role Tabs      does Component {
    has $!loaded = 0;

    has $.align-nav = 'left';

    #| list of tab sections
    has TabItem @.items;

    #| .new positional takes @items
    multi method new(*@items, *%h) {
        self.bless:  :@items, |%h;
    }

    #| makes routes for Tabs
    #| must be called from within a Cro route block
    method make-routes() {
        return if $!loaded++;
        do for self.items.map: *.kv -> ($name, $target) {
            given $target {
                when Tab {
                    my &new-method = method {$target.?HTML};
                    trait_mod:<is>(&new-method, :controller{:$name, :returns-html});
                    self.^add_method($name, &new-method);
                }
            }
        }
    }

    #| renders Tabs
    method tab-items {
        do for @.items.map: *.kv -> ($name, $target) {
            given $target {
                when Tab {
                    li a(:hx-get("$.url-path/$name"), :hx-target("#$.html-id"), Safe.new: $name)
                }
            }
        }
    }

    method STYLE {
        my $css = q:to/END/;
        .tab-nav {
            display: block;
            justify-content: %ALIGN-NAV%;
        }
        .tab-links {
            display: block;
        }
        END

        $css ~~ s:g/'%ALIGN-NAV%'/$!align-nav/;
        $css
    }

    method HTML {
        div [
            nav :class<tab-nav>, ul :class<tab-links>, self.tab-items;
            div :id($.html-id), @!items[0].value;
        ]
    }
}

=head3 role Dialog does Component

# fixme
role Dialog     does Component {
    method SCRIPT {
q:to/END/;
/*
* Modal
*
* Pico.css - https://picocss.com
* Copyright 2019-2024 - Licensed under MIT
*/

// Config
const isOpenClass = "modal-is-open";
const openingClass = "modal-is-opening";
const closingClass = "modal-is-closing";
const scrollbarWidthCssVar = "--pico-scrollbar-width";
const animationDuration = 1000; // ms
let visibleModal = null;

// Toggle modal
const toggleModal = (event) => {
  event.preventDefault();
  const modal = document.getElementById(event.currentTarget.dataset.target);
  if (!modal) return;
  modal && (modal.open ? closeModal(modal) : openModal(modal));
};

// Open modal
const openModal = (modal) => {
  const { documentElement: html } = document;
  const scrollbarWidth = getScrollbarWidth();
  if (scrollbarWidth) {
    html.style.setProperty(scrollbarWidthCssVar, `${scrollbarWidth}px`);
  }
  html.classList.add(isOpenClass, openingClass);
  setTimeout(() => {
    visibleModal = modal;
    html.classList.remove(openingClass);
  }, animationDuration);
  modal.showModal();
};

// Close modal
const closeModal = (modal) => {
  visibleModal = null;
  const { documentElement: html } = document;
  html.classList.add(closingClass);
  setTimeout(() => {
    html.classList.remove(closingClass, isOpenClass);
    html.style.removeProperty(scrollbarWidthCssVar);
    modal.close();
  }, animationDuration);
};

// Close with a click outside
document.addEventListener("click", (event) => {
  if (visibleModal === null) return;
  const modalContent = visibleModal.querySelector("article");
  const isClickInside = modalContent.contains(event.target);
  !isClickInside && closeModal(visibleModal);
});

// Close with Esc key
document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && visibleModal) {
    closeModal(visibleModal);
  }
});

// Get scrollbar width
const getScrollbarWidth = () => {
  const scrollbarWidth = window.innerWidth - document.documentElement.clientWidth;
  return scrollbarWidth;
};

// Is scrollbar visible
const isScrollbarVisible = () => {
  return document.body.scrollHeight > screen.height;
};
END
    }

    method HTML {
        div [
        Safe.new: '<button class="contrast" data-target="modal-example" onclick="toggleModal(event)">Launch demo modal</button>';
        Safe.new: q:to/MODAL/;
            <dialog id="modal-example">
                <article>
                <header>
                <button aria-label="Close" rel="prev" data-target="modal-example" onclick="toggleModal(event)"></button>
                  <h3>Confirm your action!</h3>
                </header>
                <p>
                  Cras sit amet maximus risus. Pellentesque sodales odio sit amet augue finibus
                  pellentesque. Nullam finibus risus non semper euismod.
                </p>
                <footer>
                  <button role="button" class="secondary" data-target="modal-example" onclick="toggleModal(event)">
                    Cancel</button><button autofocus="" data-target="modal-example" onclick="toggleModal(event)">
                    Confirm
                  </button>
                </footer>
              </article>
            </dialog>
            MODAL
        ]
    }
}

=head3 role Lightbox does Component

role Lightbox     does Component {
    has $!loaded;

    #| unique lightbox label
    has Str    $.label = 'open';
    has Button $.button;

    #| can be provided with attrs
    has %.attrs is rw;

    #| can be provided with inners
    has @.inners;

    #| ok to call .new with @inners as Positional
    multi method new(*@inners, *%attrs) {
        self.bless:  :@inners, :%attrs
    }

    method HTML {
        if @!inners[0] ~~ Button && ! $!loaded++ {
            $!button = @!inners.shift;
        }

        div [
            if $!button {
                a :href<#>, :class<open-link>, :data-target("#$.html-id"), $!button;
            } else {
                a :href<#>, :class<open-link>, :data-target("#$.html-id"), $!label;
            }

            div :class<lightbox-overlay>, :id($.html-id), [
                div :class<lightbox-content>, [
                    span :class<close-btn>, Safe.new: '&times';
                    do-regular-tag( 'div', @.inners, |%.attrs )
                ];
            ];
        ];
    }

    method STYLE {
        q:to/END/;
        .lightbox-overlay {
          position: fixed;
          top: 0; left: 0;
          width: 100%; height: 100%;
          background: rgba(0, 0, 0, 0.8);
          display: none;
          align-items: center;
          justify-content: center;
          z-index: 900;
        }

        .lightbox-overlay.active {
          display: flex;
        }

        .lightbox-content {
          background: grey;
          width: 70vw;
          position: relative;
          border-radius: 10px;
          box-shadow: 0 5px 15px rgba(0,0,0,0.3);
          padding: 1rem;
        }

        .close-btn {
          position: absolute;
          top: 10px;
          right: 15px;
          font-size: 24px;
          color: #333;
          cursor: pointer;
        }
        END
    }

    method SCRIPT {
        q:to/END/;
        // Open specific lightbox
        document.querySelectorAll('.open-link').forEach(link => {
          link.addEventListener('click', e => {
            e.preventDefault();
            const target = document.querySelector(link.dataset.target);
            if (target) target.classList.add('active');
          });
        });

        // Close when clicking the X or outside the content
        document.querySelectorAll('.lightbox-overlay').forEach(lightbox => {
          const content = lightbox.querySelector('.lightbox-content');
          const closeBtn = lightbox.querySelector('.close-btn');

          closeBtn.addEventListener('click', () => {
            lightbox.classList.remove('active');
          });

          lightbox.addEventListener('click', e => {
            if (!content.contains(e.target)) {
              lightbox.classList.remove('active');
            }
          });
        });

        // Close any open lightbox on Escape
        document.addEventListener('keydown', e => {
          if (e.key === 'Escape') {
            document.querySelectorAll('.lightbox-overlay.active').forEach(lb => {
              lb.classList.remove('active');
            });
          }
        });
        END
    }
}

=head2 Other Tags

=head3 role Markdown does Tag

role Markdown    does Tag {
    use Text::Markdown;

    #| markdown to be converted
    has Str $.markdown;
    # cache the result
    has Markup() $!result;

    #| .new positional takes Str $code
    multi method new(Str $markdown, *%h) {
        self.bless: :$markdown, |%h;
    }

    multi method HTML {
        $!result = Text::Markdown.new($!markdown).render unless $!result;
        $!result
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

=begin pod
=head1 AUTHOR

Steve Roe <librasteve@furnival.net>


=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
=end pod

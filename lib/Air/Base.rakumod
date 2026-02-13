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
my $site =
    site :register[lightdark],
        index
            main $Content1;

$site.serve;
=end code

Key features shown are:
=item use of C<site> functional tag - that sets up the site Cro routes and Pico SASS theme
=item C<site> takes the C<index> page as positional argument
=item C<site> takes a List of components & widgets (e.g. lightdark) as C<:register> argument
=item C<index> takes a C<main> functional tag as positional argument
=item C<main> takes the initial content
=item method C<.serve> is then called to start the site as a Cro::Service

=head1 DESCRIPTION

In general, items defined in Air::Base are exported as both roles or classes (title case) and as subroutines (lower case).

So, after `use`ing the relevant module you can code in OO or functional style:

```
my $t = Title.new: 'sometext';
```

Is identical to writing:

```
my $t = title 'sometext';
```

The Air::Base library is implemented over a set of Raku modules, which are then used in the main Base module and re-exported as both classes and functions:

=item [Air::Base::Tags](Base/Tags.md)  - HTML, Semantic & Safe Tags
=item [Air::Base::Elements](Base/Elements.md)  - Layout, Active & Markdown Elements
=item [Air::Base::Tools](Base/Tools.md)  - Tools for site-wide deployment
=item [Air::Base::Widgets](Base/Widgets.md)  - Widgets use anywhere, esp Nav

All items are re-exported by the top level module, so you can just `use Air::Base;` near the top of your code.
=end pod

# TODO items
#my loaded or has loaded - make consistent
#role Theme {...}
#provide for different title, description in head for wach page

use YAMLish;

use Air::Functional :BASE-ELEMENTS;
use Air::Component;
use Air::Form;

use Air::Base::Tags;
use Air::Base::Elements;
use Air::Base::Tools;
use Air::Base::Widgets;

sub exports-air-base {<Site Page Nav Body Header Main Footer>}

# predeclarations
role  Defaults {...}
class Nav      {...}
class Page     {...}

=head2 Page Tags

=para A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient and opinionated set of defaults for C<html>, C<head>, C<body>, C<header>, C<nav>, C<main> & C<footer>. Several of the page tags offer shortcut attrs that are populated up the DOM immediately prior to first use.

=head3 role Head   does Tag[Regular] {...}

=para Singleton pattern (Air issues the same Head for all pages)

role Head       does Tag[Regular]  {
    also        does Defaults;

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

role Header     does Tag[Regular]  {
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

role Main       does Tag[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :class<container>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head3 role Footer does Tag[Regular] {...}

role Footer     does Tag[Regular]  {
    multi method HTML {
        my %attrs = |%.attrs, :class<container>;
        do-regular-tag( $.name, @.inners, |%attrs )
    }
}

=head 3 role Body   does Tag[Regular] {...}

role Body       does Tag[Regular]  {
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

role Html      does Tag[Regular]  {
    also       does Defaults;

    has $!loaded = 0;

    #| head
    has Head   $.head .= instance;
    #| body
    has Body   $.body is rw .= new;

    multi method HTML {
        self.defaults unless $!loaded++;

        opener($.name, |%.attrs) ~
        $!head.HTML              ~
        $!body.HTML              ~
        closer($.name)           ~ "\n"
    }
}

=head2 Nav, Page and Site

=para These are the central parts of Air::Base

=head3 subset NavItem of Pair where .value ~~ Internal | External | Content | Page;

subset NavItem of Pair where .value ~~ Internal | External | Content | Page;

#| Nav does Component to do multiple instances with distinct NavItem and Widget attrs
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
            background: rgba(0, 0, 0, .95);
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

        if (hamburger && menu) {
            hamburger.addEventListener('click', () => {
                menu.classList.toggle('show');
            });

            document.addEventListener('click', (e) => {
                if (!menu.contains(e.target) && !hamburger.contains(e.target)) {
                    menu.classList.remove('show');
                }
            });
        }

        // Hide the menu when resizing the viewport to a wider width
        window.addEventListener('resize', () => {
            if (window.innerWidth > 768) {
                menu.classList.remove('show');
            }
        });
        END
    }
}

#| Page does Component to do multiple instances with distinct content and attrs
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
    method shortcuts {
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
    #| .new positional with header & main only
    multi method new(Header $header, Main $main, *%h) {
        self.bless: :$header, :$main, |%h
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
        self.shortcuts unless $!loaded;
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

=head3 subset Redirect of Pair where .key !~~ /\// && .value ~~ /^ \//;

subset Redirect of Pair where .key !~~ /\// && .value ~~ /^ \//;

#| Site is a holder for pages, performs setup of Cro routes, gathers styles and scripts, and runs SASS
class Site {
    my $loaded;

    #| Page holder -or-
    has Page @.pages;
    #| index Page ( otherwise $!index = @!pages[0] )
    has Page $.index;
    #| 404 page (otherwise bare 404 is thrown)
    has Page $.html404;
    #| Register for route setup; default = [Nav.new]
    has      @.register;
    #| Tools for sitewide behaviours
    has Tool @.tools = [];
    #| Redirects
    has Redirect @.redirects = [];


    #| use :!scss to disable the SASS compiler run
    has Bool $.scss = True;
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

    #| enqueued items are rendered in order, avoid interdependencies
    method enqueue-all {
        return if $loaded++;

        for @!register.unique( as => *.^name ) -> $registrant {
            my $head = @!pages.first.html.head;  # NB. head is a singleton

            #| SCRIPT inserts script tag (default)
            #| at end of body on every page
            for @!pages -> $page {
                with $registrant.?SCRIPT {
                    $page.html.body.scripts.append: Script.new($_)
                }
            }

            #| SCRIPT-HEAD inserts script tag in the shared head
            with $registrant.?SCRIPT-HEAD {
                $head.scripts.append: Script.new($_)
            }

            #| SCRIPT-LINKS inserts script tags in the shared head (default)
            #| takes list of script src urls
            for $registrant.?SCRIPT-LINKS -> $src {
                $head.scripts.append: Script.new( :$src ) with $src;
            }

            #| SCRIPT-LINKS-DEFER inserts script tags in the shared head (with defer)
            #| takes list of script src urls
            for $registrant.?SCRIPT-LINKS-DEFER -> $src {
                $head.scripts.append: Script.new( :$src, :defer ) with $src;
            }

            #| SCRIPT-LINKS-BODY inserts script tag in every page body
            for @!pages -> $page {
                for $registrant.?SCRIPT-LINKS-BODY -> $src {
                    $page.html.body.scripts.append: Script.new( :$src ) with $src;
                }
            }

            #| STYLE-LINKS inserts link tag in the shared head
            #| takes list of link href urls
            for $registrant.?STYLE-LINKS -> $href {
                next unless $href.defined;
                $head.links.append: Link.new( :$href, :rel<stylesheet> );
            }

            #| STYLE insert style tag into shard head
            with $registrant.?STYLE {
                $head.styles.append: Style.new($_)
            }

            with $registrant.?SCSS {
                $!scss-gather ~= "\n\n" ~ $_;
            }
        }
    }

    submethod TWEAK {
        with    @!pages[0] { $!index = @!pages[0] }
        orwith  $!index    { @!pages[0] = $!index }
        else    { note "No pages or index found!" }

        #| always register & route Nav
        @!register.push: Nav.new;

        #| gather all the registrant exports
        self.enqueue-all;

        #| inject all the tools
        .inject($!index) for @!tools;
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

            #| index & static
            get ->                  { content   'text/html',  $.index.HTML }
            get -> 'css',    *@path { static    'static/css', @path }
            get -> 'img',    *@path { static    'static/img', @path }
            get -> 'js',     *@path { static    'static/js',  @path }
            get -> 'static', *@path { static    'static',     @path }

            #| 404 routes
            with $!html404 {
                note "adding 404";
                get ->  *@rest { not-found 'text/html',  $.html404.HTML };
            }

            #| redirect routes
            for @!redirects {
                my ($old, $new) = .kv;
                note "adding redirect $old => $new";
                delegate "$old" => route { get -> { redirect $new } };
            }
        }
    }

    #| site.serve is the general (development) command to start the site Cro::Service
    #| scss compilation (e.g. dart)  is True  by default, use !scss to disable it
    #| watch file change recursively is False by default, use watch to enable  it
    method serve( :$host is copy, :$port is copy, :$scss = True, :$watch = False ) {
        #| vendor all default packages fixme

        self.scss-run if $scss;

        use Cro::HTTP::Log::File;
        use Cro::HTTP::Server;

        $host //= %*ENV<CRO_WEBSITE_HOST> // '0.0.0.0';
        $port //= %*ENV<CRO_WEBSITE_PORT> // 3000;

        my Cro::Service $http = Cro::HTTP::Server.new(
            http => <1.1>,
            :$host,
            :$port,
            application => $.routes,
            after => [
                Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
            ],
        );
        say "Starting server. Point browser at $host:$port. Ctrl-C to stop server";
        $http.start;
        react {
            whenever signal(SIGINT) {
                say "Shutting down...";
                $http.stop;
                done;
            }

            if $watch {
                whenever watch-recursive('.'.IO) -> $change {
                    my @exclusions = <DS_Store styles.scss styles.css styles.css.map>;

                    unless $change.path.IO.basename ~~ / <@exclusions> / {
                        say "File change detected: {$change.path.IO.basename}";
                        say "Restarting...";
                        $http.stop;
                        sleep 1;  #let OS breathe
                        run('raku', '-Ilib', 'air-serve.raku', "--host=$host", "--port=$port", "--scss=$scss", '--watch');
                        done;
                    }
                }
            }
        }
    }

    #| is a variant of server for production which skips all the dev / build steps
    method start( :$host, :$port, :$scss = False, :$watch ) {
        self.serve: :$host, :$port, :$scss, :$watch
    }

    method scss-run {
        my $css = self.scss-theme ~ "\n\n";
        $css ~= $_ with $!scss-gather;

        note "theme-color=$!theme-color";
        $css ~~ s:g/'%THEME_COLOR%'/$!theme-color/;

        note "bold-color=$!bold-color";
        $css ~~ s:g/'%BOLD_COLOR%'/$!bold-color/;

        my @dirs = "../static/css", "static/css";

        for @dirs -> $dir {
            if $dir.IO.d {
                chdir $dir;
                last;
            }
        }
        unless $*CWD.ends-with("static/css") {
            die "Neither '../static/css' nor 'static/css' exists!";
        }

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

    # code lifted from https://github.com/croservices/cro/blob/main/lib/Cro/Tools/Services.rakumod
    sub watch-recursive(IO::Path $path) {
        supply {
            my %watched-dirs;

            sub add-dir(IO::Path $dir, :$initial) {
                %watched-dirs{$dir} = True;

                with $dir.watch -> $dir-watch {
                    whenever $dir-watch {
                        emit $_;
                        my $path-io = .path.IO;
                        if $path-io.d {
                            unless $path-io.basename.starts-with('.') {
                                add-dir($path-io) unless %watched-dirs{$path-io};
                            }
                        }
                        CATCH {
                            default {
                                # Perhaps the directory went away; disregard.
                            }
                        }
                    }
                }

                for $dir.dir {
                    unless $initial {
                        emit IO::Notification::Change.new(
                            path => ~$_,
                            event => FileChanged
                            );
                    }
                    if .d {
                        unless .basename.starts-with('.') {
                            add-dir($_, :$initial);
                        }
                    }
                }
            }

            add-dir($path, :initial);
        }
    }
}

=head2 Defaults

=para role Defaults provides a central place to set the various website defaults across Head, Html and Site roles

=para On installation, the file `~/.rair-config/.air.yaml` is placed in the home directory (ie copied from `resources/.air.yaml`. By default, role Defaults loads the information specified in this file intio the appropriate part of each page:

=begin code
Html:
  attrs:
    lang: "en"
    data-theme: "dark"

Head:
  metas:
    - charset: "utf-8"
    - name: "viewport"
      content: "width=device-width, initial-scale=1"

  links:
    - rel: "icon"
      href: "/img/favicon.ico"
      type: "image/x-icon"
    - rel: "stylesheet"
      href: "/css/styles.css"

  scripts:
    - src: "https://unpkg.com/htmx.org@1.9.5"
      crossorigin: "anonymous"
      integrity: "sha384-xcuj3WpfgjlKF+FXhSQFQ0ZNr39ln+hwjN3npfM9VBnUskLolQAcN80McRIVOPuO"
=end code

=para These values can be customised as follows: copy this file from `~/.rair-config/.air.yaml` to `bin/.air.yaml` where `bin` is the dir where you run your website script (see Air::Examples for a working version). Note that, until we add Air::Theme support, many of the Air features and examples are HTMX centric, so only remove this if you are confident. Other fields (such as the site url and admin email) will be added here as the codebase evolves. Also, this is the basis for vendoring support to be implemented in a future release.

role Defaults {
    my %yaml;
    my $yaml-loaded;

    state $script-dir = $*CWD;

    submethod read-yaml {
        return if $yaml-loaded++;

        my $file = '.air.yaml';

        if "$script-dir/$file".IO.e {
            # place custom .air.yaml in same dir as script that calls `site.serve`
            note "Loading custom .air.yaml...";
            %yaml := load-yaml("$script-dir/$file".IO.slurp);
        } else {
            note "Loading default .air.yaml...";
            %yaml := load-yaml("$*HOME/.rair-config/$file".IO.slurp);
        }
    }

    multi method defaults(Html:) {
        self.read-yaml;

        note "Html attrs: " ~ %yaml<Html><attrs>.raku;
        self.attrs = %yaml<Html><attrs>;
    }

    multi method defaults(Head:) {
        self.read-yaml;

        note "Head metas: " ~ |%yaml<Head><metas>.raku;
        for %yaml<Head><metas><> {
            self.metas.append: Meta.new: |$_
        }

        note "Head links: " ~ %yaml<Head><links>.raku;
        for %yaml<Head><links><> {
            self.links.append: Link.new: |$_
        }

        note "Head scripts: " ~ %yaml<Head><scripts>.raku;
        for %yaml<Head><scripts><> {
            self.scripts.append: Script.new: |$_
        }
    }
}

##### Functions & Class/Role Exports #####

#| gather all the base and child module classes and roles
my @combined-exports = [
    |exports-air-base,
    |exports-air-base-tags,
    |exports-air-base-elements,
    |exports-air-base-tools,
    |exports-air-base-widgets,
];

#| put in all the @combined-exports as functions sub name( * @a, * %h) {Name.new(|@a,|%h)}
# viz. https://docs.raku.org/language/modules#Exporting_and_selective_importing
my package EXPORT::DEFAULT {

    for @combined-exports -> $name {

        OUR::{'&' ~ $name.lc} :=
            sub (*@a, *%h) {
                ::($name).new( |@a, |%h )
            }

    }

}

#| also just re-export them as vanilla classes and roles
sub EXPORT {
    Map.new:
        @combined-exports.map: {$_ => ::($_)}
}

=begin pod
=head1 AUTHOR

Steve Roe <librasteve@furnival.net>

=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
=end pod

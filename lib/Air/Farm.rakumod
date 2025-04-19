=begin pod

=head1 Air::Base

This raku module is one of the core libraries of the raku B<Air> distribution.

It provides a Base library of functional Tags and Components that can be composed into web applications.

Air::Base uses Air::Functional for standard HTML tags expressed as raku subs. Air::Base uses Air::Component for scaffolding for library Components.


=head2 Architecture

Here's a diagram of the various Air parts. (Air::Play is a separate raku module with several examples of Air websites.)

=begin code
            +----------------+
            |    Air::Play   |    <-- Web App
            +----------------+
                    |
          +--------------------+
          |  Air::Play::Site   |  <-- Site Lib
          +------------------ -+
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
#role Form  {...}

use Air::Functional :CRO;
use Air::Component;


use Cro::WebApp::Form;
use Cro::WebApp::Template;
use Cro::WebApp::Template::Repository;


=head2 Basic Tags

=para A subset of Air::Functional basic HTML tags, provided as roles, that are slightly adjusted by Air::Base to provide a convenient set of elements for the Page Tags.

=head2 Form is never Functional

class Farm does Cro::WebApp::Form does FormTag {

#    #| makes routes for Form actions
#    method make-routes() {
#        unless self.^methods.grep: * ~~ IsController {
#            for self.items.map: *.kv -> ($name, $target) {
#                given $target {
#                    when * ~~ Content {
#                        my &new-method = method {respond $target.?HTML};
#                        trait_mod:<is>(&new-method, :controller, :$name);
#                        self.^add_method($name, &new-method);
#                    }
#                }
#            }
#        }
#    }

    multi method HTML(--> Markup()) {
        my $formtmp = Q|<&form(.form)>|;

        parse-template($formtmp).render: { form => self.empty };

    }
#
#    #| renders NavItems [subset NavItem of Pair where .value ~~ Internal | External | Content | Page;]
#    method nav-items {
#        do for @.items.map: *.kv -> ($name, $target) {
#            given $target {
#                when * ~~ External | Internal {
#                    $target.label = $name;
#                    li $target.HTML
#                }
#                when * ~~ Content {
#                    li a(:hx-get("$.name/$.serial/" ~ $name), Safe.new: $name)
#                }
#                when * ~~ Page {
#                    li a(:href("/{.name}/{.serial}"), Safe.new: $name)
#                }
#            }
#        }
#    }
#
#    #| applies Style and Script for Hamburger reactive menu
#    multi method HTML {
#        self.style.HTML ~ (
#
#        nav [
#            { ul li :class<logo>, :href</>, $.logo } with $.logo;
#
#            button( :class<hamburger>, :id<hamburger>, Safe.new: '&#9776;' );
#
#            ul( :$!hx-target, :class<nav-links>,
#                self.nav-items,
#                do for @.widgets { li .HTML },
#                );
#
#            ul( :$!hx-target, :class<menu>, :id<menu>,
#                self.nav-items,
#                );
#        ]
#
#        ) ~ self.script.HTML
#    }
#
#    method style { Style.new: q:to/END/
#        /* Custom styles for the hamburger menu */
#        .menu {
#            display: none;
#            flex-direction: column;
#            gap: 10px;
#            position: absolute;
#            top: 60px;
#            right: 20px;
#            background: rgba(128, 128, 128, .97);
#            padding: 1rem;
#            border-radius: 8px;
#            box-shadow: 0 4px 6px rgba(128, 128, 128, .2);
#        }
#
#        .menu a {
#            display: block;
#        }
#
#        .menu.show {
#            display: flex;
#        }
#
#        .hamburger {
#            color: var(--pico-primary);
#            display: none;
#            cursor: pointer;
#            font-size: 2.5rem;
#            background: none;
#            border: none;
#            padding: 0.5rem;
#        }
#
#        @media (max-width: 768px) {
#            .hamburger {
#                display: block;
#            }
#
#            .nav-links {
#                display: none;
#            }
#        }
#    END
#	}
#
#    method script { Script.new: Q:to/END/;
#        const hamburger = document.getElementById('hamburger');
#        const menu = document.getElementById('menu');
#
#        hamburger.addEventListener('click', () => {
#            menu.classList.toggle('show');
#        });
#
#        document.addEventListener('click', (e) => {
#            if (!menu.contains(e.target) && !hamburger.contains(e.target)) {
#                menu.classList.remove('show');
#            }
#        });
#
#        // Hide the menu when resizing the viewport to a wider width
#        window.addEventListener('resize', () => {
#            if (window.innerWidth > 768) {
#                menu.classList.remove('show');
#            }
#        });
#    END
#    }
}



=begin pod
=head1 AUTHOR

Steve Roe <librasteve@furnival.net>


=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
=end pod

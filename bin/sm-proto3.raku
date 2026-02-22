#!/usr/bin/env raku

#`[
concept
 - there is a canonical route structure
 - there is a sitemap
 - Nav is independent of sitemap

issues
 - should stub url-path be nested - yes
 - id to serial
 - sitemap can route all page routes

 - what happens to eg tab routes

index '/'
 <a data-value="1" hx-get="/buttabs/1/multi-paradigm"   hx-target="#buttabs-1-content">multi-paradigm</a>

install '/install'
 <a hx-target="#tabs-1-content" hx-get="/tabs/1/macOS" data-value="2">macOS</a>

<== site relative (maybe should be page relative)

rules
 - canonical names such "tabs/1/xyz" are sitewide
 - component instances & routes can be used on any page
 - stubs apply to pages only
 - stubs may be nested


Wordpress flow...
If someone visits:
yoursite.com/about/
WordPress:
- Figures out it's a page
- Loads page.php
- Runs get_header() → inserts header
- Outputs the page content
- Runs get_footer() → inserts footer
So visually:
- header.php
- page content
- footer.php

Air flow...
If someone visits:
yoursite.com/about/
Air:
- maps the route to a component method (raku.org/nav/1/install)
- loads the component (nav/1) and runs the method (install)
- a Nav item method maps the page name install => target
- loads the target
- runs the HTML method on the target
-or-
- maps the route to a component method (raku.org/tabs/1/macOS)
- loads the component (tabs/1) and runs the method (macOS)
- a Tabs item method maps the tab name to content function macOS => tab macOS()

Snagging
 - what about pages with no stub (NB atm examples use same title for several pages)
 - :register[page] will route adding GET page/<Mu $id> (!)
 - no need for Nav routing? (big change needed)
 - onchange behaviour for Page.stub, Page.parent-stub (like WP)
   - admin reparent,
    - change stub
    - re-run SiteMap routes on live site
 - validate eg https://app.seotesting.com/tools/validatesitemap
 - does sitemap.xml need a url route?

Roadmap
  - all other Component routes are static
    - want them to be like WP plugins - reroute components without a site start
]


#!/usr/bin/env raku

use Data::Dump::Tree;

use Air::Functional :BASE;
use Air::Component;

class Site { ... }

class Page does Component {
    has Site $.site is rw;

    my %stubs;      #stubs are unique
    has Str  $!stub is built;

    has Str  $.parent-stub;
    has Page $.parent is rw;
    has Page @.children;

    multi method stub { $!stub }

    multi method stub($s) {
        die "Error: Stubs must be unique!" if %stubs{$s}:exists;
        %stubs{$s} = 1;

        die "Error: Stub already set!" with $!stub;   # fixme - onchange
        $!stub = $s;
    }

    method add-child(Page $child) {
        @!children.push: $child;
    }

    method segments {
        $!parent.defined ?? (|$!parent.segments, $!stub) !! ()
    }

    method url-path {
        '/' ~ self.segments.join('/');
    }

    method tree($depth = 0) {
        say '  ' x $depth ~ "- " ~ $.stub ~ " (" ~ self.url-path ~ ")";
        .tree($depth + 1) for @!children;
    }
}

class SiteMap {
    has %.routes;

    method register(Page $page) {
        %!routes{$page.url-path} = $page;
    }

    method lookup(Str $url-path) {
        %!routes{$url-path};
    }

    method list {
        %!routes.keys.sort;
    }

    method route-pages { }   #iamerejh

    method to-xml( :$base-url! ) {
        my $date = DateTime.now.Date;

        my @urls = self.routes.values.sort.map({
        qq:to/URL/;
          <url>
            <loc>{$base-url}{.url-path}</loc>
            <lastmod>{$date}</lastmod>
            <changefreq>weekly</changefreq>
            <priority>0.5</priority>
          </url>
        URL
        });

        qq:to/XML/;
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        {@urls}</urlset>
        XML
    }

    # save sitemap.xml file
    method save( :$base-url!, :$file = "sitemap.xml" ) {
        spurt $file, self.to-xml(:$base-url);
        $file;
    }
}

class Site {
    has SiteMap $.sitemap .= new;

    has Page @.pages;
    has Page $.index;

    submethod TWEAK {
        given       $!index, @!pages[0] {
            when     Page:D,  Page:U    { @!pages[0] := $!index }
            when     Page:U,  Page:D    { $!index := @!pages[0] }
            default
                { die "Please specify either index or pages!" }
        }

        self.sitemap-pages;
    }

    method sitemap-pages {
        my %stubs;

        for @!pages -> $page {
            %stubs{$page.stub} = $page
        }

        for @!pages -> $page {
            if $page.parent-stub {
                $page.parent = %stubs{$page.parent-stub};
                $page.parent.add-child($page);
                next;
            }

            FIRST next;    #skip index
            $page.parent = $!index;
            $!index.add-child($page);
        }

        for @!pages -> $page {
            $page.site = self;
            $!sitemap.register($page);
        }

        $!sitemap.route-pages;
        $!sitemap.save(:base-url('https://furnival.net'));
    }

    method tree {
        say "Site Tree:";
        $!index.tree;
    }
}

my @pages = (
    Page.new(stub => ''),
    Page.new(stub => 'about'),
    Page.new(stub => 'blog'),
    Page.new(stub => 'first-post', parent-stub => 'blog'),
    Page.new(stub => 'second-post', parent-stub => 'blog'),
    Page.new(stub => 'team', parent-stub => 'about'),
);


my $site = Site.new: :@pages;

say "\nSitemap:";
.say for $site.sitemap.list;

say "";
$site.tree;

say "\nLookup:";
say $site.sitemap.lookup('/blog/second-post');

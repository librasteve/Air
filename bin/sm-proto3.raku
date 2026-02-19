#!/usr/bin/env raku

#`[

concept
 - there is a canonical route structure
 - there is a sitemap
 - Nav is independent of sitemap




issues
 - should stub path be nested - yes
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
]


#!/usr/bin/env raku

use Data::Dump::Tree;
use Air::Component;

class Site {...}

class Page does Component {
    has Str $.stub;
    has UInt $.parent-id;   ##??
#    has Str $.id;

    has Page $.parent is rw;
    has Page @.children;
    has Site $.site is rw;

    method add-child(Page $child) {
        @!children.push($child);
    }

    method segments {
        $!parent ?? (|$!parent.segments, $!stub) !! ()
    }

    method path {
        '/' ~ self.segments.join('/');
    }

    method tree($depth = 0) {
        say '  ' x $depth ~ "- " ~ $.id ~ " (" ~ self.path ~ ")";
        .tree($depth + 1) for @!children;
    }

    method gist { self.path }
}

class SiteMap {
    has %!routes;

    method register(Page $page) {
        %!routes{$page.path} = $page;
    }

    method lookup(Str $path) {
        %!routes{$path};
    }

    method list {
        %!routes.keys.sort;
    }
}

class Site {
    has SiteMap $.sitemap = SiteMap.new;
    has %!pages;      # id → Page
    has Page $.index;

    method add-pages(@pages) {
        # store all pages first
        for @pages {
            %!pages{.id} = $_;
        }
        ddt %!pages;
#        die;

        # wire parents
        for %!pages.values -> $page {
            if $page.parent-id {
                my $parent = %!pages{$page.parent-id};
                $page.parent = $parent;
                $parent.add-child($page);
            }
        }

        # find root (no parent-id)
        $!index = %!pages.values.first(!*.parent-id.defined);

        # assign site + register routes
        for %!pages.values -> $page {
            $page.site = self;
            $!sitemap.register($page);
        }
    }

    method tree {
        say "Site Tree:";
        $!index.tree;
    }
}

#my @pages = (
#Page.new(id => 'index', stub => ''),
#Page.new(id => 'about', stub => 'about', parent-id => 'index'),
#Page.new(id => 'blog',  stub => 'blog', parent-id => 'index'),
#Page.new(id => 'post1', stub => 'first-post', parent-id => 'blog'),
#Page.new(id => 'post2', stub => 'second-post', parent-id => 'blog'),
#Page.new(id => 'team',  stub => 'team', parent-id => 'about'),
#);

#`[
pass in parent-stub name (just need to be valid before Page.new)
can change during preamble
look up stub name to id on server start / route definition

hmmm want behaviour like WP
can use admin if to re-parent
re-run SiteMap routes
]

##parent-id or parent-stub
my @pages = (
    Page.new(stub => ''),
    Page.new(stub => 'about', parent-id => 'index'),
    Page.new(stub => 'blog', parent-id => 'index'),
    Page.new(stub => 'first-post', parent-id => 'blog'),
    Page.new(stub => 'second-post', parent-id => 'blog'),
    Page.new(stub => 'team', parent-id => 'about'),
);


my $site = Site.new;
$site.add-pages(@pages);

say "\nSitemap:";
.say for $site.sitemap.list;

say "";
$site.tree;

say "\nLookup:";
say $site.sitemap.lookup('/blog/second-post');

#say $site.index.id;
say @pages[4].segments;


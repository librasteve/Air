#!/usr/bin/env raku

#`[
design
 - how to assemble pages to a site
  - ASIS site @pages
  - TOBE my $about  = $site.add-page
 - options
  - multi add-page take a list
   - make new *@ do add-page(@)
  -

SOOO big question is whether to do page assembly piece by piece OR to make a bunch of pages and then to wire them up

issues
 - fix //
 - parent default is Nil (== "parent = main page (no parent)")
]

class Page {
    has Str  $.stub;                    # URL segment
    has Page $.parent is rw;            # parent page
    has @.children;                     # child pages
    has $.site is rw;                   # reference to Site

    submethod TWEAK {
        # inherit site from parent if not given
        $!site //= $!parent.site if $!parent;

        # register as child of parent
        if $!parent {
            $!parent.add-child(self);
        }

        # register with sitemap
        $!site.sitemap.register(self) if $!site;
    }

    method add-child(Page $child) {
        @!children.push($child);
    }

    method path {
        return '' ~ $!stub unless $!parent;
        return $!parent.path ~ '/' ~ $!stub;
    }

    method gist {
        self.path;
    }

    method tree($depth = 0) {
        say '  ' x $depth ~ "- " ~ self.stub;
        .tree($depth + 1) for @!children;
    }
}

class SiteMap {
    has %!routes;   # path → Page

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
    has SiteMap $.sitemap;
    has Page    $.index;

    submethod TWEAK {
        $!sitemap = SiteMap.new;

        # Create index page
        $!index = Page.new(
            stub => '',
            site => self
        );
    }

    method add-page(*%args) {
        %args<site> //= self;
        Page.new(|%args);
    }

    method tree {
        say "Site Tree:";
        $!index.tree;
    }
}

my $site = Site.new;

# Top-level pages
my $about  = $site.add-page(parent => $site.index, stub => 'about');
my $blog   = $site.add-page(parent => $site.index, stub => 'blog');

# Nested pages
my $post1  = Page.new(parent => $blog, stub => 'first-post');
my $post2  = Page.new(parent => $blog, stub => 'second-post');

# Deep nesting
my $team   = Page.new(parent => $about, stub => 'team');

say "\nPaths:";
say $post1.path;  # /blog/first-post
say $team.path;   # /about/team

say "\nLookup:";
say $site.sitemap.lookup('/blog/second-post');

say "\nSitemap:";
.say for $site.sitemap.list;

say "";
$site.tree;

say $site.index.children;

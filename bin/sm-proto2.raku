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

#!/usr/bin/env raku

################################
# Page (pure object)
################################

class Page {
    has Str $.stub;
    has Str $.parent-id;      # symbolic reference
    has Str $.id;
    has Page $.parent is rw;
    has @.children;
    has $.site is rw;

    method add-child(Page $child) {
        @!children.push($child);
    }

    method segments {
        $!parent ?? ($!parent.segments, $!stub) !! ()
    }

    method path {
        '/' ~ self.segments.grep(*.chars).join('/');
    }

    method tree($depth = 0) {
        say '  ' x $depth ~ "- " ~ $.id ~ " (" ~ self.path ~ ")";
        .tree($depth + 1) for @!children;
    }

    method gist { self.path }
}

################################
# SiteMap
################################

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

################################
# Site (assembler)
################################

class Site {
    has SiteMap $.sitemap = SiteMap.new;
    has %!pages;      # id → Page
    has Page $.index;

    method add-pages(@pages) {
        # store all pages first
        for @pages {
            %!pages{.id} = $_;
        }

        # wire parents
        for %!pages.values -> $page {
            if $page.parent-id {
                my $parent = %!pages{$page.parent-id};
                $page.parent = $parent;
                $parent.add-child($page);
            }
        }

        # find root (no parent-id)
        $!index = %!pages.values.first(*.parent-id ~~ Nil);

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

################################
# Create Pages First (No Wiring)
################################

my @pages = (
Page.new(id => 'index', stub => ''),
Page.new(id => 'about', stub => 'about', parent-id => 'index'),
Page.new(id => 'blog',  stub => 'blog', parent-id => 'index'),
Page.new(id => 'post1', stub => 'first-post', parent-id => 'blog'),
Page.new(id => 'post2', stub => 'second-post', parent-id => 'blog'),
Page.new(id => 'team',  stub => 'team', parent-id => 'about'),
);

################################
# Now Wire Into Site
################################

my $site = Site.new;
$site.add-pages(@pages);

say "\nSitemap:";
.say for $site.sitemap.list;

say "";
$site.tree;

say "\nLookup:";
say $site.sitemap.lookup('/blog/second-post');

=begin pod

=head1 Air::Component

This raku module is one of the core libraries of the raku B<Air> distribution.

It is a scaffold to build dynamic, reusable web components.


=head1 SYNOPSIS

The synopsis is split so that each part can be annotated. First, we import the Air core libraries.

=begin code :lang<raku>
use Air::Functional :BASE;      # import all HTML tags as raku subs
use Air::Base;					# import Base components (site, page, nav...)
use Air::Component;
=end code

=head3 HTMX functions

We prepare some custom HTMX actions for our Todo component. This declutters C<class Todo> and keeps our C<hx-attrs> tidy and local.

=begin code :lang<raku>
role HxTodo {
    method hx-create(--> Hash()) {
        :hx-post("todo"),
        :hx-target<table>,
        :hx-swap<beforeend>,
    }
    method hx-delete(--> Hash()) {
        :hx-delete($.url-id),
        :hx-confirm<Are you sure?>,
        :hx-target<closest tr>,
        :hx-swap<delete>,
    }
    method hx-toggle(--> Hash()) {
        :hx-get("$.url-id/toggle"),
        :hx-target<closest tr>,
        :hx-swap<outerHTML>,
    }
}
=end code

Key features are:
=item these are packaged in a raku role which is then consumed by C<class Todo>
=item method names C<hx-toggle> echo standard HTMX attributes such as C<hx-get>
=item return values are coerced to a raku C<Hash> containing HTMX attrs

=head3 class Todo

The core of our synopsis. It C<does Component> to bring in the scaffolding.

The general idea is that a raku class implements a web Component, multiple instances of the Component are represented by objects of the class and the methods of the class represent actions that can be performed on the Component in the browser.

=begin code :lang<raku>
class Todo does Component {
    also does HxTodo;

    has Bool $.checked is rw = False;
    has Str  $.text;

    method toggle is controller {
        $!checked = !$!checked;
        respond self;
    }

    multi method HTML {
        tr
            td( input :type<checkbox>, |$.hx-toggle, :$!checked ),
            td( $!checked ?? del $!text !! $!text),
            td( button :type<submit>, |$.hx-delete, :style<width:50px>, '-'),
    }
}
=end code

Key features of C<class Todo> are:
=item Todo objects have state C<$.checked> and C<$.text> with suitable defaults
=item C<method toggle> takes the trait C<is controller> - this makes a corresponding Cro route
=item C<method toggle> adjusts the state and ends with the C<respond> sub (which calls C<.HTML>)
=item C<class Todo> provides a C<multi method HTML> which uses functional HTML tags C<tr>, C<td> and so on
=item we call our HxTodo methods eg C<|$.hx-toggle> with the I<call self> shorthand C<$.>
=item the Hash is flattened into individual attrs with C<|>
=item a smattering of style (or any HTML attr) can be added as needed

The result is a concise, legible and easy-to-maintain component implementation.

=head3 sub SITE

Now, we can make a website as follows:

=begin code :lang<raku>
my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Red, Cro',
    footer      => footer p ['Aloft on ', b 'Åir'],
);

my @todos = do for <one two> -> $text { Todo.new: :$text };

sub SITE is export {
    site :register(@todos),
        index
            main [
                h3 'Todos';
                table @todos;
                form  |Todo.hx-create, [
                    input  :name<text>;
                    button :type<submit>, '+';
                ];
            ]
}
=end code

Key features of C<sub SITE> are:
=item1 we make our own function C<&index> that
=item2 (i) uses C<.assuming> to preset some attributes (title, description, footer) and
=item2 (ii) then calls the C<page> function provided by Air::Base
=item1 we set up our list of Todo components calling C<Todo.new>
=item1 we use the Air::Base C<site> function to make our website
=item1 the call chain C<site(index(main(...))> then makes our website
=item1 C<site> is passed C<:register(@todos)> to make the component Cro routes


=head2 Run Cro service.raku

Component automagically creates some cro routes for Todo when we start our website...
=begin code
> raku -Ilib service.raku
theme-color=green
bold-color=red
adding GET todo/<#>
adding POST todo
adding DELETE todo/<#>
adding PUT todo/<#>
adding GET todo/<#>/toggle
adding GET page/<#>
Build time 0.67 sec
Listening at http://0.0.0.0:3000

=end code

=head1 DESCRIPTION

The rationale for Air Components is rooted in the powerful raku code composition capabilities. It builds on the notion of Locality of Behaviour (aka L<LOB|https://htmx.org/essays/locality-of-behaviour/>) and the intent is that a Component can represent and render every aspect of a piece of website behaviour.

=item Content
=item Layout
=item Theme
=item Data Model
=item Actions

As Air evolves, it is expected that common code idioms will emerge to make each dimensions independent (ie HTML, CSS and JS relating to Air::Theme::Font would be local, and distinct from HTML, CSS and JS for Air::Theme::Nav).

Air is an integral part of the hArc stack (HTMX, Air, Red, Cro). The Synopsis shows how a Component can externalize and consume HTMX attributes for method actions, perhaps even a set of Air::HTMX libraries can be anticipated. One implication of this is that each Component can use the L<hx-swap-oob|https://htmx.org/attributes/hx-swap-oob/> attribute to deliver Content, Style and Script anywhere in the DOM (except the C<html> tag). An instance of this could be a blog website where a common Red C<model Post> could be harnessed to populate each blog post, a total page count calculation for paging and a post summary list in an C<aside>.

In the Synopsis, both raku class inheritance and role composition provide coding dimensions to greatly improve code clarity and evolution. While simple samples are shown, raku has comprehensive encapsulation and type capabilities in a friendly and approachable language.

Raku is a multi-paradigm language for both Functional and Object Oriented (OO) coding styles. OO is a widely understood approach to code and state encapsulation - suitable for code evolution across many aspects - and is well suited for Component implementations. Functional is a surprisingly good paradigm for embedding HTML standard and custom tags into general raku source code. The example below illustrates the power of Functional tags inline when used in more intricate stanzas.

While this kind of logic can in theory be delivered in a web app using web template files, as the author of the Cro Template language L<comments|https://cro.raku.org/docs/reference/cro-webapp-template-syntax#Conditionals>
I<Those wishing for more are encouraged to consider writing their logic outside of the template.>

=begin code :lang<raku>
    method nav-items {
        do for @.items.map: *.kv -> ($name, $target) {
            given $target {
                when * ~~ External | Internal {
                  $target.label = $name;
                  li $target.HTML
                }
                when * ~~ Content {
                    li a(:hx-get("$.name/$.serial/" ~ $name), safe $name)
                }
                when * ~~ Page {
                    li a(:href("/{.name}/{.serial}"), safe $name)
                }
            }
        }
    }

    multi method HTML {
        self.style.HTML ~ (

        nav [
            { ul li :class<logo>, :href</>, $.logo } with $.logo;

            button( :class<hamburger>, :serial<hamburger>, safe '&#9776;' );

            ul( :$!hx-target, :class<nav-links>,
                self.nav-items,
                do for @.wserialgets { li .HTML },
            );

            ul( :$!hx-target, :class<menu>, :serial<menu>,
                self.nav-items,
            );
        ]

        ) ~ self.script.HTML
    }
=end code

From the implementation of the Air::Base::Nav component.


=head1 TIPS & TRICKS

When writing components:

=item custom C<multi method HTML> inners must be explicitly rendered with .HTML or wrapped in a tag eg. C<div> since being passed as AN inner will call C<render-tag> which will, in turn, call C<.HTML>

=end pod

use Air::Functional :CRO;

use Cromponent;
use Cromponent::MetaCromponentRole;

sub to-kebab(Str() $_ ) {
    lc S:g/(\w)<?before <[A..Z]>>/$0-/
}

multi trait_mod:<is>(Method $m, Bool :$controller!) is export {
    trait_mod:<is>($m, :controller{})
}
multi trait_mod:<is>(Method $m, :%controller!) is export {
    my %accessible = %controller;
    %accessible<returns-cromponent> = True unless %controller<returns-html>;   #make default
    trait_mod:<is>($m, :%accessible)
}

#| attributes and methods shared between Component and Component::Red roles
role Component::Common does Taggable {
    #| optional attr to specify url base
    has Str  $!base is built = '';
    method base {$!base}

    #| get url safe name of class doing Component role
    method url-name(--> Str()) { self.^shortname.&to-kebab, }

    #| get url (ie base/name)
    method url(--> Str) { do with self.base { "$_/" } ~ self.url-name}

    #| get url-id (ie base/name/id)
    method url-path(--> Str) { self.url ~ '/' ~ self.id }

    #| get html-id (ie url-name-id), intended for HTML id attr
    method html-id(--> Str) { self.url-name ~ '-' ~ self.id }

    #| Cromponent::MetaCromponentRole normally calls .Str on a Cromponent
    #| this method substitutes .HTML for .Str
    method Str { self.HTML }
}

#| Component is for non-Red classes
role Component[
    :C(:CREATE(:A(:$ADD))),
    :R(:READ(:L(:$LOAD))) = True,
    :U(:$UPDATE),
    :D(:$DELETE),
] does Component::Common {
    ::?CLASS.HOW does Cromponent::MetaCromponentRole;

    my  UInt $next = 1;

    #| assigns and tracks instance ids
    has UInt $!id is built;
    method id { $!id }

    my %holder;
    #| populates an instance holder [class method],
    #| may be overridden for external instance holder
    method holder { %holder }

    #| get all instances in holder
    method all { self.holder.keys.sort.map: { $.holder{$_} } }

    #| adapt component to perform LOAD, UPDATE, DELETE, ADD action(s)
    my $methods-made;

    #| called by role Site
    method make-methods {
        return if $methods-made++;

        #| Default ADD action (called on POST)
        if $ADD {
            self.^add_method(
                'ADD', my method ADD(*%data) { ::?CLASS.new: |%data }
                );
        }
        #| Default LOAD action (called on GET)
        if $LOAD {
            self.^add_method(
                'LOAD', my method LOAD($id) { self.holder{$id} }
            );
        }

        ##### FIXME CROMPONENT MetaCromponentRole.rakumod LINE 97 ####
        #| Default UPDATE action (called on PUT)
        if $UPDATE {
            self.^add_method(
                'UPDATE', my method UPDATE(*%data) { self.data(%data); self }
            );
        }
        #| Default DELETE action (called on DELETE)
        if $DELETE {
            self.^add_method(
                'DELETE', my method DELETE { self.holder{self.id}:delete }
            );
        }
    }

    submethod TWEAK {
        $!id //= $next++;
        %holder{$!id} = self;
        self.?make-routes;
    }
}

#| Component::Red is for Red models
role Component::Red[
    :C(:CREATE(:A(:$ADD))),
    :R(:READ(:L(:$LOAD))) = True,
	:U(:$UPDATE),
	:D(:$DELETE),
] does Component::Common {
    ::?CLASS.HOW does Cromponent::MetaCromponentRole;

    #| adapt component to perform LOAD, UPDATE, DELETE, ADD action(s)
    my $methods-made;

    #| called by role Site
    method make-methods {
        return if $methods-made++;

        #| Default ADD action (called on POST)
        if $ADD {
            self.^add_method(
                'ADD', my method ADD(*%data) { ::?CLASS.^create: |%data }
                );
        }
        #| Default LOAD action (called on GET)
        if $LOAD {
            self.^add_method(
                'LOAD', my method LOAD(Str() $id) { ::?CLASS.^load: $id }
                );
        }
        #| Default UPDATE action (called on PUT)
        if $UPDATE {
            self.^add_method(
                'UPDATE', my method UPDATE(*%data) { $.data = |$.data, |%data; $.^save }  #untested
                );
        }
        #| Default DELETE action (called on DELETE)
        if $DELETE {
            self.^add_method(
                'DELETE', my method DELETE { $.^delete }
                );
        }
    }
}

=begin pod
=head1 AUTHOR

Steve Roe <librasteve@furnival.net>

The `Air::Component` module integrates with the Cromponent module, author Fernando Corrêa de Oliveira <fco@cpan.com>, however unlike Cromponent this module does not use Cro Templates.


=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
=end pod


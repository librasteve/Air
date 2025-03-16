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

Predeclares some custom HTMX functions. This declutters C<class Todo>, one nice part of using an HLL to generate HTML.

=begin code :lang<raku>
sub hx-create($url --> Hash()) {
    :hx-post("$url"),
    :hx-target<table>,
    :hx-swap<beforeend>,
    :hx-on:htmx:after-request<this.reset()>,
}
sub hx-toggle($url, $id --> Hash()) {
    :hx-get("$url/$id/toggle"),
    :hx-target<closest tr>,
    :hx-swap<outerHTML>,
}
sub hx-delete($url, $id --> Hash()) {
    :hx-delete("$url/$id"),
    :hx-confirm<Are you sure?>,
    :hx-target<closest tr>,
    :hx-swap<delete>,
}
=end code

Key features are:
=item sub names C<hx-toggle> echo standard HTMX attributes such as C<hx-get>
=item return values are coerced to a raku C<Hash> containing HTMX attrs

=head3 class Todo

The core of our synopsis. It C<does role Component> to bring in the scaffolding.

The general idea is that a raku class implements a web Component, multiple instances of the Component are represented by objects of the class and the methods of the class represent actions that can be performed on the Component in the browser.

=begin code :lang<raku>
class Todo does Component {
    has Bool $.checked is rw = False;
    has Str  $.text;

    method toggle is routable {
        $!checked = !$!checked;
        respond self;
    }

    multi method HTML {
        tr
            td( input :type<checkbox>, |hx-toggle($.url,$.id), :$!checked ),
            td( $!checked ?? del $!text !! $!text),
            td( button :type<submit>, |hx-delete($.url,$.id), :style<width:50px>, '-'),
    }
}
=end code

Key features of C<class Todo> are:
=item Todo objects have state C<$.checked> and C<$.text>
=item C<method toggle> takes the trait C<is routable> - this makes a corresponding Cro route
=item C<method toggle> adjusts the state and ends with the C<respond> sub (which calls C<.HTML>)
=item C<class Todo> provides a C<multi method HTML> which uses functional HTML tags

The result is a concise, legible and easy-to-maintain component implementation.

=head3 sub SITE

Now, we can export a website as follows:

=begin code :lang<raku>
my &index = &page.assuming(
    title       => 'hÅrc',
    description => 'HTMX, Air, Red, Cro',
    footer      => footer p ['Aloft on ', b 'Åir'],
);

my @todos = do for <one two> -> $text { Todo.new: :$text };

sub SITE is export {
    site :components(@todos),
        index
            main [
                h3 'Todos';
                table @todos;
                form  |hx-create("todo"), [
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
=item1 C<site> is passed C<:components(@todos)> to make the component cro routes


=head2 Run Cro service.raku

Component automagically creates some cro routes for Todo when we start our website...
=begin code
> raku -Ilib service.raku
theme-color=azure
bold-color=red
adding GET todo/<id>
adding POST todo
adding DELETE todo/<id>
adding PUT todo/<id>
adding GET todo/<id>/toggle
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
                    li a(:hx-get("$.url-part/$.id/" ~ $name), safe $name)
                }
                when * ~~ Page {
                    li a(:href("/{.url-part}/{.id}"), safe $name)
                }
            }
        }
    }

    multi method HTML {
        self.style.HTML ~ (

        nav [
            { ul li :class<logo>, :href</>, $.logo } with $.logo;

            button( :class<hamburger>, :id<hamburger>, safe '&#9776;' );

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
=end code

From the implementation of the Air::Base::Nav component.


=head1 TIPS & TRICKS

When writing components:

=item custom C<multi method HTML> inners must be explicitly rendered with .HTML or wrapped in a tag eg. C<div> since being passed as AN inner will call C<trender> which will, in turn, call C<.HTML>

=end pod

role IsRoutable {
	has Str $.is-routable-name;
	method is-routable { True }
}

multi trait_mod:<is>(Method $m, Bool :$routable!) is export {
	trait_mod:<is>($m, :routable{})
}

multi trait_mod:<is>(Method $m, :$routable!, :$name = $m.name) is export {
	$m does IsRoutable($name)
}

use Cro::HTTP::Router;

=head2 role Component

role Component {
	my  UInt $next = 1;

	#| assigns and tracks instance ids
	has UInt $.id;   # fixme hash of ids by type

	#| optional attr to specify url base
	has Str  $.base = '';

	my %holder;
	#| populates an instance holder [class method],
	#| may be overridden for external instance holder
	method holder(--> Hash) { %holder }

	#| get all instances in holder
	method all { self.holder.keys.sort.map: { $.holder{$_} } }

	submethod TWEAK {
		$!id //= $next++;
		%holder{$!id} = self;
		self.?make-routes;
	}

	#| get url part
	method url-part(-->Str) { ::?CLASS.^name.subst('::','-').lc }
	#| get url (ie base/part)
	method url(--> Str) { do with self.base { "$_/" } ~ self.url-part }

	#| Default load action (called on GET) - may be overridden
	method LOAD($id)      { self.holder{$id} }

	#| Default create action (called on POST) - may be overridden
	method CREATE(*%data) { ::?CLASS.new: |%data }

	#| Default delete action (called on DELETE) - may be overridden
	method DELETE         { self.holder{$!id}:delete }

	#| Default update action (called on PUT) - may be overridden
	method UPDATE(*%data) { self.data = |self.data, |%data }

	::?CLASS.HOW does my role ExportMethod {
		#| Meta Method ^add-routes typically called from Air::Base::Site in a Cro route block
		method add-routes(
			$component is copy,
			:$url-part = $component.url-part;
		) is export {

			my $route-set := $*CRO-ROUTE-SET
					or die "Components should be added from inside a `route {}` block";

			my &load   = -> $id         { $component.LOAD:   $id    };
			my &create = -> *%pars      { $component.CREATE: |%pars };
			my &del    = -> $id         { load($id).DELETE          };
			my &update = -> $id, *%pars { load($id).UPDATE:  |%pars };

			note "adding GET $url-part/<id>";
			get -> Str $ where $url-part, $id {
				my $comp = load $id;
				respond $comp
			}

			note "adding POST $url-part";
			post -> Str $ where $url-part {
				request-body -> $data {
					my $new = create |$data.pairs.Map;
					redirect "$url-part/{ $new.id }", :see-other
				}
			}

			note "adding DELETE $url-part/<id>";
			delete -> Str $ where $url-part, $id {
				del $id;
				content 'text/html', ""
			}

			note "adding PUT $url-part/<id>";
			put -> Str $ where $url-part, $id {
				request-body -> $data {
					update $id, |$data.pairs.Map;
					redirect "{ $id }", :see-other   #hmm - this works
#					redirect "$url-part/{ $id }", :see-other
				}
			}

			for $component.^methods.grep(*.?is-routable) -> $meth {
				my $name = $meth.is-routable-name;

				if $meth.signature.params > 2 {
					note "adding PUT $url-part/<id>/$name";
					put -> Str $ where $url-part, $id, Str $name {
						request-body -> $data {
							load($id)."$name"(|$data.pairs.Map)
						}
					}
				} else {
					note "adding GET $url-part/<id>/$name";
					get -> Str $ where $url-part, $id, Str $name {
						load($id)."$name"()
					}
				}
			}
		}
	}
}

#| calls Cro: content 'text/html', $comp.HTML
multi sub respond(Any $comp) is export {
	content 'text/html', $comp.HTML
}
#| calls Cro: content 'text/html', $html
multi sub respond(Str $html) is export {
	content 'text/html', $html
}

=begin pod
=head1 AUTHOR

Steve Roe <librasteve@furnival.net>

The `Air::Component` module provided is based on an early version of the raku `Cromponent` module, author Fernando Corrêa de Oliveira <fco@cpan.com>, however unlike Cromponent this module does not use Cro Templates.


=head1 COPYRIGHT AND LICENSE

Copyright(c) 2025 Henley Cloud Consulting Ltd.

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
=end pod
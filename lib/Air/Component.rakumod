=begin pod

=head1 Air::Component

This raku module is one of the core libraries of the raku B<Air> module.

It is a scaffold to build dynamic, reusable web components.


=head1 SYNOPSIS

First, import the Air core libraries.

=begin code :lang<raku>
use Air::Functional :BASE;      # import all HTML tags as raku subs
use Air::Base;					# import Base components (site, page, nav...)
use Air::Component;
=end code

=head2 role HxTodo

Predeclares some custom HTMX actions. This declutters C<class Todo> and C<class Frame>.

=begin code :lang<raku>
role HxTodo {
    method hx-toggle(--> Hash()) {
        :hx-get("$.url/$.id/toggle"),
        :hx-target<closest tr>,
        :hx-swap<outerHTML>,
    }
    method hx-create(--> Hash()) {
        :hx-post("$.url"),
        :hx-target<table>,
        :hx-swap<beforeend>,
        :hx-on:htmx:after-request<this.reset()>,
    }
    method hx-delete(--> Hash()) {
        :hx-delete("$.url/$.id"),
        :hx-confirm<Are you sure?>,
        :hx-target<closest tr>,
        :hx-swap<delete>,
    }
}
=end code

Key features of C<role HxTodo> are:
=item uses a standard raku C<role> for code separation
=item method names C<hx-toggle> are chosen to echo standard HTMX attributes such as C<hx-get>
=item attributes C<$.url> and C<.id> are provided by C<role Component>
=item return values are coerced to a raku C<Hash> containing HTMX attrs

=head2 class Todo

The core of our synopsis. It C<does role Component> to bring in the scaffolding.

The general idea is that a raku class implements a web Component, multiple instances of the Component are represented by objects of the class and the methods of the class represent actions that can be performed on the Component in the browser.

=begin code :lang<raku>
class Todo does Component {
    also does HxTodo;

    has Bool $.checked is rw = False;
    has Str  $.text;

    method toggle is routable {
        $!checked = !$!checked;
        respond self;
    }

    multi method HTML {
        tr
            td(input :type<checkbox>, :$!checked, |$.hx-toggle),
            td($!checked ?? del $!text !! $!text),
            td(button :type<submit>, :style<width:50px>, |$.hx-delete, '-'),
    }
}
=end code

Key features of C<class Todo> are:
=item Todo objects have state C<$.checked> and C<$.text>
=item C<method toggle> takes the trait C<is routable>
=item C<method toggle> adjusts the state and ends with the C<respond> sub (which calls C<.HTML>)
=item C<class Todo> provides a C<multi method HTML>
=item C<method HTML> uses functional HTML tags and brings in HxTodo actions

The result is a concise, legible and easy-to-maintain component implementation.

=head2 class Frame

Provides a frame our Todo components and a form to add new ones.

=begin code :lang<raku>
class Frame does Tag {
    also does HxTodo;

    has Todo @.todos;
    has $.url = "todo";

    multi method HTML {
        div [
            h3 'Todos';
            table @!todos;
            form  |$.hx-create, [
                input  :name<text>;
                button :type<submit>, '+';
            ];
        ]
    }
}
=end code

Key features of C<class Frame> are:
=item C<does Tag> to suppress HTML escape
=item maintains our C<@.todos> list state
=item uses functional tags to make HTML
=item C<multi method HTML> is called when rendered

=head2 sub SITE

Finally, we can export a webite as follows:

=begin code :lang<raku>
my &index = &page.assuming(
        title       => 'hÅrc',
        description => 'HTMX, Air, Raku, Cro',
        footer      => footer p ['Aloft on ', b 'Åir'],
    );

my @todos = do for <one two> -> $text { Todo.new: :$text };

sub SITE is export {
    site :components(@todos), #:theme-color<azure>,
        index
            main
                Frame.new: :@todos;
}
=end code

Key features of C<sub SITE> are:
=item1 we make our own function C<&index> that
=item2 (i) uses C<.assuming> to preset some attributes (title, description, footer) and
=item2 (ii) then calls the C<page> function provided by Air::Base
=item1 we set up our list of Todo components calling C<Todo.new>
=item1 we use the Air::Base C<site> function to make our website
=item1 the call chain C<site(index(main(Frame.new: :@todos;)))> then makes our website
=item1 C<site> is passed C<:components(@todos)> to make the component cro routes
=item1 C<site> may optionally be passed theme settings also


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

---

=head1 TIPS & TRICKS

When writing components:

=item custom multi method HTML inners must be explicitly rendered with .HTML or wrapped in a tag eg. C<div> since being passed as inner will call C<trender> which will, in turn, call C<.HTML>

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

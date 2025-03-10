=begin pod

=head1 Air::Component

This raku module is one of the core libraries of the raku B<Air> module.

It exports HTML tags as raku subs that can be composed as functional code within a raku program.

It replaces the HTML::Functional module by the same author.


=head1 SYNOPSIS

Here's a regular HTML page:

=begin code :lang<html>
<div class="jumbotron">
  <h1>Welcome to Dunder Mifflin!</h1>
  <p>
    Dunder Mifflin Inc. (stock symbol <strong>DMI</strong>) is
    a micro-cap regional paper and office supply distributor with
    an emphasis on servicing small-business clients.
  </p>
</div>
=end code

And here is the same page using Air::Functional:

=begin code :lang<raku>
use Air::Functional;

div :class<jumbotron>, [
    h1 "Welcome to Dunder Mifflin!";
    p  [
        "Dunder Mifflin Inc. (stock symbol "; strong 'DMI'; ") ";
        q:to/END/;
            is a micro-cap regional paper and office
            supply distributor with an emphasis on servicing
            small-business clients.
        END
    ];
];
=end code


=head1 DESCRIPTION

Key features of the module are:
=item HTML tags are implemented as raku functions: C<div, h1, p> and so on
=item parens C<()> are optional in raku function calls
=item HTML tag attributes are passed as raku named arguments
=item HTML tag inners (e.g. the Str in C<h1>) are passed as raku positional arguments
=item the raku Pair syntax is used for each attribute i.e. C<:name<value>>
=item multiple C<@inners> are passed as a literal Array C<[]> – div contains h1 and p
=item the raku parser looks at functions from the inside out, so C<strong> is evaluated before C<p>, before C<div> and so on
=item semicolon C<;> is used as the Array literal separator to suppress nesting of tags

Normally the items in a raku literal Array are comma C<,> separated. Raku precedence considers that C<div [h1 x, p y];> is equivalent to C<div( h1(x, p(y) ) );> … so the p tag is embedded within the h1 tag unless parens are used to clarify. But replace the comma C<,> with a semi colon C<;> and predisposition to nest is reversed. So C<div [h1 x; p y];> is equivalent to C<div( h1(x), p(y) )>. Boy that Larry Wall was smart!

The raku example also shows the power of the raku B<Q-lang> at work:

=item double quotes C<""> interpolate their contents
=item curlies denote an embedded code block C<"{fn x}">
=item tilde C<~> is for Str concatenation
=item the heredoc form C<q:to/END/;> can be used for verbatim text blocks

This module generally returns C<Str> values to be string concatenated and included in an HTML content/text response.

It also defines a programmatic API for the use of HTML tags for raku functional coding and so is offered as a basis for sister modules that preserve the API, but have a different technical implementation such as a MemoizedDOM.

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

role Component {
	# ID, Holder & URL Setup
	my  UInt $next = 1;
	has UInt $.id;   # fixme hash of ids per type

	my %holder;
	method holder { %holder }

	submethod TWEAK {
		$!id //= $next++;
		%holder{$!id} = self;
		self.?make-routes;
	}

	method url-part { ::?CLASS.^name.subst('::','-').lc }
	method url { do with self.base { "$_/" } ~ self.url-part }

	# Default Actions
	method LOAD($id)      { self.holder{$id} }
	method CREATE(*%data) { ::?CLASS.new: |%data }
	method DELETE         { self.holder{$!id}:delete }
	method UPDATE(*%data) { self.data = |self.data, |%data }
	method all { self.holder.keys.sort.map: { $.holder{$_} } }


	# Method Routes
	::?CLASS.HOW does my role ExportMethod {
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

multi sub respond(Any $comp) is export {
	content 'text/html', $comp.HTML
}

multi sub respond(Str $html) is export {
	content 'text/html', $html
}




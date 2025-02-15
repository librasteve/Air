use v6.d;

unit module Air;

=begin pod

=head1 NAME

Component - A way create web components without cro templates

=head1 SYNOPSIS

=begin code :lang<raku>

use Component;
class AComponent does Component {
	has $.data;

	method RENDER {
		Q:to/END/
		<h1><.data></h1>
		END
	}
}

sub EXPORT { AComponent.^exports }

=end code

=head1 DESCRIPTION

Component is a way create web components with cro templates

You can use Components in 3 distinct (and complementar) ways

=begin item

In a template only way:
If wou just want your Component to be a "fancy substitute for cro-template sub/macro",
You can simpley create your Component, and on yout template, <:use> it, it with export
a sub (or a macro if you used the C<is macro> trait) to your template, that sub (or macro)
will accept any arguments you pass it and will pass it to your Component's conscructor
(new), and use the result of that as the value to be used.

Ex:

=begin code :lang<raku>
use Component;

class H1 does Component is macro {
	has Str $.prefix = "My fancy H1";

	method RENDER {
		Q[<h1><.prefix><:body></h1>]
	}
}

sub EXPORT { H1.^exports }

=end code

On your template:

=begin code :lang<crotmp>

<:use H1>
<|H1(:prefix('Something very important: '))>
	That was it
</|>

=end code

=end item

=head1 AUTHOR

Steve Roe <librasteve@furnival.net>

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Steve Roe

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod



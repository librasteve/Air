#!/usr/bin/env raku

use Air::Functional :BASE;
use Air::Base;
use Air::Component;

role HxTodo {
    method hx-add(--> Hash()) {
        :hx-post('todo'),
        :hx-target<table>,
        :hx-swap<beforeend>,
    }
    method hx-delete(--> Hash()) {
        :hx-delete($.url-path),
        :hx-confirm('Are you sure?'),
        :hx-target('closest tr'),
        :hx-swap<delete>,
    }
    method hx-toggle(--> Hash()) {
        :hx-get("$.url-path/toggle"),
        :hx-target<closest tr>,
        :hx-swap<outerHTML>,
    }
}

class Todo does Component[:C:R:U:D] {
    also does HxTodo;

    has Bool $.checked is rw = False;
    has Str  $.text;

    method toggle is controller {
        $!checked = !$!checked;
        self
    }

    multi method HTML {
        tr
            td( input :type<checkbox>, |$.hx-toggle, :$!checked ),
            td( $!checked ?? del $!text !! $!text),
            td( button :type<submit>, |$.hx-delete, :style<width:50px>, '-'),
    }
}


for <one two> -> $text { Todo.new: :$text };

my $site =
    site :register(Todo.new), :scss-off,
        page
        main [
            h3 'Todos';
            table  Todo.all;
            form  |Todo.hx-add, [
                input  :name<text>;
                button :type<submit>, '+';
            ];
        ];

$site.serve;

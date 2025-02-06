#!/usr/bin/env raku

use lib "../lib";
use Cro::HTTP::Router;
use Cro::HTTP::Server;

use Air::Functional :BASE;
use Air::BaseLib;

my $p = Page.new;
$p.title: "Raku HTMX";
$p.style: 'p {color: blue;}';
$p.body: '<p>Hello World!</p>';

my $routes = route {
    get -> {
        content 'text/html', $p.HTML;
    }
};

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => "0.0.0.0",
    port => 3000,
    application => $routes,
    );
$http.start;
say "Listening at http://0.0.0.0:3000";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}

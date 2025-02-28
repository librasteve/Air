#!/usr/bin/env raku

use lib "../lib";

my $p;

{
    use Air::Functional :BASE;
    use Air::Base;

    $p = Page.new:
        title => "Raku HTMX",
        main => Main.new: p 'Hello World!';

    $p.html.head.style = Style.new: 'p {color: blue;}';
}

{
    use Cro::HTTP::Router;
    use Cro::HTTP::Server;
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
}

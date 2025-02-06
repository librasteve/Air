#!/usr/bin/env raku

use lib "../lib";
use Cro::HTTP::Router;
use Cro::HTTP::Server;

use Air::Functional  :BASE;
use Air::BaseLib;

#| write your own role to setup default values and custom attributes
class MyPage does Page {
    submethod TWEAK {
        self.defaults;
        self.link: {:rel<stylesheet>, :href<https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css> };
        self.script: :src<https://unpkg.com/htmx.org@1.7.0>;

        self.style: q:to/END/;
            .jumbotron {
              background-color: #e6ffe6;
              text-align: center;
            }
            END
    }
}

#| then each Page instance can reuse the defaults
my $p = MyPage.new:
    description => 'raku does htmx',
    title       => 'Raku HTMX',
;

$p.body: [
    div( :class<jumbotron>, [
        h1("Welcome to Dunder Mifflin!"),                          #use parens to stop <h1> slurping <p>
        p  "Dunder Mifflin Inc. (stock symbol {strong 'DMI'}) " ~
            q:to/END/;
            is a micro-cap regional paper and office
            supply distributor with an emphasis on servicing
            small-business clients.
            END
    ]),

    p :hx-get<https://v2.jokeapi.dev/joke/Any?format=txt&safe-mode>,
        "Click Me",
];

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

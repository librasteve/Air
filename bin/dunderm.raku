#!/usr/bin/env raku

use lib "../lib";

my $p;

{
    use Air::Functional  :BASE;
    use Air::BaseLib;

    #| write your own role to setup default values and custom attributes
    class MyPage is Page {
        submethod TWEAK {
            self.defaults;
            self.html.head.links.append: Link.new: attrs => {:rel<stylesheet>,
                 :href<https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css>};

            self.html.head.style = Style.new: q:to/END/;
                .jumbotron {
                  background-color: #e6ffe6;
                  text-align: center;
                }
                END
        }
    }

    #| then each Page instance can reuse the defaults
    $p = MyPage.new:
        description => 'raku does htmx',
        title       => 'Raku HTMX',
    ;

    $p.html.body.main = Main.new: [
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


    my $s = Style.new: q:to/END/;
                .jumbotron {
                  background-color: #e6ffe6;
                  text-align: center;
                }
                END

    note $s.inner.raku;
    note $s.HTML;

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
#    $http.start;
#    say "Listening at http://0.0.0.0:3000";
#    react {
#        whenever signal(SIGINT) {
#            say "Shutting down...";
#            $http.stop;
#            done;
#        }
#    }
}

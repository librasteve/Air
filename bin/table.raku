#!/usr/bin/env raku

use lib "../lib";

my $html;

{
    use Air::Functional :BASE;
    use Air::BaseLib;

    my %data =
        :thead[["Planet", "Hexameter (km)", "Distance to Sun (AU)", "Orbit (days)"],],
        :tbody[["Mercury",  "4,880", "0.39",  "88"],
               ["Venus"  , "12,104", "0.72", "225"],
               ["Earth"  , "12,742", "1.00", "365"],
               ["Mars"   ,  "6,779", "1.52", "687"],],
        :tfoot[["Average",  "9,126", "0.91", "341"],];

    $html = div [
                h3 'Table';
                table |%data;
            ];

}

{
    use Cro::HTTP::Router;
    use Cro::HTTP::Server;

    my $routes = route {
        get -> {
            content 'text/html', $html;
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

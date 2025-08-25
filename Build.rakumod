class Build {
    method build($dist-path) {
        my $rair = '.rair-config';

        mkdir "$*HOME/$rair";
        copy "resources/.air.yaml", "$*HOME/$rair/.air.yaml";

        exit 0
    }
}
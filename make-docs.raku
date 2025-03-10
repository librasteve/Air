#!/usr/bin/env perl6

use File::Find;

sub MAIN (:$filename, :$output = 'index.md') {

    my @files = $filename
        ?? $filename.Array
        !!
            find
                dir => 'lib',
                name => /'.rakumod' $/;

    my ($docsDir) = ($*CWD, '');
    unless $docsDir.add('lib').e {
        say 'Please run this script from the project root directory.';
        exit;
    }

    $docsDir .= add('docs');
    $docsDir.mkdir;

    my @destFiles;
    for @files {
        my $newFile = $docsDir;

        for $*SPEC.splitdir( .relative ).skip(1) {
            $newFile .= add($_);
            $newFile.mkdir unless $newFile.Str.ends-with('.rakumod');
        }

        print "Processing { $newFile }...";
        my $docs = qqx{perl6 -Ilib --doc=Markdown $_};

        if $docs.trim {
            my $destFile = $newFile.extension('md');
            $destFile.spurt: $docs;
            @destFiles.push($destFile);
            say "output written to { $destFile.relative }";
        } else {
            say "nothing to output";
        }
    }

    # If processing a single file, do NOT write out the index.
    unless $filename {
        # Write index file
        my $index = "Document Index\n";
        $index ~= '=' x $index.chars.chomp ~ "\n\n";

        for sort @destFiles {
            my $m = .extension('');
            my $module-name = $*SPEC.splitdir( $m.relative ).skip(1).join('::');

            my $n = .extension('md');
            $index ~= "- [{ $module-name }]({ $n.relative })\n";
        }

        my $index-page = $docsDir.parent.resolve.add($output);
        $index-page.resolve.spurt: $index;
    }

}

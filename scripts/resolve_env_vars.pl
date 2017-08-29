#!/usr/bin/env perl
# given a list of dirs, finds in them files ending in
# .nginx.conf.template , reads their contents, replaces
# occurances of ${SOME_VAR} in them with matching values
# from env var and writes the contents to same file path
# minus the ".template" part.

use strict;
use warnings;

sub process_dir {
    my $directory = shift;
    my $directory_ptr;

    opendir ($directory_ptr, $directory);

    while (my $file = readdir($directory_ptr)) {
        if ($file =~ m/\.nginx\.conf\.template$/) {

            my $file_ptr;
            my $file_full_path = "$directory/$file";
            my $output_file = substr $file_full_path, 0, -9;

            print "  $directory/$file > $output_file\n";

            open $file_ptr, '<', $file_full_path or die $!;
            my @file_lines = <$file_ptr>;
            close $file_ptr;

            my $content = join("",@file_lines);
            $content =~ s/\$\{(\w+)\}/$ENV{$1}/g;

            # removing '.template' from end of the file name
            open $file_ptr, '>', $output_file or die $!;
            print $file_ptr $content;
            close $file_ptr;
        };
    }

    closedir($directory_ptr);
}

foreach my $directory (@ARGV) {
    print "Env Var Processing Dir: $directory\n";
    process_dir($directory)
}

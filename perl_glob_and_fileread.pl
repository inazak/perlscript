#!/usr/bin/perl -l

use strict;
use warnings;

my $DATADIR = "/tmp";


if (@ARGV != 1) {
  print "Usage: script.pl KEYWORD";
  exit 1;
}

my $keyword = $ARGV[0];
my @matches = ();

my @all_files = glob( "$DATADIR/*.dat" );
for my $file (@all_files) {

  ## read file
  open(my $fh, '<', $file) or die "Error: file open: $file";
  my @lines = <$fh>;
  close $fh;

  ## grep
  my @match = grep(m/^${keyword}/, @lines);
  for my $record (@match) {
    chomp $record;
    my($first, $rest) = split(/,/, $record);
    push(@matches, $rest);
  }
}

if (scalar @matches == 0) {
  print "not found";
  exit 8;
}

print "detected: " . scalar @matches;

exit 0;


#!/usr/bin/perl
use strict;
use warnings;

my @list = ();

while (my $line = <>) {

  chomp $line;
  push @list, $line;

}

my %name = ();

for my $e (sort { length $a <=> length $b } @list) {

  $e =~ s/\r//g;

  if ($e =~ m{^\.[^.]+$}) {
    $name{$e} = 1;
    next;
  }

  my $duplicated = 0;
  my $parent_name = $e;

  while ( $parent_name =~ m{^\.[^.]+(\..+)$} ) {
    $parent_name = $1;
    if (defined $name{$parent_name}) {
      $duplicated = 1;
      last;
    }
  }

  unless ($duplicated) {
    $name{$e} = 1;
  }
}

for my $e (sort keys %name) {
  print "$e\n";
}


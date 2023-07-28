#!/usr/bin/perl -wl

use strict;
use warnings;

my @list = ();
while (my $arg = shift @ARGV) {
  my @comma_separated = split(/,/, $arg);
  push @list, \@comma_separated;
}

my $result = cartesian_product(\@list);
for my $a (@$result) {
  print join(" ", @$a);
}

exit 0;

# $ perl cartesian.pl 1,2 3 4,5
# 1 3 4
# 1 3 5
# 2 3 4
# 2 3 5



sub cartesian_product {
  my $listref = shift;

  return [] if scalar @$listref == 0;

  my $first = shift @$listref;
  my @product = map {[$_]} @$first;

  rec_cartesian_product(\@product, $listref);
}

sub rec_cartesian_product {
  my ($product, $listref) = @_;
  
  return $product if scalar @$listref == 0;

  my $first = shift @$listref;
  my @new_product = ();

  for my $a (@$product) {
    for my $b (@$first) {
      push @new_product, [@$a, $b];
    }
  }

  rec_cartesian_product(\@new_product, $listref);
}



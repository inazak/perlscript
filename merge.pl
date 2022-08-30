#!/usr/bin/perl -wl -s

use strict;

my $delimiter = "\t";
my $joint = "\t";

my $file1 = shift or die "Usage: $0 FILE1 FILE2";
my $file2 = shift or die "Usage: $0 FILE1 FILE2";

my %file2_of;

open my $handle2, "<", $file2 or die "$!";
while(<$handle2>){
  chomp;
  my ($key, $value) = split(/$delimiter/, $_, 2);
  next unless $key and $value;
  $file2_of{$key} = $value;
}
close $handle2;

open my $handle1, "<", $file1 or die "$!";
while(<$handle1>){
  chomp;
  my ($key, $value) = split(/$delimiter/, $_, 2);
  next unless $key and $value;
  if(defined $file2_of{$key}){
    print $key, $delimiter, $value, $joint, $file2_of{$key};
  }else{
    print $key, $delimiter, $value, $joint;
  }
}
close $handle1;



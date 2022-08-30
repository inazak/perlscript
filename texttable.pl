#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use List::Util qw(max);

my $delim  = '[ \t]+';
my $title  = undef;
my $right  = undef;
my $noline = undef;

GetOptions(
  'd|delim=s'   => \$delim,
  't|title'     => \$title,
  'r|right'     => \$right,
  'n|noline'    => \$noline,
  'h|help'      => sub { pod2usage( -exitval => 1 ) },
) or do{ pod2usage( -exitval => 1 ); };

my @rows   = ();
my @column = (); #column width

## read each lines
while (<>) {

  my $line = $_;
  chomp $line;

  next if $line =~ m{ \A \s* \z }xms;

  my @fields = split(/$delim/, $line);
  my @length = map { length $_ } @fields;
  
  push @rows, [ @fields ];

  for my $i (0..$#length) {
    $column[$i] = defined $column[$i]?
      max($column[$i], $length[$i]): $length[$i];
  }

}

## no records
exit 0 if scalar @rows == 0;


my $bar = '+-' .
          join('-+-', map { '-' x $column[$_] } (0..$#{$rows[0]})) .
          '-+';

## print top bar line
print "$bar\n" if ! defined $noline;

for my $i (0..$#rows) {

  my @fields = ();

  for my $j (0..$#{$rows[$i]}) {
    my $padding = $column[$j];
    my $field = defined $right?
      sprintf("%${padding}s",  $rows[$i]->[$j]):
      sprintf("%-${padding}s", $rows[$i]->[$j]);
    push @fields, $field;
  }

  print defined $noline?
           join(' ',   @fields)        . "\n":
    '| ' . join(' | ', @fields) . ' |' . "\n";

  ## print header delimiter bar line
  print "$bar\n" if defined $title && $i == 0;
}

## print bottom bar line
print "$bar\n" if ! defined $noline;


__END__

=head1 NAME

texttable -- A command-line tool convert TSV into ascii-text-table

=head1 SYNOPSIS

texttable.pl [options] file

Options:

    -d,   --delim=s   field Delimiter
    -t,   --title     divide first line as Title
    -r,   --right     Right Align
    -n,   --noline    No line
    -h,   --help      diplay this Help

Single-character options may be stacked.

Sample Output is follows.

  $ cat a.tsv.txt
  Name OS Since
  alice MacOS 2013/11/01
  bob Windows 2012/03/03
  john Linux 2001/07/01
  
  $ texttable.pl -t a.tsv.txt
  +-------+---------+------------+
  | Name  | OS      | Since      |
  +-------+---------+------------+
  | alice | MacOS   | 2013/11/01 |
  | bob   | Windows | 2012/03/03 |
  | john  | Linux   | 2001/07/01 |
  +-------+---------+------------+

=head1 OVERVIEW

texttable is a command-line tool convert TSV into ascii-text-table

=cut


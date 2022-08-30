#!/usr/bin/perl -wl -s
use strict;
use warnings;
use Cwd;

our $width;
$width = 3 if !defined $width;

my $answer = "";
my $topfolder = cwd();

print "zero padding? (Y/N)";
$answer = <STDIN>;
exit 1 if $answer !~ m{ \A y \Z }xmsi;

for my $file (glob_from($topfolder)) {
  next if -d $file;
  if ($file =~ /^(.+?)(\d+)(\D*)$/) {
    my $head   = $1;
    my $number = $2;
    my $tail   = $3;
    if (length $number < $width) {
      my $prep = "0" x ($width - length($number));
      print "   ${head}${number}${tail}\n";
      print "=> ${head}${prep}${number}${tail}\n";
      rename $file, "${head}${prep}${number}${tail}";
    }
  }
}

exit 0;

# glob_from function works with files
# that contains spaces within name
sub glob_from {
  my $path = shift;
  my $handle;
  opendir $handle, $path or die "$! $path";
  return map { "$path/$_" }
         grep { $_ !~ /^[.]+$/ }
         readdir $handle;
}

__END__

=head1 NAME

  zeropad

=head1 OVERVIEW

  if the number in the file name is not within the specified width,
  this script will be completed with zero

=head1 SYNOPSIS

  $ zeropad.pl

  For example, if the folder structure is as follows,

  current/ ---+--- any1.jpg
              +--- any10.jpg
              +--- any100.jpg

  The result is as follows.

  current/ ---+--- any001.jpg
              +--- any010.jpg
              +--- any100.jpg

  OPTION
    -width=N       N is padding width.

  $ zeropad.pl -width=5

  current/ ---+--- any00001.jpg
              +--- any00010.jpg
              +--- any00100.jpg

=cut



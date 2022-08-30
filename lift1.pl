#!/usr/bin/perl -wl
use strict;
use warnings;
use Cwd;
use File::Basename;

my $topfolder = cwd();

my $batchfile = "$topfolder/a.bat";
open my $batch, ">", $batchfile;

for my $subfolder (glob_from($topfolder)) {
  next if -f $subfolder;

  my $moved = 0;

  for my $folder (glob_from($subfolder)) {
    next if -f $folder;
    $moved = 1;
    print "Target is [$folder]";
    print $batch qq{move  /y "$folder" "$topfolder"};
  }
  
  if ($moved) {
    print $batch qq{rmdir /s "$subfolder"};
  }
}

close $batch;

print "Do you want to move? (Y/N)";
my $answer = <STDIN>;
do { unlink $batchfile; exit 1 } if $answer !~ m{ \A y \Z }xmsi;

system(qq{cmd /c call "$batchfile"});

unlink $batchfile;

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

  lift1 (works on windows only)

=head1 OVERVIEW

  move folder in subfolder to current folder.
  this script works on *windows only*.

=head1 SYNOPSIS

  there is no option, no argument.
  
  $ lift1.pl

  For example, if the folder structure is as follows,

  current/ ---+-- a/ ---+--- 001/
              |         +--- 002/
              |         +--- 003/
              |
              +-- b/ ---+--- 004/
                        +--- 005/

  The result is as follows.

  current/ ---+--- 001/
              +--- 002/
              +--- 003/
              +--- 004/
              +--- 005/

=cut


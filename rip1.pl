#!/usr/bin/perl -wl
use strict;
use warnings;
use Cwd;
use File::Basename;

my $topfolder = cwd();

print "";
print "Target is subfolder of [$topfolder]";
print "!! Do you want to rename? (Y/N)";
my $answer = <STDIN>;
exit 1 if $answer !~ m{ \A y \Z }xmsi;

my $batchfile = "$topfolder/a.bat";
open my $batch, ">", $batchfile;

for my $folder (glob_from($topfolder)) {
  next if -f $folder;

  print "";
  print "folder is [$folder]";

  if (failsafe_target_is_popular_files($folder)) {
    print "Failsafe exit.";
    close $batch;
    unlink $batchfile;
    exit 1;
  }

  rename_files($folder);

  print $batch qq{move "$folder\\*" "$topfolder"};
}

close $batch;

print "";
print "Move to [$topfolder]";
print "Do you want to move? (Y/N)";
$answer = <STDIN>;
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

## rename image file
## before: DIRNAME\FILE.jpg
## after : DIRNAME\DIRNAME___FILE.jpg
sub rename_files {
  my $dirname = shift;
  my $prefix = basename($dirname);
  $prefix =~ s/ /_/g;

  for my $file (glob_from($dirname)) {
    print "$file";
    if (-d $file) {
      print STDERR "Skip: detect inner folder [$file]";
    } else {
      my $newfile = $dirname . "\\" . $prefix . "___" . basename($file);
      print " => $newfile";
      rename $file, $newfile;
    }
  }
}

sub failsafe_target_is_popular_files {
  my $dirname = shift;

  for my $file (glob_from($dirname)) {
    if (-f $file) {
      if ($file !~ /\.(jpg|jpeg|png|bmp|tiff|txt|zip|rar|lnk|url|mp3|pdf)$/i) {
        print STDERR "Error: detect unknown file [$file]";
        return 1;
      }
    }
  }
  return 0;
}

__END__

=head1 NAME

  rip1 (works on windows only)

=head1 OVERVIEW

  move files in subfolder to current folder.
  failsafe interruption works if the target
  file is not one of the following.

  jpg|jpeg|png|bmp|tiff|txt|zip|rar|lnk|url|mp3|pdf

  this script works on *windows only*.

=head1 SYNOPSIS

  there is no option, no argument.
  
  $ rip1.pl

  For example, if the folder structure is as follows,

  current/ ---+-- a/ ---+--- 001.jpg
              |         +--- 002.jpg
              |         +--- 003.jpg
              |
              +-- b/ ---+--- 004.jpg
                        +--- 005.jpg

  The result is as follows.

  current/ ---+--- a___001.jpg
              +--- a___002.jpg
              +--- a___003.jpg
              +--- b___004.jpg
              +--- b___005.jpg

=cut



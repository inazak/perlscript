#!/usr/bin/perl -w
use strict;
use warnings;
use Cwd;
use File::Basename;
use File::Path qw/rmtree/;

my $headsize = 10;
if (scalar @ARGV == 1) {
  $headsize = $ARGV[0];
}
my $width = 4;

my $topfolder = cwd();

for my $subfolder (glob_from($topfolder)) {
  next if -f $subfolder;

  print "------------------------------------------\n";
  print "[$subfolder]\n";

  ## inner folder
  for my $folder (glob_from($subfolder)) {
    next if not -d $folder;
    print "!! [$folder] !!\n";

    while(1) {
      print "\nSubfolder [y,p=next,d=del,r=rip] >> ";
      my $answer = <STDIN>;

      last if $answer =~ m{ \A (y|p) \Z }xmsi;
      if ($answer =~ m{ \A d \Z }xmsi) {
        rmtree $folder;
        last;
      }
      if ($answer =~ m{ \A r \Z }xmsi) {
        rip($folder, $subfolder);
        last;
      }
    } 
    print "\n";
  }

  ## inner files
  my $count = 0;
  for my $file (glob_from($subfolder)) {
    next if $count >= $headsize;
    next if -d $file;
    print "$file\n";
    $count++;
  }

  my $redo = 0; 
  while(1) {
    print "\nAction [y,p=next,k=padding,r=rename,c=continue] >> ";
    my $answer = <STDIN>;

    last if $answer =~ m{ \A (y|p) \Z }xmsi;
    if ($answer =~ m{ \A k \Z }xmsi) {
      padding($subfolder, $width); 
      $redo = 1;
      last;
    }
    if ($answer =~ m{ \A r \Z }xmsi) {
      rename_files($subfolder); 
      $redo = 1;
      last;
    }
    if ($answer =~ m{ \A c \Z }xmsi) {
      $redo = 1;
      last;
    }
  }
  print "\n";
  redo if $redo == 1;
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

sub padding {
  my ($folder, $width) = @_;
  for my $file (glob_from($folder)) {
    next if -d $file;
    if ($file =~ /^(.+?)(\d+)(\D*)$/) {
      my $head   = $1;
      my $number = $2;
      my $tail   = $3;
      if (length $number < $width) {
        my $pad = "0" x ($width - length($number));
        print "   ${head}${number}${tail}\n";
        print "=> ${head}${pad}${number}${tail}\n";
        rename $file, "${head}${pad}${number}${tail}";
      }
    }
  }
}

sub rip { 
  my ($folder, $upperfolder) = @_;

  for my $file (glob_from($folder)) {
    if (-d $file) {
      print "!!RIP FAIL: InnerDir $file\n";
      return 1;
    }

    my $newfile = $upperfolder . "\\" . basename($file);
    rename $file, $newfile;
  }
  rmdir $folder;
}

sub rename_files {
  my $dirname = shift;
  my $count = 1;

  for my $file (glob_from($dirname)) {
    if (-d $file) {
      print STDERR "WARN: InnerDir $file";
      return;
    }
    else {
      $file =~ /\.(jpg|jpeg|png|bmp|tiff)$/i;
      my $ext = $1;
      my $newfile = sprintf("$dirname/%04d.$ext", $count);
      rename $file, $newfile;
      $count++;
    }
  }
}


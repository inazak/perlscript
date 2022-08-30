#!/usr/bin/perl -wl -s
use strict;
use warnings;
use Cwd;

our $single;

die "imgzip.pl TITLE" if scalar @ARGV != 1;
my $title  = $ARGV[0];
my $topfolder = cwd();

print "target title is [$title]";
print "Do you want to rename folder and files? (Y/N)";
my $answer = <STDIN>;
exit 1 if $answer !~ m{ \A y \Z }xmsi;

my $zipbatchfile = "$topfolder/a.bat";
open my $zipbatch, ">", $zipbatchfile;

for my $folder (glob_from($topfolder)) {
  next if -f $folder;

  if (defined $single) {
    my $newname = "$title";
    rename $folder, $newname;
    rename_files($newname);
    #make batchfile
    print $zipbatch qq{7za a -tzip -r "$newname.zip" "$newname"};
    print $zipbatch qq{del /Q "$title\\*"};
    last;
  }

  if ($folder =~ /^.+?(\d+)\D*$/) {
    my $newname = "$title VOL-$1";
    rename $folder, $newname;
    rename_files($newname);
    #make batchfile
    print $zipbatch qq{7za a -tzip -r "$newname.zip" "$newname"};
    print $zipbatch qq{mkdir "$title"};
  }
}

print $zipbatch qq{move "$title*.zip" "$title"};
close $zipbatch;

print "Do you want to zip file and move folder? (Y/N)";
$answer = <STDIN>;
do { unlink $zipbatchfile; exit 1 } if $answer !~ m{ \A y \Z }xmsi;

system(qq{cmd /c call "$zipbatchfile"});
unlink $zipbatchfile;

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

sub rename_files {
  my $dirname = shift;
  my $count = 1;

  for my $file (glob_from($dirname)) {
    if (-d $file) {
      print STDERR "WARN: InnerDir $file";
      exit 1;
    }
    else {
      if ($file !~ /\.(jpg|jpeg|jpe|png|bmp|tiff|webp)$/i) {
        if ($file =~ /\.(zip|rar)$/i) {
          print STDERR "WARN: InnerFile $file";
          exit 1;
        }
        print "DEL: $file";
        unlink $file;
      }
      else {
        $file =~ /\.(jpg|jpeg|jpe|png|bmp|tiff|webp)$/i;
        my $ext = $1;
        my $newfile = sprintf("$dirname/IMGZIP%04d.$ext", $count);
        rename $file, $newfile;
        $count++;
      }
    }
  }
}


use strict;
use warnings;

use utf8;
binmode STDIN,  ":utf8";
binmode STDOUT, ":utf8";

for my $file (@ARGV) {

  open(my $FH, "<:utf8", $file) or die;
  my $text = do { local $/; <$FH> };

  while ($text =~ m/<img alt="([^"]+)"/msg) {
    print "$1\n";
  }

  close $FH;
}

exit 0;



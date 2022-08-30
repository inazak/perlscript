#!/usr/bin/perl

use strict;
use warnings;
use MIME::Base64;

if (scalar @ARGV != 1) {
  print "Usage: base64script.pl SCRIPT_FILE\n";
  exit 1;
}

open(my $FH, "<", $ARGV[0]) or die;
my $text = do { local $/; <$FH> };

eval decode_base64($text);

exit 0;



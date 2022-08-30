#!/usr/bin/perl
use warnings;
use strict;

## USAGE:
## perl caesar.pl cqrbrbrc
#
## EXAMPLE:
# $ perl caesar.pl cqrbrbrc
# 00: CQRBRBRC
# 01: DRSCSCSD
# 02: ESTDTDTE
# 03: FTUEUEUF
# 04: GUVFVFVG
# 05: HVWGWGWH
# 06: IWXHXHXI
# 07: JXYIYIYJ
# 08: KYZJZJZK
# 09: LZAKAKAL
# 10: MABLBLBM
# 11: NBCMCMCN
# 12: OCDNDNDO
# 13: PDEOEOEP
# 14: QEFPFPFQ
# 15: RFGQGQGR
# 16: SGHRHRHS
# 17: THISISIT
# 18: UIJTJTJU
# 19: VJKUKUKV
# 20: WKLVLVLW
# 21: XLMWMWMX
# 22: YMNXNXNY
# 23: ZNOYOYOZ
# 24: AOPZPZPA
# 25: BPQAQAQB


sub caesar_char {
  my ($char, $shift) = @_;

  if (length $char != 1) {
    die "caesar_char only work 1byte char"
  }

  return $char if $char !~ m/[a-zA-Z]/;

  $char =~ tr/a-z/A-Z/;

  $shift = (ord($char) - ord('A') + $shift) % 26;

  return chr(ord('A') + $shift);
}


my @crypt = split(//, $ARGV[0]);

for my $n (0..25) {
  printf("%02d: ", $n);
  for my $c (@crypt) {
    print caesar_char($c, $n);
  }
  print "\n";
}



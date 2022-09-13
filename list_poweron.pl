#!/usr/bin/perl

use warnings;
use strict;
use Net::Ping;

my %stores = (
'拠点A        ' => '10.1',
'拠点B        ' => '10.2',
'拠点C        ' => '10.3',
);

my $ignore = qr|^(SOMETHING)|;

my %summary;
my %list;
my $icmp = Net::Ping->new("icmp");

my @lookup = grep { m|^\\\\| } `net view /domain:xxxx`;
map { chomp; s|^\\\\(\S+).*$|$1|g; } @lookup;

for my $term (@lookup) {
  next if $term =~ $ignore;
  my @addrs = (gethostbyname($term))[4];
  my $i = sprintf("%s.%s.%s.%s", unpack('CCCC', $addrs[0]));
  next unless ($icmp->ping($i, 3));
  unless (@addrs) {
    $summary{"ip_lookup_fail"}++;
    $list{"ip_lookup_fail"} .= "$term\n";
  } else {
    my $ip16bit = sprintf("%s.%s", unpack('CCCC', $addrs[0]));
    $summary{$ip16bit}++;
    $list{$ip16bit} .= "$term\n";
  }
}

### header
print "■ 端末起動チェック ■\n\n";
print "（レポート日時）\n\n";
print localtime(time) . "\n";
print "\n\n";

### summary view
print "（サマリー）\n\n";
for my $store (sort keys %stores) {
  my $ip = $stores{$store};
  my $ip_show = sprintf("% 6s", $ip);
  if ($summary{$ip}) {
    my $count = sprintf("% 4d", $summary{$ip});
    print "$store ($ip_show)  =>  $count\n";
  } else {
    print "$store ($ip_show)  =>     0\n";
  }
}
print "\n\n\n";

### list view
print "（端末別）\n\n";
for my $store (sort keys %stores) {
  my $ip = $stores{$store};
  print "------ $store\n";
  print "$list{$ip}\n" if ($list{$ip});
  print "\n" unless ($list{$ip});
}
print "\n\n\n";


#!/usr/bin/perl

use warnings;
use strict;
use URI::Escape;
use utf8;

my @keywords = (
'マリーゴールド',
'すずらん',
'チューリップ',
'鳳仙花',
);

my $UA = 'Mozilla/5.0';
my $RF = 'https://www.google.com';

for my $keyword (@keywords) {
  my $k = uri_escape_utf8($keyword);
  my $html = `curl -A "$UA" -e "$RF" http://something.example/?s=$k`;
  parse_html_and_print($keyword, $html);
  sleep 5;
}

exit 0;

sub parse_html_and_print {
  my ($keyword, $html) = @_;

  my @articles = $html =~ m{<article[^>]+>(.+?)</article>}sg;

  print "=== [$keyword] ===\n";
  for my $article (@articles) {
    $article =~ s/<.+?>//g;
    $article =~ s/\n\n+/\n/g;
    print "$article\n";
    print "---\n";
  }
  print "\n\n";
}



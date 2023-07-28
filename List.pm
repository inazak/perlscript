package MyUtil::List;

use strict;
use warnings;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT_OK = qw(group_by has_duplicate any every);
our %EXPORT_TAGS = (
  all => [ @EXPORT_OK ]
);



sub any (&@) {
    my $f = shift;
    foreach ( @_ ) {
        return !0 if $f->();
    }
    return !1;
}

sub every (&@) {
    my $f = shift;
    foreach ( @_ ) {
        return !1 unless $f->();
    }
    return !0;
}

sub group_by (&@) {
  my ($create_key, @copy) = @_;
  my @key_queue = ();
  my %key_index = ();
  my $index = 0;

  local $_;
  foreach (@copy) {
    my $val = $_;
    my $key = &$create_key();
    if (!defined $key_index{$key}) {
      $key_queue[$index] = [$val];
      $key_index{$key} = $index++;
    }
    else {
      push @{$key_queue[$key_index{$key}]}, $val;
    }
  }
  return @key_queue;
}


sub has_duplicate {
  my @copy = @_;
  my %exists = ();

  for my $item (@copy) {
    return !0 if defined $exists{$item};
    $exists{$item} = 1;
  }
  return !1;
}


1;


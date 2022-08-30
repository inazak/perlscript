package MyUtil::Iterator;

use strict;
use warnings;

use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT_OK = qw(iterator imap igrep ifold
                    imin imax imin_n imax_n
                    ilist cartesian_product);
our %EXPORT_TAGS = (
  all => [ @EXPORT_OK ]
);

sub iterator(&) {
  return $_[0];
}

sub imap(&$) {
	my ($code, $it) = @_;

	return iterator {
		local $_ = &$it();
		return if ! defined $_;
		return &$code();
	};
}

sub igrep(&$) {
	my ($pred, $it) = @_;

  return iterator {
    local $_;
    while (defined ($_ = &$it())) {
      return $_ if &$pred();
    }
    return;
  }
}

sub ifold(&$$) {
	my ($code, $it, $init) = @_;

  local $_;
  local $];
  while (defined ($_ = &$it())) {
    $] = $init;
    $init = &$code();
  }
  return $init;
}

sub imin(&$) {
	my ($code, $it) = @_;

  local $_;
  $it = imap { [$_, &$code()] } $it;

  my $val = &$it();
  return if !defined $val;

  $val = ifold { $_->[1] < $]->[1]? $_: $] } $it, $val;

  return wantarray? @$val: $val->[0];
}

sub imax(&$) {
	my ($code, $it) = @_;

  local $_;
  $it = imap { [$_, &$code()] } $it;

  my $val = &$it();
  return if !defined $val;

  $val = ifold { $_->[1] > $]->[1]? $_: $] } $it, $val;

  return wantarray? @$val: $val->[0];
}

sub imin_n(&$$) {
  my ($code, $it, $size) = @_;
  my ($k, $copy) = ();
  my @keys = ();
  my @vals = ();

  local $_;
  while (defined ($_ = &$it())) {
    $copy = $_;
    $k = &$code();
    for my $i (reverse 0..($size - 1)) {
      if ((!defined $keys[$i]) || ($k < $keys[$i])) {
        if ($i < $size - 1) {
          $vals[$i+1] = $vals[$i];
          $keys[$i+1] = $keys[$i];
        }
        $vals[$i] = $copy;
        $keys[$i] = $k;
      }
      else {
        last;
      }
    }
  }
  for my $i (reverse 0..($size - 1)) {
    if (!defined $keys[$i]) {
      pop @keys;
      pop @vals;
    }
  }
  return if @keys == 0;
  return wantarray? (\@vals, \@keys): \@vals;
}

sub imax_n(&$$) {
  my ($code, $it, $size) = @_;
  my ($k, $copy) = ();
  my @keys = ();
  my @vals = ();

  local $_;
  while (defined ($_ = &$it())) {
    $copy = $_;
    $k = &$code();
    for my $i (reverse 0..($size - 1)) {
      if ((!defined $keys[$i]) || ($k > $keys[$i])) {
        if ($i < $size - 1) {
          $vals[$i+1] = $vals[$i];
          $keys[$i+1] = $keys[$i];
        }
        $vals[$i] = $copy;
        $keys[$i] = $k;
      }
      else {
        last;
      }
    }
  }
  for my $i (reverse 0..($size - 1)) {
    if (!defined $keys[$i]) {
      pop @keys;
      pop @vals;
    }
  }
  return if @keys == 0;
  return wantarray? (\@vals, \@keys): \@vals;
}

sub ilist($) {
  my ($it) = @_;
  my @list = ();

  local $_;
  while (defined ($_ = &$it())) {
    push @list, $_;
  }
  return @list;
}


sub cartesian_product {
  my @list = @_;
  my @index = map {    0 } @list;
  my @limit = map { $#$_ } @list;

  return iterator {
    
    return if ! @list;

    my @result = map { $list[$_]->[$index[$_]] } (0..$#list);

    # generate next pattern
    for my $i (0..$#index) {
      if ($index[$i]  < $limit[$i]) { $index[$i] += 1; last; }
      if ($index[$i] == $limit[$i]) { $index[$i]  = 0; next; }
    }

    # when iterator exhausted
    unless (grep { $_ != 0 } @index) {
      @list = @index = @limit = ();
    }

    # return scalar value
    return \@result;
  }
}

1;
__END__

- undef is exhausted sign
- iterator must return scalar value



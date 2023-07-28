package MyGmailSender;

use strict;
use warnings;
use utf8;

use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;
use IO::All;

sub new {
  my ($class, %hash) = @_;
  my $self = {
    addr => $hash{addr},
    cred => $hash{cred},
  };
  return bless $self, $class;
}

sub send {
  my ($self, %hash) = @_;

  my $to   = $hash{to};
  my $subj = defined $hash{subj}? $hash{subj}: '';
  my $body = defined $hash{body}? $hash{body}: '';
  my $atch = defined $hash{atch}? $hash{atch}: '';

  if ((! defined $to) or (! defined $self->{addr}) or (! defined $self->{cred})) {
    return 'undefined [to] or [addr] or [cred]';
  }

  my $sender = Email::Sender::Transport::SMTP::TLS->new(
    host     => 'smtp.gmail.com',
    port     => 587,
    username => "$self->{addr}",
    password => "$self->{cred}",
  );

  my @parts = (
    Email::MIME->create(
      attributes => {
        content_type => 'text/plain',
        charset      => 'utf-8',
        encoding     => 'base64',
      },
      body_str => $body,
    ),
  );

  if ($atch) {
    push @parts, Email::MIME->create(
      attributes => {
        content_type => 'application/octet-stream',
        encoding     => 'base64',
        filename     => $atch,
        name         => $atch,
        disposition  => 'attachment',
      },
      body => io($atch)->all,
    );
  }

  my $mail = Email::MIME->create(
    header => [
      To      => "$to",
      From    => "$self->{addr}",
      Subject => "$subj",
    ],
    parts => [ @parts ],
  ); 

  sendmail($mail, {transport => $sender});

}

1;

__END__

=head1 NAME

MyGmailSender

=head1 SYNOPSIS

  use FindBin;
  use lib $FindBin::Bin;
  
  use MyGmailSender;
  
  my $gmail = new MyGmailSender(
    addr => '---@gmail.com',
    cred => 'P@ssw0rd',
  );
  
  $gmail->send(
    to   => '===@gmail.com',
    subj => 'this is test',
  );

  or attach file

  $gmail->send(
    to   => '===@gmail.com',
    subj => 'this is test',
    body => 'UTF-8 string',
    atch => 'a.txt'
  );

=head1 DESCRIPTION

connect to smpt.gmail.com:587 and send mail

=head1 REQUIRED

  (debian linux)
  apt-get install libio-socket-ssl-perl
  apt-get install libemail-sender-perl
  apt-get install libemail-sender-transport-smtp-tls-perl
  apt-get install libemail-mime-perl
  apt-get install libio-all-perl

=cut



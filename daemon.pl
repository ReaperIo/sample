#!/usr/bin/env perl

use FindBin qw{ $RealBin };
use DBIx::Custom;                 # можно было, конечно, обычным DBI, но много лишнего мусора в коде будет + это просто удобный модуль для DBI. драйвер использует тот же.
use Mojo::JSON qw{ encode_json }; # в задании не указано было - разложить по разным полям в базе или в одно, сложил в jsonb.
use Mojo::UserAgent;

sub init {
  my $config;

  my $file = sprintf "%s/etc/application.conf", $RealBin;

  unless ( $config = do $file ) {
    die "couldn't parse $file: $@" if $@;
    die "couldn't do $file: $!"    unless defined $config;
    die "couldn't run $file"       unless $config;
  }

  my $dsn = sprintf "dbi:%s:database=%s;host=%s;", $config->{'sql'}{'driver'}, $config->{'sql'}{'database'}, $config->{'sql'}{'hostname'};
  
  my $dbh = DBIx::Custom->connect(
    dsn      => $dsn,
    user     => $config->{'sql'}{'username'},
    password => $config->{'sql'}{'password'},
    option   => {
        mysql_enable_utf8 => $config->{'sql'}{'options'}{'utf8'},
        RaiseError        => $config->{'sql'}{'options'}{'RaiseError'},
        PrintError        => $config->{'sql'}{'options'}{'PrintError'},
        AutoCommit        => $config->{'sql'}{'options'}{'AutoCommit'},
    },
  );

  die "Not a DBIx::Custom connection" unless $dbh->isa('DBIx::Custom');

  return ( $config, $dbh );
}

sub get_data {
  my ( $url, $limit ) = @_;

  $limit //= 3;

  my $ua  = Mojo::UserAgent->new;
  my $res = $ua->get( $url );

  return undef if ( $res->{'completed'} ne 2 );

  my %result;

  for my $item ( ( sort keys %{ $res->result->headers->{'headers'} } )[0..$limit-1] ) {
    $result{ $item } = $res->result->headers->{'headers'}{ $item }[0];
  }

  return ( keys %result > 0 ) ? ( $res->result->code, encode_json \%result ): undef;
}

my ( $config, $db ) = init();

my $rs = $db->select(
  table  => 'resources',
  column => [ qw{id_resource url} ],
  where  => { valid => 1 },
  append => 'order by id_resource asc'
  )->all;

die "Empty database" if ( scalar @{ $rs } == 0 );

foreach my $row ( @{ $rs } ) {
  my ( $code, $result ) = ( defined $row->{'url'} ) ? get_data( $row->{'url'}, $config->{'other'}{'header_limit'} ) : 'undefined url';

  if ( defined $result ) {
    $db->update(
      {
        headers_field => $result,
        http_status   => $code
      },
      table => 'resources',
      where => { id_resource => $row->{'id_resource'} },
      mtime => 'date_upd'
    );
  } else {
    $db->update(
      { valid => 0 },
      table => 'resources',
      where => { id_resource => $row->{'id_resource'} },
      mtime => 'date_upd'
    );
  }
}

1;
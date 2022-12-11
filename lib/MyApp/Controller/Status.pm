package MyApp::Controller::Status;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::JSON qw{decode_json encode_json};

sub index ( $c ) {
  my $rs = $c->dbi->select(
    table  => 'resources',
    column => '*',
    where  => { valid => 1 },
    append => 'order by id_resource asc'
  )->all;

  if ( scalar @{ $rs } > 0 ) {
    $c->respond_to(
      json => { json => $rs ? { results => $rs, message => 'success' } : { status => 'error', message => 'not found' } },
      any => { text => 'u not welcome, go away', status => 404 },
    );
  } else {
    $c->render( text => 'empty database', status => 204 );
  }
}

sub show ( $c ) {
  my $id_resource = $c->param('id');
  #return $c->reply->exception('incorrect id') unless $id_resource;
  return $c->render( json => { result => undef, message => 'incorrect id' }, status => 302 ) unless $id_resource;

  my $rs = $c->dbi->select(
    table  => 'resources',
    column => [ qw{url date_upd http_status headers_field} ],
    where  => { valid => 1, id_resource => $id_resource }
  )->one;

  if ( $rs ) {
    $c->respond_to(
      json => { json => $rs ? { results => $rs, message => 'success' } : { status => 'error', message => 'not found' } },
      any => { content => $rs, status => 404 },
    );
  } else {
    $c->render( json => { result => "resource width id `$id_resource` not found", message => 'success' }, status => 302 );
  }
}

sub create ( $c ) {
  my $url = $c->param('url');

  my $rs = $c->dbi->select(
    table  => 'resources',
    column => 'id_resource',
    where  => { url => $url }
  )->one;

  #return $c->reply->exception("url: $url already exist") if $rs;
  return $c->render( json => { result => "url: $url already exist", message => 'error' }, status => 302 ) if $rs;

  my ( $code, $result ) = $c->_get_data( $url );

  return $c->render( json => { result => "incorrect url: $url", message => 'error' }, status => 302 ) unless $result;

  $c->dbi->insert(
    { 
      url           => $url,
      headers_field => $result,
      http_status   => $code
    },
    table => 'resources'
  );

  return $c->render( json => { result => "url: $url added to database", message => 'success' }, status => 302 );
}

sub remove ( $c ) {
  my $id_resource = $c->param('id');
  #return $c->reply->exception('incorrect id') unless $id_resource;
  return $c->render( json => { result => undef, message => 'incorrect id' }, status => 302 ) unless $id_resource;

  my $rs = $c->dbi->select(
    table  => 'resources',
    column => 'id_resource',
    where  => { id_resource => $id_resource }
  )->one;

  return $c->render( json => { result => undef, message => "resource width id `$id_resource` not found" }, status => 302 ) unless $rs;

  $c->dbi->delete(
    table  => 'resources',
    where  => { id_resource => $id_resource }
  );

  if ( $rs ) {
    $c->respond_to(
      json => { json => { results => "$id_resource removed", message => 'success' } },
      any => { content => "u not welcome, go away", status => 404 },
    );
  } else {
    $c->render( json => { result => undef, message => "resource width id `$id_resource` not found" }, status => 302 );
  }
}

sub _get_data ( $c, $url ) {
  use Mojo::UserAgent;

  my $limit = $c->app->config->{'other'}{'header_limit'} //= 3;

  my $ua  = Mojo::UserAgent->new;
  my $res = $ua->get( $url );

  return undef if ( $res->{'completed'} ne 2 );

  my %result;

  for my $item ( ( sort keys %{ $res->result->headers->{'headers'} } )[0..$limit-1] ) {
    $result{ $item } = $res->result->headers->{'headers'}{ $item }[0];
  }

  return ( keys %result > 0 ) ? ( $res->result->code, encode_json \%result ): undef;
}

1;

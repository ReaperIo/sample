package Mojolicious::Plugin::DBIxCustom;
use Mojo::Base 'Mojolicious::Plugin';

use DBIx::Custom;

sub register{
  my ( $self, $app, $config ) = @_;
  $config = ( keys %{ $config } eq 0 ) ? $app->config->{'sql'} : $config;

  $app->helper( dbi => sub{ 
    foreach ( qw{driver database hostname username password} ) {
      die "No $_ was passed!" unless $config->{ $_ };
    }

    my $dbi = DBIx::Custom->connect(
      dsn      => sprintf ( "dbi:%s:database=%s;host=%s;", $config->{'driver'}, $config->{'database'}, $config->{'hostname'} ),
      user     => $config->{'username'},
      password => $config->{'password'},
      option   => {
        sprintf ( "%s_enable_utf8", lcfirst $config->{'driver'} ) => $config->{'options'}{'utf8'},
        RaiseError => $config->{'options'}{'RaiseError'},
        PrintError => $config->{'options'}{'PrintError'},
        AutoCommit => $config->{'options'}{'AutoCommit'}
      }
    );

    die "Not a DBIx::Custom connection" unless $dbi->isa( 'DBIx::Custom' );

    return $dbi;
  });
  $app->helper( model => sub {
      my ( $c, $model_name ) = @_;
      $c->dbi->model( $model_name );
    }
  );
}

1;
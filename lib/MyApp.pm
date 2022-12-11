package MyApp;
use Mojo::Base 'Mojolicious', -signatures;

sub startup ( $app ) {
  $app->plugin( 'Config', { file => $app->home->rel_file( 'etc/application.conf' ) } );
  $app->secrets( $app->config->{'secrets'} );
  $app->mode( $app->config->{'mode'} );

  $app->plugin( 'DBIxCustom' ); # можно было, конечно, обычным DBI/Mojo::PG, но много лишнего мусора в коде будет + это просто удобный модуль для DBI. драйвер использует тот же.

  my $r = $app->routes;

  $r->add_shortcut( resource => sub ( $r, $name ) {
    my $resource = $r->any("/$name")->to("$name#");
    $resource->get( '/' => [ format => [ qw{html json} ] ] )->to( '#index', format => 'json' )->name("index_$name");
    $resource->get( '/:id' => [ id => qw{\d+}, format => [ qw{html json} ] ] )->to( '#show', format => 'json' )->name("show_$name");
    $resource->put( '/*url' => [ url => qw{((http.*?:\/\/)?[\w-]+(\.[\w-]+)+\.?(:\d+)?(\/\S*)?)} ] )->to( '#create', format => 'json' )->name("create_$name");
    $resource->delete( '/:id' => [ id => qw{\d+} ] )->to( '#remove', format => 'json' )->name("remove_$name");
    return $resource;
  });

  $r->get('/')->to('Example#welcome');
  $r->resource( 'status' );
}

1;

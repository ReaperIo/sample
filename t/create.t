use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t  = Test::Mojo->new('MyApp');
foreach my $url ( 'google.com', 'http://google.com', 'https://google.com', 'google.com:80', 'http://google.com:80', 'https://google.com:443' ) {
  $t->put_ok( '/status/' . $url );
}

$t->put_ok( '/status/google.com' )->status_is(302)->json_is({ result => 'url: google.com already exist', message => 'error' });

done_testing();
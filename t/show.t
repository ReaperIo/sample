use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

my $t  = Test::Mojo->new('MyApp');
$t->get_ok('/status')->status_is(200)->text_is('table');
$t->get_ok('/status')->status_is(200)->json_is( '/results/1/url' => 'http://google.com' );
$t->get_ok('/status/99')->status_is('302')->json_is({ result => 'resource width id `99` not found', message => 'success' });
$t->get_ok('/status/qwerty')->status_is('404');

done_testing();

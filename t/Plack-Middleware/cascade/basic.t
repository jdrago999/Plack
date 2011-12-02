use Plack::Test;
use Test::More;

use Plack::App::Cascade;
use Plack::App::URLMap;
use Plack::App::File;
use HTTP::Request::Common;

my $cascade = Plack::App::Cascade->new;

test_psgi $cascade, sub {
    my $cb = shift;
    $res = $cb->(GET "http://localhost/");
    is $res->code, 404;
};

$cascade->add( Plack::App::File->new(root => "t/Plack-Middleware")->to_app );
$cascade->add( Plack::App::File->new(root => "t/Plack-Util")->to_app );
$cascade->add( sub { [ 404, [], [ 'Custom 404 Page' ] ] } );

my $app = Plack::App::URLMap->new;
$app->map("/static", $cascade);

test_psgi app => $app->to_app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/static/access_log.t");
    is $res->code, 200;

    $res = $cb->(GET "http://localhost/static/foo");
    is $res->code, 404;
    is $res->content, 'Custom 404 Page';

    $res = $cb->(GET "http://localhost/static/foreach.t");
    is $res->code, 200;
};

done_testing;

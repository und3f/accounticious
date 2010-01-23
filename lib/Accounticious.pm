package Accounticious;

our $VERSION = 0.1;

use strict;
use warnings;

use Mojo::JSON ();
use DBI ();

use base 'Mojolicious';

my %config = (
    loglevel        => 'debug',
    session_expires => 60 * 60 * 24 * 3,
);

# This method will run once at server start
sub startup {
    my $self = shift;

    # Use our own controller
    $self->controller_class( 'Accounticious::Controller' );
    
    # Load configuration
    %config = ( %config, %{$self->plugin('json_config')} );

    # Use latests templates
    $self->renderer->default_handler('ep');

    # And nice encoding
    $self->renderer->encoding('utf-8');

    # Logging
    $self->log->level( $config{loglevel} );
    $self->mode( 'production' ) if $self->log->level ne 'debug';

    # Database 
    $self->plugin(
        database => [
            @{$config{db}},
            {
                PrintWarn  => 1,
                PrintError => 1,
            }, 
        ]
    );

    # Install sessions
    $self->plugin(
        session => {
            stash_key       => 'session',
            store           => 'dbi',
            expires_delta   => $config{session_expires},
            init            => sub {
                my ( $self, $session ) = @_;
                $session->store->dbh( $self->stash->{db}->dbh );
            },
        }
    );
    
    # Routes
    my $auth = $self->routes->bridge->to( 'auth#auth' );

    $auth->route( '/login' )
        ->to( 'auth#login', error_code  => '')
        ->name( 'login' );

    $auth->route( '/login_do' )
        ->to( 'auth#login_do', error_code  => '')
        ->name( 'login_do' );

    $auth->route( '/logout' )
        ->to( 'auth#logout' )
        ->name( 'logout' );

    $auth->route('/')
        ->to( 'auth#root' )
        ->name( 'root' );

    $auth->route('/account')
        ->to( 'account#index' )
        ->name( 'account' );

}

1;

package Mojolicious::Plugin::Database;

use strict;
use warnings;

use DBI;
use DBIx::Simple;

use base 'Mojolicious::Plugin';

our @cache;

sub register {
    my ($self, $app, $db_config) = @_;

    # Connect
    $app->plugins->add_hook(
        before_dispatch => sub {
            my ( $self, $c ) = @_;

            return if ( $c->res->code );

            my $cached = shift @cache;
            if ( defined $cached ) {
                $c->stash( db => $cached );
                return;
            }

            my $dbh = DBI->connect( @$db_config )
                or die 'DBI connect failed';

            # dbi
            my $db = DBIx::Simple->connect( $dbh )
                or die DBIx::Simple->error;

            $c->stash( db => $db );

            return;
        }
    );

    # Cache
    $app->plugins->add_hook(
        after_dispatch => sub {
            my ( $self, $c ) = @_;
            return unless my $db = $c->db;
            push( @cache, $db );
            $c->stash( db => undef );
        }
    );
}


1;

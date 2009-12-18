package Accounticious;

our $VERSION = 0.1;

use strict;
use warnings;

use Mojo::JSON ();
use DBI ();
use MojoX::Session ();

use base 'Mojolicious';

my %config = (
    loglevel        => 'debug',
    session_expires => 60 * 60 * 24 * 3,
);

sub _load_config_file {
    my ($self, $conf_file) = @_;
    if (-e $conf_file) {
        if (open FILE, '<', $conf_file) {
            my @lines = <FILE>;
            close FILE;
            my $source = join '', map { $_=~s/\#.*$//;chomp;$_ } @lines;
            my $json = Mojo::JSON->new;
            my $json_config = $json->decode( $source );
            $self->log->fatal("JSON parsing failed: ", $json->error)
                unless $json_config;
            %config = (%config, %$json_config);
        };
    };
};

# Do it on every request
sub process {
    my ($self, $c) = @_;

    # Connect to DB
    my $dbh  = DBI->connect( 
        @{$config{DB}},
        {
            PrintWarn  => 1,
            PrintError => 1,
        },
    );

    $c->db( $dbh );

    $c->session( MojoX::Session->new(
            tx              => $c->tx,
            store => [dbi   => {dbh => $dbh}],
            transport       => 'cookie',
            expires_delta   => $config{session_expires},
    ));

    $self->dispatch( $c );
}

# This method will run once at server start
sub startup {
    my $self = shift;

    # Use our own controller
    $self->controller_class( 'Accounticious::Controller' );
    
    # Load configuration
    $self->_load_config_file( $self->home->rel_file('accounticious.conf') );

    # Use latests templates
    $self->renderer->default_handler('ep');

    # And nice encoding
    $self->renderer->encoding('utf-8');

    # Logging
    $self->log->level( $config{loglevel} );
    $self->mode( 'production' ) if $self->log->level ne 'debug';
    
    # Routes
    my $r = $self->routes;

    # Routes
    $r->route('/')
      ->to(controller => 'account', action => 'index');

}

1;

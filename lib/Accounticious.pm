package Accounticious;

our $VERSION = 0.1;

use strict;
use warnings;

use base 'Mojolicious';

use Mojo::JSON ();

my %config = (
    loglevel    => 'debug',
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

# This method will run once at server start
sub startup {
    my $self = shift;

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

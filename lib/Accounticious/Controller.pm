package Accounticious::Controller;

use strict;
use warnings;

use base 'Mojolicious::Controller';

__PACKAGE__->attr( db => sub {
        return shift->stash->{db};
});

sub new {
    my $class = shift;
    $class->SUPER::new( @_ );
}


sub redirect {
    my ( $self, $target, $extra ) = @_;

    $self->res->code( 302 );
    $self->res->headers->header(
        Location => $self->url_for( $target ) . ( defined $extra ? $extra : '' )
    );

    return;
}

1;

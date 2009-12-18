package Accounticious::Controller;

use strict;
use warnings;

use base 'Mojolicious::Controller';

__PACKAGE__->attr([qw/ db session /]);

sub new {
    my $class = shift;
    $class->SUPER::new( @_ );
}

1;

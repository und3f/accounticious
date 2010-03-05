package Accounticious::Auth;

use strict;
use warnings;

use base 'Accounticious::Controller';

sub login_do {
    my $self = shift;

    my $p = $self->req->params->to_hash;

    if ( defined $p->{username} && $p->{username} ne ''
        && defined $p->{password} && $p->{password} ne '' ) {

        # Try to login
        if (my $user_id = $self->db->check_login( @{$p}{qw/ username password /} )) 
        {
            $self->session( user_id => $user_id );

            $self->redirect( 'account' );
            return;

        } else {
            $self->stash( error_code => 'INVALID' );
        }
    } else {
        $self->stash( error_code => 'REQUIRED' );
    }

    $self->render( action => 'login' );
}

sub logout {
    my $self = shift;

    $self->session( expires => 1 );
    $self->redirect( 'login' );
}

sub auth {
    my $self = shift;
    my $user_id = $self->session('user_id');
    unless ($user_id) {
        $self->redirect( 'login' );
        return undef;
    }

    $self->stash('user' => $self->db->get_user_data( $user_id ) );
}

1;

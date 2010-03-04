package Accounticious::Auth;

use strict;
use warnings;

use base 'Accounticious::Controller';

sub login_do {
    my $self = shift;

    my $p = $self->req->params->to_hash;

    if ( defined $p->{username} && $p->{username} ne ''
        && defined $p->{password} && $p->{password} ne '' ) {

        # Clear old session
        if ( $self->session->load ) {
            $self->session->expire;
            $self->session->flush;
        }

        # Try to login
        if (my $user_id = $self->db->checkLogin( @{$p}{qw/ username password /} )) 
        {
            $self->session->create;
            $self->session->data( user_id => $user_id );
            $self->session->extend_expires;

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

    if ($self->session->load) {
        $self->session->expire;
        $self->session->flush;
    }
    $self->redirect( 'login' );
}

sub auth {
    my $self = shift;

    unless ($self->session->load) {
        $self->redirect( 'login' );
        return undef;
    }

    $self->stash('user' => $self->db->getUserData( $self->session->data('user_id') ) );
}

1;

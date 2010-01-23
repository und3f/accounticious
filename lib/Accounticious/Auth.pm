package Accounticious::Auth;

use strict;
use warnings;

use base 'Accounticious::Controller';

use Digest::SHA1 ();

sub check_login {
    my ($self, $username, $password) = @_;
    my ( $user_id ) = $self->db->query(q{
        SELECT id
        FROM user 
        WHERE username = ? AND password = ?
        LIMIT 1
    }, $username, Digest::SHA1::sha1_base64($password) )->list;
    return $user_id;
}

sub login {
    my $self = shift;
}

sub login_do {
    my $self = shift;

    my $p = $self->req->params->to_hash;

    print "Here\n";
    if ( defined $p->{username} && $p->{username} ne ''
        && defined $p->{password} && $p->{password} ne '' ) {

        # Clear old session
        if ( $self->session->load ) {
            $self->session->expire;
            $self->session->flush;
        }

        # Try to login
        if (my $user_id = $self->check_login( @{$p}{qw/ username password /} )) 
        {
            $self->session->create;
            $self->session->data( user_id => $user_id );
            $self->session->extend_expires;

            $self->redirect( 'account' );

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

}

1;

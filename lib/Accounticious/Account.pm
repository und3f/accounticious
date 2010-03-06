package Accounticious::Account;

use strict;
use warnings;

use base 'Accounticious::Controller';

sub index {
    my $self = shift;
    
    my $account = $self->db->get_account_data( $self->stash('user')->{id} );

    $self->render( account => $account );
}

sub insert_record {
    my $self = shift;

    my $error_code = undef;
    my %operation;
    foreach my $f (qw/ src dst amount currency comment /) {
        $error_code = 'REQUIRED' unless ($operation{$f} = $self->req->param($f));
    }

    unless ($error_code) {
        # Do operation
        $self->db->execute_transaction( user => $self->stash('user')->{id}, %operation );
        my $account = $self->db->get_account_data( $self->stash('user')->{id} );
        $self->render( account => $account, template => 'account/index', );
    }
    else {
        # print error
        my $account = $self->db->get_account_data( $self->stash('user')->{id} );
        $self->render( account => $account, template => 'account/index',
            error_code => $error_code, %operation,
        );
    }
}

sub password {
    my $self = shift;

    my ($submit, $cur, $new, $new_ret) = @{$self->req->params->to_hash}{qw/ submit cur new new_ret /};

    if ($submit) {
        if ($new ne $new_ret) {
            $self->stash(error_code => 'DOESNT_MATCH');
        } elsif ( ! $self->db->check_login($self->stash('user')->{username}, $cur ) ) {
            $self->stash(error_code => 'WRONG');
        } else {
            # Change that password
            $self->db->change_password( $self->stash('user')->{id}, $new );
            $self->stash(error_code => 'OK');
        }
    }

}

sub history {
    my $self = shift;

    $self->render( account => $self->db->get_account_history( $self->stash('account_id') ) );
}

1;

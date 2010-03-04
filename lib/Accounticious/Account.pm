package Accounticious::Account;

use strict;
use warnings;
use utf8;

use base 'Accounticious::Controller';

sub index {
    my $self = shift;
    
    my $account = $self->db->getAccountData( $self->stash('user')->{id} );

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
        $self->db->executeTransaction( user => $self->stash('user')->{id}, %operation );
        my $account = $self->db->getAccountData( $self->stash('user')->{id} );
        $self->render( account => $account, template => 'account/index', );
    }
    else {
        # print error
        my $account = $self->db->getAccountData( $self->stash('user')->{id} );
        $self->render( account => $account, template => 'account/index',
            error_code => $error_code, %operation,
        );
    }
}

sub history {
    my $self = shift;

    $self->render( account => $self->db->getAccountHistory( $self->stash('account_id') ) );
}

1;

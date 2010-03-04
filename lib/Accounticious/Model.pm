package Accounticious::Model;

use strict;
use warnings;
use utf8;

use DBIx::Simple;

use base 'DBIx::Simple';

sub new {
    my $class = shift;
    $class->SUPER::new( @_ );
}

sub getUserData {
    my ($self, $id) = @_;
    return $self->query('SELECT * FROM user WHERE id = ?', $id)->hash;
}

sub getAccountData {
    my ($self, $account_id) = @_;
    my $account_name = $self->query('SELECT account_name FROM account WHERE account_id = ?', $account_id)->list;
    my @balances = $self->query('SELECT currency, amount FROM balance WHERE account = ?', $account_id)->hashes;
    return {
        id      => $account_id,
        name    => $account_name,
        balance => \@balances,
    };
}

sub getAccountHistory {
    my ($self, $account_id) = @_;
    my $account = $self->getAccountData( $account_id );
    $account->{history} = $self->query(
        q{
            SELECT 
                user.username AS user, created,
                account_src.account_name AS src, account_src.account_id AS src_id,
                account_dst.account_name AS dst, account_dst.account_id AS dst_id,
                amount, currency, comment
            FROM history
            JOIN
                user ON user.id = user
            JOIN
                account AS account_src ON account_src.account_id = account_src
            JOIN
                account AS account_dst ON account_dst.account_id = account_dst
            WHERE account_src = ? OR account_dst = ?
        },
        $account_id, $account_id
    )->hashes;
    return $account;
}

# executeTransaction( $self, %operation );
# fields of %operation:
# 'user' - who made transaction
# 

sub executeTransaction {
    my ($self, %operation) = @_;

    # Determine whatever account are present
    my $sql_select_acc_id = 'SELECT account_id FROM account WHERE account_name = ?';
    my $sql_create_acc = 'INSERT INTO account(account_name) VALUES (?)';

    my $src_acc = $operation{src};
    my $dst_acc = $operation{dst};


    # Source account ID
    my $src_id = $self->query($sql_select_acc_id, $src_acc)->list;
    unless ($src_id) {
        $self->query( $sql_create_acc, $src_acc );
        my $src_id = $self->query($sql_select_acc_id, $src_acc)->list;
    }

    # Destination account ID
    my $dst_id = $self->query($sql_select_acc_id, $dst_acc)->list;
    unless ($dst_id) {
        $self->query( $sql_create_acc, $dst_acc );
        my $dst_id = $self->query($sql_select_acc_id, $dst_acc)->list;
    }

    # Do it in double record way
    $self->query(q{
        INSERT INTO history (account_src, account_dst, currency, user, comment, amount)
        VALUES (?, ?, ?, ?, ?, ?)
        },
        $src_id, $dst_id,
        $operation{currency}, $operation{user},
        $operation{comment}, $operation{amount}
    );
}

1;


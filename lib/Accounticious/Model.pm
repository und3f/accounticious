package Accounticious::Model;

use strict;
use warnings;
use utf8;

use DBIx::Simple;

use base 'DBIx::Simple';

use Digest::SHA1 ();

sub new {
    my $class = shift;
    $class->SUPER::new( @_ );
}

sub check_login {
    my ($self, $username, $password) = @_;
    my ( $user_id ) = $self->query(q{
        SELECT id
        FROM user 
        WHERE username = ? AND password = ?
        LIMIT 1
    }, $username, Digest::SHA1::sha1_base64($password) )->list;
    return $user_id;
}

sub change_password {
    my ($self, $userid, $password) = @_;

    $self->query(q{
        UPDATE user
        SET password = ?
        WHERE id = ?
    }, Digest::SHA1::sha1_base64($password), $userid );
}


sub get_user_data {
    my ($self, $id) = @_;
    return $self->query('SELECT * FROM user WHERE id = ?', $id)->hash;
}

sub get_account_data {
    my ($self, $account_id) = @_;
    my $account_name = $self->query('SELECT account_name FROM account WHERE account_id = ?', $account_id)->list;
    my @balances = $self->query('SELECT currency, amount FROM balance WHERE account = ?', $account_id)->hashes;
    return {
        id      => $account_id,
        name    => $account_name,
        balance => \@balances,
    };
}

sub get_account_history {
    my ($self, $account_id) = @_;
    my $account = $self->get_account_data( $account_id );
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

sub get_or_create_balance {
    my ($self, $name) = @_;

    # Get it
    if ( my $id = $self->query(
            'SELECT account_id FROM account WHERE account_name = ?',
            $name)->list
    )
    {
        return $id;
    }

    # or create
    $self->query('INSERT INTO account(account_name) VALUES (?)', $name)->list;
    return $self->query( 'SELECT account_id FROM account WHERE account_name = ?', $name )
        ->list;
}

# executeTransaction( $self, %operation );
# fields of %operation:
# 'user' - who made transaction
# 

sub execute_transaction {
    my ($self, %operation) = @_;

    # Determine whatever account are present
    my $src_acc = $operation{src};
    my $dst_acc = $operation{dst};


    # Source account ID
    my $src_id = $self->get_or_create_balance( $src_acc );

    # Destination account ID
    my $dst_id = $self->get_or_create_balance( $dst_acc );

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


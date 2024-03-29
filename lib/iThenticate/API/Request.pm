package iThenticate::API::Request;

use strict;
use warnings;


our $VERSION = 0.06;

use RPC::XML;

$RPC::XML::ENCODING = 'UTF-8';

=head1 NAME

iThenticate::API::Request - create request objects for the iThenticate::API

=head1 SYNOPSIS

 # construct a new API request
 $request = iThenticate::API::Request->new( {
     method => 'login',         # required
     auth   => $auth_object,    # auth object appropriate to the transport mechanism
 } );

 # make the request using an iThenticate::API::Client user agent
 $response = $client->make_request( { request => $request } );

 # dump out the request as a string
 $string = $request->as_string;


=head1 DESCRIPTION


=head1 VARIABLES

=over 4

=item Validations

This package scoped hash consists of methods and their required
arguments.  It is necessary because we cannot always rely on the server
to validate request arguments.

=back

=cut

# note that there is no entry for document.get, that method does not
# use the same request argument structure as the rest of the methods
# and must be handled individually
# we use a simple hash for validation here instead of Params::Validate
# just to keep the dependencies to a minimum.

our %Validations = (
    'document.get'   => { id => 'int' },
    'document.trash' => { id => 'int' },

    'report.get' => { id => 'int' },

    'user.add' => { first_name => 'string',
        last_name => 'string',
        email     => 'string',
        password  => 'string',
        timezone  => 'int', },

    'user.drop' => { id => 'int' },

    'group.add'     => { name => 'string' },
    'group.folders' => { id   => 'int' },
    'group.drop'    => { id   => 'int' },

    'folder.add' => { name => 'string',
        description    => 'string',
        folder_group   => 'int',
        exclude_quotes => 'boolean', },    # add_to_index is optional

    'folder.get'   => { id => 'int' },
    'folder.trash' => { id => 'int' },
);



=head1 METHODS

=over 4

=item new()

 # construct a new API request
 $request = iThenticate::API::Request->new({
     method => 'login',               # required
     auth   => $auth_object,          # required
 });

=cut

sub new {
    my ( $class, $args ) = @_;

    my $method     = $args->{method}            || die 'no method passed';
    my $auth       = $args->{auth}              || die 'no auth passed';
    my $novalidate = delete $args->{novalidate} || undef;

    # create a data structure for the rpc struct
    my %struct_args = %{$auth};

    # handle the novalidate workaround needed for document.add method
    my $validated_args;
    if ( !$novalidate ) {

        # arguments specific to the request were passed so validate them
        $validated_args = eval { $class->validate( $method, $args->{req_args} ) };
        die "parameter validation failed: $@\n" if $@;
    } elsif ( $novalidate && $args->{req_args} ) {

        $validated_args = $args->{req_args};
    }

    if ( $validated_args ) {
        foreach my $arg_key ( keys %{$validated_args} ) {
            $struct_args{$arg_key} = $validated_args->{$arg_key};
        }
    }

    my $rpc_request = RPC::XML::request->new(
        $args->{method}, RPC::XML::struct->new( \%struct_args ),
    );
    die 'could not create new rpc request object' unless $rpc_request;

    # validation complete, create the object
    my %self;
    bless \%self, $class;

    $self{rpc_request} = $rpc_request;

    return \%self;

} ## end sub new

=item validate()

 my $validated_args = eval { $class->validate( $method, $args->{req_args} ) };

Given an xmlrpc method, and a hash reference of key value argument pairs,
this returns the corresponding RPC::XML entities.  If any arguments are
missing or invalid, this method dies with an appropriate error string;

=cut


sub validate {
    my ( $class, $method, $args ) = @_;

    return $args unless exists $Validations{$method};

    my $validate = $Validations{$method};
    my %validated;

    # check to make sure the required arguments are of the right type
    foreach my $key ( keys %{$validate} ) {
        die "required arg $key not present\n" unless defined $args->{$key};
        my $sub = '_' . $validate->{$key};

        # validate the argument
        no strict 'refs';    ## no-critic
        $validated{$key} = $sub->( $key, $args->{$key} );
    }

    return \%validated;
} ## end sub validate

sub _int {
    my ( $key, $val ) = @_;

    # our friendly RPC::XML library doesn't actually verify this is an
    # integer so we have to run an additional check
    die "$key value $val is not an integer\n" unless $val =~ m/^\d+$/;

    return RPC::XML::int->new( $val );
}

sub _boolean {
    my ( $key, $val ) = @_;

    # RPC::XML is broken for booleans also :(
    die "$key is not a boolean\n" unless $val =~ m/^(?:0|1|yes|no|true|false)$/;

    return RPC::XML::boolean->new( $val );
}

sub _string {
    my ( $key, $val ) = @_;

    return RPC::XML::string->new( $val );
}


=back

=head1 FAQ

Q:  Why are you using this hodge podge validation scheme instead of
Params::Validate? 

A:  To minimize the number of dependencies.  Partly evil yes, but easy
install is one of the goals of this module.

=head1 BUGS

Plenty at this stage I'm sure.  Send patches to the author.

=head1 SEE ALSO

 iThenticate::API::Client, iThenticate::API::Response, RPC::XML

=head1 AUTHOR

Fred Moyer <fred@iparadigms.com>

=head1 COPYRIGHT

Copyright 2008 iParadigms LLC

=cut


1;

package custom::apps::protocols::x509::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
							'validity'	=> 'custom::apps::protocols::x509::mode::validity',
                        );
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check X509's certificate validity.
Requires : 
- Crypt::OpenSSL::X509
- Date::Calc
- Getopt::Long;

=cut

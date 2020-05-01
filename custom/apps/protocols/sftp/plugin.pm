package custom::apps::protocols::sftp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
							'login'	=> 'custom::apps::protocols::sftp::mode::login',
                        );
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check a SFTP server.
Requires :
- Net::SFTP::Foreign
- Time::HiRes

=cut

package custom::network::f5::bigip::snmp::mode::member;

use base qw(centreon::plugins::mode);
use IO::Socket;

use strict;
use warnings;
use feature 'switch';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';

    $options{options}->add_options(arguments =>
                                {
                                  "pool:s" => { name => 'pool' },
				                  "node:s" => { name => 'node' },
				                  "port:s" => { name => 'port' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub to_oid {
        my $string = shift;

        my @chars = split("", $string);
        my @oid_chars;

        foreach my $char (@chars) {
                push @oid_chars, ord($char);
        }

        return join(".", @oid_chars);
}

sub run {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    my $length_pool = length($self->{option_results}->{pool});
    my $length_node = length($self->{option_results}->{node});

    # OIDs
    my $oid_base = '.1.3.6.1.4.1.3375.2.2.5';
    my $oid_pool = to_oid($self->{option_results}->{pool});
    my $oid_node = to_oid($self->{option_results}->{node});

    my $oid_port = $oid_base.".6.2.1.8.".$length_pool.".".$oid_pool.".".$length_node.".".$oid_node;
    my $oid_status = $oid_base.".6.2.1.5.".$length_pool.".".$oid_pool.".".$length_node.".".$oid_node;
    my $oid_trafficin = $oid_base.".4.3.1.6.".$length_pool.".".$oid_pool.".".$length_node.".".$oid_node;
    my $oid_trafficout = $oid_base.".4.3.1.8.".$length_pool.".".$oid_pool.".".$length_node.".".$oid_node;

    # Get requests
    my $result = $self->{snmp}->get_table(oid => $oid_base);

    my $severity = 'OK';
    my $output = $result->{$oid_port.".".$self->{option_results}->{port}};
    my $trafficin = $result->{$oid_trafficin.".".$self->{option_results}->{port}};
    my $trafficout = $result->{$oid_trafficout.".".$self->{option_results}->{port}};

    my $status = $result->{$oid_status.".".$self->{option_results}->{port}};

    if ($status eq '1' || $status eq '4') {
        $severity = "OK";
    } else {
        $severity = "CRITICAL";
    }

    # Print output
    $self->{output}->output_add(severity => $severity, 
				short_msg => sprintf ($output));
    $self->{output}->perfdata_add(label    => 'traffic_in',
                              value    => $trafficin,
                              unit     => 'B');
    $self->{output}->perfdata_add(label    => 'traffic_out',
                              value    => $trafficout,
                              unit     => 'B');

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Member

=over 8

=item B<--pool>

Pool name.

=item B<--node>

Node name.

=item B<--port>

Port number.

=back

=cut


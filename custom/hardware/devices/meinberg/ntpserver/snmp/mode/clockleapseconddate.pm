package custom::hardware::devices::meinberg::ntpserver::snmp::mode::clockleapseconddate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_clockleapseconddate  = '.1.3.6.1.4.1.5597.30.0.1.2.1.11';

    my $result = $self->{snmp}->get_table(oid => $oid_clockleapseconddate, nothing_quit => 1);

    foreach my $oid (keys %$result) {
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $date = $result->{$oid};
        #my $descr = $result->{$oid_clockleapseconddate};

        $self->{output}->output_add(short_msg => sprintf("ClockLeapSecondDate '%s': '%s'", $instance,
                                                        $date));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Display the Clock Leap Second Date.

=over 8

=back

=cut

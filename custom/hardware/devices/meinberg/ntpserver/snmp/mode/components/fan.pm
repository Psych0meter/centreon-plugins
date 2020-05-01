package custom::hardware::devices::meinberg::ntpserver::snmp::mode::components::fan;

use strict;
use warnings;

my %map_states_fan = (
    0 => 'notAvailable',
    1 => 'no',
    2 => 'yes',
);

my $mapping = {
    fanSpeedSensorName => { oid => '.1.3.6.1.4.1.5597.30.0.5.1.2.1.1' },
    fanSpeedSensorStatus => { oid => '.1.3.6.1.4.1.5597.30.0.5.1.2.1.3', map => \%map_states_fan },
};
my $oid_fanSpeedSensorEntry = '.1.3.6.1.4.1.5597.30.0.5.1.2.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_fanSpeedSensorEntry, start => $mapping->{fanSpeedSensorName}->{oid}, end => $mapping->{fanSpeedSensorStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fanSpeedSensorEntry}})) {
        next if ($oid !~ /^$mapping->{fanSpeedSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fanSpeedSensorEntry}, instance => $instance);

        next if ($self->check_filter(section => 'fan', instance => $instance));
        # can be SysFAN(J4)
        next if ($result->{fanSpeedSensorName} !~ /^[\(\)0-9a-zA-Z ]+$/); # sometimes there is some wrong values in hex

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' sensor out of range status is '%s'",
                                    $result->{fanSpeedSensorName}, $result->{fanSpeedSensorStatus}));
        my $exit = $self->get_severity(section => 'fan', value => $result->{fanSpeedSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Fan '%s' sensor out of range status is '%s'", $result->{fanSpeedSensorName}, $result->{fanSpeedSensorStatus}));
        }

    }
}

1;

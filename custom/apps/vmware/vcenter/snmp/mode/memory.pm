package custom::apps::vmware::vcenter::snmp::mode::memory;

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
									"warning:s"		=> { name => 'warning' },
									"critical:s"	=> { name => 'critical' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
		$self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
		$self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
		$self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
		$self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    #HOST-RESOURCES-MIB::hrStorageType.19 = OID: HOST-RESOURCES-TYPES::hrStorageRam
    my $oid_getmemory = '.1.3.6.1.2.1.25.2.3.1.3';
    my $realmemoryid;

    my $result = $self->{snmp}->get_table(oid => $oid_getmemory);
    foreach my $key (keys %$result) {
        #print $key." --> ".$result->{$key}."\n";
        if ($result->{$key} eq "Real Memory") {
                my $id = $key;
                $id =~ s/$oid_getmemory\.(.*)/$1/;
                $realmemoryid = $id;
        }
    }

    my $oid_memTotalReal ='.1.3.6.1.2.1.25.2.3.1.5.'.$realmemoryid;
    #my $oid_memUsedReal = '.1.3.6.1.2.1.25.2.3.1.6.18';
    my $oid_processmemory = '.1.3.6.1.2.1.25.5.1.1.2';

    $result = $self->{snmp}->get_table(oid => $oid_processmemory);

    #use Data::Dumper;
    #print Dumper \$result;

    my $physical_used = 0;
    foreach my $key (keys %$result) {
        $physical_used += $result->{$key};
        #print "[$key] --> ".$result->{$key}."\n";
    }

    $result = $self->{snmp}->get_leef(oids => [$oid_memTotalReal],
                                         nothing_quit => 1);

    #my $physical_used = $used_value;

    my $total_size = $result->{$oid_memTotalReal} * 1024;

    my $prct_used = $physical_used * 100 / $total_size;

    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $physical_used);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Ram Total: %s, Used: %s (%.2f%%)",
                                            $total_value . " " . $total_unit,
                                            $used_value . " " . $used_unit, $prct_used,));

    $self->{output}->perfdata_add(label => "physical_memory", unit => 'B',
                                  value => $total_size,
                                  min => 0);
    $self->{output}->perfdata_add(label => "used_memory", unit => 'B',
                                  value => $physical_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
                                  min => 0, max => $total_size);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check VMWare vCenter physical memory (UCD-SNMP-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut

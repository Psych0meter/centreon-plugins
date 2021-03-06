package custom::os::linux::snmp::mode::memory;

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
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
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

    # New OIDs
    my $oid_memTotalSwap = '.1.3.6.1.4.1.2021.4.3.0';
    my $oid_memTotalReal = '.1.3.6.1.4.1.2021.4.5.0';
    my $oid_memTotalFree = '.1.3.6.1.4.1.2021.4.11.0';

    # Old OIDs
    my $oid_memUsedReal = '.1.3.6.1.2.1.25.2.3.1.6.1';
    my $oid_memBuffer    = '.1.3.6.1.2.1.25.2.3.1.6.6';
    my $oid_memCached    = '.1.3.6.1.2.1.25.2.3.1.6.7';
    my $oid_slab_extend = '.1.3.6.1.4.1.8072.1.3.2.4.1.2.4.115.108.97.98.1'; # .4 : length of command / .115.108.97.98 : slab converted to ascii


    my $oid_kernel = '.1.3.6.1.2.1.1.1.0';
#    my $oid_versionTag = '.1.3.6.1.4.1.2021.100.2.0';

    my $oids = [$oid_memTotalReal, $oid_memTotalFree, $oid_memTotalSwap, $oid_kernel, $oid_memUsedReal, $oid_memBuffer, $oid_memCached, $oid_slab_extend];
    my $result = $self->{snmp}->get_leef(oids => $oids,
                                         nothing_quit => 1);


    # New values
    my $total_real = $result->{$oid_memTotalReal} * 1024;
    my $total_free = $result->{$oid_memTotalFree} * 1024;
    my $total_swap = $result->{$oid_memTotalSwap} * 1024;

    # Old values
    my $cached_used = $result->{$oid_memCached} * 1024;
    my $buffer_used = $result->{$oid_memBuffer} * 1024;
    my $physical_used = $result->{$oid_memUsedReal} * 1024;
    my $slab = 0;
    $slab = $result->{$oid_slab_extend} * 1024 if ($result->{$oid_slab_extend});
 
    my $nobuf_used = $physical_used - $buffer_used - $cached_used - $slab;


    # Check kernel version for RAM calculation, change in RHEL 7 - 3.10.0-1062
    my $kernel = $result->{$oid_kernel};
    my $rhel_version;
    my $kernel_version;
    my $major_revision;
    my $minor_revision;
    my $patch_number;

    my $old_version = 1;

    if ($kernel =~ m/.* (\d+)\.(\d+)\.(\d+)\-(\d+)\S+el(\d+)\S+ .*/gi) {
	$kernel_version = $1;
	$major_revision = $2;
	$minor_revision = $3;
	$patch_number = $4;
	$rhel_version = $5;
    }

    if ($rhel_version > 7) {
	$old_version = 0;
    } elsif ($rhel_version == 7) {
	if ($kernel_version > 3) {
		$old_version = 0;
	} elsif ($kernel_version == 3) {
		if ($major_revision > 10) {
			$old_version = 0;
		} elsif ($major_revision == 10 ) {
		    $old_version = 0;
			if ($minor_revision > 0) {
				$old_version = 0;
			} else {
				if ($patch_number >= 1062) {
					$old_version = 1;
				}
			}
		}
	}
    }
    

    # If OLD version
    if ($old_version == 1) {
	my $total_size = $result->{$oid_memTotalReal} * 1024;
	    
	my $prct_used = $nobuf_used * 100 / $total_size;
	my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

	my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
	my ($nobuf_value, $nobuf_unit) = $self->{perfdata}->change_bytes(value => $nobuf_used);
	my ($buffer_value, $buffer_unit) = $self->{perfdata}->change_bytes(value => $buffer_used);
	my ($cached_value, $cached_unit) = $self->{perfdata}->change_bytes(value => $cached_used);
	    
	$self->{output}->output_add(	severity => $exit,
					short_msg => sprintf("Ram Total: %s, Used: %s (%.2f%%), Buffer: %s, Cached: %s",
						    $total_value . " " . $total_unit,
						    $nobuf_value . " " . $nobuf_unit, $prct_used,
						    $buffer_value . " " . $buffer_unit,
						    $cached_value . " " . $cached_unit,));
	   
	$self->{output}->perfdata_add(	label => "physical_memory", unit => 'B',
					value => $total_size,
					min => 0); 
	$self->{output}->perfdata_add(	label => "cached_memory", unit => 'B',
					value => $cached_used,
					min => 0);
	$self->{output}->perfdata_add(	label => "buffer_memory", unit => 'B',
					value => $buffer_used,
					min => 0);
	$self->{output}->perfdata_add(	label => "used_memory", unit => 'B',
					value => $nobuf_used,
					warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
					critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
					min => 0, max => $total_size);

    } else {
    	# If NEW version
	my $total_size = $total_real + $total_swap;

	my $used = $total_size - $total_free;

	my $prct_used = $used * 100 / $total_size;
	my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

	my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
	my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $used);


	$self->{output}->output_add(	severity => $exit,
					short_msg => sprintf("Ram Total: %s, Used: %s (%.2f%%)",
						$total_value . " " . $total_unit,
						$used_value . " " . $used_unit, $prct_used,));

	$self->{output}->perfdata_add(	label => "physical_memory", unit => 'B',
					value => $total_real,
					min => 0);
	$self->{output}->perfdata_add(	label => "swap_memory", unit => 'B',
					value => $total_swap,
					min => 0);
	$self->{output}->perfdata_add(	label => "used_memory", unit => 'B',
					value => $used,
					warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
					critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
					min => 0, max => $total_size);

    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check memory.

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut

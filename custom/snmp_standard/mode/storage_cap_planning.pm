
package custom::snmp_standard::mode::storage_cap_planning;

use base qw(centreon::plugins::mode);
use Switch;
use centreon::plugins::statefile;

use strict;
use warnings;

my %oids_hrStorageTable = (
    'hrstoragedescr'    => '.1.3.6.1.2.1.25.2.3.1.3',
    'hrfsmountpoint'    => '.1.3.6.1.2.1.25.3.8.1.2',
    'hrfsstorageindex'  => '.1.3.6.1.2.1.25.3.8.1.7',
    'hrstoragetype'     => '.1.3.6.1.2.1.25.2.3.1.2',
);

my $oid_hrStorageAllocationUnits = '.1.3.6.1.2.1.25.2.3.1.4';
my $oid_hrStorageSize = '.1.3.6.1.2.1.25.2.3.1.5';
my $oid_hrStorageUsed = '.1.3.6.1.2.1.25.2.3.1.6';
my $oid_hrStorageType = '.1.3.6.1.2.1.25.2.3.1.2';

my $tmp_dir = '/var/lib/centreon/centplugins/';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "days:i"                  => { name => 'days', default => 30},
                                  "warning:i"               => { name => 'warning'},
                                  "critical:i"              => { name => 'critical'},
                                  "storage:s"               => { name => 'storage' },
                                  "retention-time:i"       => { name => 'retention_time', default => (86400*90) }, #### 3Months
                                });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (!defined($self->{option_results}->{storage})) {
       $self->{output}->add_option_msg(short_msg => "Need to specify a storage device");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
    $self->{statefile_cache}->check_options(%options);
}

sub run {
        my ($self, %options) = @_;
    my $time = time();
        $self->{snmp} = $options{snmp};
        my $storage_id = get_index($self,$self->{option_results}->{storage});
    if ( !defined($storage_id)){
        $self->{output}->output_add(severity => 'UNKNOWN', short_msg => "The storage ".$self->{option_results}->{storage}." could not be found\n");
        $self->{output}->display();
        $self->{output}->exit();
    }
        $self->{snmp}->load(oids => [$oid_hrStorageAllocationUnits.'.'.$storage_id, $oid_hrStorageSize.'.'.$storage_id, $oid_hrStorageUsed.'.'.$storage_id], nothing_quit => 1);
    my $result = $self->{snmp}->get_leef();
    if (!defined($result->{$oid_hrStorageAllocationUnits . "." . $storage_id})) {
        $self->{output}->add_option_msg(long_msg => sprintf("skipping storage '%s': not found (need to reload the cache)", $self->{option_results}->{storage}));
    }
    my $total_size = $result->{$oid_hrStorageSize . "." . $storage_id} * $result->{$oid_hrStorageAllocationUnits . "." . $storage_id};
    if ($total_size <= 0) {
        $self->{output}->add_option_msg(long_msg => sprintf("skipping storage '%s': total size is <= 0 (%s)", $self->{option_results}->{storage}, int($total_size)));
    }

    ### Disk Values Calculation
    my $allocation_units = $result->{$oid_hrStorageAllocationUnits . "." . $storage_id};
    my $size = $result->{$oid_hrStorageSize . "." . $storage_id};
    my $used = $result->{$oid_hrStorageUsed . "." . $storage_id} * $allocation_units;
    my $total = $size * $allocation_units;
    my $prct_used = $used * 100 / $total;

    ### Adding current values and retrieving old ones from cache file
    my $values = data_cache($self,$used,$total,$prct_used,$storage_id);

    ### Only use values between now and number of days specified from cache
    my $last_timestamp = $$values{time}[$#{$$values{time}}];
    my $days_of_data = sprintf("%d",($time - $last_timestamp)/86400);
    my (@prct_values,@timestamp_values, @prct_evol,@time_int) = ();
    for (my $index = 0; $index <= $#{$$values{time}}; $index++) {
        if ( ($time-(86400*$self->{option_results}->{days})) < $$values{time}[$index] ){
            push @prct_values , $$values{prct_used}[$index];
            push @timestamp_values , $$values{time}[$index];
        }
    }

    ### If not enough days of data in cache modify output
    my $not_enough_days = "";
    if ( $days_of_data < $self->{option_results}->{days} ){
        $not_enough_days = 'ONLY '.$days_of_data.' DAYS OF DATA - ';
    }

    ### Get Disk Usage Percentage evolution and seconds passed between each points
    for (my $index = 0; $index < $#prct_values; $index++) {
        my $pct_t0 = $prct_values[$index];
        my $pct_t1 = $prct_values[$index+1];
        push @prct_evol, ($pct_t0-$pct_t1);
        my $t0 = $timestamp_values[$index];
        my $t1 = $timestamp_values[$index+1];
        push @time_int,($t0-$t1);
    }

    ### Number of points used
    my $nb_of_points = $#prct_values;

    #### Average Percentage for number available points
    my $pct_sum = 0;
    foreach (@prct_evol){
        $pct_sum = $pct_sum+$_;
    }
    my $daily_avg_pct = $pct_sum/$nb_of_points;

    ### Standard Deviation of Time Intervals
    my $it_sum = 0;
    foreach (@time_int){
        $it_sum = $it_sum+$_;
    }
    my $it_avg = $it_sum / $nb_of_points;
    my $it_dev_sum = 0;
    foreach (@time_int){
        $it_dev_sum = $it_dev_sum + (($_ - $it_avg)**2);
    }
    my $it_std_dev = sqrt($it_dev_sum / $nb_of_points);
    my $output_time_dev = sprintf(" - Standard Time Interval Deviation %ds",$it_std_dev);

    my $pct_used_now = $prct_values[0];

    ### If Daily evolution rate of disk is 0 or below then it is fine
    if ( $daily_avg_pct <= 0 ){
        $self->{output}->output_add(severity => 'OK',
        short_msg => $not_enough_days.'Daily Average Rate Growth for '.$self->{option_results}->{storage}.' is 0% or below'.$output_time_dev."\n");
        perf_data_exit($self,0,$daily_avg_pct,$it_std_dev);
    }

    ### Check Thresholds compared to the number of days until disk is full then exit
    my $days_b4_full = (100-$pct_used_now)/$daily_avg_pct;
    $self->{output}->output_add(severity => 'OK',
    short_msg => $not_enough_days.sprintf($self->{option_results}->{storage}.' full in '."%.0f days",$days_b4_full)."\n");
    if ( defined($self->{option_results}->{warning}) ){
        if ( $days_b4_full <= $self->{option_results}->{warning} ){
            $self->{output}->output_add(severity => 'WARNING')        }
    }
    if ( defined($self->{option_results}->{critical}) ){
        if ( $days_b4_full <= $self->{option_results}->{critical} ){
            $self->{output}->output_add(severity => 'CRITICAL')        }
    }
    perf_data_exit($self,$days_b4_full,$daily_avg_pct,$it_std_dev);
}

sub perf_data_exit {
    my ($self,$days_b4_full,$daily_avg_pct,$it_std_dev) = @_;
    $self->{output}->perfdata_add(label => 'nb_days',
        value => sprintf("%.0f",$days_b4_full),
        warning => $self->{option_results}->{warning},
        critical => $self->{option_results}->{critical},
        min => 0
    );
    $self->{output}->perfdata_add(label => 'avg_growth_last'.$self->{option_results}->{days}.'days',
        unit => '%',
        value => sprintf("%.4f",$daily_avg_pct),
        min => 0
    );
    $self->{output}->perfdata_add(label => 'it_std_dev',
        unit => 's',
        value => sprintf("%d",$it_std_dev),
        min => 0
    );
    $self->{output}->display();
    $self->{output}->exit();
}

sub get_index{
    my ($self,$disk_name) = @_;
    my $disk_id = undef;
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_snmpstandard_' . $self->{snmp}->get_hostname()  . '_' . $self->{snmp}->get_port() . '_storage');
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $all_ids = $self->{statefile_cache}->get(name => 'all_ids');
    foreach my $i (@{$all_ids}) {
        if ( $self->{statefile_cache}->get(name => "hrstoragedescr_" . $i) =~ /^($disk_name)$/i ) {
            $disk_id = $i;
        };
    }
    my $result;

    ### If disk_id not found in standard cache try to get it using SNMP
    if (!defined($disk_id)){
        $result = $self->{snmp}->get_table(oid => $oids_hrStorageTable{'hrstoragedescr'} , nothing_quit => 1);
        foreach (keys %$result){
            if ($$result{$_} =~ /^($disk_name)$/i ){
                my @tmp_oid = split (/\./,$_);
                $disk_id = pop (@tmp_oid);
            }
        }
    }
    return $disk_id;
}

sub data_cache{
    my ($self,$used,$total,$prct_used,$storage_id) = @_;
    my $time = time();
    my (@time,@used,@total,@prct_used) = ();
    my $cache_file = '/var/lib/centreon/centplugins/disk_cap_planning_' . $self->{snmp}->get_hostname()  . '_' . $self->{snmp}->get_port() . '_' . $storage_id;
    push @time,$time;
    push @used,$used;
    push @total,$total;
    push @prct_used,$prct_used;

    ### If Cache file does not exist then create it
    if (! -e ($cache_file)) {
        open (FILE,'>',$cache_file) or die "Couldn't open: $!";
        print FILE "$time,$used,$total,$prct_used\n";
        close FILE;
        print "Buffer in Creation ...\n";
        exit 3;
    }
    ### Read Cache into 4 arrays
    open (FILE,'<',$cache_file);
    while (my $line = <FILE>){
        chomp ($line);
        my ($t_time,$t_used,$t_total,$t_prct_used) = split /,/, $line;
        push @time,$t_time;
        push @used,$t_used;
        push @total,$t_total;
        push @prct_used,$t_prct_used;
    }
    close FILE;

    open (FILE,'>',$cache_file);
    ### If last timestamp longer than retention delete last value
    if ( ($time-($self->{option_results}->{retention_time})) > $time[$#time] ){
        pop @time;
        pop @used;
        pop @total;
        pop @prct_used;
    }
    ### If Size of disk changed reload cache
    if ( $total != $total[0] ){
        print FILE "$time,$used,$total,$prct_used\n";
        close FILE;
        print "The size of the disk has changed - Cache has been reloaded\n";
        exit 3;
    }

    ### Print updated values in cache
    for (my $index = 0; $index < scalar(@time); $index++){
        print FILE "$time[$index],$used[$index],$total[$index],$prct_used[$index]\n";
    }
    close FILE;

    ### Return hash ref
    my %values = (
        'time' => \@time,
        'used' => \@used,
        'total' => \@total,
        'prct_used' => \@prct_used,
    );
    return \%values;
}


1;

__END__

=head1 MODE

=item Description

Check Number of days until disk specified with '--storage' is full.

Uses SNMP to retrieve values and stores them in cache file named 'disk_cap_planning_...'.

The plugin will output a message if there aren't enough values in the cache for the number of days specified with '--days'.

If the size of the specified storage changed the cache file will be reloaded.

You can find the Standard Deviation of time intervals between points as perfdata.To have meaningful results this plugin should be used at consistent time intervals and this value should therefore be low.

=over 8

=item B<--storage>

REQUIRED
Name of the storage device to use.

=item B<--days>

Days of data to use for the calcul.
Default 30

=item B<--warning>

Threshold remaining days warning.

=item B<--critical>

Threshold remaining days critical.

=item B<--retention-time>

Retention time for values in cache file in seconds.
Default 3 months

=back

=cut

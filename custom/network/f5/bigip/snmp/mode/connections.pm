package custom::network::f5::bigip::snmp::mode::connections;

use base qw(centreon::plugins::mode);
use IO::Socket;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';

    $options{options}->add_options(arguments =>
                                {
									"filter:s"              => { name => 'filter', default => '' },
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

    # OIDs
    my $oid_vs          = '.1.3.6.1.4.1.3375.2.2.10.13.2.1';
    my $oid_connections = '.1.3.6.1.4.1.3375.2.2.10.2.3.1.12';
    my $oid_requests    = '.1.3.6.1.4.1.3375.2.2.10.2.3.1.27';

    # Get requests
    $self->{results} = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vs },
                                                            { oid => $oid_connections },
                                                            { oid => $oid_requests },
                                                         ],
                                                         , nothing_quit => 1);
    use Data::Dumper;

    my $nb_connections = 0;
    my $nb_requests = 0;

    # If no filter specified
    if (($self->{option_results}->{filter}) eq '') {
	foreach my $array ($self->{results}->{$oid_connections}) {
	    foreach (keys %{$array}) {
	        $nb_connections += ${$array}{$_};
    	    }
	}

        foreach my $array ($self->{results}->{$oid_requests}) {
            foreach (keys %{$array}) {
                $nb_requests += ${$array}{$_};
            }
        }
    } else {
	my @vs_oid_list;
	foreach my $array ($self->{results}->{$oid_vs}) {
	    foreach (keys %{$array}) {
                my $oid = $_;
		my $filter = $self->{option_results}->{filter};
		$oid =~ s/$oid_vs\.1//gi;
		#print "OID : ".$oid." --> ".${$array}{$_}."\n" if ${$array}{$_} =~ m/$filter/gi;
		push @vs_oid_list, $oid if ${$array}{$_} =~ m/$filter/gi;
            }

	}


	foreach my $oid (@vs_oid_list) {
            foreach my $array ($self->{results}->{$oid_connections}) {
                foreach (keys %{$array}) {
                    $nb_connections += ${$array}{$_} if ($_ eq $oid_connections.$oid);
                }
            }

            foreach my $array ($self->{results}->{$oid_requests}) {
                foreach (keys %{$array}) {
                    $nb_requests += ${$array}{$_} if ($_ eq $oid_requests.$oid);;
                }
            }
	}
    }


    # Cache
    my $last_requests = 0;
    my $last_check_time = 0;
    my $flg_created = 0;

    my $file_path = "/var/lib/centreon/centplugins/custom_cache_f5_connections-requests_".$self->{option_results}->{filter}."_".$self->{option_results}->{host};

    if (-e $file_path) {
        open(FILE,"<".$file_path);
        while(my $row = <FILE>){
                my @last_values = split(":",$row);
                $last_check_time = $last_values[0];
                $last_requests   = $last_values[1];
                $flg_created = 1;
        }
        close(FILE);
    } else {
        $flg_created = 0;
    }

    my $update_time = time();

    unless (open(FILE,">".$file_path)){
        $self->{output}->add_option_msg(short_msg => "Check mod for temporary file : ".$file_path." !");
        $self->{output}->option_exit();
    } 

    print FILE "$update_time:$nb_requests";

    close(FILE);

    if ($flg_created == 0){
        $self->{output}->output_add(        severity => 'OK',
                                            short_msg => "First execution : Buffer in creation.... ");
        $self->{output}->display();
        $self->{output}->option_exit();
    }

    my $display_requests = $nb_requests - $last_requests;

    # Print output
    $self->{output}->output_add(severity => 'OK', 
				short_msg => sprintf ("Total connections: %s, Total requests: %s", $nb_connections, $display_requests));

    $self->{output}->perfdata_add(label => 'connections',
                                  value => $nb_connections);

    $self->{output}->perfdata_add(label => 'requests',
                                  value => $display_requests);


    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__


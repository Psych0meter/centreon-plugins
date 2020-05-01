package custom::network::f5::bigip::snmp::mode::response;

use base qw(centreon::plugins::mode);
use IO::Socket;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';

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
    my $oid_200 = '.1.3.6.1.4.1.3375.2.1.1.2.4.3.0';
    my $oid_300 = '.1.3.6.1.4.1.3375.2.1.1.2.4.4.0';
    my $oid_400 = '.1.3.6.1.4.1.3375.2.1.1.2.4.5.0';
    my $oid_500 = '.1.3.6.1.4.1.3375.2.1.1.2.4.6.0';

    # Get response codes
    my $result = $self->{snmp}->get_table(oid => '.1.3.6.1.4.1.3375.2.1.1.2.4');

    my $value_200 = $result->{$oid_200};
    my $value_300 = $result->{$oid_300};
    my $value_400 = $result->{$oid_400};
    my $value_500 = $result->{$oid_500};

    # Cache
    my $last_200 = 0;
    my $last_300 = 0;
    my $last_400 = 0;
    my $last_500 = 0;
    my $last_check_time = 0;
    my $flg_created = 0;

    my $file_path = "/var/lib/centreon/centplugins/custom_cache_f5_response_".$self->{option_results}->{host};

    if (-e $file_path) {
        open(FILE,"<".$file_path);
        while(my $row = <FILE>){
                my @last_values = split(":",$row);
                $last_check_time = $last_values[0];
                $last_200 = $last_values[1];
                $last_300 = $last_values[2];
                $last_400 = $last_values[3];
                $last_500 = $last_values[4];
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

    print FILE "$update_time:$value_200:$value_300:$value_400:$value_500";

    close(FILE);

    if ($flg_created == 0){
        $self->{output}->output_add(        severity => 'OK',
                                            short_msg => "First execution : Buffer in creation.... ");
        $self->{output}->display();
        $self->{output}->option_exit();
    }

    my $display_200 = $value_200 - $last_200;
    my $display_300 = $value_300 - $last_300;
    my $display_400 = $value_400 - $last_400;
    my $display_500 = $value_500 - $last_500;

    # Print output
    $self->{output}->output_add(severity => 'OK', 
				short_msg => sprintf ("200s: %s, 300s: %s, 400s: %s, 500s: %s", $display_200, $display_300, $display_400, $display_500));

    $self->{output}->perfdata_add(label => '200s',
                                  value => $display_200);

    $self->{output}->perfdata_add(label => '300s',
                                  value => $display_300);

    $self->{output}->perfdata_add(label => '400s',
                                  value => $display_400);

    $self->{output}->perfdata_add(label => '500s',
                                  value => $display_500);



    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__


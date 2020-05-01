package custom::database::mssql::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_sql);

sub new {
    my ($class, %options) = @_;
    
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'alwayson'       => 'custom::database::mssql::mode::alwayson',
                         'countincident'  => 'custom::database::mssql::mode::countincident', # Specific for Axios Assyst software
                         'dbmirroring'    => 'custom::database::mssql::mode::dbmirroring',
                         'running'        => 'custom::database::mssql::mode::running',
                         'sql'            => 'custom::centreon::common::protocols::sql::mode::sql',
                         'sqldate'        => 'custom::database::mssql::mode::sqldate',
                         );

    return $self;
}

sub init {
    my ($self, %options) = @_;

    $self->{options}->add_options(
                                   arguments => {
                                                'hostname:s@'       => { name => 'hostname' },
                                                'port:s@'           => { name => 'port' },
                                                'database:s'        => { name => 'database' },
                                                }
                                  );
    $self->{options}->parse_options();
    my $options_result = $self->{options}->get_options();
    $self->{options}->clean();

    if (defined($options_result->{hostname})) {
        @{$self->{sqldefault}->{dbi}} = ();
        for (my $i = 0; $i < scalar(@{$options_result->{hostname}}); $i++) {
            $self->{sqldefault}->{dbi}[$i] = { data_source => 'Sybase:host=' . $options_result->{hostname}[$i] };
            if (defined($options_result->{port}[$i])) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';port=' . $options_result->{port}[$i];
            }
            if ((defined($options_result->{database})) && ($options_result->{database} ne '')) {
                $self->{sqldefault}->{dbi}[$i]->{data_source} .= ';database=' . $options_result->{database};
            }
        }
    }
    $self->SUPER::init(%options);    
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check MSSQL Server.
Requires : custom::centreon::common::protocols::sql::mode::sql

=over 8

=item B<--hostname>

Hostname to query.

=item B<--port>

Database Server Port.

=back

=cut

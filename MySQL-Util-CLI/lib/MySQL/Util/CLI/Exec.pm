package MySQL::Util::CLI::Exec;

use Modern::Perl;
use Moose;
use Kavorka '-all';
use namespace::autoclean;
use Data::Printer alias => 'pdump';
use MySQL::Util::CLI;
use Text::ASCIITable;
use Carp;

with 'Util::Medley::Roles::Attributes::List';

##############################################################################
# PUBLIC ATTRIBUTES
##############################################################################

has user => (
	is      => 'rw',
	isa     => 'Str',
);

has pass => (
	is      => 'rw',
	isa     => 'Str',
);

has host => (
	is      => 'rw',
	isa     => 'Str',
);

has port => (
	is      => 'rw',
	isa     => 'Str',
);

has dbName => (
	is      => 'rw',
	isa     => 'Str',
);

has dryRun => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

##############################################################################
# PRIVATE_ATTRIBUTES
##############################################################################

##############################################################################
# PUBLIC METHODS
##############################################################################

method showGrants (Str :$forUser,
				   Str :$forHost) {

	my $cli = $self->_getMysqlUtilCli;
	my @grants = $cli->getGrants(@_);

	my $t = Text::ASCIITable->new;
	$t->setCols('GRANTS');		
		
	foreach my $grant (@grants) {
		$t->addRow($grant->[0]);
	}
	
	print $t;
}

method showUsers {
	
	my $cli = $self->_getMysqlUtilCli;
	
	my $sql = "select * from user";
	my $sth = $cli->getDbh->prepare($sql);
	$sth->execute;

	my %users;	
	while(my $href = $sth->fetchrow_hashref) {
		$users{$href->{user}} = { %$href };			
	}		

	my $t = Text::ASCIITable->new;
	$t->setCols('USER', 'HOST');
		
	foreach my $key ($self->List->nsort(keys %users)) {
		my $href = $users{$key};
		$t->addRow($href->{user}, $href->{host});	
	}
	
	print $t;
}

method createUser(Str :$createUser!,
			      Str :$createPass!,
			      Str :$createHosts) {

	my $cli = $self->_getMysqlUtilCli;
	
	my %p;
	$p{userName} = $createUser;
	$p{userPass} = $createPass;
	$p{hosts} = [ split(/,/, $createHosts) ] if $createHosts;

	$cli->createUser(%p);			
}

method grantPrivileges (Str :$grantUser!,
						Str :$privileges!,
						Str :$grantDbName,
						Str :$grantTables,
						Str :$grantHosts ) {
	
	my $cli = $self->_getMysqlUtilCli;
	
	my %p;
	$p{userName} = $grantUser;
	$p{privileges} = [ split(/,/, $privileges) ];
	$p{hosts} = [ split(/,/, $grantHosts) ] if $grantHosts;
	$p{dbName} = $grantDbName if $grantDbName;
	$p{tables} = [ split(/,/, $grantTables) ] if $grantTables;
pdump %p;	
	$cli->grantPrivileges(%p);	
}
					   				       	
method dropUser (Str :$dropUser!,
				 Str :$dropHost,
				 Str :$keepHosts) {

	my $cli = $self->_getMysqlUtilCli;
	
	my %p;
	$p{userName} = $dropUser;
	$p{host} = $dropHost if $dropHost;
	$p{keepHosts} = [ split(/,/, $keepHosts) ] if $keepHosts;

	$cli->dropUser(%p);	
}

##############################################################################
# PRIVATE METHODS
##############################################################################

method _getMysqlUtilCli {

	return 	MySQL::Util::CLI->new($self->_getAttributeHash);
}

method _getAttributeHash {

	my %a;
	$a{user} = $self->user if $self->user;
	$a{pass} = $self->pass if $self->pass;
	$a{host} = $self->host if $self->host;
	$a{port} = $self->port if $self->port;
	$a{dbName} = $self->dbName if $self->dbName;

	return %a;		
}

1;

package FreeBSD::Pkgs::FindUpdates;

use warnings;
use strict;
use FreeBSD::Pkgs;
use FreeBSD::Ports::INDEXhash qw/INDEXhash/;
use Sort::Versions;

=head1 NAME

FreeBSD::Pkgs::FindUpdates - Finds updates for FreeBSD pkgs by checking the ports index.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

This does use FreeBSD::Ports::INDEXhash. Thus if you want to specifiy the location of the
index file, you will want to see the supported methodes for it in that module.

    use FreeBSD::Pkgs::FindUpdates;
    #initiates the module
    my $pkgsupdate = FreeBSD::Pkgs::FindUpdates->new();
    #finds changes
    my %changes=$pkgsupdate->find();
    #prints the upgraded stuff
    while(my ($name, $pkg) = each %{$changes{upgrade}}){
        print $name.' updated from "'.
              $pkg->{oldversion}.'" to "'.
              $pkg->{newversion}."\"\n";
    }
    #prints the downgraded stuff
    while(my ($name, $pkg) = each %{$changes{upgrade}}){
        print $name.' updated from "'.
              $pkg->{oldversion}.'" to "'.
              $pkg->{newversion}."\"\n";
    }

=head1 FUNCTIONS

=head2 new

This initiate the module.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	my $self={error=>undef, errorString=>''};
	bless $self;
	return $self;

}

=head2 find

This finds any changes creates a hash.

=cut

sub find {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	};

	#parse the installed packages
	my $pkgdb=FreeBSD::Pkgs->new;
	$pkgdb->parseInstalled;

	my %index=INDEXhash();


	#a hash of stuff that needes changed
	my %change;
	$change{upgrade}={};
	$change{same}={};
	$change{downgrade}={};

	#process it
	while(my ($pkgname, $pkg) = each %{$pkgdb->{packages}}){
		my $src=$pkg->{contents}{origin};

		#versionless packagename
		my $vpkgname=$pkgname;
		my @vpkgnameSplit=split(/-/, $vpkgname);
		my $int=$#vpkgnameSplit - 1;#just called int as I can't think of a better name
		$vpkgname=join('-', @vpkgnameSplit[0..$int]);

		#get the pkg version
		my $pkgversion=$pkgname;
		$pkgversion=~s/.*-//;

		#if this is not defined, we can't upgrade it... so skip it
		#stuff in stalled via cpan will do this
		if (!defined($src)) {
			warn('FreeBSD-Pkgs-FindUpdates find:1: No origin for "'.$pkgname.'"');
		}else{
			#
			my $portSearch=1;
			while((my ($portname, $port) = each %index) && $portSearch){
				my $path=$port->{path};
				#this should never happen...
				if (!defined($path)) {
					warn('FreeBSD-Pkgs-FindUpdates find:2: No path for "'.$portname.'"');
				}else {
					$path=~s/.*\/ports\///g;
					if ($src eq $path) {
						#versionless portname
						my $vportname=$portname;
						my @vportnameSplit=split(/-/, $vportname);
						$int=$#vportnameSplit - 1;#just called int as I can't think of a better name
						$vportname=join('-', @vportnameSplit[0..$int]);

						#get the port version
						my $portversion=$portname;
						$portversion=~s/.*-//;

						#
#						my $pkgv=version->new($pkgversion);
#						my $portv=version->new($portversion);

						#if the pkg versionis less than the port version, it needs to be upgraded
						if (versioncmp($pkgversion, $portversion) == -1) {
							$change{upgrade}{$pkgname}={old=>$pkgname, new=>$portname,
												oldversion=>$pkgversion,
												newversion=>$portversion,
												port=>$path};
						}

						#if the pkg version and the port version are the same it is the same
						if (versioncmp($pkgversion, $portversion) == 0) {
							$change{same}{$pkgname}={old=>$pkgname, new=>$portname,
												oldversion=>$pkgversion,
												newversion=>$portversion,
												port=>$path};
						}

						#if the pkg version is greater than the port version, it needs to be downgraded
						if (versioncmp($pkgversion, $portversion) == 1) {
							$change{downgrade}{$pkgname}={old=>$pkgname, new=>$portname,
												oldversion=>$pkgversion,
												newversion=>$portversion,
												port=>$path};
						}

					}
				}
			}
		}
		
	}

	return %change;
}

=head1 Changes Hash

This hash contains several keys that are listed below. Each is a hash
that contain several keys of their own. Please see the sub hash section
for information on that.

The name of the installed package is used as the primary key in each.

=head2 downgrade

This is a hash that contains a list of packages to be down graded.

=head2 upgrade

This is a hash that contains a list of packages to be up graded.

=head2 same

This means there is no change.

=head2 sub hash

All three keys contain hashes that then contian these values.

=head3 old

This is the name of the currently installed package.

=head3 new

This is the name of what it will be changed to if upgraded/downgraded.

=head3 oldversion

This is the old version.

=head3 newversion

This is the version ofwhat it will be changed toif upgraded/downgraded.

=head3 port

This is the port that provides it.

=head1 ERROR

=head2 1

No origin for a specified package. This is not a fatal error.

=head2 2

A line in the INDEX file is missing the path to the ports directory for that port.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freebsd-pkgs-findupdates at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FreeBSD-Pkgs-FindUpdates>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FreeBSD::Pkgs::FindUpdates


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FreeBSD-Pkgs-FindUpdates>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FreeBSD-Pkgs-FindUpdates>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FreeBSD-Pkgs-FindUpdates>

=item * Search CPAN

L<http://search.cpan.org/dist/FreeBSD-Pkgs-FindUpdates>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FreeBSD::Pkgs::FindUpdates

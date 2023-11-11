#!/usr/bin/perl
#------------------------------------------------------------
# libraryWindow
#------------------------------------------------------------

use lib '/base/apps/artisan';

package libraryWindow;
use strict;
use warnings;
use Wx qw(:everything);	# allclasses needed for MediaPlayer
use Wx::Event qw(EVT_BUTTON);
use My::Utils;
use Pub::WX::Window;
use Library;
use SSDPSearch;
use base qw(Wx::Window Pub::WX::Window);


my $REMOTE_GENNYMOTION = "192.168.0.115:8008";
	# Uhm, apparently the gmotion vBox has an address 192.168.56.101,
	# and prh_travel router gives the android in it 192.168.0.115, so,
	# ahem, both of those addresses work for the emulator
my $REMOTE_CAR_STEREO = "192.168.0.103:8008";
	# assigned by prh_travel router


my $remote_device = $REMOTE_GENNYMOTION;


my $BUTTON_SCAN_LIBRARY = 67890;
my $BUTTON_LIST_DEVICES = 67891;


#---------------------------
# new
#---------------------------

sub new
{
	my ($class,$frame,$id,$book) = @_;
	display(0,0,"new libraryWindow()");
	my $this = $class->SUPER::new($book,$id);
	$this->MyWindow($frame,$book,$id,"");		# "" is data

    Wx::Button->new($this,$BUTTON_SCAN_LIBRARY,'Scan Library',[10,10],[90,30]);
    Wx::Button->new($this,$BUTTON_LIST_DEVICES,'List Devices',[10,40],[90,30]);

	EVT_BUTTON($this,-1,\&onButton);
	return $this;
}


sub onButton
{
	my ($this,$event) = @_;
	my $id = $event->GetId();
	if ($id == $BUTTON_SCAN_LIBRARY)
	{
		Library::scanner_thread(1);
	}
	elsif ($id == $BUTTON_LIST_DEVICES)
	{
		my @devices = SSDPSearch::getUPNPDeviceList();
	}
}







1;

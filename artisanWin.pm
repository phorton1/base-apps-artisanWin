#!/usr/bin/perl
#-------------------------------------------------------------------------
# the main application object
#-------------------------------------------------------------------------

BEGIN {
	unshift @INC,"/base/apps/artisan"
}

package artisanFrame;
use strict;
use warnings;
use threads;
use threads::shared;
use appFrame;
use Utils;

our $program_name = 'Artisan Server (Win wxWidgets)';

use artisanResources;
use libraryWindow;
use mediaPlayerWindow;
use artisanInit;


use Wx qw(:everything);
use Wx::Event qw(
	EVT_MENU
	EVT_MENU_RANGE );
use base qw(appFrame);


$appConfig::ini_file = "/base/apps/artisanWin/artisanWin.ini";
unlink $appConfig::ini_file;
	# set app specific basic directories


# Starting Artisan here puts it in the main thread
# which seems to work better.  And it doesn't work
# with the multi-threaded HTTP Server!!

$HTTPServer::SINGLE_THREAD=1;
artisan::start_artisan();



sub new
{
	my ($class, $parent) = @_;
	my $this = $class->SUPER::new($parent);
	return $this;
}


sub onInit
{
    my ($this) = @_;
    return if !$this->SUPER::onInit();
    $this->{frames} = {};
	
	EVT_MENU($this, $COMMAND_TEST, \&onTest);
	EVT_MENU($this, $WINDOW_MEDIA_PLAYER, \&appFrame::onOpenPane);
	EVT_MENU_RANGE($this, $BEGIN_PANE_RANGE, $END_PANE_RANGE, \&appFrame::onOpenPane);

	# Starting Artisan here starts it in a child thread
	# as evidenced by the display(), where the first integer
	# is the thread id (0=main), and seems to have problems
	#
	# 		artisan::start_artisan();

	# Create the local renderer
	
	$this->createPane($WINDOW_MEDIA_PLAYER);

    return $this;
}



sub unused_onClose
	# Override gets called by base class by name
{
	my ($this,$event) = @_;
	display(0,0,"start artisanFrame::onClose()");
    $this->SUPER::onClose($event);
    if ($event->GetSkipped())
    {
        display(0,1,"doing artisanFrame::onClose()");
        LOG(0,"shutting down ...");
    	$this->{frames} = {};
        $event->Skip();
		# force the floating player closed
		# mediaPlayerWindow::forceClose();
    }

	display(0,0,"leaving artisanFrame::onClose()");
}




sub onTest
{
	my ($this) = @_;
	display(0,0,"artisanWin::onTest() called");
}



sub createPane
	# factory method must be implemented if derived
    # classes want their windows restored on opening
{
	my ($this,$id,$book,$data,$config_str) = @_;
	display(4,1,"fileManager::createPane($id) book=".($book?$book->{name}:'undef'));
	return error("No id specified in mbeManager::createPane()") if (!$id);
    $book = $this->getOpenDefaultNotebook($id) if (!$book);
	
	if ($id == $WINDOW_MEDIA_PLAYER)
	{
        return mediaPlayerWindow->new($this,$book,$id);
    }
	elsif ($id == $WINDOW_LIBRARY)
	{
        return libraryWindow->new($this,$book,$id);
		
	}
    return $this->SUPER::createPane($id,$book,$data,$config_str);
}



#----------------------------------------------------
# CREATE AND RUN THE APPLICATION
#----------------------------------------------------

package artisanApp;
use strict;
use warnings;
use appUtils;
use appMain;
use base 'Wx::App';


my $frame;

sub OnInit
{
	$frame = artisanFrame->new();
	unless ($frame) {print "unable to create frame"; return undef}
	$frame->Show( 1 );
	display(0,0,"artisan.pm started");
	return 1;
}


my $app = artisanApp->new();
appMain::run($app);

# This little snippet is required for my standard
# applications (needs to be put into)

display(0,0,"ending artisan.pm frame=$frame");
$frame->DESTROY() if $frame;
$frame = undef;
display(0,0,"finished artisan.pm");

exit 1;



1;

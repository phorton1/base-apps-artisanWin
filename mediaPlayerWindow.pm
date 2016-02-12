#!/usr/bin/perl
#------------------------------------------------------------
# mediaPlayerWindow
#------------------------------------------------------------

package mediaPlayerWindow;
use strict;
use warnings;
use appUtils;
use appWindow;
use Wx qw(:everything :allclasses);	# allclasses needed for MediaPlayer
use Wx::Event qw(
	EVT_MEDIA_LOADED
	EVT_MEDIA_STOP
	EVT_MEDIA_FINISHED
	EVT_MEDIA_STATECHANGED
	EVT_MEDIA_PLAY
	EVT_MEDIA_PAUSE);
use base qw(Wx::Window appWindow);


#---------------------------
# new
#---------------------------

sub new
{
	my ($class,$frame,$book,$id) = @_;
	display(0,0,"new mediaPlayerWindow()");
	my $this = $class->SUPER::new($book,$id);
	$this->appWindow($frame,$book,$id,"");		# "" is data
	
    $this->{sync_dirs} = Wx::CheckBox->new($this,-1,'sync dirs',[10,10],[-1,-1]);
	$this->{media_ctrl} = Wx::MediaCtrl->new($this,-1,"",[10,50],[1,1]);
		# the minimimum height is 68 which includes
		# transport/volume controls, and the name of the track
		# which I don't know how to get rid of. Any bigger and
		# it would be a video player.
	

    $this->{media_ctrl}->Show( 1 );
    $this->{media_ctrl}->ShowPlayerControls(wxMEDIACTRLPLAYERCONTROLS_DEFAULT);
		# or wxMEDIACTRLPLAYERCONTROLS_NONE
		# wxMEDIACTRLPLAYERCONTROLS_STEP
		# wxMEDIACTRLPLAYERCONTROLS_VOLUME
		# wxMEDIACTRLPLAYERCONTROLS_DEFAULT
								
	EVT_MEDIA_LOADED($this, 1,   		\&onMediaLoaded);
	EVT_MEDIA_STOP($this, -1, 	   		\&onMediaStop);
	EVT_MEDIA_FINISHED($this, -1, 		\&onMediaFinished);
	EVT_MEDIA_STATECHANGED($this, -1, 	\&onMediaStateChange);
	EVT_MEDIA_PLAY($this, -1, 			\&onMediaPlay);
	EVT_MEDIA_PAUSE($this, -1,   		\&onMediaPause);								
	
	return $this;
}



sub loadAndPlay
{
	my ($this) = @_;
	display(0,0,"loadAndPlay");
	$this->{media_ctrl}->Stop();
	my $file = Wx::FileSelector('Choose a media file');   
    if( length( $file ) )
	{
		display(0,1,"loadAndPlay got file=$file");
        $this->{media_ctrl}->LoadFile($file);
		$this->{play_it} = 1;
		display(0,0,"back from LoadFile()");
	}
}


sub onMediaLoaded
{
	my ($this,$event) = @_;
	display(0,0,"onMediaLoaded()");
}


sub onMediaStop
{
	my ($this,$event) = @_;
	display(0,0,"onMediaStop()");
	if ($this->{play_it})
	{
		display(0,1,"length=".$this->{media_ctrl}->Length());
		$this->{media_ctrl}->Play();
		display(0,0,"Play() called");
		$this->{play_it} = 0;
	}
}

sub onMediaFinished
{
	my ($this,$event) = @_;
	display(0,0,"onMediaFinished()");
}

sub onMediaStateChange
{
	my ($this,$event) = @_;
	display(0,0,"onMediaStateChange()");
}

sub onMediaPlay{
	my ($this,$event) = @_;
	display(0,0,"onMediaPlay()");
}

sub onMediaPause
{
	my ($this,$event) = @_;
	display(0,0,"onMediaPause()");
}




1;

#!/usr/bin/perl
#------------------------------------------------------------
# mediaPlayerWindow
#------------------------------------------------------------
# uses as 1 pixel Wx::MediaCtrl() for the player.
# should present a UI

package mediaPlayerWindow;
use strict;
use warnings;
use appWindow;
use Utils;
use localRenderer;
use DLNARenderer;
use Wx qw(:everything :allclasses);	# allclasses needed for MediaPlayer
use Wx::Event qw(
	EVT_IDLE
	
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
	
	display(0,1,"creating local_renderer");
	$this->{local_renderer} = localRenderer->new();
	display(0,1,"setting local_renderer");
	DLNARenderer::setLocalRenderer($this->{local_renderer});
	
	EVT_IDLE($this, \&onIdle);
	
	return $this;
}



sub onClose
{
	my ($this) = @_;
	display(0,0,"mediaPlayerWindow::onClose()");
	display(0,1,"onClose() unregistering local_renderer");
	DLNARenderer::setLocalRenderer(undef);
	display(0,1,"onClose() deleting local_renderer");
	delete $this->{local_renderer};
	display(0,1,"onClose() calling SUPER::onClose()");
	$this->SUPER::onClose();
	display(0,1,"onClose() returning");
}


sub onIdle
{
	my ($this,$event) = @_;
	
	if (@lr_command_stack)
	{
		my $string = shift(@lr_command_stack);
		my ($command,$arg) = split(/\t/,$string);
		LOG(0,"onIdle doing media_player::command($command,$arg)");

		if ($command eq 'stop')
		{
			# $this->{local_renderer}->{song_id} = '';
			my $rslt = $this->{media_ctrl}->Stop();
			display(0,0,"back from mp->Stop() rslt=$rslt");
			$this->{local_renderer}->{state} = 'STOPPED1';
			return $rslt;
		}
		elsif ($command eq 'pause')
		{
			my $rslt = $this->{media_ctrl}->Pause();
			display(0,0,"back from mp->Pause() rslt=$rslt");
			$this->{local_renderer}->{state} = 'PAUSED1';
		}
		elsif ($command eq 'seek')
		{
			my $millis = Renderer::time_to_secs($arg) * 1000;
			my $rslt = $this->{media_ctrl}->Seek($millis,wxFromStart);
			display(0,0,"back from mp->Seek() rslt=$rslt");
			return;
		}
		elsif ($command eq 'play')
		{
			$this->{play_it} = 1;
			return $this->{media_ctrl}->Play();
		}
		elsif ($command eq 'set_song')
		{
			if ($arg)
			{
				my $track = localRenderer::getDBTrack($arg);
				if (!$track)
				{
					error("Could not get track($arg)");
					return;
				}
		
				my $path = "$mp3_dir/$track->{FULLNAME}";
				display(0,1,"loading path='$path'");
				$this->{local_renderer}->{song_id} = $arg;
				$this->{local_renderer}->{state} = 'LOADING';
				
				# the path may need to be windows relative
				
				return $this->{media_ctrl}->LoadFile($path);
				display(0,0,"back from LoadFile()");
			}
			else
			{
				$this->{local_renderer}->{song_id} = '';
				$this->{local_renderer}->{state} = 'STOPPED2';
			}
		}
		else
		{
			error("Unknown command $command arg=$arg in onIdle::command()");
		}
	}
	elsif ($this->{local_renderer}->{state} =~ /PLAYING/)
	{
		my $millis = $this->{media_ctrl}->Tell();
		my $secs = int(($millis+500)/1000);
		$this->{local_renderer}->{reltime} = Renderer::secs_to_time($secs);
	}

	$event->Skip();
}



sub unused_loadAndPlay
{
	my ($this) = @_;
	display(0,0,"loadAndPlay");
	$this->{media_ctrl}->Stop();
	my $file = Wx::FileSelector('Choose a media file');   
    if( length( $file ) )
	{
		display(0,1,"loadAndPlay got file=$file");
		$this->{local_renderer}->{state} = 'LOADING';
        $this->{media_ctrl}->LoadFile($file);
			# loadfile will issue a onMediaStop event
			# at that point we actuall start playing
			# the file.
			
		$this->{play_it} = 1;
		display(0,0,"back from LoadFile()");
	}
}


sub onMediaLoaded
{
	my ($this,$event) = @_;
	display(0,0,"onMediaLoaded()");
	$this->{local_renderer}->{state} = 'LOADED';
	
	my $millis = $this->{media_ctrl}->Length();
	my $secs = int(($millis+500)/1000);
	$this->{local_renderer}->{duration} = Renderer::secs_to_time($secs);
}


sub onMediaStop
{
	my ($this,$event) = @_;
	display(0,0,"onMediaStop()");
	
	# if play_it == 1 this is a defered "play" command
	# and we now start it playing ...
	
	if ($this->{play_it})
	{
		display(0,1,"length=".$this->{media_ctrl}->Length());
		$this->{media_ctrl}->Play();
		display(0,0,"Play() called");
		$this->{play_it} = 0;
		$this->{local_renderer}->{state} = 'PLAYING1';
		
	}
}


sub onMediaFinished
{
	my ($this,$event) = @_;
	display(0,0,"onMediaFinished()");
	$this->{local_renderer}->{state} = 'FINISHED';
}


sub onMediaStateChange
	# ignore generic changes
	# wonder if I can get the description?
{
	my ($this,$event) = @_;
	display(0,0,"onMediaStateChange()");
}


sub onMediaPlay{
	my ($this,$event) = @_;
	display(0,0,"onMediaPlay()");
	$this->{local_renderer}->{state} = 'PLAYING2';
}


sub onMediaPause
{
	my ($this,$event) = @_;
	display(0,0,"onMediaPause()");
	$this->{local_renderer}->{state} = 'PAUSED';
	
}




1;

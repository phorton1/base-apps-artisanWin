#!/usr/bin/perl
#------------------------------------------------------------
# mediaPlayerWindow
#------------------------------------------------------------
# uses as 1 pixel Wx::MediaCtrl() for the player.
# should present a UI

package mediaPlayerWindow;
use strict;
use warnings;
use Wx qw(:everything :allclasses);	# allclasses needed for MediaPlayer
use Wx::Event qw(
	EVT_IDLE
	EVT_MEDIA_LOADED
	EVT_MEDIA_STOP
	EVT_MEDIA_FINISHED
	EVT_MEDIA_STATECHANGED
	EVT_MEDIA_PLAY
	EVT_MEDIA_PAUSE);
use MyWX::Window;
use Utils;
use localRenderer;
use DLNARenderer;
use Library;
use base qw(Wx::Window MyWX::Window);


#---------------------------
# new
#---------------------------

sub new
{
	my ($class,$frame,$book,$id) = @_;
	display(0,0,"new mediaPlayerWindow()");
	my $this = $class->SUPER::new($book,$id);
	$this->MyWindow($frame,$book,$id,"");		# "" is data
	
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
	$this->{local_renderer} = localRenderer->new($this);
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
		# do it, then shift it off the queue
		my $string = $lr_command_stack[0];
		my ($command,$arg) = split(/\t/,$string);
		LOG(0,"onIdle doing media_player::command($command,$arg)");
		$this->direct_command($command,$arg);
		shift @lr_command_stack;
		# localRenderer will be in state Transitioning, until then
	}
	elsif ($this->{local_renderer}->{state} =~ /PLAYING/)
	{
		$this->{local_renderer}->{position} =
			$this->{media_ctrl}->Tell();
	}

	$event->RequestMore(1);
	$event->Skip();
}


sub direct_command
{
	my ($this,$command,$arg) = @_;
	LOG(0,"direct_command($command,$arg)");

	if ($command eq 'stop')
	{
		# $this->{local_renderer}->{song_id} = '';
		my $rslt = $this->{media_ctrl}->Stop();
		display(0,0,"back from mp->Stop() rslt=$rslt");
		$this->{local_renderer}->{state} = 'STOPPED';
		return $rslt;
	}
	elsif ($command eq 'pause')
	{
		my $rslt = $this->{media_ctrl}->Pause();
		display(0,0,"back from mp->Pause() rslt=$rslt");
		$this->{local_renderer}->{state} = 'PAUSED';
	}
	elsif ($command eq 'seek')
	{
		my $rslt = $this->{media_ctrl}->Seek($arg,wxFromStart);
		display(0,0,"back from mp->Seek() rslt=$rslt");
	}
	elsif ($command eq 'play')
	{
		$this->{play_it} = 1;
		my $rslt = $this->{media_ctrl}->Play();
		$this->{local_renderer}->{state} = 'PLAYING';
		display(0,0,"back from mp->Play() rslt=$rslt");
	}
	elsif ($command eq 'set_song')
	{
		if ($arg)
		{
			my $track = get_track(undef,$arg);
			if (!$track)
			{
				error("Could not get track($arg)");
				return;
			}
	
			my $path = "$mp3_dir/$track->{path}";
			display(0,1,"loading path='$path'");
			$this->{local_renderer}->{song_id} = $arg;
			$this->{local_renderer}->{state} = 'TRANSITIONING';
			
			# the path may need to be windows relative
			
			return $this->{media_ctrl}->LoadFile($path);
			display(0,0,"back from LoadFile()");
		}
		else
		{
			$this->{local_renderer}->{song_id} = '';
			$this->{local_renderer}->{state} = 'STOPPED';
		}
	}
	else
	{
		error("Unknown command $command arg=$arg in onIdle::command()");
	}
}	# direct_command



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
	$this->{local_renderer}->{duration} = $this->{media_ctrl}->Length();
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
		$this->{local_renderer}->{state} = 'PLAYING';
	}
	else
	{
		$this->{local_renderer}->{state} = 'STOPPED';
	}
	
}


sub onMediaFinished
{
	my ($this,$event) = @_;
	display(0,0,"onMediaFinished()");
	$this->{local_renderer}->{state} = 'STOPPED';
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
	$this->{local_renderer}->{state} = 'PLAYING';
}


sub onMediaPause
{
	my ($this,$event) = @_;
	display(0,0,"onMediaPause()");
	$this->{local_renderer}->{state} = 'PAUSED';
	
}




1;

#!/usr/bin/perl
#------------------------------------------------------------
# localRenderer.pm
#------------------------------------------------------------
# An object that can be registered with the pure perl
# DLNARenderer class as a local renderer.
#
# This object must be created in SHARED MEMORY and
# contain all the necessary member fields:
#
#       id
#       name
#       maxVol
#       canMute
#       canLoud
#       maxBal
#       maxFade
#       maxBass
#       maxMid
#       maxHigh
#
# By convention it should probably also provide
# blank values for the following:
#
#       ip
#       port
#       transportURL
#       controlURL
#
# It must provide the following APIs
#
#    getState()
#
#        Returns undef if renderer is not online or there
#            is a problem with the return value (no status)
#        Otherwise, returns the state of the DLNA renderer
#            PLAYING, TRANSITIONING, ERROR, etc
#
#    getDeviceData()
#
#        If getState() returns 'PLAYING' this method may be called.
#        Returns undef if renderer is not online.
#        Otherwise, returns a $data hash with interesting fields:
#
#			duration
#           reltime
#           vol			- 0 (not supported)
#           mute		- 0 (not supported)
#           uri			- that the renderer used to get the song
#           song_id     - our song_id, if any, by RE from the uri
#           type        - song "type" from RE on the uri, or metadata mime type
#			metadata    - hash containing
#				artist
#				title
#				album
#			    track_num
#  				albumArtURI
#				genre
#				date
#				size
#				pretty_size
#
#    public doCommand(command,args)
#		 'stop'
#        'set_song', song_id
#        'play'
#        'seek', reltime
#        'pause'
#
#------------------------------------------------------------
# IMPLEMENTATION
#------------------------------------------------------------
# The question is how to get this shared memory object to
# communicate with an activeX control.  First try, just
# keep a member variable to it.


package localRenderer;
use strict;
use warnings;
use threads;
use threads::shared;
use artisanUtils;
use Database;
use Library;


BEGIN
{
 	use Exporter qw( import );
	our @EXPORT = qw (
        @lr_command_stack
    );
}

our @lr_command_stack:shared;
	# set on a stop, returned until the actual state changes to stopped



sub new
{
    my ($class) = @_;
    my $this = shared_clone({

        # basic state variables
        # managed by mediaPlayerWindow
        # and returned in getState() and getDeviceData()

        state   => 'INIT',      # state of this player
        song_id => '',          # currently playing song, if any

        # these are returned in getDeviceData()
        # and are set in the named mediaPlayerWindow method

        duration => 0,          # milliseconds
        position => 0,

        # these are the normal DLNAServer member variables
        # that a derived class must provide, and which are
        # returned returned directly to the ui as a hash of
        # this object.

        id      => 'local_renderer',
        name    => 'Local Renderer',

        maxVol  => 100,
        canMute => 0,
        canLoud => 0,
        maxBal  => 0,
        maxFade => 0,
        maxBass => 0,
        maxMid  => 0,
        maxHigh => 0,

        # there are unused normal DLNARenderer fields
        # that are set for safety

        ip      => '',
        port    => '',
        transportURL => '',
        controlURL => '',
    });

    bless $this, $class;
    return $this;

}


sub getState
{
    my ($this) = @_;
	if (0 && @lr_command_stack)
	{
		warning(0,1,"getState() while command pending ... our state=$this->{state}");
		return "TRANSITIONING";
	}
	display(0,1,"getState() returning $this->{state}");
    return $this->{state};
}



sub getDeviceData()
{
    my ($this) = @_;
    my $song_id = $this->{song_id};
    $song_id ||= '';

    my $track = $song_id ? get_track(undef,$song_id) : undef;
    if ($song_id && !$track)
    {
        error("Could not get track($song_id)");
    }
	if ($track)
	{
		$track->{pretty_size} = $track ? bytesAsKMGT($track->{size}): '';
		$track->{art_uri} = $track->getPublicArtUri();
	}

    my $data = shared_clone({
        song_id     => $song_id,
        position    => $this->{position} || 0,
        duration    => $this->{duration} ? $this->{duration} :
                       $track ? $track->{duration} : 0,
        uri			=> $track ? $track->{path}    : '',
        type        => $track ? $track->{type}    : '',

        vol			=> 0,
        mute		=> 0,
        metadata    => $track,
    });

    return $data;

}



sub doCommand
    # This code can be runs on a thread from the HTTP Server,
    # so it cannot access the media_player directly.
    #
    # Instead, we push commands commands on a shared stack,
    # and the mediaPlayer object *does* them during an onIdle
    # loop in the mediaPlayerWindow;
{
    my ($this,$command,$arg) = @_;
    $arg ||= '';

    display(0,0,"localRenderer::command($command,"._def($arg).")");
	push @lr_command_stack,"$command\t$arg";
    return 1;
}




1;
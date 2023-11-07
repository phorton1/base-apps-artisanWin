#!/usr/bin/perl
#-------------------------------------------------------------
# rtisanResources.pm
#-------------------------------------------------------------
# All appBase applications may provide resources that contain the
# app_title, main_menu, command_data, notebook_data, and so on.
# Derived classes should merge their values into the base
# class $resources member.

package artisanResources;
use strict;
use warnings;
use Pub::WX::Resources;
#use Wx qw(wxAUI_NB_BOTTOM);
#use Wx::AUI;


BEGIN
{
 	use Exporter qw( import );
	our @EXPORT = qw (
        $resources
		$COMMAND_TEST
        $WINDOW_MEDIA_PLAYER

		$WINDOW_LIBRARY
		$WINDOW_EXPLORER
		$WINDOW_STATIONS
		$WINDOW_SEARCH
		$WINDOW_SONGLIST
		$WINDOW_NOW_PLAYING
		$BEGIN_PANE_RANGE
		$END_PANE_RANGE
    );
}


our (
	$COMMAND_TEST,
    $WINDOW_MEDIA_PLAYER,

	# ranged windows

	$WINDOW_LIBRARY,
	$WINDOW_EXPLORER,
	$WINDOW_STATIONS,
	$WINDOW_SEARCH,
	$WINDOW_SONGLIST,
	$WINDOW_NOW_PLAYING )= (10000..11000);


# RANGED RESOURCES

our $BEGIN_PANE_RANGE = $WINDOW_LIBRARY;
our $END_PANE_RANGE = $WINDOW_NOW_PLAYING;


# Command data for this application.
# Notice the merging that takes place

my %command_data = (%{$resources->{command_data}},

	$WINDOW_LIBRARY			=> ['&Library',		'Library Administrator Window'	],
	$WINDOW_EXPLORER		=> ['&Explorer',	'Explorer and modify the library'	],
	$WINDOW_STATIONS		=> ['S&tations',	'Manage Stations'	],
	$WINDOW_SEARCH			=> ['&Search',		'Search for songs by Artist, Title, etc'	],
	$WINDOW_SONGLIST		=> ['Song&list',	'View and Modify List of Songs'	],
	$WINDOW_NOW_PLAYING		=> ['Now &Playing',	'The Now-Playing Window'	],

	$COMMAND_TEST 			=> ['Test','Test'],
    $WINDOW_MEDIA_PLAYER 	=> ['Media Player',    'Media Player Window' ],
);


#-------------------------------------
# Menus
#-------------------------------------

my @main_menu = (
    'view_menu,&View',
	'windows_menu,&Windows',
    'test_menu,&Test' );


my @windows_menu = (
	$WINDOW_LIBRARY,
	$WINDOW_EXPLORER,
	$WINDOW_STATIONS,
	$WINDOW_SEARCH,
	$WINDOW_SONGLIST,
	$WINDOW_NOW_PLAYING,
);


my @test_menu = (
	$WINDOW_MEDIA_PLAYER,
	$COMMAND_TEST
);


#-----------------------------------------
# Merge and reset the single public object
#-----------------------------------------

$resources = { %$resources,
    app_title       => 'Artisan',

    command_data    => \%command_data,

    main_menu       => \@main_menu,
    windows_menu    => \@windows_menu,
    test_menu    	=> \@test_menu,

};


1;

//
//  AppDelegate.h
//  Rdio Alarm Clock
//
//  Created by David Brunow on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Rdio/Rdio.h>
#import "Reachability.h"
#import "AlarmViewController.h"
#import "AlarmNavController.h"
#import "SimpleKeychain.h"
#import "AuthViewController.h"
#import <MediaPlayer/MPMusicPlayerController.h>

@interface AppDelegate : NSObject <UIApplicationDelegate>
{
    Rdio *rdio;
    Reachability *internetReachable;
    Reachability *hostReachable;
    UIWindow *window;
    bool loggedIn;
    bool alarmIsSet;
    bool alarmIsPlaying;
    float originalBrightness;
    float originalVolume;
    float appVolume;
    float appBrightness;
    UINavigationController *mainNav;
    NSDate  *alarmTime;
    UILocalNotification *backupAlarm;
    UILocalNotification *mustBeInApp;
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, retain) Rdio *rdio;
@property (nonatomic) bool loggedIn;
@property (nonatomic) bool alarmIsSet;
@property (nonatomic) bool alarmIsPlaying;
@property (nonatomic) float appBrightness;
@property (nonatomic) float originalBrightness;
@property (nonatomic) float originalVolume;
@property (nonatomic) float appVolume;
@property (strong, nonatomic) UINavigationController *mainNav;
@property (strong, nonatomic) NSDate *alarmTime;
@property (nonatomic) NSIndexPath *selectedPlaylistPath;
@property (nonatomic) NSString *selectedPlaylist;
@property (nonatomic) int numberOfPlaylistsOwned;
@property (nonatomic) int numberOfPlaylistsCollab;
@property (nonatomic) int numberOfPlaylistsSubscr;
@property (nonatomic, retain) NSMutableArray *typesInfo;
@property (nonatomic, retain) NSMutableArray *playlistsInfo;
@property (nonatomic, retain) NSMutableArray *tracksInfo;


+(Rdio *)rdioInstance;

- (void) checkNetworkStatus:(NSNotification *)notice;

@end

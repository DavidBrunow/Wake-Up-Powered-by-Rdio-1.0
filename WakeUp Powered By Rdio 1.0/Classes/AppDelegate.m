//
//  AppDelegate.m
//  Rdio Alarm Clock
//
//  Created by David Brunow on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "AlarmViewController.h"
#import "AlarmNavController.h"
#import "Credentials.h"

@implementation AppDelegate

@synthesize window, rdio, loggedIn, mainNav, appBrightness, originalBrightness, alarmIsSet, alarmIsPlaying, alarmTime, originalVolume, appVolume, selectedPlaylist, selectedPlaylistPath, numberOfPlaylistsOwned, numberOfPlaylistsCollab, numberOfPlaylistsSubscr, playlistsInfo, typesInfo, tracksInfo;

+(Rdio *)rdioInstance
{
    return [(id)[[UIApplication sharedApplication] delegate] rdio];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    [application setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    
    alarmIsSet = NO;
    alarmIsPlaying = NO;
    originalBrightness = [UIScreen mainScreen].brightness;
    appBrightness = originalBrightness;
    MPMusicPlayerController *music = [[MPMusicPlayerController alloc] init];

    originalVolume = music.volume;
    appVolume = originalVolume;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0];
    
    rdio = [[Rdio alloc] initWithConsumerKey:CONSUMER_KEY andSecret:CONSUMER_SECRET delegate:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
    
    internetReachable = [Reachability reachabilityForInternetConnection];
    [internetReachable startNotifier];
    
    // check if a pathway to a random host exists
    hostReachable = [Reachability reachabilityWithHostname: @"www.rdio.com"];
    [hostReachable startNotifier];
    
    // now patiently wait for the notification
    
    NSString *accessToken = [SFHFKeychainUtils getPasswordForUsername:USER_NAME andServiceName:SERVICE_NAME error:nil];
    
    if(accessToken != nil) {
        self.loggedIn = YES;
    } else {
        self.loggedIn = NO;
    }
    mainNav = [[AlarmNavController alloc] init];
    [mainNav.navigationBar setTintColor:[UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0]];
    
    [self.window setRootViewController:mainNav];
    
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    MPMusicPlayerController *music = [[MPMusicPlayerController alloc] init];

    float currentVolume = music.volume;
    if (currentVolume < originalVolume) {
        [music setVolume:originalVolume];
    }
    
    if (alarmIsSet) {
        
        mustBeInApp = [[UILocalNotification alloc] init];
        
        mustBeInApp.fireDate = [NSDate dateWithTimeIntervalSinceNow:5];
        NSLog(@"alarm will go off: %@", mustBeInApp.fireDate);
        mustBeInApp.timeZone = [NSTimeZone systemTimeZone];
        
        mustBeInApp.alertBody = [NSString stringWithFormat:NSLocalizedString(@"APP MUST BE OPEN REMINDER", nil)];
        mustBeInApp.alertAction = [NSString stringWithFormat:NSLocalizedString(@"TURN ALARM BACK ON", nil)];
        mustBeInApp.soundName = UILocalNotificationDefaultSoundName;
        
        [[UIApplication sharedApplication] scheduleLocalNotification:mustBeInApp];
        
        backupAlarm = [[UILocalNotification alloc] init];
        
        backupAlarm.fireDate = alarmTime;
        NSLog(@"alarm will go off: %@", backupAlarm.fireDate);
        backupAlarm.timeZone = [NSTimeZone systemTimeZone];
        
        backupAlarm.alertBody = @"Good morning, time to wake up.";
        backupAlarm.alertAction = @"Show me";
        backupAlarm.soundName = UILocalNotificationDefaultSoundName;
        
        //[[UIApplication sharedApplication] scheduleLocalNotification:backupAlarm];
        
    } else if (!alarmIsPlaying) {
        [self.window setRootViewController:nil];
    }
    [application setIdleTimerDisabled:NO];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    //[[UIScreen mainScreen] setBrightness:originalBrightness];
    [application setIdleTimerDisabled:NO];
    if (!alarmIsSet && !alarmIsPlaying) {
        [self.window setRootViewController:nil];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    //originalBrightness = [UIScreen mainScreen].brightness;
    //[UIScreen mainScreen].brightness = appBrightness;
    
    
    if (alarmIsSet) {
        MPMusicPlayerController *music = [[MPMusicPlayerController alloc] init];
        [music setVolume:0.0];
        [[UIScreen mainScreen] setBrightness:0.0];
        [[UIApplication sharedApplication] cancelLocalNotification:mustBeInApp];
        [[UIApplication sharedApplication] cancelLocalNotification:backupAlarm];
        [application setIdleTimerDisabled:YES];
    } else if (!alarmIsPlaying) {
        [self.window setRootViewController:mainNav];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    if (alarmIsSet || alarmIsPlaying) {
        [application setIdleTimerDisabled:YES];
    }
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    //originalBrightness = [UIScreen mainScreen].brightness;
    //[UIScreen mainScreen].brightness = appBrightness;
    /*[[UIApplication sharedApplication] cancelLocalNotification:mustBeInApp];
    [[UIApplication sharedApplication] cancelLocalNotification:backupAlarm];
    [application setIdleTimerDisabled:YES];
    if (alarmIsSet) {
        MPMusicPlayerController *music = [[MPMusicPlayerController alloc] init];
        [music setVolume:0.0];
        [[UIScreen mainScreen] setBrightness:0.0];
    }*/
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void) checkNetworkStatus:(NSNotification *)notice
{
    // called after network status changes
    NetworkStatus internetStatus = [internetReachable currentReachabilityStatus];
    switch (internetStatus)
    
    {
        case NotReachable:
        {
            //UIAlertView * alert  = [[UIAlertView alloc] initWithTitle:@"No Internet Connection" message:@"Internet is needed for this app. Enable internet, or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil ];
            //[alert show];
            NSLog(@"The internet is down.");
            
            break;
            
        }
        case ReachableViaWiFi:
        {               
            NSLog(@"The internet is working via WIFI.");
            
            break;
            
        }
        case ReachableViaWWAN:
        {
            NSLog(@"The internet is working via WWAN.");
            
            break;
            
        }
    }
    
    NetworkStatus hostStatus = [hostReachable currentReachabilityStatus];
    switch (hostStatus)
    
    {
        case NotReachable:
        {
            NSLog(@"A gateway to the host server is down.");
            UIAlertView * alert  = [[UIAlertView alloc] initWithTitle:@"Website Unreachable" message:[NSString stringWithFormat:NSLocalizedString(@"CANNOT CONNECT TO RDIO", nil)] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil ];
            [alert show];
            break;
            
        }
        case ReachableViaWiFi:
        {
            NSLog(@"A gateway to the host server is working via WIFI.");
            
            break;
            
        }
        case ReachableViaWWAN:
        {
            NSLog(@"A gateway to the host server is working via WWAN.");
            
            break;
            
        }
    }
}

- (void)application:(UIApplication *)application 
didReceiveLocalNotification:(UILocalNotification *)notification {
	//[mainView playClicked];
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateInactive) {
        //[mainView playClicked];
        // Application was in the background when notification
        // was delivered.
    }
    if (alarmIsSet || alarmIsPlaying) {
        [application setIdleTimerDisabled:YES];
    }
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)notification {
	//[mainView playClicked];
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateInactive) {
        //[mainView playClicked];
        // Application was in the background when notification
        // was delivered.
    }
    if (alarmIsSet || alarmIsPlaying) {
        [application setIdleTimerDisabled:YES];
    }
}


@end

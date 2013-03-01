//
//  AlarmNavController.m
//  Rdio Alarm
//
//  Created by David Brunow on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AlarmNavController.h"
#import "AlarmViewController.h"

@implementation AlarmNavController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated 
{
    [self.view setBackgroundColor:[UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0]];
}

- (void) viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [[AppDelegate rdioInstance] setDelegate:self];
    alarmVC = [[MainViewController alloc] init];
    logIn = [[UIBarButtonItem alloc] initWithTitle:@"Sign In" style:UIBarButtonItemStylePlain target:self action:@selector(loginClicked)];
    self.navigationBar.tintColor = [UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0];
    //alarmVC.title = @"Wake Up";
    
    UIImage *navBarLogo = [UIImage imageNamed:@"navbarclockicon"];
    UIImageView *navBarLogoView = [[UIImageView alloc] initWithImage:navBarLogo];
    [navBarLogoView setFrame:CGRectMake(140.0, 0.0, 40.0, 40.0)];
    [self.navigationBar addSubview:navBarLogoView];
    
    [self pushViewController:alarmVC animated:true];
    [[alarmVC navigationItem] setHidesBackButton:TRUE];
    if (!appDelegate.loggedIn) {
        [[alarmVC navigationItem] setLeftBarButtonItem:logIn animated:YES];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginClicked) name:@"logOutNotification" object:nil];
	// Do any additional setup after loading the view.
    
    NSString *accessToken = [SFHFKeychainUtils getPasswordForUsername:@"rdioUser" andServiceName:@"rdioAlarm" error:nil];
    
    //NSLog(@"access token: %@", accessToken);
    
    if(accessToken != nil) {
        [[AppDelegate rdioInstance] authorizeUsingAccessToken:accessToken fromController:self];
        //[logIn setTitle:@"Sign Out"];
        //appDelegate.loggedIn = YES;
    } else if(appDelegate.loggedIn) {
        //[logIn setTitle:@"Sign Out"];
    } else {
        //[logIn setTitle:@"Sign In"];
        //appDelegate.loggedIn = NO;
    } 
}

- (void) loginClicked {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.loggedIn) {
        //[[AppDelegate rdioInstance] logout];
        [logIn setTitle:@"Sign In"];
        appDelegate.loggedIn = NO;
        bool success = [SFHFKeychainUtils deleteItemForUsername:@"rdioUser" andServiceName:@"rdioAlarm" error:nil];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout Successful" message:@"You have been logged out of your Rdio account." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
        
        UIViewController *logInAlarmVC = [[MainViewController alloc] init];

        [self popToRootViewControllerAnimated:NO];
        [self popViewControllerAnimated:NO];
        
        [alarmVC removeFromParentViewController];
        alarmVC = nil;
        alarmVC = [[MainViewController alloc] init];
        [self pushViewController:alarmVC animated:NO];
        [[alarmVC navigationItem] setLeftBarButtonItem:logIn animated:NO];
        [[alarmVC navigationItem] setHidesBackButton:true];
        //[self popViewControllerAnimated:NO];
    } else {
        [[AppDelegate rdioInstance] authorizeFromController:self];
        //[logIn setTitle:@"Sign Out"];
        appDelegate.loggedIn = YES;
        [[alarmVC navigationItem] setHidesBackButton:true];
    }
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma mark -
#pragma mark RdioDelegate
- (void) rdioDidAuthorizeUser:(NSDictionary *)user withAccessToken:(NSString *)accessToken {
    NSLog(@"got here rdio did auth");
    [self setLoggedIn:YES];
    [logIn setTitle:@"Sign Out"];
    NSLog(@"got here");
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    bool success = [SFHFKeychainUtils storeUsername:@"rdioUser" andPassword:accessToken forServiceName:@"rdioAlarm" updateExisting:TRUE error:nil]; 
    if(!success)
    {
        bool success = [SFHFKeychainUtils deleteItemForUsername:@"rdioUser" andServiceName:@"rdioAlarm" error:nil];
        if(!success)
        {
            NSLog(@"Deleting keychain entry not successful.");
        }
    }
    /*AlarmNavController *mainNav = [[AlarmNavController alloc] init];
    [mainNav.navigationBar setTintColor:[UIColor purpleColor]];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    [appDelegate.window setRootViewController:mainNav];*/
    
}

- (void) rdioAuthorizationFailed:(NSString *)error {
    [self setLoggedIn:NO];
}

- (void) rdioAuthorizationCancelled {
    [self setLoggedIn:NO];
}

- (void) rdioDidLogout {
    [self setLoggedIn:NO];
    
    bool success = [SFHFKeychainUtils deleteItemForUsername:@"rdioUser" andServiceName:@"rdioAlarm" error:nil];
    if(!success)
    {
        NSLog(@"Deleting keychain entry not successful.");
    }
}

- (void) setLoggedIn:(BOOL)logged_in {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.loggedIn = logged_in;
    if (logged_in) {
        //[logIn setTitle:@"Sign Out"];
    } else {
        //[logIn setTitle:@"Sign In"];
    }
}

@end

//
//  MainViewController.m
//  Rdio Alarm
//
//  Created by David Brunow on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AlarmViewController.h"
#import "AlarmNavController.h"
#import "AppDelegate.h"
#import "SimpleKeychain.h"
#import <Rdio/Rdio.h>
#import <QuartzCore/QuartzCore.h>

@implementation MainViewController

@synthesize player, playButton, snoozeTime, sleepTime, autoStartAlarm;

-(RDPlayer*)getPlayer
{
    if (player == nil) {
        player = [AppDelegate rdioInstance].player;
    }
    return player;
}

- (void) setAlarmClicked {
    NSRange colonRange = NSRangeFromString(@"2,1");
    
    if (timeTextField.text.length == 4 && [[timeTextField.text substringWithRange:colonRange] isEqualToString:_timeSeparator]) {
        timeTextField.text = [timeTextField.text stringByReplacingOccurrencesOfString:_timeSeparator withString:@""];
        timeTextField.text = [NSString stringWithFormat:@"%@%@%@", [timeTextField.text substringToIndex:1], _timeSeparator, [timeTextField.text substringFromIndex:1]];
        //NSLog(@"newtime: %@", timeTextField.text);
    }
    
    NSString *tempTimeString = timeTextField.text;
    tempTimeString = [NSString stringWithFormat:@"%@ AM", tempTimeString];
    
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirmation" message:[NSString stringWithFormat:@"Set alarm for %@?", tempTimeString] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    //[alert show];
    [self setAlarm];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex) {
        
    } else {
        [self setAlarm];
    }
}

- (void) getAlarmTime {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSString *tempTimeString = @"";
    
    if (timeTextField.text.length == 4) {
        tempTimeString = [NSString stringWithFormat:@"0%@", timeTextField.text];
    } else {
        tempTimeString = timeTextField.text;
    }
    tempTimeString = [tempTimeString stringByReplacingOccurrencesOfString:_timeSeparator withString:@":"];
    
    [_settings setValue:timeTextField.text forKey:@"Alarm Time"];
    [self writeSettings];
    
    NSString *tempDateString = [formatter stringFromDate:[NSDate date]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm"];
    
    tempDateString = [NSString stringWithFormat:@"%@T%@", tempDateString, tempTimeString];
    appDelegate.alarmTime = [formatter dateFromString:tempDateString];
    if(!_is24h) {
        if ([appDelegate.alarmTime earlierDate:[NSDate date]]==appDelegate.alarmTime) {
            appDelegate.alarmTime = [appDelegate.alarmTime dateByAddingTimeInterval:43200];
            if ([appDelegate.alarmTime earlierDate:[NSDate date]]==appDelegate.alarmTime) {
                appDelegate.alarmTime = [appDelegate.alarmTime dateByAddingTimeInterval:43200];
            }
        }
    } else if (_is24h) {
        if ([appDelegate.alarmTime earlierDate:[NSDate date]]==appDelegate.alarmTime) {
            appDelegate.alarmTime = [appDelegate.alarmTime dateByAddingTimeInterval:86400];
            if ([appDelegate.alarmTime earlierDate:[NSDate date]]==appDelegate.alarmTime) {
                appDelegate.alarmTime = [appDelegate.alarmTime dateByAddingTimeInterval:86400];
            }
        }
    }

}

- (void) setAlarm {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [timeTextField resignFirstResponder];
    //[timeTextField removeFromSuperview];
    //[remindMe removeFromSuperview];
    //[setAlarmView removeFromSuperview];
    [self getAlarmTime];
    //NSLog(@"alarm time: %@", appDelegate.alarmTime);
    
    if (remindMe.on) {
        nightlyReminder = [[UILocalNotification alloc] init];
        
        nightlyReminder.fireDate = [NSDate dateWithTimeIntervalSinceNow:86400];
        //NSLog(@"alarm will go off: %@", nightlyReminder.fireDate);
        nightlyReminder.timeZone = [NSTimeZone systemTimeZone];
        
        nightlyReminder.alertBody = @"Are you ready to set your nightly alarm?";
        nightlyReminder.alertAction = @"Set Alarm";
        nightlyReminder.soundName = UILocalNotificationDefaultSoundName;
        
        [[UIApplication sharedApplication] scheduleLocalNotification:nightlyReminder];
    }

    t = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setIdleTimerDisabled:true];
    
    [self displaySleepScreen];

}

- (void) displaySleepScreen {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.alarmIsSet = YES;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGRect sleepLabelRect = CGRectMake(40.0, 200.0, 240.0, 50.0);
    CGRect alarmLabelRect = CGRectMake(40.0, 150.0, 240.0, 50.0);
    CGRect chargingLabelRect = CGRectMake(40.0, 350.0, 240.0, 60.0);
    
    
    NSString *alarmTimeText = [[NSString alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (!_is24h) {
        [formatter setDateFormat:@"h:mm a"];
    } else if (_is24h) {
        [formatter setDateFormat:@"H:mm"];
        //NSLog(@"this is 24 hour clock");
    }
    alarmTimeText = [formatter stringFromDate:appDelegate.alarmTime];
    alarmTimeText = [alarmTimeText stringByReplacingOccurrencesOfString:@":" withString:_timeSeparator];
    sleepView = [[UIView alloc] initWithFrame:screenRect];
    
    //[sleepView gestureRecognizers];
    UIPanGestureRecognizer *slideViewGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    //[sleepView addGestureRecognizer:slideViewGesture];
    //[sleepView 
    [sleepView setBackgroundColor:[UIColor blackColor]];
    UILabel *sleepLabel = [[UILabel alloc] initWithFrame:sleepLabelRect];
    [sleepLabel setText:NSLocalizedString(@"PLEASE REST PEACEFULLY", nil)];
    [sleepLabel setTextColor:[UIColor grayColor]];
    [sleepLabel setFont:[UIFont fontWithName:@"Helvetica" size:22.0]];
    [sleepLabel setBackgroundColor:[UIColor blackColor]];
    [sleepLabel setNumberOfLines:10];
    
    [sleepLabel setAdjustsFontSizeToFitWidth:YES];
    [sleepView addSubview:sleepLabel];
    
    _alarmLabel = [[UILabel alloc] initWithFrame:alarmLabelRect];
    [_alarmLabel setText:[NSString stringWithFormat:NSLocalizedString(@"YOUR ALARM IS SET", nil), alarmTimeText]];
    [_alarmLabel setTextColor:[UIColor grayColor]];
    [_alarmLabel setFont:[UIFont fontWithName:@"Helvetica" size:22.0]];
    [_alarmLabel setBackgroundColor:[UIColor blackColor]];
    [_alarmLabel setNumberOfLines:10];
    [_alarmLabel setAdjustsFontSizeToFitWidth:YES];
    [sleepView addSubview:_alarmLabel];
    
    _chargingLabel = [[UILabel alloc] initWithFrame:chargingLabelRect];
    [_chargingLabel setText:NSLocalizedString(@"PLUG ME IN", nil)];
    [_chargingLabel setTextColor:[UIColor grayColor]];
    [_chargingLabel setFont:[UIFont fontWithName:@"Helvetica" size:22.0]];
    [_chargingLabel setBackgroundColor:[UIColor blackColor]];
    [_chargingLabel setNumberOfLines:10];
    [_chargingLabel setAdjustsFontSizeToFitWidth:YES];
    if ([UIDevice currentDevice].batteryState != UIDeviceBatteryStateCharging && [UIDevice currentDevice].batteryState != UIDeviceBatteryStateFull) {
        [sleepView addSubview:_chargingLabel];
    }
    
    CGRect cancelFrame = CGRectMake(261, self.view.frame.size.height - 19 - 49, 49, 49);
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setFrame:cancelFrame];
    
    UIImage *cancelButtonImage = [UIImage imageNamed:@"x"];
    
    [cancelButton setBackgroundColor:[UIColor blackColor]];
    [cancelButton setImage:cancelButtonImage forState:UIControlStateNormal];
    [cancelButton setTintColor:[UIColor blackColor]];
    [cancelButton setAccessibilityLabel:NSLocalizedString(@"Cancel Alarm", nil)];
    //[cancelButton addTarget:self action:@selector(cancelAlarm) forControlEvents:UIControlEventTouchUpInside];
    //[cancelButton addTarget:self action:@selector(slideViewUp) forControlEvents:UIControlEventTouchDragInside];
    [cancelButton addGestureRecognizer:slideViewGesture];
    [cancelButton addTarget:self action:@selector(bounceView) forControlEvents:UIControlEventTouchUpInside];
    
    //[cancelButton setEnabled:NO];
    [sleepView addSubview:cancelButton]; 
    
    [self.view addSubview:sleepView]; 
    
    [fader invalidate];
    
    if (sleepTime != 0) {
        if ([[AppDelegate rdioInstance] player].state == RDPlayerStatePaused) {
            [[[AppDelegate rdioInstance] player] togglePause];
        } else {
            self.shuffle = NO; //remove this code once the toggle for shuffling is in place
            if(self.shuffle) {
                songsToPlay = [self shuffle:songsToPlay];
            }
            songsToPlay = [self getEnough:songsToPlay];
            [[[AppDelegate rdioInstance] player] playSources:songsToPlay];
        }
        fader = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(fadeScreenOut) userInfo:nil repeats:YES];
    } else {
        fader = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fadeScreenOut) userInfo:nil repeats:YES]; 
    }
    
    //appDelegate.originalVolume = music.volume;
    //[music setVolume:0.0];
    //[[UIScreen mainScreen] setBrightness:0.0];
    //appDelegate.appBrightness = 0.0;
}

- (void) handlePanGesture:(UIPanGestureRecognizer *)sender {
    CGPoint translate = [sender translationInView:sender.view.superview];
    
    CGRect newFrame = [[UIScreen mainScreen] bounds];

    newFrame.origin.y += (translate.y);
    sender.view.superview.frame = newFrame;
        
         
    //}
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (translate.y < -100.0) {
            [UIView animateWithDuration:0.3 animations:^{[sender.view.superview setFrame:CGRectMake(0.0, -[[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];} completion:^(BOOL finished){[sender.view.superview removeFromSuperview];[self cancelAlarm];}];
        } else {
            [self bounceView];
        }
    }
}

- (void) cancelAlarm {
    [fader invalidate];
    fader = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fadeScreenIn) userInfo:nil repeats:YES];
    [t invalidate];
    [self stopAlarm];
}

- (void) fadeScreenOut {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSInteger sleepTimeSeconds = sleepTime * 60;
    if (sleepTimeSeconds == 0) {
        sleepTimeSeconds = 100;
    }
    
    if ([UIScreen mainScreen].brightness <= 0.0) {
        [fader invalidate];
        if (sleepTime != 0) {
            [[[AppDelegate rdioInstance] player] togglePause];
        }
        appDelegate.appBrightness = 0.0;
        [_alarmLabel removeFromSuperview];
        [_chargingLabel removeFromSuperview];
    } else {
        float increment = (appDelegate.originalBrightness - 0.0)/(sleepTimeSeconds);
        float newBrightness = [UIScreen mainScreen].brightness - increment;
        [[UIScreen mainScreen] setBrightness:newBrightness];
        
        float incrementVolume = (appDelegate.originalVolume - 0.0)/(sleepTimeSeconds);
        float newVolume = [self.music volume] - incrementVolume;
        if (appDelegate.appVolume > 0) {
            if (sleepTime != 0) {
                [self.music setVolume:newVolume];
                appDelegate.appVolume = newVolume;
            } else {
                [self.music setVolume:0];
                appDelegate.appVolume = 0;
            }
        }
    }
}

- (void) fadeScreenIn {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.originalVolume <= 0.1) {
        appDelegate.originalVolume = 0.5;
    }
    
    if ([UIScreen mainScreen].brightness >= appDelegate.originalBrightness && [self.music volume] >= appDelegate.originalVolume) {
        [fader invalidate];
    } else {
        if ([UIScreen mainScreen].brightness < appDelegate.originalBrightness) {
            float incrementScreen = (appDelegate.originalBrightness - 0.0)/100.0;
            float newBrightness = [UIScreen mainScreen].brightness + incrementScreen;
            [[UIScreen mainScreen] setBrightness:newBrightness];
            appDelegate.appBrightness = newBrightness;
        }
        
        if ([self.music volume] < appDelegate.originalVolume) {
            float incrementVolume = (appDelegate.originalVolume - 0.0)/100.0;
            float newVolume = [self.music volume] + incrementVolume;
            if (appDelegate.appVolume < appDelegate.originalVolume) {
                [self.music setVolume:newVolume];
                appDelegate.appVolume = newVolume;
            }
        }
    }
}

- (void) alarmSounding {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.alarmIsSet = NO;
    appDelegate.alarmIsPlaying = YES;
    [fader invalidate];
    fader = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(fadeScreenIn) userInfo:nil repeats:YES];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    [sleepView removeFromSuperview];
    
    if ([[AppDelegate rdioInstance] player].state == RDPlayerStatePaused) {
        [[[AppDelegate rdioInstance] player] togglePause];
    } else {
        songsToPlay = [self shuffle:songsToPlay];
        [[[AppDelegate rdioInstance] player] playSources:songsToPlay];
    }
    
    wakeView = [[UIView alloc] initWithFrame:screenRect];
    [wakeView setBackgroundColor:[UIColor colorWithRed:241.0/255 green:147.0/255 blue:20.0/255 alpha:1.0]];
    
    UIPanGestureRecognizer *slideViewGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    //[wakeView addGestureRecognizer:slideViewGesture];
    
    CGRect snoozeFrame = CGRectMake(40, 170, 240, 80);
    UIButton *snoozeButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [snoozeButton setFrame:snoozeFrame];
    
    [snoozeButton setTitle:NSLocalizedString(@"SNOOZE", nil) forState: UIControlStateNormal];
    [snoozeButton setTintColor:[UIColor colorWithRed:241.0/255 green:147.0/255 blue:20.0/255 alpha:1.0]];
    [snoozeButton setBackgroundColor:[UIColor clearColor]];
    [snoozeButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:58.0]];
    [snoozeButton.titleLabel setTextColor:[UIColor blackColor]];
    
    [snoozeButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [snoozeButton addTarget:self action:@selector(startSnooze) forControlEvents:UIControlEventTouchUpInside];
    [wakeView addSubview:snoozeButton];
    
    CGRect offFrame = CGRectMake(261, self.view.frame.size.height - 19 - 49, 49, 49);
    UIImage *offButtonImage = [UIImage imageNamed:@"orangex"];
    UIButton *offButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [offButton setImage:offButtonImage forState:UIControlStateNormal];
    [offButton setAccessibilityLabel:NSLocalizedString(@"TURN OFF ALARM", nil)];
    [offButton setFrame:offFrame];
    [offButton setBackgroundColor:[UIColor clearColor]];
    [offButton addTarget:self action:@selector(bounceView) forControlEvents:UIControlEventTouchUpInside];
    [offButton addGestureRecognizer:slideViewGesture];
    //[offButton addTarget:self action:@selector(slideViewUp) forControlEvents:UIControlEventTouchDragInside];
    [wakeView addSubview:offButton]; 
    [self.view addSubview:wakeView];
}

- (void) bounceView
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    CGRect bounceUpFrameFirst = [[UIScreen mainScreen] bounds];
    bounceUpFrameFirst.origin.y = bounceUpFrameFirst.origin.y - 30.0;
    CGRect bounceUpFrameSecond = [[UIScreen mainScreen] bounds];
    bounceUpFrameSecond.origin.y = bounceUpFrameFirst.origin.y - 15.0;
    CGRect bounceUpFrameThird = [[UIScreen mainScreen] bounds];
    bounceUpFrameThird.origin.y = bounceUpFrameFirst.origin.y - 10.0;
    CGRect bounceDownFrame = [[UIScreen mainScreen] bounds];
    
    [UIView animateWithDuration:0.1 animations:^{[wakeView setFrame:bounceUpFrameFirst]; [sleepView setFrame:bounceUpFrameFirst];} completion:^(BOOL finished){[UIView animateWithDuration:0.1 animations:^{[wakeView setFrame:bounceDownFrame]; [sleepView setFrame:bounceDownFrame];} completion:^(BOOL finished){[UIView animateWithDuration:0.1 animations:^{[wakeView setFrame:bounceUpFrameSecond]; [sleepView setFrame:bounceUpFrameSecond];} completion:^(BOOL finished){[UIView animateWithDuration:0.1 animations:^{[wakeView setFrame:bounceDownFrame]; [sleepView setFrame:bounceDownFrame];} completion:^(BOOL finished){[UIView animateWithDuration:0.1 animations:^{[wakeView setFrame:bounceUpFrameThird]; [sleepView setFrame:bounceUpFrameThird];} completion:^(BOOL finished){[UIView animateWithDuration:0.1 animations:^{[wakeView setFrame:bounceDownFrame]; [sleepView setFrame:bounceDownFrame];}];}];}];}];}];}];
    
    if (UIAccessibilityIsVoiceOverRunning())
    {
        if (appDelegate.alarmIsSet) {
            [sleepView removeFromSuperview];
            [self cancelAlarm];
            [self setAccessibilityLabel:NSLocalizedString(@"ALARM CANCELED", nil)];
                    } else {
            [wakeView removeFromSuperview];
            [self stopAlarm];
            [self setAccessibilityLabel:NSLocalizedString(@"ALARM STOPPED", nil)]; 
        }
    }
}

- (NSMutableArray *) shuffle: (NSMutableArray *) list
{
    NSMutableArray *newList = [[NSMutableArray alloc] initWithCapacity:[list count]];
    int x = 0;
    int oldListCount = list.count;
    
    while (oldListCount != newList.count) {
        //NSLog(@"oldlistcount: %d, newlistcount: %d", list.count, newList.count);
         
        int listIndex = (arc4random() % list.count);
        NSString *testObject = [list objectAtIndex:listIndex];

        //NSLog(@"_canBeStreamed: %@",[_canBeStreamed objectAtIndex:listIndex]);
        if ([_canBeStreamed objectAtIndex:listIndex] == @"YES") {
            [newList  addObject:testObject];
            [list removeObjectAtIndex:listIndex];
            [_canBeStreamed removeObjectAtIndex:listIndex];
            
            //NSLog(@"list item #%d: %@", x, [newList objectAtIndex:x]);
            x++;
        } else {
            //NSLog(@"list item not added: %@", [list objectAtIndex:listIndex]);
            [list removeObjectAtIndex:listIndex];
            [_canBeStreamed removeObjectAtIndex:listIndex];
            oldListCount--;
        }
    }
    
    return newList;
}

- (NSMutableArray *) getEnough: (NSMutableArray *) list
{
    NSMutableArray *newList = [[NSMutableArray alloc] initWithCapacity:[list count]];
    
    while (newList.count < 120) {
        [newList addObjectsFromArray:list];
        //NSLog(@"number of items in songstoplay now: %d", newList.count);
    }
    
    return newList;
}

- (void) startSnooze {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    //double currentPosition = [[AppDelegate rdioInstance] player].position; 
    [[[AppDelegate rdioInstance] player] togglePause];
    
    int snoozeTimeSeconds = snoozeTime * 60;
    
    appDelegate.alarmTime = [NSDate dateWithTimeIntervalSinceNow:snoozeTimeSeconds];
    
    t = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick) userInfo:nil repeats:YES];
    [wakeView removeFromSuperview];
    [self displaySleepScreen];
}

- (void) stopAlarm {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    appDelegate.alarmIsSet = NO;
    appDelegate.alarmIsPlaying = NO;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:false];
    [self.music setVolume:appDelegate.originalVolume];
    [[UIScreen mainScreen] setBrightness:appDelegate.originalBrightness];
    self.navigationController.navigationBarHidden = NO;
    [[[AppDelegate rdioInstance] player] stop];
    [self determineStreamableSongs];
    [[UIApplication sharedApplication] setIdleTimerDisabled:true];
    //[wakeView removeFromSuperview];
    //[self.view addSubview:setAlarmView];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{

}
*/

- (void) loginClicked {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"logOutNotification" object:nil];
}

- (void) updateSnoozeLabel {
    if ((int)_sliderSnooze.value == 1) {
        [_lblSnooze setText:[NSString stringWithFormat:NSLocalizedString(@"SNOOZE SLIDER LABEL", nil), (int)_sliderSnooze.value]];
    } else {
        [_lblSnooze setText:[NSString stringWithFormat:NSLocalizedString(@"SNOOZE SLIDER LABEL PLURAL", nil), (int)_sliderSnooze.value]];
    }
    NSString *sliderSnoozeString = [NSString stringWithFormat:@"%d", (int)_sliderSnooze.value];
    [_settings setValue:sliderSnoozeString forKey:@"Snooze Time"];
    self.snoozeTime = (int)_sliderSnooze.value;
    [self writeSettings];
}

- (void) updateSleepLabel {
    float sleepTimeValue = _sliderSleep.value/10;
    double svalue = _sliderSleep.value / 10.0;
    double dvalue = svalue - floor(svalue);
    //Check if the decimal value is closer to a 5 or not
    if(dvalue >= 0.25 && dvalue < 0.75)
        dvalue = floorf(svalue) + 0.5f;
    else
        dvalue = roundf(svalue);
    sleepTimeValue = dvalue * 10;
    //NSLog(@"%f", sleepTimeValue);
    //if ((int)_sliderSleep.value == 1) {
    //    [_lblSleep setText:[NSString stringWithFormat:NSLocalizedString(@"SLEEP SLIDER LABEL", nil), (int)sleepTimeValue]];
    //
    /*} else */
    if ((int)_sliderSleep.value < 5) {
        [_lblSleep setText:[NSString stringWithFormat:NSLocalizedString(@"SLEEP SLIDER LABEL DISABLED", nil)]];
        [_sliderSleep setValue:0.0];
    } else {
        [_lblSleep setText:[NSString stringWithFormat:NSLocalizedString(@"SLEEP SLIDER LABEL PLURAL", nil), (int)sleepTimeValue]];
    }
    NSString *sliderSleepString = [NSString stringWithFormat:@"%d", (int)sleepTimeValue];
    [_settings setValue:sliderSleepString forKey:@"Sleep Time"];
    self.sleepTime = (int)sleepTimeValue;
    [self writeSettings];
}

- (void) updateAutoStart {
    NSString *autoStartString = [NSString stringWithFormat:@"%d", (bool)_switchAutoStart.on];
    [_settings setValue:autoStartString forKey:@"Auto Start Alarm"];
    self.autoStartAlarm = (bool)_switchAutoStart.on;
    [self writeSettings];
}

- (void) updateShuffle {
    //NSString *shuffleString = [NSString stringWithFormat:@"%d", (bool)self.switchShuffle.on];
    //[_settings setValue:shuffleString forKey:@"Shuffle"];
    //self.shuffle = (bool)self.switchShuffle.on;
    //[self writeSettings];
}

-(void)writeSettings
{
    //NSString* docFolder = [NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //NSString * path = [docFolder stringByAppendingPathComponent:@"Settings.plist"];
    
    if([_settings writeToFile:_settingsPath atomically: YES]){
    } else {

    }
    
}

- (void)moveSettingsToDocumentsDir
{
    /* get the path to save the favorites */
    _settingsPath = [self settingsPath];
    NSString *_oldSettingsPath = [self oldSettingsPath];
    
    /* check to see if there is already a file saved at the favoritesPath
     * if not, copy the default FavoriteUsers.plist to the favoritesPath
     */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:_settingsPath])
    {
        if(![fileManager fileExistsAtPath:_oldSettingsPath]) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
            //NSArray *settingsArray = [NSArray arrayWithContentsOfFile:path];
            [[NSFileManager defaultManager]copyItemAtPath:path toPath:_settingsPath error:nil];
            //[settingsArray writeToFile:_settingsPath atomically:YES];
        } else {
            NSPropertyListFormat format;
            NSString *errorDesc = nil;
            NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:_oldSettingsPath];

            _settings = (NSDictionary *)[NSPropertyListSerialization
                                         propertyListFromData:plistXML
                                         mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                         format:&format
                                         errorDescription:&errorDesc];
            if (!_settings) {
                NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
            }
            //NSDictionary *root = [temp objectForKey:@"root"];
            NSString *sleepTimeString = [_settings valueForKey:@"Sleep Time"];
            NSString *snoozeTimeString = [_settings valueForKey:@"Snooze Time"];
            NSString *alarmTimeString = [_settings valueForKey:@"Alarm Time"];
            //this is not a likely scenario, since the file structures will most likely be different if they are different versions
            //in that case, this would be the right place to take each value in the old file and put it in the new one
            //[[NSFileManager defaultManager]moveItemAtPath:_oldSettingsPath toPath:_settingsPath error:nil];
            
            NSString *path = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
            //NSArray *settingsArray = [NSArray arrayWithContentsOfFile:path];
            [[NSFileManager defaultManager]copyItemAtPath:path toPath:_settingsPath error:nil];
            
            [_settings setValue:sleepTimeString forKey:@"Sleep Time"];
            [_settings setValue:snoozeTimeString forKey:@"Snooze Time"];
            [_settings setValue:alarmTimeString forKey:@"Alarm Time"];
            [self writeSettings];
        }
    }
}

- (NSString *)settingsPath
{
    /* get the path for the Documents directory */
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    /* append the path component for the FavoriteUsers.plist */
    NSString *settingsPath = [documentsPath stringByAppendingPathComponent:@"WakeUpRdioSettingsv2.plist"];

    return settingsPath;
}

- (NSString *)oldSettingsPath
{
    /* get the path for the Documents directory */
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    /* append the path component for the FavoriteUsers.plist */
    NSString *settingsPath = [documentsPath stringByAppendingPathComponent:@"WakeUpRdioSettingsv1.plist"];
    
    return settingsPath;
}

- (void) changeBatteryLabel
{
    if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateCharging) {
        [_chargingLabel setText:[NSString stringWithFormat:NSLocalizedString(@"CHARGING LABEL", nil)]];
        [_chargingLabel setAdjustsFontSizeToFitWidth:YES];
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [self moveSettingsToDocumentsDir];
    self.music = [[MPMusicPlayerController alloc] init];
    appDelegate.originalVolume = [self.music volume];
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeBatteryLabel) name:@"UIDeviceBatteryStateDidChangeNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideVolumeView) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    _language = [[NSLocale preferredLanguages] objectAtIndex:0];
    
    _timeSeparator = @":";
    
    if([_language isEqualToString:@"en"]) {
        _timeSeparator = @":";
    } else if([_language isEqualToString:@"fr"] || [_language isEqualToString:@"pt-PT"]) {
        _timeSeparator = @"h";
    } else if([_language isEqualToString:@"de"] || [_language isEqualToString:@"da"] || [_language isEqualToString:@"fi"]) {
        _timeSeparator = @".";
    }
    //NSLog(@"%@", _language);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [formatter stringFromDate:[NSDate date]];
    NSRange amRange = [dateString rangeOfString:[formatter AMSymbol]];
    NSRange pmRange = [dateString rangeOfString:[formatter PMSymbol]];
    _is24h = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
    //NSLog(@"%@\n",(_is24h ? @"YES" : @"NO"));

    /*
    
    
    NSString *plistPath = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self settingsPath]]) {
        _settingsPath = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"];
        NSLog(@"first thing didn't work");
    }
     */
    NSPropertyListFormat format;
    NSString *errorDesc = nil;
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:_settingsPath];
    _settings = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          errorDescription:&errorDesc];
    if (!_settings) {
        NSLog(@"Error reading plist: %@, format: %d", errorDesc, format);
    }
    //NSDictionary *root = [temp objectForKey:@"root"];
    NSString *sleepTimeString = [_settings valueForKey:@"Sleep Time"];  
    NSString *snoozeTimeString = [_settings valueForKey:@"Snooze Time"];
    NSString *autoStartAlarmString = [_settings valueForKey:@"Auto Start Alarm"];
    
        
    self.sleepTime = [sleepTimeString integerValue];
    self.snoozeTime = [snoozeTimeString integerValue];
    self.autoStartAlarm = [autoStartAlarmString boolValue];
    
    _lastLength = 0;
    [self.navigationItem setHidesBackButton:true];
    [self.view setBounds:[[UIScreen mainScreen] bounds]];
    //[self.view setBackgroundColor:[UIColor whiteColor]];
    
    
    listsViewController = [[ListsViewController alloc] init];
    
    //CGRect fullScreen = [[UIScreen mainScreen] bounds];
    CGRect fullScreen = [self.navigationController view].frame;
    
    UIView *settingsView = [[UIView alloc] initWithFrame:fullScreen];
    //UIColor *backgroundColor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"550L_cloth.jpg"]];
    [settingsView setBackgroundColor:[UIColor darkGrayColor]];
    
    CGRect frameBtnSignOut = CGRectMake(60, self.view.frame.size.height - 140, 89, 29);
    UIButton *btnSignOut = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [btnSignOut setFrame:frameBtnSignOut];
    [btnSignOut setTitle:[NSString stringWithFormat:NSLocalizedString(@"SIGN OUT", nil)] forState:UIControlStateNormal];
    [btnSignOut.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    
    [btnSignOut.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [btnSignOut setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [btnSignOut addTarget:self action:@selector(loginClicked) forControlEvents:UIControlEventTouchUpInside];
    
    _sliderSnooze = [[UISlider alloc] initWithFrame:CGRectMake(30, 60, 150, 50)];
    [_sliderSnooze setMinimumValue:1.0];
    [_sliderSnooze setMaximumValue:30.0];
    [_sliderSnooze setValue:snoozeTime animated:NO];
    [_sliderSnooze addTarget:self action:@selector(updateSnoozeLabel) forControlEvents:UIControlEventAllEvents];
    
    [settingsView addSubview:_sliderSnooze];
    
    _lblSnooze = [[UILabel alloc] initWithFrame:CGRectMake(5, 20, 200, 50)];
    if ((int)_sliderSnooze.value == 1) {
        [_lblSnooze setText:[NSString stringWithFormat:NSLocalizedString(@"SNOOZE SLIDER LABEL", nil), (int)_sliderSnooze.value]];
    } else {
        [_lblSnooze setText:[NSString stringWithFormat:NSLocalizedString(@"SNOOZE SLIDER LABEL PLURAL", nil), (int)_sliderSnooze.value]];
    }
    [_lblSnooze setTextColor:[UIColor whiteColor]];
    [_lblSnooze setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    [_lblSnooze setBackgroundColor:[UIColor clearColor]];
    [_lblSnooze setNumberOfLines:10];
    
    [_lblSnooze setAdjustsFontSizeToFitWidth:YES];
    
    [_lblSnooze setTextAlignment:UITextAlignmentCenter];
    [settingsView addSubview:_lblSnooze];
    
    _sliderSleep = [[UISlider alloc] initWithFrame:CGRectMake(30, 160, 150, 50)];
    [_sliderSleep setMinimumValue:0.0];
    [_sliderSleep setMaximumValue:60.0];
    [_sliderSleep setValue:sleepTime animated:NO];
    [_sliderSleep addTarget:self action:@selector(updateSleepLabel) forControlEvents:UIControlEventAllEvents];
    
    _lblSleep = [[UILabel alloc] initWithFrame:CGRectMake(5, 120, 200, 50)];
    if ((int)_sliderSleep.value == 1) {
        [_lblSleep setText:[NSString stringWithFormat:NSLocalizedString(@"SLEEP SLIDER LABEL", nil), (int)_sliderSleep.value]];
        
    } else if ((int)_sliderSleep.value == 0) {
        [_lblSleep setText:[NSString stringWithFormat:NSLocalizedString(@"SLEEP SLIDER LABEL DISABLED", nil)]];
    } else {
        [_lblSleep setText:[NSString stringWithFormat:NSLocalizedString(@"SLEEP SLIDER LABEL PLURAL", nil), (int)_sliderSleep.value]];
    }
    [_lblSleep setTextColor:[UIColor whiteColor]];
    [_lblSleep setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    [_lblSleep setBackgroundColor:[UIColor clearColor]];
    [_lblSleep setNumberOfLines:10];
    [_lblSleep setAdjustsFontSizeToFitWidth:YES];
    
    [_lblSleep setTextAlignment:UITextAlignmentCenter];
    
    _switchAutoStart = [[UISwitch alloc] initWithFrame:CGRectMake(65, 285, 50, 50)];
    [_switchAutoStart setOn:autoStartAlarm animated:NO];
    [_switchAutoStart addTarget:self action:@selector(updateAutoStart) forControlEvents:UIControlEventAllEvents];
    
    [settingsView addSubview:_switchAutoStart];
    
    _lblAutoStart = [[UILabel alloc] initWithFrame:CGRectMake(5, 220, 200, 60)];
    [_lblAutoStart setText:[NSString stringWithFormat:NSLocalizedString(@"AUTO ALARM", nil)]];
    [_lblAutoStart setTextColor:[UIColor whiteColor]];
    [_lblAutoStart setTextAlignment:UITextAlignmentCenter];
    [_lblAutoStart setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    [_lblAutoStart setBackgroundColor:[UIColor clearColor]];
    [_lblAutoStart setLineBreakMode:UILineBreakModeWordWrap];
    [_lblAutoStart setNumberOfLines:10];
    [_lblAutoStart setAdjustsFontSizeToFitWidth:YES];
    
    [settingsView addSubview:_lblAutoStart];
    
    self.switchShuffle = [[UISwitch alloc] initWithFrame:CGRectMake(65, 350, 50, 50)];
    [self.switchShuffle setOn:autoStartAlarm animated:NO];
    [self.switchShuffle addTarget:self action:@selector(updateShuffle) forControlEvents:UIControlEventAllEvents];
    
    //[settingsView addSubview:self.switchShuffle];
    
    self.lblShuffle = [[UILabel alloc] initWithFrame:CGRectMake(5, 310, 200, 60)];
    [self.lblShuffle setText:[NSString stringWithFormat:NSLocalizedString(@"SHUFFLE", nil)]];
    [self.lblShuffle setTextColor:[UIColor whiteColor]];
    [self.lblShuffle setTextAlignment:UITextAlignmentCenter];
    [self.lblShuffle setFont:[UIFont fontWithName:@"Helvetica" size:16.0]];
    [self.lblShuffle setBackgroundColor:[UIColor clearColor]];
    [self.lblShuffle setLineBreakMode:UILineBreakModeWordWrap];
    [self.lblShuffle setNumberOfLines:10];
    [self.lblShuffle setAdjustsFontSizeToFitWidth:YES];
    
    //[settingsView addSubview:self.lblShuffle];

    if (appDelegate.loggedIn) {
        [settingsView addSubview:btnSignOut];
        [settingsView addSubview:_lblSleep];
        [settingsView addSubview:_sliderSleep];
    }
    
    UILabel *lblName = [[UILabel alloc] initWithFrame:CGRectMake(30, self.view.frame.size.height - 100, 150, 50)];
    [lblName setText:[NSString stringWithFormat:@"David Brunow\n@davidbrunow\nhelloDavid@brunow.org"]];
    [lblName setTextColor:[UIColor blackColor]];
    [lblName setFont:[UIFont fontWithName:@"Helvetica" size:12.0]];
    [lblName setBackgroundColor:[UIColor clearColor]];
    [lblName setNumberOfLines:10];
    
    [lblName setTextAlignment:UITextAlignmentCenter];
    [settingsView addSubview:lblName];
    
    [self.view addSubview:settingsView];
    
    setAlarmView = [[UIView alloc] initWithFrame:fullScreen];
    [setAlarmView setBackgroundColor:[UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0]];
    
    CGRect setAlarmFrame = CGRectMake(40, 165, 240, 50);
    setAlarmButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [setAlarmButton setFrame:setAlarmFrame];
    
    [setAlarmButton setTitle:NSLocalizedString(@"SET ALARM", nil) forState: UIControlStateNormal];
    [setAlarmButton setBackgroundColor:[UIColor clearColor]];
    [setAlarmButton.titleLabel setAdjustsFontSizeToFitWidth:TRUE];
    [setAlarmButton addTarget:self action:@selector(setAlarmClicked) forControlEvents:UIControlEventTouchUpInside];
    [setAlarmButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:42.0]];
    [setAlarmButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [setAlarmButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [setAlarmButton setEnabled:NO];
    [setAlarmView addSubview:setAlarmButton];
    
    /*
     CGRect remindMeFrame = CGRectMake(40.0, 180.0, 120, 30);
     remindMe = [[UISwitch alloc] initWithFrame:remindMeFrame];
     [remindMe setOn:YES animated:YES];
     [setAlarmView addSubview:remindMe]; */
    
    CGRect timeTextFrame = CGRectMake(40.0, 87, 240, 60);
    UIImage *timeTextBackground = [UIImage imageNamed:@"timeSetRoundedRect"];
    UIImageView *timeTextBackgroundView = [[UIImageView alloc] initWithImage:timeTextBackground];
    [timeTextBackgroundView setFrame:timeTextFrame];
    [setAlarmView addSubview:timeTextBackgroundView];
    
    timeTextField = [[UITextField alloc] initWithFrame:timeTextFrame];
    [timeTextField setDelegate:self];
    [timeTextField setBackgroundColor:[UIColor clearColor]];
    [timeTextField setTextAlignment:UITextAlignmentCenter];
    [timeTextField setTextColor:[UIColor whiteColor]];
    [timeTextField setKeyboardType:UIKeyboardTypeNumberPad];
    [timeTextField setFont:[UIFont fontWithName:@"Helvetica" size:48.0]];
    [timeTextField setBounds:CGRectMake(40.0, 87, 240, 60)];
    [timeTextField setContentMode:UIViewContentModeScaleToFill];
    [timeTextField setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"CHOOSE ALARM TIME", nil)]];
    [timeTextField addTarget:self action:@selector(textFieldValueChange:) forControlEvents:UIControlEventEditingChanged];
    NSString *timeTextString = [NSString stringWithFormat:@"%@",[_settings valueForKey:@"Alarm Time"] ];
    if (timeTextString == nil) {
        timeTextString = [NSString stringWithFormat:@""];
    } else {
        timeTextString = [timeTextString stringByReplacingOccurrencesOfString:@"h" withString:_timeSeparator];
    }
    [timeTextField setText:timeTextString];
    
    [timeTextField setPlaceholder:_timeSeparator];
    [setAlarmView addSubview:timeTextField];
    
    CGRect chooseMusicFrame = CGRectMake(30.0, 15.0, 260.0, 100.0);
    _chooseMusic = [[UITableView alloc] initWithFrame:chooseMusicFrame style:UITableViewStyleGrouped];
    [_chooseMusic setScrollEnabled:NO];
    [_chooseMusic setBackgroundColor:[UIColor clearColor]];
    [_chooseMusic setBackgroundView:nil];
    [_chooseMusic setDelegate:self];
    [_chooseMusic setDataSource:self];
    
    if (appDelegate.loggedIn) {
        [setAlarmView addSubview:_chooseMusic];
    } else {
        
        CGRect notLoggedInLabelFrame = CGRectMake(40.0, -5.0, 240.0, 100.0);
        UIButton *notLoggedInButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [notLoggedInButton setFrame:notLoggedInLabelFrame];
        [notLoggedInButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"NOT SIGNED IN LABEL", nil)] forState:UIControlStateNormal];
        [notLoggedInButton setBackgroundColor:[UIColor clearColor]];
        [notLoggedInButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [notLoggedInButton.titleLabel setLineBreakMode:UILineBreakModeWordWrap];
        [notLoggedInButton.titleLabel setNumberOfLines:0];
        
        [notLoggedInButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
        [notLoggedInButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:14.0]];
        [notLoggedInButton.titleLabel setTextAlignment:UITextAlignmentCenter];
        [notLoggedInButton addTarget:self action:@selector(RdioSignUp) forControlEvents:UIControlEventTouchUpInside];

        [setAlarmView addSubview:notLoggedInButton];
        
    }
    
    /* This is supposed to hide the volume controls, but has a problem where the controls are initially shown when this view is added. */
    self.hideVolume = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, 0, 10, 0)];
    [self.hideVolume sizeToFit];
    [self.view addSubview:self.hideVolume];

    [setAlarmView.layer setShadowColor:[UIColor blackColor].CGColor];
    [setAlarmView.layer setShadowOffset:CGSizeMake(2.0, 2.0)];
    [setAlarmView.layer setShadowRadius:35.0];
    [setAlarmView.layer setShadowOpacity:1.0];
    
    CGRect settingsButtonFrame = CGRectMake(10, self.view.frame.size.height - 80, 26, 26);
    UIImage *settingsButtonImage = [UIImage imageNamed:@"preferences"];
    UIButton *btnSettings = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnSettings setImage:settingsButtonImage forState:UIControlStateNormal];
    [btnSettings setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"CHANGE SETTINGS", nil)]];
    [btnSettings setFrame:settingsButtonFrame];
    [btnSettings setBackgroundColor:[UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0]];
    [btnSettings setTintColor:[UIColor clearColor]];
    
    [btnSettings addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    
    [setAlarmView addSubview:btnSettings];
    
    [self.view addSubview:setAlarmView];
    
    NSInteger pNumber = [[_settings valueForKey:@"Playlist Number"] intValue];
    NSInteger pSection = [[_settings valueForKey:@"Playlist Section"] intValue];
    NSIndexPath *ipPlaylistPath = [NSIndexPath indexPathForRow:pNumber inSection:pSection] ;
    
    if(ipPlaylistPath.section != -1 && appDelegate.selectedPlaylistPath == nil) {
        appDelegate.selectedPlaylistPath = ipPlaylistPath;
        appDelegate.selectedPlaylist = [_settings valueForKey:@"Playlist Name"];
    }
    
    [self setAMPMLabel];
    
    if (_switchAutoStart.on && ![timeTextString isEqualToString:@""]) {
        [self getAlarmTime];
        NSString *alarmTimeText = [[NSString alloc] init];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        if(!_is24h) {
            [formatter setDateFormat:@"h:mm a"];
        } else {
            [formatter setDateFormat:[NSString stringWithFormat:@"H:mm"]];
        }
        alarmTimeText = [formatter stringFromDate:appDelegate.alarmTime];
        alarmTimeText = [alarmTimeText stringByReplacingOccurrencesOfString:@":" withString:_timeSeparator];
        self.navigationController.navigationBarHidden = YES;
        autoStartAlarmView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        [autoStartAlarmView setBackgroundColor:[UIColor colorWithRed:68.0/255 green:11.0/255 blue:104.0/255 alpha:1.0]];
        UILabel *autoStartAlarmViewLabel = [[UILabel alloc] initWithFrame:CGRectMake(40, 40, 240, 400)];
        [autoStartAlarmViewLabel setBackgroundColor:[UIColor clearColor]];
        [autoStartAlarmViewLabel setLineBreakMode:UILineBreakModeWordWrap];
        [autoStartAlarmViewLabel setText:[NSString stringWithFormat:NSLocalizedString(@"AUTO ALARM BEING SET", nil), appDelegate.selectedPlaylist, alarmTimeText]];
        [autoStartAlarmViewLabel setNumberOfLines:20];
        [autoStartAlarmViewLabel setAdjustsFontSizeToFitWidth:YES];
        [autoStartAlarmViewLabel setTextColor:[UIColor whiteColor]];
        [autoStartAlarmViewLabel setFont:[UIFont fontWithName:@"Helvetica" size:22.0]];
        [autoStartAlarmView addSubview:autoStartAlarmViewLabel];
        
        [self.view addSubview:autoStartAlarmView];
        [delay invalidate];
        delay = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(delayAutoStart) userInfo:nil repeats:NO];

    }
}

-(void) hideVolumeView
{
    NSLog(@"Here");
    self.hideVolume = [[MPVolumeView alloc] initWithFrame:CGRectMake(-100, 0, 10, 0)];
    [self.hideVolume sizeToFit];
    //[self.view addSubview:self.hideVolume];
}

-(void) setAMPMLabel
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [_lblAMPM removeFromSuperview];
    [self getAlarmTime];
    NSString *sAMPM = [[NSString alloc] init];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"a"];
    sAMPM = [formatter stringFromDate:appDelegate.alarmTime];
    
    _lblAMPM = [[UILabel alloc] initWithFrame:CGRectMake(240, 93, 50, 50)];
    [_lblAMPM setBackgroundColor:[UIColor clearColor]];
    [_lblAMPM setLineBreakMode:UILineBreakModeWordWrap];
    [_lblAMPM setText:[NSString stringWithFormat:@"%@", sAMPM]];
    [_lblAMPM setTextColor:[UIColor whiteColor]];
    [_lblAMPM setFont:[UIFont fontWithName:@"Helvetica" size:18.0]];
    if (sAMPM.length > 0 && !_is24h) {
        [setAlarmView addSubview:_lblAMPM];
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (delay.isValid) {
        [self cancelAutoStart];
    }
}

- (void) showSettings
{
    //AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    CGRect settingsOpenFrame = [[UIScreen mainScreen] bounds];
    settingsOpenFrame.origin.x = 220;
    CGRect settingsClosedFrame = [[UIScreen mainScreen] bounds];

    CGFloat x = setAlarmView.frame.origin.x;
    
    if (x == 0 ) {
        [UIView animateWithDuration:0.3 animations:^{[setAlarmView setFrame:settingsOpenFrame];}];
        setAlarmButton.enabled = false;
        [self setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"SETTINGS OPENED", nil)]];
    } else {
        [UIView animateWithDuration:0.3 animations:^{[setAlarmView setFrame:settingsClosedFrame];}];
        //setAlarmButton.enabled = true;
        [self testToEnableAlarmButton];
        [self setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"SETTINGS CLOSED", nil)]];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [super viewDidAppear:animated];
    
    NSInteger pNumber = [[_settings valueForKey:@"Playlist Number"] intValue];
    NSInteger pSection = [[_settings valueForKey:@"Playlist Section"] intValue];
    NSIndexPath *ipPlaylistPath = [NSIndexPath indexPathForRow:pNumber inSection:pSection] ;
    
    if(ipPlaylistPath.section != -1 && appDelegate.selectedPlaylistPath == nil) {
        //appDelegate.selectedPlaylistPath = ipPlaylistPath;
        //appDelegate.selectedPlaylist = [_settings valueForKey:@"Playlist Name"];
        [self loadSongs];
    } else if (appDelegate.selectedPlaylistPath != nil) {
        [_settings setValue:[NSNumber numberWithInteger:appDelegate.selectedPlaylistPath.section] forKey:@"Playlist Section"];
        [_settings setValue:[NSNumber numberWithInteger:appDelegate.selectedPlaylistPath.row] forKey:@"Playlist Number"];
        [_settings setValue:appDelegate.selectedPlaylist forKey:@"Playlist Name"];
        //NSLog(@"Selected Playlist Name: %@", appDelegate.selectedPlaylist);
        //NSLog(@"Selected Playlist Section: %@", appDelegate.selectedPlaylistPath);
        [self writeSettings];
    }
    
    if (appDelegate.loggedIn) {
        [_chooseMusic reloadData];
    }
    
    if (appDelegate.selectedPlaylistPath != nil && playlists != nil) {
        [self loadSongs];
    }
    
    if(playlists == nil) {
        if(appDelegate.loggedIn) {
            NSDictionary *trackInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"trackKeys", @"extras", nil];
            [[AppDelegate rdioInstance] callAPIMethod:@"getPlaylists" withParameters:trackInfo delegate:self];
            _loadingView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds] ];
            [_loadingView setBackgroundColor:[UIColor blackColor]];
            [_loadingView setAlpha:0.9];
            UIActivityIndicatorView *aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [aiView setCenter:CGPointMake(160, 200)];
            [aiView startAnimating];
            UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 200.0, 120.0, 100.0)];
            [loadingLabel setText:[NSString stringWithFormat:NSLocalizedString(@"LOADING", nil)]];
            [loadingLabel setBackgroundColor:[UIColor clearColor]];
            [loadingLabel setTextColor:[UIColor whiteColor]];
            [loadingLabel setFont:[UIFont fontWithName:@"Helvetica" size:24.0]];
            [loadingLabel setTextAlignment:UITextAlignmentCenter];
            
            [loadingLabel setAdjustsFontSizeToFitWidth:YES];
            [_loadingView addSubview:loadingLabel];
            [_loadingView addSubview:aiView];
            if (!_switchAutoStart.on) {
                [self.view addSubview:_loadingView];
            }
        } else {
            //choose songs from top songs chart
            NSDictionary *trackInfo = [[NSDictionary alloc] initWithObjectsAndKeys:@"Track", @"type", nil];
            [[AppDelegate rdioInstance] callAPIMethod:@"getTopCharts" withParameters:trackInfo delegate:self];
        }
    }
    
    [self testToEnableAlarmButton];
    
    //[self determineStreamableSongs];
    
    

    //songsToPlay = [self shuffle:songsToPlay];
}

- (void) testToEnableAlarmButton
{
    NSString *firstChar = @"";
    NSString *secondChar = @"";
    NSString *thirdChar = @"";
    NSString *fourthChar = @"";
    
    if (timeTextField.text.length > 0) {
        firstChar = [timeTextField.text substringToIndex:1];
    }
    
    NSRange secondCharRange = NSRangeFromString(@"1,1");
    if (timeTextField.text.length > 1) {
        secondChar = [timeTextField.text substringWithRange:secondCharRange];
    }
    
    NSRange thirdCharRange = NSRangeFromString(@"2,1");
    if (timeTextField.text.length > 2) {
        thirdChar = [timeTextField.text substringWithRange:thirdCharRange];
    }
    
    NSRange fourthCharRange = NSRangeFromString(@"3,1");
    if (timeTextField.text.length > 3) {
        fourthChar = [timeTextField.text substringWithRange:fourthCharRange];
    }
    
    if (!_is24h) {
        if (songsToPlay != nil && timeTextField.text.length == 5 && [firstChar isEqualToString:@"1"] && ([secondChar isEqualToString:@"0"] || [secondChar isEqualToString:@"1"] || [secondChar isEqualToString:@"2"])) {
            [setAlarmButton setEnabled:YES];
        } else if (songsToPlay != nil && timeTextField.text.length == 4 ) {
            [setAlarmButton setEnabled:YES];
        } else {
            [setAlarmButton setEnabled:NO];
        }
    } else if(_is24h) {
        if (songsToPlay != nil && timeTextField.text.length == 5 && ([firstChar isEqualToString:@"1"] || ([firstChar isEqualToString:@"2"] && ([secondChar isEqualToString:@"0"] || [secondChar isEqualToString:@"1"] || [secondChar isEqualToString:@"2"] || [secondChar isEqualToString:@"3"])))) {
            [setAlarmButton setEnabled:YES];
        } else if (songsToPlay != nil && timeTextField.text.length == 4 ) {
            [setAlarmButton setEnabled:YES];
        } else {
            [setAlarmButton setEnabled:NO];
        }
    }
}

- (void) determineStreamableSongs
{
    songsToPlay = [self removeDuplicatesInPlaylist:songsToPlay];
    _canBeStreamed = [[NSMutableArray alloc] initWithCapacity:songsToPlay.count];
    NSString *songsToPlayString = [songsToPlay objectAtIndex:0];
    for (int x = 1; x < songsToPlay.count; x++) {
        songsToPlayString = [NSString stringWithFormat:@"%@, %@", songsToPlayString, [songsToPlay objectAtIndex:x]];
    }
    //NSLog(@"Songs to play: %@", songsToPlayString);
    NSDictionary *trackInfo = [[NSDictionary alloc] initWithObjectsAndKeys:songsToPlayString, @"keys", @"canStream", @"extras", nil];
    [[AppDelegate rdioInstance] callAPIMethod:@"get" withParameters:trackInfo delegate:self];
}

- (NSMutableArray *) removeDuplicatesInPlaylist: (NSMutableArray *) playlist
{    
    for (int x = 0; x < playlist.count; x++) {
        for (int y = x+1; y < playlist.count; y++) {
            if ([[playlist objectAtIndex:x] isEqual:[playlist objectAtIndex:y]]) {
                [playlist removeObjectAtIndex:y];
            }
        }
    }
    
    return playlist;
}

- (void) RdioSignUp 
{
    UIViewController *signUpViewController = [[UIViewController alloc] init];

    CGRect webViewRect = [[UIScreen mainScreen] bounds];
    UIWebView *signUpView = [[UIWebView alloc] initWithFrame:webViewRect];
    //[signUpView setDelegate:signUpViewController];
    NSURL *RdioAffiliateURL = [NSURL URLWithString:@"http://click.linksynergy.com/fs-bin/click?id=TWsTggfYv7c&offerid=221756.10000002&type=3&subid=0"];
    NSURLRequest *RdioAffiliateRequest = [NSURLRequest requestWithURL:RdioAffiliateURL];
    [signUpView loadRequest:RdioAffiliateRequest];
    //[signUpViewController setTitle:@"Learn More"];
    [signUpViewController.view addSubview:signUpView];
    
    //[self.view addSubview:signUpView];
    [self.navigationController pushViewController:signUpViewController animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"musicCell"];
    
    if (appDelegate.selectedPlaylist != nil) {
        [cell setAccessibilityLabel:[NSString stringWithFormat:NSLocalizedString(@"SELECTED PLAYLIST IS", nil), appDelegate.selectedPlaylist]];
        cell.textLabel.text = appDelegate.selectedPlaylist;
    } else {
        cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"CHOOSE PLAYLIST", nil)];
        
        [cell.textLabel setAdjustsFontSizeToFitWidth:YES];
    }
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
    
    [self.navigationController pushViewController:listsViewController animated:YES];
}

- (void) textFieldValueChange:(UITextField *) textField
{
    float currentLength = textField.text.length;
        
    if (_lastLength == 0) {
        _lastLength = currentLength;
    }

    NSString *firstChar = @"";
    NSString *secondChar = @"";
    NSString *thirdChar = @"";
    NSString *fourthChar = @"";
    
    if (textField.text.length > 0) {
        firstChar = [textField.text substringToIndex:1];
    }
    
    NSRange secondCharRange = NSRangeFromString(@"1,1");
    //NSLog(@"%@", secondCharRange);
    if (textField.text.length > 1) {
        secondChar = [textField.text substringWithRange:secondCharRange];
    }
    
    NSRange thirdCharRange = NSRangeFromString(@"2,1");
    if (textField.text.length > 2) {
        thirdChar = [textField.text substringWithRange:thirdCharRange];
    }
    
    NSRange fourthCharRange = NSRangeFromString(@"3,1");
    if (textField.text.length > 3) {
        fourthChar = [textField.text substringWithRange:fourthCharRange];
    }
    
    if(!_is24h) {
        if (([firstChar isEqualToString: @"0"])) {
            textField.Text = [NSString stringWithFormat:@""];
        } else if (!([firstChar isEqualToString: @"1"]) || [secondChar isEqualToString:_timeSeparator]) {
            
            if(currentLength == 5) {
                textField.text = [textField.text substringToIndex:4];
            } else if(currentLength == 1 && _lastLength <= currentLength) {
                textField.text = [NSString stringWithFormat:@"%@%@", firstChar,_timeSeparator];
            } else if (currentLength == 1 && _lastLength > currentLength) {
                textField.text = [NSString stringWithFormat:@""];
            } else if(currentLength == 2 && _lastLength <= currentLength) {
                if ([secondChar isEqualToString: @"0"] || [secondChar isEqualToString: @"1"] || [secondChar isEqualToString: @"2"] || [secondChar isEqualToString: @"3"] || [secondChar isEqualToString: @"4"] || [secondChar isEqualToString: @"5"]) {
                    textField.text = [NSString stringWithFormat:@"%@%@%@", firstChar, _timeSeparator, secondChar ];
                } else if (![secondChar isEqualToString:_timeSeparator]) {
                    textField.text = [NSString stringWithFormat:@"%@", firstChar];
                }
            } else if (currentLength == 2 && _lastLength > currentLength) {
                textField.text = [NSString stringWithFormat:@"%@", firstChar];
            }
        } else {
            if(currentLength == 6) {
                textField.text = [textField.text substringToIndex:5];
            } else if(currentLength == 2 && _lastLength <= currentLength) {
                if ([secondChar isEqualToString: @"3"] || [secondChar isEqualToString: @"4"] || [secondChar isEqualToString: @"5"]) {
                    textField.Text = [NSString stringWithFormat:@"%@%@%@", firstChar, _timeSeparator, secondChar ];
                } else if ([secondChar isEqualToString: @"0"] || [secondChar isEqualToString: @"1"] || [secondChar isEqualToString: @"2"]) {
                    textField.Text = [NSString stringWithFormat:@"%@%@", textField.text, _timeSeparator ];
                } else {
                    textField.text = [NSString stringWithFormat:@"%@", firstChar];
                }
            } else if (currentLength == 2 && _lastLength > currentLength) {
                textField.text = [NSString stringWithFormat:@"%@", firstChar];
            }
        }
    } else if (_is24h) {
        if (([firstChar isEqualToString: @"0"])) {
            textField.Text = [NSString stringWithFormat:@""];
        } else if (!([firstChar isEqualToString: @"1"] || [firstChar isEqualToString:@"2"]) || [secondChar isEqualToString:_timeSeparator]) {
            
            if(currentLength == 5) {
                textField.text = [textField.text substringToIndex:4];
            } else if(currentLength == 1 && _lastLength <= currentLength) {
                textField.text = [NSString stringWithFormat:@"%@%@", firstChar,_timeSeparator];
            } else if (currentLength == 1 && _lastLength > currentLength) {
                textField.text = [NSString stringWithFormat:@""];
            } else if(currentLength == 2 && _lastLength <= currentLength) {
                if ([secondChar isEqualToString: @"0"] || [secondChar isEqualToString: @"1"] || [secondChar isEqualToString: @"2"] || [secondChar isEqualToString: @"3"] || [secondChar isEqualToString: @"4"] || [secondChar isEqualToString: @"5"]) {
                    textField.text = [NSString stringWithFormat:@"%@%@%@", firstChar, _timeSeparator, secondChar ];
                } else if (![secondChar isEqualToString:_timeSeparator]) {
                    textField.text = [NSString stringWithFormat:@"%@", firstChar];
                } 
            } else if (currentLength == 2 && _lastLength > currentLength) {
                textField.text = [NSString stringWithFormat:@"%@", firstChar];
            } else if(currentLength == 3 && _lastLength <= currentLength) {
                if ([thirdChar isEqualToString: @"6"] || [thirdChar isEqualToString: @"7"] || [thirdChar isEqualToString: @"8"] || [thirdChar isEqualToString: @"9"]) {
                    textField.Text = [NSString stringWithFormat:@"%@%@", firstChar, _timeSeparator];
                }
            }
        } else if ([firstChar isEqualToString: @"1"] || [firstChar isEqualToString:@"2"]) {
            if(currentLength == 6) {
                textField.text = [textField.text substringToIndex:5];
            } else if(currentLength == 2 && _lastLength <= currentLength) {
                if ([firstChar isEqualToString:@"2"] && ([secondChar isEqualToString: @"4"] || [secondChar isEqualToString: @"5"])) {
                    textField.Text = [NSString stringWithFormat:@"%@%@%@", firstChar, _timeSeparator, secondChar ];
                } else if ([firstChar isEqualToString:@"1"] && ([secondChar isEqualToString: @"6"] || [secondChar isEqualToString: @"7"] || [secondChar isEqualToString: @"8"] || [secondChar isEqualToString: @"9"])) {
                    textField.Text = [NSString stringWithFormat:@"%@%@", textField.text, _timeSeparator ];
                } else if ([firstChar isEqualToString:@"2"] && ([secondChar isEqualToString: @"0"] || [secondChar isEqualToString: @"1"] || [secondChar isEqualToString: @"2"] || [secondChar isEqualToString: @"3"])) {
                    textField.Text = [NSString stringWithFormat:@"%@%@", textField.text, _timeSeparator ];
                } else if ([firstChar isEqualToString:@"1"] && ([secondChar isEqualToString: @"0"] || [secondChar isEqualToString: @"1"] || [secondChar isEqualToString: @"2"] || [secondChar isEqualToString: @"3"] || [secondChar isEqualToString: @"4"] || [secondChar isEqualToString: @"5"])) {
                    textField.Text = [NSString stringWithFormat:@"%@%@", textField.text, _timeSeparator ];
                } else {
                    textField.text = [NSString stringWithFormat:@"%@", firstChar];
                }
            } else if (currentLength == 2 && _lastLength > currentLength) {
                textField.text = [NSString stringWithFormat:@"%@", firstChar];
            } else if (currentLength == 5 && _lastLength <= currentLength && (([secondChar isEqualToString:@"0"] || [secondChar isEqualToString:@"1"] || [secondChar isEqualToString:@"2"] || [secondChar isEqualToString:@"3"] || [secondChar isEqualToString:@"4"] || [secondChar isEqualToString:@"5"]) && ([fourthChar isEqualToString:@"6"] || [fourthChar isEqualToString:@"7"] || [fourthChar isEqualToString:@"8"] || [fourthChar isEqualToString:@"9"]))) {
                textField.text = [NSString stringWithFormat:@"%@%@%@%@", firstChar, secondChar, _timeSeparator, fourthChar];
            } else if (currentLength == 4 && _lastLength <= currentLength && (([secondChar isEqualToString:@"6"] || [secondChar isEqualToString:@"7"] || [secondChar isEqualToString:@"8"] || [secondChar isEqualToString:@"9"]) && ([fourthChar isEqualToString:@"6"] || [fourthChar isEqualToString:@"7"] || [fourthChar isEqualToString:@"8"] || [fourthChar isEqualToString:@"9"]))) {
                textField.text = [NSString stringWithFormat:@"%@%@%@", firstChar, secondChar, _timeSeparator];
            }
        }

    }
    
    [self testToEnableAlarmButton];
    [self setAMPMLabel];
    _lastLength = textField.text.length;
}

- (void) tick
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    NSLog(@"current time: %@ & alarm time: %@", [NSDate date], appDelegate.alarmTime);
    
    NSDate *now = [NSDate date];
    
    if([appDelegate.alarmTime isEqualToDate:([appDelegate.alarmTime earlierDate:now])] && !playing)
    {
        [self alarmSounding];
        [t invalidate];
    }

}

- (void) delayAutoStart
{
    [self cancelAutoStart];
    [self setAlarm];
}

- (void) cancelAutoStart
{
    self.navigationController.navigationBarHidden = NO;
    [autoStartAlarmView removeFromSuperview];
    [delay invalidate];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark RDPlayerDelegate

- (BOOL) rdioIsPlayingElsewhere {
    // let the Rdio framework tell the user.
    return NO;
}

- (void) rdioPlayerChangedFromState:(RDPlayerState)fromState toState:(RDPlayerState)state {
    playing = (state != RDPlayerStateInitializing && state != RDPlayerStateStopped);
    paused = (state == RDPlayerStatePaused);
    if (paused || !playing) {
        [playButton setTitle:@"Play" forState:UIControlStateNormal];
    } else {
        [playButton setTitle:@"Pause" forState:UIControlStateNormal];
    }
}

#pragma mark -
#pragma mark RDAPIRequestDelegate
/**
 * Our API call has returned successfully.
 * the data parameter can be an NSDictionary, NSArray, or NSData 
 * depending on the call we made.
 *
 * Here we will inspect the parameters property of the returned RDAPIRequest
 * to see what method has returned.
 */
- (void)rdioRequest:(RDAPIRequest *)request didLoadData:(id)data {
    NSString *method = [request.parameters objectForKey:@"method"];
    
    //NSLog(@"request: %@", [request.parameters objectForKey:@"method"]);
    //NSLog(@"data: %@", [data objectAtIndex:0]);
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if([method isEqualToString:@"getTopCharts"]) {
        if(playlists != nil) {
            playlists = nil;
        }
        playlists = [[NSMutableArray alloc] initWithArray:data];
        playlists = data;
        songsToPlay = [[NSMutableArray alloc] initWithCapacity:playlists.count];
        //listsViewController.tableInfo = [[NSMutableArray alloc] initWithCapacity:playlists.count];
        for (int x = 0; x < playlists.count; x++) {
            //NSLog(@"top chart song: %@", [[playlists objectAtIndex:x] objectForKey:@"key"]);
            [songsToPlay addObject:[[playlists objectAtIndex:x] objectForKey:@"key"]];
            
            //[listsViewController.tableInfo addObject:songsToPlay];
        }
        [self determineStreamableSongs];
        //[self getTrackKeysForAlbums];
    } else if([method isEqualToString:@"getPlaylists"]) {
        // we are returned a dictionary but it will be easier to work with an array
        // for our needs

        playlists = [[NSMutableArray alloc] initWithCapacity:[data count]];
        appDelegate.typesInfo = [[NSMutableArray alloc] initWithCapacity:(1000)];
        appDelegate.playlistsInfo = [[NSMutableArray alloc] initWithCapacity:(1000)];
        appDelegate.tracksInfo = [[NSMutableArray alloc] initWithCapacity:(1000)];
        
        int x = 0;
        for(NSString *key in [data allKeys]) {
            [playlists addObject:[data objectForKey:key]];
            //NSLog(@"playlist added: %@", [data objectForKey:key]);
            for (int xy = 0; xy < [[playlists objectAtIndex:x] count]; xy++) {
                [appDelegate.playlistsInfo addObject:[[[playlists objectAtIndex:x] objectAtIndex:xy] objectForKey:@"name"]];
                if (x == 0) {
                    appDelegate.numberOfPlaylistsCollab = [[playlists objectAtIndex:x] count];
                } else if (x == 1) {
                    appDelegate.numberOfPlaylistsOwned = [[playlists objectAtIndex:x] count];
                } else {
                    appDelegate.numberOfPlaylistsSubscr = [[playlists objectAtIndex:x] count];
                }
            }
            for (int y = 0; y < [[playlists objectAtIndex:x] count]; y++) {
                //[listsViewController.playlistsInfo addObject:[[[playlists objectAtIndex:x] objectAtIndex:y] objectForKey:@"name"]];
                for (int z = 0; z < [[[[playlists objectAtIndex:x] objectAtIndex:y] objectForKey:@"trackKeys"] count]; z++) {
                    [appDelegate.tracksInfo addObject:[[[playlists objectAtIndex:x] objectAtIndex:y] objectForKey:@"trackKeys"]];
                }
            }
            x++;
        }
        appDelegate.selectedPlaylistPath = nil;
        for (int i = 0; i < [playlists count]; i++) {
            for(int j = 0; j < [[playlists objectAtIndex:i] count]; j++) {
                if ([[[[playlists objectAtIndex:i] objectAtIndex:j] objectForKey:@"name"] isEqualToString:appDelegate.selectedPlaylist]) {
                    //NSLog(@"I found the right playlist! %d, %d", i, j);
                    //NSLog(@"For reference: %@", appDelegate.selectedPlaylistPath);
                    appDelegate.selectedPlaylistPath = [NSIndexPath indexPathForRow:j inSection:i];
                    //NSLog(@"Then after setting it: %@", appDelegate.selectedPlaylistPath);
                }
            }
        }
        
        if((appDelegate.selectedPlaylistPath == nil && appDelegate.selectedPlaylist != nil) || appDelegate.alarmTime == nil) {
            //alert the user that the playlist could not be found
            [self cancelAutoStart];
            appDelegate.selectedPlaylist = nil;
            
        }
        
        if(appDelegate.selectedPlaylistPath != nil) {
            [self loadSongs];
            [self testToEnableAlarmButton];
        }
        [_loadingView removeFromSuperview];
        //[self loadSongs];
        //[self determineStreamableSongs];
        //[self loadAlbumChoices];
    } else if ([method isEqualToString:@"get"]) {
        //NSLog(@"total number of keys: %d", [data allKeys].count);
        for(NSString *key in [data allKeys]) {
            //NSLog(@"canstream: %@", [[data objectForKey:key] objectForKey:@"canStream"]);
            //[_canBeStreamed addObject:[[data objectForKey:key] objectForKey:@"canStream"]];
            if ([[[data objectForKey:key] objectForKey:@"canStream"] isEqual:[NSNumber numberWithBool:YES]]) {
                [_canBeStreamed addObject:@"YES"];
            } else {
                [_canBeStreamed addObject:@"NO"];
            }
        }
        
    }
}

- (void) loadSongs 
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    if (appDelegate.selectedPlaylistPath != nil && playlists != nil) {
        songsToPlay = [[NSMutableArray alloc] initWithArray:[[[playlists objectAtIndex:appDelegate.selectedPlaylistPath.section] objectAtIndex:appDelegate.selectedPlaylistPath.row] objectForKey:@"trackKeys"]];
        //NSLog(@"section selected: %d, row selected: %d", appDelegate.selectedPlaylistPath.section, appDelegate.selectedPlaylistPath.row);
        songsToPlay = [[[playlists objectAtIndex:appDelegate.selectedPlaylistPath.section] objectAtIndex:appDelegate.selectedPlaylistPath.row] objectForKey:@"trackKeys"];
    } /* else {
        songsToPlay = [[NSMutableArray alloc] initWithArray:[[[playlists objectAtIndex:1] objectAtIndex:1] objectForKey:@"trackKeys"]];
        songsToPlay = [[[playlists objectAtIndex:1] objectAtIndex:1] objectForKey:@"trackKeys"];
    } */
    [self determineStreamableSongs];
}

- (void)rdioRequest:(RDAPIRequest *)request didFailWithError:(NSError*)error {
    
}

@end

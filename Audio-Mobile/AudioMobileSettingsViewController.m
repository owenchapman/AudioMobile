//
//  AudioMobileSettingsViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileSettingsViewController.h"
#import "AudioMobileStyle.h"

@interface AudioMobileSettingsViewController ()

@end

@implementation AudioMobileSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //selectively enable/disable relevant controls and labels based on whether the app is logged into the server or not
    [self adjustViewControlsToLoginState:[[AudioMobileAppDelegate sharedInstance] loggedIn]];
    [[self gpsIntervalControl] setSelectedSegmentIndex:[[AudioMobileAppDelegate sharedInstance] locationTrackingMode]];
    
    //add observer on the login status variable of the app within the app delegate
    [((AudioMobileAppDelegate*)[[UIApplication sharedApplication] delegate]) addObserver:self forKeyPath:@"loggedIn" options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [AudioMobileAppDelegate sharedInstance] && [keyPath isEqualToString:@"loggedIn"]) {
        NSLog(@"logged in status changed");
        id newValue = change[NSKeyValueChangeNewKey];
        id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
        NSLog(@"Old, new, current values for loggedIn: %@, %@, %d",oldValue,newValue,[[AudioMobileAppDelegate sharedInstance] loggedIn]);
        if ([[AudioMobileAppDelegate sharedInstance] loggedIn]) {
            [self adjustViewControlsToLoginState:YES];
        }
        else {
            [self adjustViewControlsToLoginState:NO];
        }
    }
}

-(void) adjustViewControlsToLoginState:(bool) loginState {
    
    [[self publicAudioB] setEnabled:loginState];
    [[self privateAudioB] setEnabled:loginState];
    [[self profileImageThumb] setEnabled:loginState];
    
    if (loginState==YES) {
        [[self loginLogoutButton] setTitle:@"LOGOUT" forState:UIControlStateNormal];
    }
    else {
        [[self loginLogoutButton] setTitle:@"LOGIN" forState:UIControlStateNormal];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark UI control action methods

- (IBAction)setAudioToPublic:(id)sender {
    //change user account settings to public audio
    [self.publicAudioB setTitleColor:AudioMobileGreen forState:UIControlStateNormal];
    [self.privateAudioB setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [[AudioMobileAppDelegate sharedInstance] setPostPrivately:false];

    
    
}
- (IBAction)setAudioToPrivate:(id)sender {
    //change user account settings to private audio
    [self.privateAudioB setTitleColor:AudioMobileGreen forState:UIControlStateNormal];
    [self.publicAudioB setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [[AudioMobileAppDelegate sharedInstance] setPostPrivately:true];
}

- (IBAction)setGpsInterval:(id)sender {
    
    
}

- (IBAction)setAudioType:(id)sender {
}

-(void) setSegmentedControlStyle:(UISegmentedControl*)segmentedControl {
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;

    UIColor *newTintColor = [UIColor colorWithRed: 225/255.0 green:225/255.0 blue:225/255.0 alpha:1.0];
    segmentedControl.tintColor = newTintColor;
    
    NSLog(@"selected segment index is %u",[segmentedControl selectedSegmentIndex]);
    [segmentedControl setSelectedSegmentIndex:[segmentedControl selectedSegmentIndex]];
    [[[segmentedControl subviews] objectAtIndex:[segmentedControl selectedSegmentIndex]] setTintColor:AudioMobileGreen];
    
    
    UISegmentedControl* sender = segmentedControl;
    for (int i=0; i<[sender.subviews count]; i++)
    {
        if ([[sender.subviews objectAtIndex:i] respondsToSelector:@selector(isSelected)] && [[sender.subviews objectAtIndex:i]isSelected])
        {
            [[sender.subviews objectAtIndex:i] setTintColor:AudioMobileGreen];
        }
        if ([[sender.subviews objectAtIndex:i] respondsToSelector:@selector(isSelected)] && ![[sender.subviews objectAtIndex:i] isSelected])
        {
            [[sender.subviews objectAtIndex:i] setTintColor:newTintColor];
        }
    }
    
}

- (IBAction)changeProfileImage:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Info"
                                                    message:@"Please visit the http://audio-mobile.org website to change your profile image."
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Visit Website",nil];
    [alert show];
    
    
//    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    
}

#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==0) {
        NSLog(@"OK");
    }
    else {
        NSLog(@"Visit Website");
        NSURL *url = [NSURL URLWithString:@"http://www.audio-mobile.org"];
        
        if (![[UIApplication sharedApplication] openURL:url]) {
            NSLog(@"Error:  failed to open link to main website.");
        }
    }
}


- (IBAction)showImagePickerForPhotoPicker:(id)sender
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}


- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    [self presentViewController:imagePickerController animated:YES completion:nil];
}


- (IBAction)loginLogout:(id)sender {
    AudioMobileAppDelegate* appD = (AudioMobileAppDelegate*) [[UIApplication sharedApplication] delegate];
    if ([appD loggedIn]) {
        //User is logged in, so log them out
        [[AudioMobileRestAPIManager sharedInstance] logout:self];
        [[AudioMobileAppDelegate sharedInstance] setLoggedIn:false];
    }
    else {
        //User is note yet logged in, so show the login view
        [self performSegueWithIdentifier:@"ShowLoginScreen" sender:self];
    }
}

- (IBAction)returnToStepOne:(UIStoryboardSegue *)segue {
    NSLog(@"And now we are back.");
}

- (IBAction)registerButtonAction:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.audio-mobile.org"];
    
    if (![[UIApplication sharedApplication] openURL:url]) {
        NSLog(@"Error:  failed to open link to main website.");
    }
}

#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [[self profileImageThumb] setImage:image forState:UIControlStateNormal];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)gpsIntervalControlAction:(id)sender {
    
    //set app delegate property and update user defaults.  Any other code interested in the change of value should have placed an observer on the app delegate property
    [[AudioMobileAppDelegate sharedInstance] setLocationTrackingMode:(AMGPSTRACKINGMODE)[sender selectedSegmentIndex]];
    [[NSUserDefaults standardUserDefaults] setInteger:[sender selectedSegmentIndex] forKey:@"LOCATION_TRACKING_MODE"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}



@end
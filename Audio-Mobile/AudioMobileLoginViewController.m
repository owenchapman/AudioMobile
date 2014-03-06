//
//  AudioMobileLoginViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileLoginViewController.h"

@interface AudioMobileLoginViewController ()

@end

@implementation AudioMobileLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self registerForKeyboardNotifications];
    
    //if user has stored password information in the keychain, preload it into the appropriate text fields
    NSString* savedPassword = [[AudioMobileAppDelegate sharedInstance] getSavedPassword];
    NSString* savedUsername =[[AudioMobileAppDelegate sharedInstance] getSavedUsername];
    if (savedPassword) [[self passwordField] setText:savedPassword];
    if (savedUsername) [[self usernameField] setText:savedUsername];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark custom methods

- (IBAction)login:(id)sender {

    UITextField* usernameField = [self usernameField];
    UITextField* passwordField = [self passwordField];
    
    internetReachable = [Reachability reachabilityWithHostname:@"www.audiomobile.org"];
    AudioMobileLoginViewController* this = self;

    // Internet is reachable
    internetReachable.reachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            //                NSLog(@"Yayyy, we have the interwebs!");
            [[AudioMobileRestAPIManager sharedInstance] clearCookies];
            [[AudioMobileRestAPIManager sharedInstance] login:[usernameField text] password:[passwordField text] AndNotify:this];
            
            //save the username and password to the keychain, so users don't need to reload them each time
            [[AudioMobileAppDelegate sharedInstance] keychainSaveUsername:[usernameField text] andPassword:[passwordField text]];
        });
    };
    
    // Internet is not reachable
    internetReachable.unreachableBlock = ^(Reachability*reach)
    {
        // Update the UI on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"No internet access, cannot log in");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Website Inaccessible"
                                                            message:@"Please ensure you are connected to the internet and can access audiomobile.org in order to log in."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    };
    
    [internetReachable startNotifier];
  

    
}
- (IBAction)registerNewAccount:(id)sender {
}

- (IBAction)cancelWithoutLoggingIn:(id)sender {
    [self dismissViewControllerAnimated:true completion:nil];
}
- (IBAction)forgetUsernameAndPassword:(id)sender {
    [[AudioMobileAppDelegate sharedInstance] forgetUsernameAndPassword];
    [[self usernameField] setText:@""];
    [[self passwordField] setText:@""];
    
}

#pragma mark AudioMobileRestAsyncResponseNotifier methods

-(void) loginCompletedWithResult:(AMLOGINSTATUS)loginStatus {
    if (loginStatus == AMLOGINFAIL) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to login, please try again later."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    else if (loginStatus == AMLOGINSUCCESS){
        NSLog(@"Successfully logged into audio-mobile.org server");
        [[AudioMobileAppDelegate sharedInstance] setLoggedIn:true];
        [self dismissViewControllerAnimated:true completion:nil];
        
    }
    else {
        NSLog(@"Unrecognized audio mobile login status %d",loginStatus);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to login."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark UITextFieldDelegate methods, for handling input from title and tag fields

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if ([textField isEqual:[self passwordField]]) {
        //scroll the view up to account for the keyboard, so the password field remains visible
        
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if ([textField isEqual:[self usernameField]]) {

        [[self passwordField] becomeFirstResponder];
    }
    else if ([textField isEqual:[self passwordField]]) {
        [textField resignFirstResponder];
        [self login:self];
    }
    else {
        [textField resignFirstResponder];
    }
    return false;
}

#pragma mark methods for scrolling the view up and down based on keyboard appearance/disappearance; based on example code here:  https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    //TODO figure out why autoscroll code is not working, might be ios7 issue
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    [self containerScrollView].contentInset = contentInsets;
    [self containerScrollView].scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, [self passwordField].frame.origin) ) {
        [[self containerScrollView] scrollRectToVisible:[self passwordField].frame animated:YES];
    }

}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    [self containerScrollView].contentInset = contentInsets;
    [self containerScrollView].scrollIndicatorInsets = contentInsets;
}

@end

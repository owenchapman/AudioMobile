//
//  AudioMobileRecordTabViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileRecordTabViewController.h"
#import "AudioMobileRecordingViewController.h"

@interface AudioMobileRecordTabViewController ()

@end

@implementation AudioMobileRecordTabViewController

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
}

-(void) viewWillAppear:(BOOL)animated {
    if ([self takePictureButton]) {
        [[self view] bringSubviewToFront:[self takePictureButton]];
    }
}

-(void) viewDidAppear:(BOOL)animated {

    if (![[AudioMobileAppDelegate sharedInstance] userHasAcceptedTerms]) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Terms of Use"
                                                        message:@"By clicking here you agree to the terms and conditions"
                                                       delegate:self
                                              cancelButtonTitle:@"Accept"
                                              otherButtonTitles:@"View Terms",nil];
        [alert show];
    }
    
#if !(TARGET_IPHONE_SIMULATOR)
    [self showCameraView];
#endif
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //handle terms of use consent alert view
    if (buttonIndex==0) {
        //user has accepted terms, so update the user defaults appropriately
        [[AudioMobileAppDelegate sharedInstance] userAcceptsTermsOfUse];
    }
    else {
        //user has chosen to view the terms first
        [self performSegueWithIdentifier:@"TermsOfUse" sender:self];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

#pragma mark custom methods

-(void) showCameraView {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePickerController.delegate = self;
    
    [self addChildViewController:imagePickerController];
    [[imagePickerController view] setFrame:[[UIScreen mainScreen] bounds]];
    //we want the image preview view to be below the nav header bar, so we get the navbar's height and then increment the origin's x coordinate down by that much
    CGRect navFrame = [[[self navigationController] navigationBar] frame];
    [[imagePickerController view] setFrame:CGRectMake(0, navFrame.size.height, self.cameraPaneContainerView.frame.size.width, self.cameraPaneContainerView.frame.size.height)];
    imagePickerController.showsCameraControls = NO;
    [imagePickerController setDelegate:self];
    
    [[self cameraPaneContainerView] addSubview:[imagePickerController view]];
    
    [[self cameraPaneContainerView] bringSubviewToFront:[self flashButton]];
    
    if ([self takePictureButton]) {
        [[self cameraPaneContainerView] bringSubviewToFront:[self takePictureButton]];
    }
    
    
    [self setCameraPicker:imagePickerController]; //dealloc old picker controller, if it exists
    //update flash mode to match set mode
    [self setCameraPickerFlashMode:[[NSUserDefaults standardUserDefaults] integerForKey:@"FlashMode"]];
    
}

#pragma mark uiviewcontroller storyboard methods

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if([segue.identifier isEqualToString:@"RecordToRecording"]){
        //the sender will be the image picker's info package, an NSDictionary object which will contain the captured image
        UIImage *image = [self imageToDisplay];
        
        //placeholder image insertion
        if (!image) {
            image = [UIImage imageNamed:@"rainbow_power.png"];
        }
        
        AudioMobileRecordingViewController *destViewController = segue.destinationViewController;
        [destViewController setDisplayImage:image];
        [destViewController.displayImageView setImage: image];
    }
}

-(void) disposeCameraPicker {
    [[[self cameraPicker] view] removeFromSuperview];
    [[self cameraPicker] removeFromParentViewController];
    [self setCameraPicker:nil];
}


#pragma mark uiimagepickercontrollerdelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    //Segue to the recording view
    [self disposeCameraPicker];
    [self setImageToDisplay:[info valueForKey:UIImagePickerControllerOriginalImage]];
    [self performSelector:@selector(segueToRecordingView:) withObject:info afterDelay:0.5];
    
}
-(void) segueToRecordingView:(id) sender {
        [self performSegueWithIdentifier:@"RecordToRecording" sender:sender];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}
- (IBAction)goToSettingsTab:(id)sender {

    NSArray *viewControllers = self.navigationController.viewControllers;
    UIViewController *rootViewController = [viewControllers objectAtIndex:viewControllers.count - 1];
    UITabBarController* tabBar = (UITabBarController*) rootViewController;
    [tabBar setSelectedIndex:3];
}

- (IBAction)cancelRecord:(id)sender {
}

- (IBAction)snapInitialPhoto:(id)sender {
    if ([self cameraPicker]) {
        [[self cameraPicker] takePicture];
    }
    else {
        NSLog(@"photo capture requested but camera is not initialized/set");
    }
}

-(void) setCameraPickerFlashMode:(AMFLASHMODE) newMode {
    if (newMode == AMFLASHMODEAUTO) {
        [self setFlashMode:AMFLASHMODEAUTO];
        [[self flashButton] setTitle:@"Flash: AUTO" forState:UIControlStateNormal];
        [[self cameraPicker] setCameraFlashMode:UIImagePickerControllerCameraFlashModeAuto];
    }
    else if (newMode == AMFLASHMODEON) {
        [self setFlashMode:AMFLASHMODEON];
        [[self flashButton] setTitle:@"Flash: ON" forState:UIControlStateNormal];
        [[self cameraPicker] setCameraFlashMode:UIImagePickerControllerCameraFlashModeOn];
    }
    else if (newMode == AMFLASHMODEOFF){
        [self setFlashMode:AMFLASHMODEOFF];
        [[self flashButton] setTitle:@"Flash: OFF" forState:UIControlStateNormal];
        [[self cameraPicker] setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
    }
    else {
        NSLog(@"Unrecognized flashmode enum value %u passed",newMode);
    }
    [[NSUserDefaults standardUserDefaults] setInteger:newMode forKey:@"FlashMode"];
}

- (IBAction)changeFlashMode:(id)sender {
    if (sender == [self flashButton]) {
        if ([self flashMode] == AMFLASHMODEAUTO) {
            [self setFlashMode:AMFLASHMODEON];
            [[self flashButton] setTitle:@"Flash: ON" forState:UIControlStateNormal];
            [[self cameraPicker] setCameraFlashMode:UIImagePickerControllerCameraFlashModeOn];
            [[NSUserDefaults standardUserDefaults] setInteger:AMFLASHMODEON forKey:@"FlashMode"];
        }
        else if ([self flashMode] == AMFLASHMODEON) {
            [self setFlashMode:AMFLASHMODEOFF];
            [[self flashButton] setTitle:@"Flash: OFF" forState:UIControlStateNormal];
            [[self cameraPicker] setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
            [[NSUserDefaults standardUserDefaults] setInteger:AMFLASHMODEOFF forKey:@"FlashMode"];
        }
        else {
            [self setFlashMode:AMFLASHMODEAUTO];
            [[self flashButton] setTitle:@"Flash: AUTO" forState:UIControlStateNormal];
            [[self cameraPicker] setCameraFlashMode:UIImagePickerControllerCameraFlashModeAuto];
            [[NSUserDefaults standardUserDefaults] setInteger:AMFLASHMODEAUTO forKey:@"FlashMode"];
        }
    }
}

@end

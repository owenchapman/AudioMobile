//
//  AudioMobileRecordingViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileRecordingViewController.h"
#import "AudioMobileDataModel.h"

@interface AudioMobileRecordingViewController ()

@end

@implementation AudioMobileRecordingViewController

NSString* wavRecordingFileName = @"wavRecording.wav";
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
    //add observer for recording timer
    [[AudioMobileAppDelegate sharedInstance] addObserver:self forKeyPath:@"locationTrackingMode" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [AudioMobileAppDelegate sharedInstance] && [keyPath isEqualToString:@"locationTrackingMode"]) {
        NSLog(@"gps interval changed, updating recording location update timer.");
        AMGPSTRACKINGMODE newMode = [[AudioMobileAppDelegate sharedInstance] locationTrackingMode];
        if ([self recording]) {
            //we're recording, so invalidate the current timer and change to the new one, if any
            if ([self locationCaptureIntervalTimer]) [[self locationCaptureIntervalTimer] invalidate];
            //start a new timer with appropriate interval
            [self startLocationUpdateTimerWithInterval:[[[self trackingModeToGPSInterval] objectAtIndex:newMode] doubleValue]];
        }
    }
}

-(void) startLocationUpdateTimerWithInterval:(NSTimeInterval) interval {
    if (interval ==0) {
        NSLog(@"location update interval is 0, which is interpreted as to not update location");
    }
    else {
        [self setLocationCaptureIntervalTimer:[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(captureCurrentLocation:) userInfo:nil repeats:true]];
    }
}

-(void) startAudioRecordingSession {
    [self startRecording];
    
    //setup the timer which will update the time label
    [self setStartDate:[[NSDate date] timeIntervalSince1970]];
    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateTimerLabel:) userInfo:nil repeats:true];
    [self setRecordingTimer:timer];
    
    [self setRecording:true];
    
    return;
    
    bool useFullCaptureSession = false;
    if (useFullCaptureSession) {
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        // Add inputs and outputs.
        [self listAVDevices];
        
        NSArray *devices = [AVCaptureDevice devices];
        
        for (AVCaptureDevice *device in devices) {
            
            NSLog(@"Device name: %@", [device localizedName]);

            if ([device hasMediaType:AVMediaTypeAudio]) {
                NSError *error;
                AVCaptureDeviceInput *input =
                [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
                if (!input) {
                    NSLog(@"Error:  no av capture input for device %@; will not be able create audio recording session.",device);
                }
                
                AVCaptureSession *captureSession = session;
                AVCaptureDeviceInput *captureDeviceInput = input;
                if ([captureSession canAddInput:captureDeviceInput]) {
                    [captureSession addInput:captureDeviceInput];
                }
                else {
                    NSLog(@"Error:  Cannot add device input device %@ to capture session",captureDeviceInput);
                }
            }
        }
        
        [session startRunning];
        [self setCaptureSession:session];
        
    }
    else {
        //Determine temp file to store audio to
        NSString *prefixString = @"NodeAudio";
        
        NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
        NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@.wav", prefixString, guid];
        
        NSURL* imageFileURL = [[[AudioMobileAppDelegate sharedInstance] applicationDocumentsDirectory] URLByAppendingPathComponent:uniqueFileName isDirectory:false];
        
        
        NSString* audioOutputPath = [imageFileURL path];
        NSLog(@"audio recording file path is %@",audioOutputPath);
        NSURL* audioOutputURL = [[NSURL alloc] initFileURLWithPath:audioOutputPath];

        NSError* err;
        NSDictionary* recorderSettingsDict=[[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                              [NSNumber numberWithInt:44100.0],AVSampleRateKey,
                              [NSNumber numberWithInt: 2],AVNumberOfChannelsKey,
                              [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                              [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                              [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                              nil];
        
        AVAudioRecorder* recorder = [[AVAudioRecorder alloc] initWithURL:audioOutputURL settings:recorderSettingsDict error:&err];
        if (err) {
            NSLog(@"error occurred while attempting to initialize audio recorder: %@",err);
        }
        [recorder setDelegate:self];
//            dispatch_async(dispatch_get_main_queue(), ^{
                [self setAudioRecorder:recorder];
//            });
        BOOL recordingPreparedSuccessfully = [recorder prepareToRecord];
        
        if (recordingPreparedSuccessfully) {
            NSLog(@"recording prepared");
        }
        else {
            NSLog(@"Failed to prepare recording");
        }
        
        BOOL recordingStartedSuccessfully = [recorder record];
        
        if (recordingStartedSuccessfully) {
            NSLog(@"recording started");
        }
        else {
            NSLog(@"Failed to start recordings");
        }
    }

}

-(void) captureCurrentLocation:(NSTimer*) locationUpdateIntervalTimer {
    if (!isUpdatingLocation) {
        [self getCurrentLocation]; //this will capture a single location at highest accuracy and then stop location updates
    }
    else {
        NSLog(@"Could not start new location capture because the last new location capture update has not yet returned; will try again the next location update interval, in %f seconds",[locationUpdateIntervalTimer timeInterval]);
    }
}

- (NSArray*) trackingModeToGPSInterval {
    return @[@0.0,@20.0,@10.0,@5.0];
}

-(NSTimeInterval) locationUpdateInterval {
    AMGPSTRACKINGMODE mode = [[AudioMobileAppDelegate sharedInstance] locationTrackingMode];
    return [[[self trackingModeToGPSInterval] objectAtIndex:mode] doubleValue];
}

-(void) startRecording {
    
    AVAudioSession *audioSess = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSess setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audio session error: %@", [[err userInfo] description]);
        return;
    }
    [audioSess setActive:true error:&err];
    err = nil;
    if(err){
        NSLog(@"audio session error: %@", [[err userInfo] description]);
        return;
    }
    
    NSDictionary* audioRecordingSettings = [[NSMutableDictionary alloc] init];
    
    [audioRecordingSettings setValue :[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [audioRecordingSettings setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [audioRecordingSettings setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    [audioRecordingSettings setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [audioRecordingSettings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    [audioRecordingSettings setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    
    NSString *prefixString = @"NodeAudio";
    
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@.wav", prefixString, guid];
    
    NSURL* imageFileURL = [[[AudioMobileAppDelegate sharedInstance] applicationDocumentsDirectory] URLByAppendingPathComponent:uniqueFileName isDirectory:false];
    
    NSString* audioOutputPath = [imageFileURL path];
    NSLog(@"audio recording file path is %@",audioOutputPath);
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath:audioOutputPath];
    
    err = nil;
    AVAudioRecorder* recorder = [[ AVAudioRecorder alloc] initWithURL:url settings:audioRecordingSettings error:&err];
    if(!recorder){
        NSLog(@"recorder: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Error"
                                   message: @"Failed to initialize recording session."
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [alert show];
        return;
    }
    [self setAudioRecorder:recorder];
    //prepare to record
    [recorder setDelegate:self];
    [recorder prepareToRecord];
    recorder.meteringEnabled = YES;
    
    BOOL audioHWAvailable = audioSess.inputIsAvailable;
    if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert =
        [[UIAlertView alloc] initWithTitle: @"Warning"
                                   message: @"Audio input hardware not available.  Cannot record."
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [cantRecordAlert show];
        return;
    }
    [recorder record];
}

- (IBAction)stopRecording:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        // do work here
        if ([self audioRecorder]) {
            
            [[self audioRecorder] stop];
            NSLog(@"stopping recording");
        }
        else {
            NSLog(@"error: no audio recorder to stop");
        }
    });
}

-(void)displayComposerSheetWithAttachement:(NSURL*)fileURL
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:@"Check out this image!"];
    
    // Attach an image to the email
    [picker addAttachmentData:[NSData dataWithContentsOfURL:fileURL] mimeType:@"audio/vnd.wav" fileName:wavRecordingFileName];
    
    // Fill out the email body text
    NSString *emailBody = @"My cool image is attached";
    [picker setMessageBody:emailBody isHTML:NO];
    [self presentModalViewController:picker animated:YES];
}

#pragma mark custom location capture methods


-(void) getCurrentLocation {
    isUpdatingLocation = true;
    // if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                        message:@"You must authorize location services for this application in order to attach location data to a post.  Please authorize location services and try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        if ([self locationCaptureIntervalTimer]) [[self locationCaptureIntervalTimer] invalidate];
        isUpdatingLocation = false;
        [[AudioMobileAppDelegate sharedInstance] removeObserver:self forKeyPath:@"locationTrackingMode"];
        [self dismissViewControllerAnimated:true completion:nil];

        return;
    }
    
    // if locationManager does not currently exist, create it
    if (!_locationManager)
    {
        [self setLocationManager:[[CLLocationManager alloc] init]];
        if ([[self locationManager] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
//            [[self locationManager] requestWhenInUseAuthorization]; //required for ios8+ in order to retrieve
            [[self locationManager] performSelector:@selector(requestWhenInUseAuthorization) withObject:nil];
        }
        [self locationManager].desiredAccuracy = kCLLocationAccuracyBest;
        [_locationManager setDelegate:self];
        _locationManager.distanceFilter = 10.0f; // we don't need to be any more accurate than 10m
        _locationManager.purpose = @"To show nearby nodes and to tag your posts with location information"; //TODO remove deprecated purpose property setting
    }
    
    [_locationManager startUpdatingLocation];
    
}

- (void)startUpdatingCurrentLocation
{
    // if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted )
    {
        return;
    }
    
    // if locationManager does not currently exist, create it
    if (!_locationManager)
    {
        [self setLocationManager:[[CLLocationManager alloc] init]];
        if ([[self locationManager] respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            //            [[self locationManager] requestWhenInUseAuthorization]; //required for ios8+ in order to retrieve
            [[self locationManager] performSelector:@selector(requestWhenInUseAuthorization) withObject:nil];
        }
        [_locationManager setDelegate:self];
        _locationManager.distanceFilter = 10.0f; // we don't need to be any more accurate than 10m
        _locationManager.purpose = @"To show nearby nodes and to tag your posts with location information";
    }
    
    [_locationManager startUpdatingLocation];
    
//    [self showCurrentLocationSpinner:YES];
}

- (void)stopUpdatingCurrentLocation
{
    [_locationManager stopUpdatingLocation];
    
//    [self showCurrentLocationSpinner:NO];
}

- (IBAction)showMidRecordingCameraTakerView:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Placeholder"
                                                    message:@"Tapping this button will bring up a camera preview pane to take additional photos to add to the node being recorded."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (NSMutableArray *)subsequentRecordingTimepoints {
    if (!_subsequentRecordingTimepoints) {
        _subsequentRecordingTimepoints = [[NSMutableArray alloc] init];
    }
    return _subsequentRecordingTimepoints;
}

- (NSMutableArray *)subsequentRecordingLocations {
    if (!_subsequentRecordingLocations) {
        _subsequentRecordingLocations = [[NSMutableArray alloc] init];
    }
    return _subsequentRecordingLocations;
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations  {
    NSLog(@"captured location info");
    if ([locations count]>0) {
        //take the first location and use it as the current location
        CLLocation* currentLocation = [locations objectAtIndex:0];
        
        NSLog(@"location manager returned with %d locations, using the 0 index location",[locations count]);
        if (!isRecordingInitialLocationDetermined) {
            
            [self setRecordingInitialLocation:[currentLocation coordinate]];
            isRecordingInitialLocationDetermined = true;
        }
        else {
            
            [[self subsequentRecordingLocations] addObject:currentLocation];
            [[self subsequentRecordingTimepoints] addObject:[NSDate date]];
            
        }
        //we only need one gps coordinate, manager will be restarted next time a gps coordinate is needed, as per the location update setting chosen by the user.
        [_locationManager stopUpdatingLocation];
        isUpdatingLocation = false;
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    NSLog(@"location manager failed with error %@; Failed to update location %u times",error,[self locationUpdateFailedCount]);
    
    if ([self locationUpdateFailedCount]>3) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to determine location due to error, cannot create new audio node without location information."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        if ([self locationCaptureIntervalTimer]) [[self locationCaptureIntervalTimer] invalidate];
        isUpdatingLocation = false;
        
        //remove observer status
        [[AudioMobileAppDelegate sharedInstance] removeObserver:self forKeyPath:@"locationTrackingMode"];
        [self dismissViewControllerAnimated:true completion:nil];
        return;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    //implement handling of when location authorization changes, probably generate popup warning of decreased functionality without location info.
    NSLog(@"Location authorization changed");
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
    //handle location update pausing
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
    //handle location update resuming
}

#pragma mark MFMailComposerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error  {
    [[AudioMobileAppDelegate sharedInstance] removeObserver:self forKeyPath:@"locationTrackingMode"];
    [controller dismissViewControllerAnimated:true completion:nil];
}

#pragma mark storyboard methods

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"RecordingToPostRecord"]){
        UIImage *image = [self displayImage];
        
        //TODO remove this dummy image insertion
        if (!image) {
            image = [UIImage imageNamed:@"rainbow_power.png"];
        }
        
        AudioMobilePostRecordViewController *destViewController = segue.destinationViewController;
        destViewController.displayImage = image;
        [destViewController.displayImageView setImage: image];
        
        [destViewController setNodeStartLocation:[self recordingInitialLocation]];
        
        //the sender object should be the file url of the wav recording, so set it in the destviewcontroller
        [destViewController setWavFileRecordingURL:(NSURL*)sender];
        [destViewController setRecordingLength:[self recordingLength]];
    }
    else if ([segue.identifier isEqualToString:@"RecordingComplete"]) {
        
    }
}

#pragma mark AVAudioRecorderDelegate methods

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    [[self recordingTimer] invalidate];
    if ([self locationCaptureIntervalTimer]) [[self locationCaptureIntervalTimer] invalidate];
    
    [self setRecording:false];
    
    if (!flag) {
        NSLog(@"audio recordings finished but not successfully");
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle: @"Error"
                                   message: @"Audio recording session did not finish successfully."
                                  delegate: nil
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSLog(@"finished recording to url %@",[recorder url]);
    
    NSDictionary* fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[[recorder url] path] error:nil];
    
    NSLog(@"Size of recorded file: %@",fileAttributes[NSFileSize]);
    
    bool playWaveAfterRecording = false;
    
    if (playWaveAfterRecording) {
        AVAudioPlayer* player = [[AVAudioPlayer alloc] initWithContentsOfURL:[recorder url] error:nil];
        [self setPlayer:player];
        [player setDelegate:self];
        [player play];
    }
    else {
        NSManagedObjectContext* ctxt = [[AudioMobileAppDelegate sharedInstance] managedObjectContext];
        AudioNode1* newNode = [NSEntityDescription insertNewObjectForEntityForName:@"AudioNode1" inManagedObjectContext:ctxt];
        
        NSDate* startDate = [NSDate dateWithTimeIntervalSince1970:[self startDate]];
        [newNode setDate:startDate];
        
        //save this recording for later upload
        NSString *prefixString = @"NodeImage";
        
        NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
        NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@.jpg", prefixString, guid];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *previewImagePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:uniqueFileName];
        NSURL* imageFileURL = [[[AudioMobileAppDelegate sharedInstance] applicationDocumentsDirectory] URLByAppendingPathComponent:uniqueFileName isDirectory:false];
        
        [newNode setImageFileURL:[imageFileURL path]];
        
        // Save image.
        [UIImageJPEGRepresentation([AudioMobileAppDelegate fixrotation:[self displayImage]], 0.25) writeToFile:previewImagePath atomically:YES];
        
        [newNode setAudioFileURL:[[recorder url] path]];
        NSLog(@"setting audio file url to %@",[newNode audioFileURL]);
        [newNode setLongitude:[NSNumber numberWithDouble:[self recordingInitialLocation].longitude]];
        [newNode setLatitude:[NSNumber numberWithDouble:[self recordingInitialLocation].latitude ]];
        
        //if there are subsequent locations, set them
        for (int i=0;i<[[self subsequentRecordingLocations] count];i++) {
             CLLocation* location = [[self subsequentRecordingLocations] objectAtIndex:i];
             LocationVisit* locationVisit = [NSEntityDescription insertNewObjectForEntityForName:@"LocationVisit" inManagedObjectContext:ctxt];
             [locationVisit setTimeVisited:[[self subsequentRecordingTimepoints] objectAtIndex:i]];
             [locationVisit setLatitude:[NSNumber numberWithDouble:[location coordinate].latitude ]];
             [locationVisit setLongitude:[NSNumber numberWithDouble:[location coordinate].longitude ]];
            [newNode addSubsequentLocationsObject:locationVisit];
        }
        
        [newNode setLength:[NSNumber numberWithDouble:[self recordingLength]]];
        
        [[AudioMobileAppDelegate sharedInstance] removeObserver:self forKeyPath:@"locationTrackingMode"]; //need this otherwise we'll get bad access errors the next time locationTrackingMode is updated
        [self.navigationController popToRootViewControllerAnimated:YES];
        NSError* err;
        [ctxt save:&err];
        
        if (err) {
            NSLog(@"Error: Failed to save audio node to offline storage");
        }
        else {
            NSLog(@"Successfully stored audio node offline for later upload");
        }

        NSLog(@"saving recordings with audio and image file paths: %@, %@",[newNode audioFileURL],[newNode imageFileURL]);
        
        [[AudioMobileAppDelegate sharedInstance] setOfflineNodeCount:[[AudioMobileAppDelegate sharedInstance] offlineNodeCount] + 1];
        
        dispatch_queue_t myQueue = dispatch_queue_create([[newNode imageFileURL] UTF8String],NULL);
        dispatch_async(myQueue, ^{
            // Perform long running process
            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the UI
                //indicate that a new entry has been added to the nodes for upload database
            });
        });
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self performSegueWithIdentifier:@"RecordingToPostRecord" sender:[player url]];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Failed to decode sound file");
    if ([self locationCaptureIntervalTimer]) [[self locationCaptureIntervalTimer] invalidate];
    [self performSegueWithIdentifier:@"RecordingToPostRecord" sender:[player url]];
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"finished recording with error");
}

#if TARGET_OS_IPHONE

/* audioRecorderBeginInterruption: is called when the audio session has been interrupted while the recorder was recording. The recorded file will be closed. */
- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
    
}

/* audioRecorderEndInterruption:withOptions: is called when the audio session interruption has ended and this recorder had been interrupted while recording. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags NS_AVAILABLE_IOS(6_0) {
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags NS_DEPRECATED_IOS(4_0, 6_0) {
}

/* audioRecorderEndInterruption: is called when the preferred method, audioRecorderEndInterruption:withFlags:, is not implemented. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder NS_DEPRECATED_IOS(2_2, 6_0) {
    
}

#endif // TARGET_OS_IPHONE

-(void) listAVDevices {
    NSArray *devices = [AVCaptureDevice devices];
    
    for (AVCaptureDevice *device in devices) {
        
        NSLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                NSLog(@"Device position : back");
            }
            else {
                NSLog(@"Device position : front");
            }
        }
    }
}



-(void) viewWillAppear:(BOOL)animated {
    if ([ self displayImage]) {
        [[self displayImageView] setImage:[self displayImage]];
    }
    else {
        NSLog(@"no image to display, using");
        [[self displayImageView] setImage:[UIImage imageNamed:@"rainbow_power.png"]];
    }
    if (![self recording]) {
        [self performSelectorOnMainThread:@selector(startAudioRecordingSession) withObject:nil waitUntilDone:true];
        //start capturing location info
        [self getCurrentLocation];
        [self startLocationUpdateTimerWithInterval:[[[self trackingModeToGPSInterval] objectAtIndex:[[AudioMobileAppDelegate sharedInstance] locationTrackingMode]] doubleValue]];
    }

}

-(void) startAudioRecordingOnMainThread {

}

-(void) viewWillDisappear:(BOOL)animated {
    //end capturing of location info
    [self stopUpdatingCurrentLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

#pragma mark dynamic display handling methods

-(void) updateTimerLabel:(NSTimer*)theTimer {
    NSTimeInterval elapsedSeconds = [[NSDate date] timeIntervalSince1970] - [self startDate];
    [self setRecordingLength:elapsedSeconds];
    
    NSUInteger m = (int)(elapsedSeconds / 60.0) % (int)60.0;
    NSUInteger s = (int)elapsedSeconds % (int)60;
    
    NSString *formattedTime = [NSString stringWithFormat:@"%02u:%02u", m, s];
    [[self timerLabel] setText:formattedTime];
}

@end

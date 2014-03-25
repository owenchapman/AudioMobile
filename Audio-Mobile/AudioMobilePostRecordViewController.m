//
//  AudioMobilePostRecordViewController.m
//  Audio-Mobile
//
//

#import "AudioMobilePostRecordViewController.h"

@interface AudioMobilePostRecordViewController ()

@end

@implementation AudioMobilePostRecordViewController

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
	// Do any additional setup after loading the view.
    
    //begin encoding the recording to ogg vorbis format
    AudioMobileOggVorbisEncoder* oggVorbisEncoder = [[AudioMobileOggVorbisEncoder alloc] init];
    [oggVorbisEncoder setDelegate:self];
    [self setEncoder:oggVorbisEncoder];
    
    if (![self wavFileRecordingURL]) {
        NSLog(@"No wave file specified to encode");
        return;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    NSString* oggVorbisFileURLPath = [NSString pathWithComponents:@[basePath,@"vorbisForUpload.ogg"]];
    NSLog(@"ogg file path is %@",oggVorbisFileURLPath);
    NSURL* oggVorbisFileURL = [[NSURL alloc] initFileURLWithPath:oggVorbisFileURLPath];
    
    [self setOggVorbisFileRecordingURL:oggVorbisFileURL];
    
    //create background queue on which to run ogg vorbis encoding
    dispatch_queue_t myQueue = dispatch_queue_create("EncoderQueue",NULL);
    
    dispatch_async(myQueue, ^{
        // Perform long running process
        [oggVorbisEncoder encodeWav:[self wavFileRecordingURL] toOggVorbisDestination:oggVorbisFileURL];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            NSLog(@"ogg encoder completed");

        });
    });
    
    //read existing title and note information from item
    AudioNode1* offlineNode = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
    if ([offlineNode title]) {
        [[self titleTextField] setText:[offlineNode title]];
    }
    
    if ([offlineNode notes]) {
        [[self notesTextField] setText:[offlineNode notes]];
    }
    
    if ([offlineNode locationDescription]) {
        [[self locationDescriptionField] setText:[offlineNode locationDescription]];
    }
    
    bool postPrivately = [[AudioMobileAppDelegate sharedInstance] postPrivately];
    if ([offlineNode private]) {
        postPrivately = true;
    }
    [[self publicPrivateControl] setSelectedSegmentIndex:postPrivately?1:0];
    
    if ([offlineNode weatherCode]) {
        for(int i=0;i<[self segmentToWeatherMap].count;i++) {
            if ([[offlineNode weatherCode] isEqualToString:([self segmentToWeatherMap][i][@"tid"])]) {
                [[self weatherControl] setSelectedSegmentIndex:i];
                [self selectWeatherWithIndex:i updateOfflineRecord:false];
                break;

            }
        }
    }
    
    [[self displayImageView] setAlpha:0.5];
    
}

- (IBAction)cancelNodeCreation:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Audio Node?"
                                                    message:@"Cannot be undone.  Are you sure? "
                                                   delegate:self
                                          cancelButtonTitle:@"No, continue."
                                          otherButtonTitles:@"Yes, delete.",nil];
    [self setDeleteNodeDialog:alert];
    [alert show];
}

#pragma mark UIAlertView delegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView == [self deleteNodeDialog]) {
        if (buttonIndex ==0) {
            //user wants to continue node creation
            return;
        }
        else {
            //they want to cancel, so pop back to the root view controller after deleting this node
            [[AudioMobileAppDelegate sharedInstance] deleteOfflineNodeAt:[self offlineNodeIndex]];
            [self.navigationController popToRootViewControllerAnimated:true];
        }
        
    }
    else if (alertView == [self changeImageDialog]) {
        //0 is cancel
        if (buttonIndex == 1) { //take new picture
            [self openCameraPickerToChangeImage:false]; //
        }
        else if (buttonIndex == 2) { //from camera roll
            [self openCameraPickerToChangeImage:true];
        }
    }
}

-(void) openCameraPickerToChangeImage:(BOOL) fromCameralRoll {
    NSLog(@"User has chosen to grab new picture.  From camera roll? %@",fromCameralRoll?@"YES":@"NO");
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.mediaTypes = @[(NSString *)kUTTypeImage];
    if (fromCameralRoll) {
        pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    else {
        pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    }

    pickerController.delegate = self;
    
    [self setImagePicker:pickerController];
    [self presentViewController:pickerController
                       animated:YES
                     completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [picker dismissViewControllerAnimated:true completion:^{
        
    }];
    
    NSLog(@"image picker returned");
    UIImage* newImage = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    NSURL* newImageURL = [AudioMobileAppDelegate generateUniqueFileURLWithPrefix:@"NodeImage" andExtension:@"jpg"];
    
    [UIImageJPEGRepresentation([AudioMobileAppDelegate fixrotation:newImage], 0.25) writeToFile:[newImageURL path] atomically:YES];
    
    
    //update our audio node record with the new image
    NSError* err;
    NSManagedObjectContext* ctxt = [[AudioMobileAppDelegate sharedInstance] managedObjectContext];
    
    AudioNode1* nodeToUpdate = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex] withContext:ctxt];
    
    NSLog(@"current image url for offline node is %@",[nodeToUpdate imageFileURL]);
    [nodeToUpdate setImageFileURL:[newImageURL path]];
    NSLog(@"updated image url for offline node is %@",[nodeToUpdate imageFileURL]);
    [self setDisplayImage:newImage];
    [[self displayImageView] setImage:newImage];
    
    [ctxt save:&err];
    if (err) {
        NSLog(@"Error: Failed to save updated image url to offline storage");
    }
    else {
        NSLog(@"Successfully stored updated image url");
    }
    [self setImagePicker:nil];
}

-(void) changeNodeImageInternal:(UIImage*) newImage {
    
    
}

-(void) encodingCompletedWithStatus:(AMENCODINGSTATUS)status {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update the UI
        NSLog(@"ogg encoder completed");
        if (status == AMENCODINGSUCCESS) {
            [[self progressStatusLabel] setText:@"Ready for Upload"];
            [[self progressIndicator] setHidden:true];
            [[self uploadButton] setEnabled:true];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"File preparation failed."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [[self progressStatusLabel] setText:@"Cannot upload."];
            [[self progressIndicator] setHidden:true];
        }
        
    });
    
}

-(void) viewWillAppear:(BOOL)animated {
    if ([ self displayImage]) {
        [[self displayImageView] setImage:[self displayImage]];
    }
    else {
        NSLog(@"no image to display");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITextFieldDelegate methods, for handling input from title and tag fields
- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return false;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSError* err;
    //update our locally saved copy of node record with the text field data
    if (textField == [self titleTextField]) {
        //update our audio node appropriately
        AudioNode1* nodeToUpdate = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
        [nodeToUpdate setTitle:[[self titleTextField] text]];
        [[[AudioMobileAppDelegate sharedInstance] managedObjectContext] save:&err];
    }
    else if (textField == [self notesTextField]) {
        //update our audio node appropriately
        AudioNode1* nodeToUpdate = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
        [nodeToUpdate setNotes:[[self notesTextField] text]];
        [[[AudioMobileAppDelegate sharedInstance] managedObjectContext] save:&err];
    }
    else if (textField == [self locationDescriptionField]) {
        //update our audio node appropriately
        AudioNode1* nodeToUpdate = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
        [nodeToUpdate setLocationDescription:[[self locationDescriptionField] text]];
        [[[AudioMobileAppDelegate sharedInstance] managedObjectContext] save:&err];
    }
    if (err) {
        NSLog(@"Failed to set notes or title property for offline node record due to error: %@",err);
    }
    
    [textField resignFirstResponder];
}

- (IBAction)saveNode:(id)sender {
    
    if ([[[self titleTextField] text] isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Entitle"
                                                        message:@"Please choose a name for your recording in order to upload."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        
        [[self titleTextField] becomeFirstResponder];
    }
    else {
        
        //verify user is logged in before uploading
        if (![[AudioMobileAppDelegate sharedInstance] loggedIn]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Log In"
                                                            message:@"Please Login to your Audio Mobile account in order to upload."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            [self performSegueWithIdentifier:@"PostRecordToLogin" sender:self];
            
        }
        else {
            //upload node

            NSData *imgData = UIImageJPEGRepresentation([self displayImage], 0.1); // 1 is compression quality
            // Identify the home directory and file name
            NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/ImageToUpload.jpg"];
            NSURL* imageFileOnDiskURL = [[NSURL alloc] initFileURLWithPath:jpgPath];
            
            // Write the file.  Choose YES atomically to enforce an all or none write. Use the NO flag if partially written files are okay which can occur in cases of corruption
            [imgData writeToFile:jpgPath atomically:YES];
            
            NSError* __block err;
            
            NSString* notes = [[self notesTextField] text];
            
            AudioNode1* offlineNode = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
            NSDate* recordingDate = [offlineNode date];
            NSString* locationDescription = [[self locationDescriptionField] text];
            
            //add an activity indicator to the view and start it
            UIActivityIndicatorView* actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [actInd setFrame:self.view.frame];
            [[self view] addSubview:actInd];
            [actInd startAnimating];
            [self setActivityIndicator:actInd];
            
            CLLocationCoordinate2D recordingLocation = CLLocationCoordinate2DMake([[offlineNode latitude] doubleValue], [[offlineNode longitude] doubleValue]);
            
            NSSet* subsequentLocations = [offlineNode subsequentLocations];

            bool postPrivately = [[self publicPrivateControl] selectedSegmentIndex]==1;
            dispatch_queue_t myQueue = dispatch_queue_create("FeaturedItemRetrievalQueue",NULL);
            dispatch_async(myQueue, ^{
                [[AudioMobileRestAPIManager sharedInstance] uploadNode:[NSString stringWithFormat:AMDEVMODE?@"DevNode01-%@":@"%@",[[self titleTextField] text]] notes:notes imageFile:imageFileOnDiskURL audioFile:[self oggVorbisFileRecordingURL] recordingLength:33 weather:[((NSDictionary*)[[self segmentToWeatherMap] objectAtIndex:[[self weatherControl] selectedSegmentIndex]]) objectForKey:@"name"]   geodata:recordingLocation secondaryGeodata:subsequentLocations subsequentLocationTimepoints:nil private:postPrivately date:recordingDate locationDescription:locationDescription error:&err notify:self];

            });
        }
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//    PostRecordToPlayback
    if([segue.identifier isEqualToString:@"PostRecordToPlayback"]){
        //set item data for playback view
        
        UIImage* nodeMainImage = [self displayImage];
        AudioMobilePlaybackViewController* destViewController = segue.destinationViewController;
        [destViewController setNodeImage:nodeMainImage];
        
        // Save image.
        [destViewController setNodeImage:[self displayImage]];
        
        NSString* username =[[AudioMobileRestAPIManager sharedInstance] userName];
        if (!username) username = @"anonymous";
        
        //retrieve the creator thumbnail
        NSDictionary* infoDict = @{@"title":[[self titleTextField] text],
                                   @"audio":[[self oggVorbisFileRecordingURL] absoluteString],
                                   @"author uid":[[NSNumber numberWithInteger:[[AudioMobileRestAPIManager sharedInstance] uid]] stringValue],
                                   @"name":username,
//                                   @"image":[previewImageURL absoluteString]
                                   @"isPreview":@true
                                   };
        
        
        [destViewController setItemInfo:infoDict];
        [destViewController setTitle:[[self titleTextField] text]];
    }
}

-(NSArray*) segmentToWeatherMap {
    if (!_segmentToWeatherMap) {
        _segmentToWeatherMap = @[@{@"name":@"sunny",@"imageView":[self sunnyImage],@"tid":@"11"},
                                 @{@"name":@"rainy",@"imageView":[self rainyImage],@"tid":@"15"},
                                 @{@"name":@"windy",@"imageView":[self windyImage],@"tid":@"13"},
                                 @{@"name":@"cold",@"imageView":[self coldImage],@"tid":@"17"},
                                 @{@"name":@"hot",@"imageView":[self hotImage],@"tid":@"16"}];
    }
    return _segmentToWeatherMap;
}

- (IBAction)weatherValueChanged:(id)sender {
    NSLog(@"Weather Value Changed");
    //determine which item is now selected
    NSInteger selectedWeatherIndex = [[self weatherControl] selectedSegmentIndex];
    for(NSInteger i=0;i<[[self segmentToWeatherMap] count];i++) {
        if (i==selectedWeatherIndex) {
            [((UIImageView*)([self segmentToWeatherMap][i][@"imageView"])) setAlpha:1.0];
            //update the offline record for this node in the database to reflect the new weather value
            AudioNode1* offlineNode = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
            [offlineNode setWeatherCode:[self segmentToWeatherMap][i][@"tid"] ];
            
            NSError* err;
            [[[AudioMobileAppDelegate sharedInstance] managedObjectContext] save:&err];
            if (err) {
                NSLog(@"Error:  Failed to save new weather code to offline database");
            }
        }
        else {
            [((UIImageView*)([self segmentToWeatherMap][i][@"imageView"])) setAlpha:0.7];
        }
    }
    
}

-(void) selectWeatherWithIndex:(NSUInteger) selectedWeatherIndex updateOfflineRecord:(BOOL) updateOfflineRecord {
    for(NSInteger i=0;i<[[self segmentToWeatherMap] count];i++) {
        if (i==selectedWeatherIndex) {
            [((UIImageView*)([self segmentToWeatherMap][i][@"imageView"])) setAlpha:1.0];
            //update the offline record for this node in the database to reflect the new weather value
            if (updateOfflineRecord) {
                AudioNode1* offlineNode = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
                [offlineNode setWeatherCode:[self segmentToWeatherMap][i][@"tid"] ];
                
                NSError* err;
                [[[AudioMobileAppDelegate sharedInstance] managedObjectContext] save:&err];
                if (err) {
                    NSLog(@"Error:  Failed to save new weather code to offline database");
                }
            }
        }
        else {
            [((UIImageView*)([self segmentToWeatherMap][i][@"imageView"])) setAlpha:0.7];
        }
    }
}

- (IBAction)previewRecording:(id)sender {
    [self performSegueWithIdentifier:@"PostRecordToPlayback" sender:self];
}

#pragma mark AudioMobileRestAsyncResponseNotifier delegate methods

-(void) uploadCompletedWithResult:(AMUPLOADSTATUS)uploadStatus {
    if ([self activityIndicator]) [[self activityIndicator] stopAnimating];
    
    if (uploadStatus == AMUPLOADFAIL) {
        NSLog(@"upload of node failed");
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Failed"
                                                            message:@"An error occurred uploading to the server, please try again later."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        });
    }
    else {
        NSLog(@"upload of node succeeded");
        dispatch_async(dispatch_get_main_queue(), ^{
            //delete the entry in the offline recording database for this node
            [[AudioMobileAppDelegate sharedInstance] deleteOfflineNodeAt:[self offlineNodeIndex]];
            
            //update the database size recording, so other views can update accordingly
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Complete"
                                                            message:@"Your node has been uploaded to the server."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [self.navigationController popToRootViewControllerAnimated:YES];

        });
    }

}

- (IBAction)emailAudioNode:(id)sender {
    
    AudioNode1* nodeToUpdate = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
    [self displayComposerSheetWithAttachements:[nodeToUpdate imageFileURL] andAudio:[nodeToUpdate audioFileURL]];
}

-(void)displayComposerSheetWithAttachements:(NSString*)imageFilePath andAudio:(NSString*)audioFilePath
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    [picker setSubject:@"Check out this image!"];
  
    [picker addAttachmentData:[NSData dataWithContentsOfFile:imageFilePath] mimeType:@"image/jpeg" fileName:@"image.jpg"];
    
    [picker addAttachmentData:[NSData dataWithContentsOfFile:audioFilePath] mimeType:@"audio/ogg" fileName:@"audio.ogg"];
    
    NSString *emailBody = @"Here is some audio I recorded using AudioMobile, encoded as an <a href=\"http://www.vorbis.com/\">ogg vorbis</a> file. <p>For more details on the AudioMobile project and to download our free iOS recording app, visit <a href=\"http://audio-mobile.org\">audio-mobile.org</a>.";
    [picker setMessageBody:emailBody isHTML:YES];
    if ([[self titleTextField] text] && [[[self titleTextField] text] length]>0) {
        [picker setSubject:[NSString stringWithFormat:@"'%@' Audio recording from AudioMobile",[[self titleTextField] text]]];
    }
    else {
        [picker setSubject:@"Audio recording from AudioMobile"];
    }
    
    [self presentViewController:picker
                       animated:YES
                     completion:NULL];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    NSLog(@"Mail composer result was %d",result);
    [self dismissViewControllerAnimated:true completion:nil];
}

- (IBAction)changeNodeImage:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choose New Image"
                                                    message:@"Would you like to take a new picture or choose from your camera roll?"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Take Picture",@"Choose Existing",nil];
    [self setChangeImageDialog:alert];
    [alert show];
}

- (IBAction)publicPrivateControlAction:(id)sender {
    if (sender == [self publicPrivateControl]) {
        //update our audio node appropriately
        AudioNode1* nodeToUpdate = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineNodeIndex]];
        [nodeToUpdate setPrivate:[[self publicPrivateControl] selectedSegmentIndex]==0?false:true];
        NSError* err;
        [[[AudioMobileAppDelegate sharedInstance] managedObjectContext] save:&err];
        if (err) {
            NSLog(@"Failed to set public/private status of offline node due to error: %@",err);
        }
    }
    
}

- (IBAction)repositionNodeAction:(id)sender {
    [self performSegueWithIdentifier:@"DetailsToReposition" sender:self];
    
}

@end

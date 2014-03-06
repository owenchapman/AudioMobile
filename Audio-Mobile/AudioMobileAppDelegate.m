//
//  AudioMobileAppDelegate.m
//  Audio-Mobile
//
//

#import "AudioMobileAppDelegate.h"

@implementation AudioMobileAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Register the standard defaults early.
    NSDictionary *appDefaults = @{@"TermsAndConditionsAccepted":@false,
                                  @"LOCATION_TRACKING_MODE":[NSNumber numberWithInt:AMGPSTRACKINGMODEFIXED]};
    [[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
    
    //initialize app wide properties from defaults
    [self setLocationTrackingMode:[[NSUserDefaults standardUserDefaults] integerForKey:@"LOCATION_TRACKING_MODE"]];
    
    
    //initialize URL cache
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:4 * 1024 * 1024
                                                         diskCapacity:20 * 1024 * 1024
                                                             diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    
    
    //Set the title bar color and font
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.45   green:0.75	 blue:0.26	 alpha:1.0]];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackTranslucent];

    //ensures the status bar is still visible in our record tab view
    [[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
    
    self.window.backgroundColor = [UIColor colorWithRed:(20.0/255) green:(20.0/255) blue:(20.0/255) alpha:1.0];
    
    [[UITabBar appearance] setSelectedImageTintColor:[UIColor colorWithRed:(87/255.0) green:(163/255.0) blue:(47/255.0) alpha:1.0]];
    
    //initialize a background queue on which we will request remote image data so it doesn't stall the main thread
    [self setImageRequestQueue:dispatch_queue_create("ImageRequestQueue", NULL)];
    
    //initialize keychain item for securely storing storing AudioMobile username and password
    self.keychainItem = [[KeychainItemWrapper alloc] initWithIdentifier:@"AudioMobileKeychainItem" accessGroup:nil];
    
    //attempt to log into server if we have saved username and password information in the keychain
    NSString* keychainSavedAMUsername =[self getSavedUsername];
    NSString* keychainSavedAMPassword = [self getSavedPassword];
    if (keychainSavedAMPassword && keychainSavedAMUsername) {
        [[AudioMobileRestAPIManager sharedInstance] clearCookies];
        [[AudioMobileRestAPIManager sharedInstance] login:keychainSavedAMUsername password:keychainSavedAMPassword AndNotify:self];
    }

    //determine number of offline nodes saved
    NSManagedObjectContext* ctxt = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"AudioNode1" inManagedObjectContext:ctxt]];
    
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [ctxt countForFetchRequest:request error:&err];
    if(count == NSNotFound) {
        //Handle error
        NSLog(@"Failed to determine count of AudioNode's stored offline for later upload");
    }
    else {
        NSLog(@"We have %u nodes waiting offline for upload to the server",count);
        [self setOfflineNodeCount:count];
    }
    
    return YES;
}

-(NSUInteger) queryOfflineNodeCount {
    NSManagedObjectContext* ctxt = [self managedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"AudioNode1" inManagedObjectContext:ctxt]];
    
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [ctxt countForFetchRequest:request error:&err];
    if(count == NSNotFound) {
        //Handle error
        NSLog(@"Failed to determine count of AudioNode's stored offline for later upload");
        return 0;
    }
    else {
        return count;
    }
}

-(void) deleteOfflineNodeAt:(NSUInteger) index {
    NSManagedObjectContext* ctxt = [[AudioMobileAppDelegate sharedInstance] managedObjectContext];
    
    AudioNode1* nodeToDelete = [self getOfflineNodeAtIndex:index withContext:ctxt];
    if ([nodeToDelete audioFileURL]) {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:[nodeToDelete audioFileURL]] error:nil];
    }
    if ([nodeToDelete imageFileURL]) {
        [[NSFileManager defaultManager] removeItemAtURL:[NSURL fileURLWithPath:[nodeToDelete imageFileURL]] error:nil];
    }

    [ctxt deleteObject:nodeToDelete];
    [self setOfflineNodeCount:[self offlineNodeCount]-1];
    
    NSError* err;
    [ctxt save:&err];
    if (err) {
        NSLog(@"Failed to delete offline node due to error %@", [err localizedDescription]);
    }
}

-(AudioNode1*) getOfflineNodeAtIndex:(NSUInteger) index withContext:(NSManagedObjectContext*)ctxt {
    NSSortDescriptor *sortDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"date"
                                ascending:NO];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"AudioNode1" inManagedObjectContext:ctxt];
    request.fetchBatchSize = 100;
    request.fetchLimit = 1000;
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError* err = nil;
    
    NSArray *results = [ctxt executeFetchRequest:request error:&err];
    
    NSLog(@"Number of results in offline nodes table: %u",[results count]);
    
    if (err) {
        NSLog(@"Error attempting to fetch audionode entries from database: %@",err);
        return nil;
    }
    else if ([results count] <= index) {
        NSLog(@"Error: not enough entries in database to retrieve one with index %u",index);
        return nil;
    }
    else {
        return [results objectAtIndex:index];
    }

}

-(AudioNode1*) getOfflineNodeAtIndex:(NSUInteger) index {
    NSManagedObjectContext* ctxt = [[AudioMobileAppDelegate sharedInstance] managedObjectContext];
    return [self getOfflineNodeAtIndex:index withContext:ctxt];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//            abort();
        }
    }
}

#pragma mark AudioMobileRestAsyncResponseNotifier methods

-(void) loginCompletedWithResult:(AMLOGINSTATUS)loginStatus {
    if (loginStatus == AMLOGINSUCCESS) {
        NSLog(@"successfully logged in to AM server upon app startup");
        [self setLoggedIn:true];
    }
    else {
        NSLog(@"failed to log in to AM server upon app startup");
        [self setLoggedIn:false];
    }
}

#pragma mark custom methods

-(NSString*) getSavedPassword {
    
    return [[self keychainItem] objectForKey:(__bridge id)kSecValueData];
}

-(NSString*) getSavedUsername {
    return [[self keychainItem] objectForKey:(__bridge id)kSecAttrAccount];
}

-(void) keychainSaveUsername:(NSString*) username andPassword:(NSString*)password {
    [[self keychainItem] resetKeychainItem]; //delete old values
    [[self keychainItem] setObject:password forKey:(__bridge id)kSecValueData];
    [[self keychainItem] setObject:username forKey:(__bridge id)kSecAttrAccount];
}

-(void) forgetUsernameAndPassword {
    [[self keychainItem] resetKeychainItem]; //delete old values
}


//takes an AudioMobile url and returns a url for a thumbnail version of that image at one of the preset scales
+(NSURL*) getURLOfImage:(NSURL*)originalURL atScale:(AMIMAGESCALE)scale {

    //determine proper path component for specified scale
    NSString* scalePathComponent = nil;
    switch (scale) {
        case AMIMAGESCALETHUMBNAIL:
            scalePathComponent = @"thumbnail";
            break;
        case AMIMAGESCALEMEDIUM:
            scalePathComponent = @"medium";
            break;
        case AMIMAGESCALELARGE:
            scalePathComponent = @"large";
            break;
        case AMIMAGESCALEI5:
            scalePathComponent = @"i5";
            break;
            
        default:
            NSLog(@"ERROR Invalid scale enum value %d specified for original image url %@ ",scale,originalURL);
            return originalURL;
    }
    
    NSArray* pathComponents = [originalURL pathComponents];
    NSLog(@"protocol: %@",[originalURL scheme] );
    NSLog(@"host: %@",[originalURL host] );

    NSMutableArray* thumbnailPathComponents = [NSMutableArray arrayWithArray:pathComponents];
    if ([thumbnailPathComponents count]>=2) {
        [thumbnailPathComponents insertObject:@"styles" atIndex:[thumbnailPathComponents count]-1];
        [thumbnailPathComponents insertObject:scalePathComponent atIndex:[thumbnailPathComponents count]-1];
        [thumbnailPathComponents insertObject:@"public" atIndex:[thumbnailPathComponents count]-1];
        
    }
    
    NSURL* thumbnailURL = [[NSURL alloc] initWithScheme:[originalURL scheme] host:[originalURL host] path:[thumbnailPathComponents componentsJoinedByString:@"/"]];
    
    
    return thumbnailURL;
}





-(NSMutableDictionary*) urlImageCache {
    @synchronized (self) {
        if (!_urlImageCache) {
            _urlImageCache = [[NSMutableDictionary alloc] initWithCapacity:10];
        }
    }
    return _urlImageCache;

}

//convenience method to retrieve the current application's instance of the app delegate

+(AudioMobileAppDelegate*) sharedInstance {
    //verification code to ensure class is correct, just in case this method is used in another application
    id<UIApplicationDelegate> audioMobileAppDelegate = [[UIApplication sharedApplication] delegate];
    if ([audioMobileAppDelegate isKindOfClass:[AudioMobileAppDelegate class]]) {
        return (AudioMobileAppDelegate*)[[UIApplication sharedApplication] delegate];
    }
    else {
        return nil;
    }

}

#pragma mark Explicitly write Core Data accessors

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSLog(@"Need to create new context for call");
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Model.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

+(NSURL*) generateUniqueFileURLWithPrefix:(NSString*) prefix  andExtension:(NSString*) extension{
    NSString *prefixString = prefix;
    
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString] ;
    //        NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@.png", prefixString, guid];
    NSString *uniqueFileName = [NSString stringWithFormat:@"%@_%@.%@", prefixString, guid,extension];
    
    
    NSLog(@"uniqueFileName: '%@'", uniqueFileName);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *previewImagePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:uniqueFileName];
    NSURL* imageFileURL = [NSURL fileURLWithPath:previewImagePath];
    return imageFileURL;
}

+ (UIImage *)fixrotation:(UIImage *)rotatedImage{
    
    
    if (rotatedImage.imageOrientation == UIImageOrientationUp)return rotatedImage;
    CGAffineTransform affineTransform = CGAffineTransformIdentity;
    
    switch (rotatedImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            affineTransform = CGAffineTransformTranslate(affineTransform, rotatedImage.size.width, rotatedImage.size.height);
            affineTransform = CGAffineTransformRotate(affineTransform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            affineTransform = CGAffineTransformTranslate(affineTransform, rotatedImage.size.width, 0);
            affineTransform = CGAffineTransformRotate(affineTransform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            affineTransform = CGAffineTransformTranslate(affineTransform, 0, rotatedImage.size.height);
            affineTransform = CGAffineTransformRotate(affineTransform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (rotatedImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            affineTransform = CGAffineTransformTranslate(affineTransform, rotatedImage.size.width, 0);
            affineTransform = CGAffineTransformScale(affineTransform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            affineTransform = CGAffineTransformTranslate(affineTransform, rotatedImage.size.height, 0);
            affineTransform = CGAffineTransformScale(affineTransform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL, rotatedImage.size.width, rotatedImage.size.height,
                                             CGImageGetBitsPerComponent(rotatedImage.CGImage), 0,
                                             CGImageGetColorSpace(rotatedImage.CGImage),
                                             CGImageGetBitmapInfo(rotatedImage.CGImage));
    CGContextConcatCTM(context, affineTransform);
    switch (rotatedImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(context, CGRectMake(0,0,rotatedImage.size.height,rotatedImage.size.width), rotatedImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(context, CGRectMake(0,0,rotatedImage.size.width,rotatedImage.size.height), rotatedImage.CGImage);
            break;
    }
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    UIImage *fixedImage = [UIImage imageWithCGImage:cgImage];
    CGContextRelease(context);
    CGImageRelease(cgImage);
    return fixedImage;
    
}

-(BOOL) userHasAcceptedTerms {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"TermsAndConditionsAccepted"];
}

-(void) userAcceptsTermsOfUse {
    [[NSUserDefaults standardUserDefaults] setBool:true forKey:@"TermsAndConditionsAccepted"];
}


+ (UIImage *) convertToGreyscale:(UIImage *)originalImage {
    
    int kRed = 1;
    int kGreen = 2;
    int kBlue = 4;
    
    int colors = kGreen;
    int originalImageWidth = originalImage.size.width;
    int originalImageHeight = originalImage.size.height;
    
    uint32_t *imageBuf = (uint32_t *) malloc(originalImageWidth * originalImageHeight * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(imageBuf, originalImageWidth, originalImageHeight, 8, originalImageWidth * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextSetShouldAntialias(context, NO);
    
    CGContextDrawImage(context, CGRectMake(0, 0, originalImageWidth, originalImageHeight), [originalImage CGImage]);
    
    CGContextRelease(context);
    
    CGColorSpaceRelease(colorSpace);
    
    uint8_t *greyscaleImageData = (uint8_t *) malloc(originalImageWidth * originalImageHeight);
    for(int y = 0; y < originalImageHeight; y++) {
        for(int x = 0; x < originalImageWidth; x++) {
            uint32_t pixel=imageBuf[y*originalImageWidth+x];
            uint32_t sum=0,count=0;
            if (colors & kRed) {sum += (pixel>>24)&255; count++;}
            if (colors & kGreen) {sum += (pixel>>16)&255; count++;}
            if (colors & kBlue) {sum += (pixel>>8)&255; count++;}
            greyscaleImageData[y*originalImageWidth+x]=sum/count;
        }
    }

    uint8_t *result = (uint8_t *) calloc(originalImageWidth * originalImageHeight *sizeof(uint32_t), 1);
    
    uint8_t *rgbResult = (uint8_t *) imageBuf;
    
    for(int i = 0; i < originalImageHeight * originalImageWidth; i++) {
        result[i*4]=0;
        int val=greyscaleImageData[i];
        result[i*4+1]=val*0.6 + rgbResult[i*4+1]*0.4;
        result[i*4+2]=val*0.6 + rgbResult[i*4+2]*0.4;
        result[i*4+3]=val*0.6 + rgbResult[i*4+3]*0.4;
        
    }
    free(imageBuf);
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate(result, originalImageWidth, originalImageHeight, 8, originalImageWidth * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    
    free(greyscaleImageData);
    
    [NSData dataWithBytesNoCopy:result length:originalImageWidth * originalImageHeight];
    
    return resultUIImage;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

//this method will take a file url pointing to the documents directory with an invalid/incorrect application directory, and revise it to point to the same file in the documents directory of the new version of the app.  This is for when we have a file url from an old installation/update of the app that we need to translate to the the apps current install directory location, such as for audio and image file urls of un-uploaded audio nodes
+(NSURL*) reformatDocumentsURLForCurrentAppDirectory:(NSURL*) oldDocumentURL {
    if (!oldDocumentURL) return nil;
    NSURL* currentDocumentURL = [[[AudioMobileAppDelegate sharedInstance] applicationDocumentsDirectory] URLByAppendingPathComponent:[oldDocumentURL lastPathComponent] isDirectory:false]; //
    NSLog(@"converted %@ to %@",oldDocumentURL,currentDocumentURL);
    return currentDocumentURL;
    
    
}

@end

//
//  AudioMobileAppDelegate.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import "AudioMobileRestAPIManager.h"
#import "KeychainItemWrapper.h"
#import <CoreData/CoreData.h>
#import "AudioMobileDataModel.h"

//TODO implement user profile image upload, once server side functionality has been implemented

enum {
    AMIMAGESCALETHUMBNAIL = 0,
    AMIMAGESCALEMEDIUM = 1,
    AMIMAGESCALELARGE = 2,
    AMIMAGESCALEI5 = 3
    
};
typedef NSUInteger AMIMAGESCALE;

enum {
    AMGPSTRACKINGMODEFIXED = 0,
    AMGPSTRACKINGMODEWALKING = 1,
    AMGPSTRACKINGMODEBIKING = 2,
    AMGPSTRACKINGMODEDRIVING = 3
    
};
typedef NSUInteger AMGPSTRACKINGMODE;

static bool AMDEVMODE=false; //set to false in production mode

@interface AudioMobileAppDelegate : UIResponder <UIApplicationDelegate,AudioMobileRestAsyncResponseNotifier>

@property (nonatomic) AMGPSTRACKINGMODE locationTrackingMode;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSMutableDictionary* urlImageCache;
@property (strong, nonatomic) dispatch_queue_t imageRequestQueue;

//implementing secure storage of username and password in the keychain as per recommendations here:  http://stackoverflow.com/questions/6972092/ios-how-to-store-username-password-within-an-app
@property (strong, nonatomic) KeychainItemWrapper* keychainItem;

//state variables
//records whether we are currently logged in.
@property (nonatomic) BOOL loggedIn;
@property (nonatomic) BOOL postPrivately;

@property (nonatomic) NSUInteger offlineNodeCount;

//Core Data properties
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+(AudioMobileAppDelegate*) sharedInstance;

//get keychain stored password
-(NSString*) getSavedPassword;

//get keychain stored username
-(NSString*) getSavedUsername;

-(void) keychainSaveUsername:(NSString*) username andPassword:(NSString*)password;

-(void) forgetUsernameAndPassword;

+(NSURL*) getURLOfImage:(NSURL*)originalURL atScale:(AMIMAGESCALE)scale;


//CoreData methods
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

-(NSUInteger) queryOfflineNodeCount;
-(AudioNode1*) getOfflineNodeAtIndex:(NSUInteger) index ;
-(AudioNode1*) getOfflineNodeAtIndex:(NSUInteger) index withContext:(NSManagedObjectContext*)ctxt ;
-(void) deleteOfflineNodeAt:(NSUInteger) index;

+(NSURL*) generateUniqueFileURLWithPrefix:(NSString*) prefix andExtension:(NSString*) extension;
+ (UIImage *)fixrotation:(UIImage *)image;

+ (UIImage *) convertToGreyscale:(UIImage *)i ;

@property (readonly,nonatomic) BOOL userHasAcceptedTerms;

-(void) userAcceptsTermsOfUse;

//takes a url for a file in an application's documents directory, and returns a url pointing to the same relative Documents file but from the current application install directory; used for correcting document file paths between app updates.
+(NSURL*) reformatDocumentsURLForCurrentAppDirectory:(NSURL*) oldDocumentURL;


@end

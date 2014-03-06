//
//  AudioMobileRestAPIManager.h
//  Audio-Mobile
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

enum {
    AMLOGINSUCCESS = 1,		
    AMLOGINFAIL = 2,
    
   };
typedef NSUInteger AMLOGINSTATUS;

enum {
    AMUPLOADSUCCESS = 1,
    AMUPLOADFAIL = 2,
    
};
typedef NSUInteger AMUPLOADSTATUS;

@protocol AudioMobileRestAsyncResponseNotifier <NSObject>

@optional
-(void) loginCompletedWithResult:(AMLOGINSTATUS)loginStatus;
-(void) uploadCompletedWithResult:(AMUPLOADSTATUS)uploadStatus;

@end


@interface AudioMobileRestAPIManager : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (strong,nonatomic) NSString* csrfToken;

-(NSDictionary*) uploadFile:(NSURL*) fileURL withName:(NSString*)fileName error:(NSError**)err;

+(AudioMobileRestAPIManager*) sharedInstance;  //class method for accessing a singleton object of this class.  All other objects in the program can/will share this singleton for their web API requests to the audio-mobile.org server

-(NSArray*) getFeaturedItems:(NSUInteger) pageNumber;
-(UIImage*) getCreatorThumbnail:(NSString*)creatorID ;
-(NSURL*) getCreatorThumbnailURL:(NSString*)creatorID ;

-(void) login:(NSString*)username password:(NSString*) password AndNotify:(id<AudioMobileRestAsyncResponseNotifier>) responder;

-(void) logout:(id<AudioMobileRestAsyncResponseNotifier>) responder;

-(void) downloadNodeAudioToDisk:(NSUInteger) nid;

-(NSArray*) getUsersFollowedBy:(NSUInteger)uid;

-(NSArray*) getNodesForUsers:(NSArray*) users;

-(NSArray*) getNodesForUsersFollowedBy:(NSUInteger) userID includeSelfNodes:(bool) includeSelf;

-(void) uploadNode:(NSString*)title notes:(NSString*)notes imageFile:(NSURL*)image audioFile:(NSURL*)audio recordingLength:(NSTimeInterval) duration weather:(NSString*)weatherCode geodata:(CLLocationCoordinate2D)geodata secondaryGeodata:(NSSet*) subsequentLocations subsequentLocationTimepoints:(NSArray*) timepointIntervals private:(BOOL) isPrivate date:(NSDate*) date locationDescription:(NSString*) locationDescription error:(NSError**) error notify:(id<AudioMobileRestAsyncResponseNotifier>)responder;

- (void)clearCookies;

-(NSArray*) getNodesInRegionLatMin:(double) latMin latMax:(double)latMax lonMin:(double)lonMin lonMax:(double) lonMax;

@property (nonatomic) NSInteger uid; //uid of the currently logged in user, set during the login function

@property (nonatomic, strong) NSString* userName; //name of the currently logged in user, set during the login function

-(NSArray*) getNodes:(NSArray*) nodeIDs;

-(NSArray*) getNodesMatchingSearchPhrase:(NSString*) searchPhrase;

-(bool) likeNode:(NSString*) nodeID  doLike:(bool) like;

@end

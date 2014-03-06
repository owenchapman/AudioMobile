//
//  LocationVisit.h
//  Audio-Mobile
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AudioNode1;

@interface LocationVisit : NSManagedObject

@property (nonatomic, retain) NSDate * timeVisited;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) AudioNode1 *inRecording;

@end

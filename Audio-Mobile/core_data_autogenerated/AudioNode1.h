//
//  AudioNode1.h
//  Audio-Mobile
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LocationVisit;

@interface AudioNode1 : NSManagedObject

@property (nonatomic, retain) NSString * audioFileURL;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * geo;
@property (nonatomic, retain) NSString * imageFileURL;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * locationDescription;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic) BOOL private;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * weatherCode;
@property (nonatomic, retain) NSSet *subsequentLocations;
@end

@interface AudioNode1 (CoreDataGeneratedAccessors)

- (void)addSubsequentLocationsObject:(LocationVisit *)value;
- (void)removeSubsequentLocationsObject:(LocationVisit *)value;
- (void)addSubsequentLocations:(NSSet *)values;
- (void)removeSubsequentLocations:(NSSet *)values;

@end

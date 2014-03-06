//
//  AudioMobileMapViewAnnotation.h
//  Audio-Mobile
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@protocol AudioMobileMapViewAnnotationDelegate <NSObject>

-(void) newCoordinate:(CLLocationCoordinate2D)newCoordinate;

@end

@interface AudioMobileMapViewAnnotation : NSObject<MKAnnotation>

@property ( nonatomic) CLLocationCoordinate2D nodeCoordinate;
@property (strong, nonatomic) NSDictionary* nodeInfo;

@property (assign, nonatomic) id<AudioMobileMapViewAnnotationDelegate> delegate;

@end

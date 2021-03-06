//
//  AudioMobileLocationRepositioningViewController.h
//  Audio-Mobile
//
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AudioMobileAppDelegate.h"
#import "AudioMobileMapViewAnnotation.h"


@interface AudioMobileLocationRepositioningViewController : UIViewController<MKMapViewDelegate,AudioMobileMapViewAnnotationDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) AMMAPMODE mapMode;
@property (weak, nonatomic) IBOutlet UILabel *hintLabel;

@property (nonatomic) NSUInteger offlineItemIndex;

@property (nonatomic) CLLocationCoordinate2D chosenCoordinates;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeToggleButton;

@end

//
//  AudioMobileMapViewController.h
//  Audio-Mobile
//
//




#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "AudioMobileAppDelegate.h"
#import "AudioMobileRestAPIManager.h"
#import "AudioMobileMapViewAnnotation.h"
#import "AudioMobilePlaybackViewController.h"

@interface AudioMobileMapViewController : UIViewController<MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic) AMMAPMODE mapMode;

@property (nonatomic, retain) CLLocation* initialLocation; //where the user is when the view loads; set and read once

@property (nonatomic, strong) id<MKAnnotation> lastSelectedAnnotation;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *mapTypeToggleButton;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeToggleB;

@end

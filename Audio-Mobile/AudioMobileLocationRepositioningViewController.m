//
//  AudioMobileLocationRepositioningViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileLocationRepositioningViewController.h"


@interface AudioMobileLocationRepositioningViewController ()

@end

@implementation AudioMobileLocationRepositioningViewController

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
    //get the initial coordinates from the offlineNodeIndex as set by the summoning view controller, and display them on the map as a pin
    AudioNode1* offlineNode = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineItemIndex]];
    
    [self setChosenCoordinates:CLLocationCoordinate2DMake([[offlineNode latitude] doubleValue], [[offlineNode longitude] doubleValue])];
    
    AudioMobileMapViewAnnotation* ann = [[AudioMobileMapViewAnnotation alloc] init];
    
    [ann setNodeCoordinate:[self chosenCoordinates]];
    
    [[self mapView] setRegion:MKCoordinateRegionMake([self chosenCoordinates], MKCoordinateSpanMake(0.05, 0.05))];
    
    if ([offlineNode title]) {
        [ann setNodeInfo:@{@"title":[offlineNode title],
                           @"name":@""}];
    }

    [ann setDelegate:self];
    
    [[self mapView] addAnnotation:ann];
}

#pragma mark AudioMobileMapViewAnnotationDelegate method, responds to drag and drop of pin

-(void) newCoordinate:(CLLocationCoordinate2D)newCoordinate {
    [self setChosenCoordinates:newCoordinate];

}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[AudioMobileMapViewAnnotation class]]) {
        MKAnnotationView* annView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"AudioNodePin"];
    
        
        annView.draggable = true;
        
        annView.canShowCallout = false;
        
        NSLog(@"Created pin view for annotation");
        
        UIImageView* nodeImageView = [[UIImageView alloc] init];
        UIButton* nodeDiveButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,33,33)];
        [nodeDiveButton addSubview:nodeImageView];
        
        
        [nodeImageView setFrame:CGRectMake(0, 0, 33, 33)];
        annView.rightCalloutAccessoryView = nodeDiveButton;
        [nodeDiveButton addTarget:self
                           action:@selector(goToSelectedNode)
                 forControlEvents:UIControlEventTouchDown];
        UIImage* annImage = [UIImage imageNamed:@"MapIcon_v2.png"];
        
        annImage = [UIImage imageWithCGImage:[annImage CGImage] scale:[annImage scale]*2 orientation:[annImage imageOrientation]];
        annView.image = annImage;
        
        return annView;
    }
    else {
        NSLog(@"Unidentified annotation class found: %@",[annotation class]);
        return nil;
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    
    if (oldState == MKAnnotationViewDragStateStarting && newState == MKAnnotationViewDragStateEnding)
    {
        NSLog(@"Ending drag");
        [[self hintLabel] setText:@"Tap and hold pin to pick it up"];
        [annotationView setDragState:MKAnnotationViewDragStateNone];
    }
    
    if (newState == MKAnnotationViewDragStateStarting)
    {
        NSLog(@"Beginning drag");
        [[self hintLabel] setText:@"Drag and drop pin to reposition"];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (IBAction)acceptAction:(id)sender {
    NSError* err;
    NSManagedObjectContext* ctxt = [[AudioMobileAppDelegate sharedInstance] managedObjectContext];
    
    AudioNode1* offlineNode = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[self offlineItemIndex] withContext:ctxt];
    
    [offlineNode setLatitude:[NSNumber numberWithDouble:[self chosenCoordinates].latitude]];
    [offlineNode setLongitude:[NSNumber numberWithDouble:[self chosenCoordinates].longitude]];
    
    [ctxt save:&err];
    if (err) {
        NSLog(@"Error: Failed to save updated node location");
    }

    [self dismissViewControllerAnimated:TRUE completion:nil];
    
    
    
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:TRUE completion:nil];
}

@end

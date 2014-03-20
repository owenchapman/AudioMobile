//
//  AudioMobileMapViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileMapViewController.h"
#import "UIImageView+AFNetworking.h"

@interface AudioMobileMapViewController ()

@end

@implementation AudioMobileMapViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if ([self.mapView showsUserLocation]) {
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if ( !_initialLocation )
    {
        self.initialLocation = userLocation.location;
        
        MKCoordinateRegion region;
        region.center = mapView.userLocation.coordinate;
        region.span = MKCoordinateSpanMake(0.1, 0.1);
        
        region = [mapView regionThatFits:region];
        [mapView setRegion:region animated:YES];
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKCoordinateRegion region = [[self mapView] region];
    
    
    dispatch_queue_t myQueue = dispatch_queue_create("populateRegionWithNodes",NULL);
    dispatch_async(myQueue, ^{
        // Perform long running process
        NSArray* nodeSummaries = [[AudioMobileRestAPIManager sharedInstance] getNodesInRegionLatMin:(region.center.latitude-region.span.latitudeDelta/2) latMax:(region.center.latitude+region.span.latitudeDelta/2) lonMin:(region.center.longitude-region.span.longitudeDelta/2) lonMax:(region.center.longitude+region.span.longitudeDelta/2)];
        
        if (!nodeSummaries || nodeSummaries.count ==0) return;
        
        NSMutableArray* nodeIDs = [[NSMutableArray alloc] initWithCapacity:[nodeSummaries count]];
        for(NSDictionary* nodeSummary in nodeSummaries) {
            NSLog(@"Node in region: %@",[nodeSummary objectForKey:@"nid"]);
            [nodeIDs addObject:[nodeSummary objectForKey:@"nid"]];
        }
        
        NSArray* nodeInfo = [[AudioMobileRestAPIManager sharedInstance] getNodes:nodeIDs];
        
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            //indicate that a new entry has been added to the nodes for upload database
            
            for(NSDictionary* nodeSummary in nodeInfo) {
                NSLog(@"Node in region: %@",nodeSummary);
                
                AudioMobileMapViewAnnotation* ann = [[AudioMobileMapViewAnnotation alloc] init];
                [ann setNodeCoordinate:CLLocationCoordinate2DMake([((NSString*) nodeSummary[@"latitude"]) doubleValue], [((NSString*) nodeSummary[@"longitude"]) doubleValue])];
                
                [ann setNodeInfo:nodeSummary];
                
                [[self mapView] addAnnotation:ann];

            }
        });
    });
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[AudioMobileMapViewAnnotation class]]) {
        
        MKPinAnnotationView* annView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"AudioNodePin"];
        
        annView.canShowCallout = true;
        
        [annView setPinColor:MKPinAnnotationColorGreen];
        NSLog(@"Created pin view for annotation");
        
        UIImageView* nodeImageView = [[UIImageView alloc] init];
        UIButton* nodeDiveButton = [[UIButton alloc] initWithFrame:CGRectMake(0,0,33,33)];
        [nodeDiveButton addSubview:nodeImageView];
        
        NSURL* imageURL = [NSURL URLWithString:[[((AudioMobileMapViewAnnotation*) annotation) nodeInfo] objectForKey:@"image"]];
        
        [nodeImageView setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"LoadingTexture.png"]];
        [nodeImageView setFrame:CGRectMake(0, 0, 33, 33)];
        annView.rightCalloutAccessoryView = nodeDiveButton;
        [nodeDiveButton addTarget:self
                   action:@selector(goToSelectedNode)
         forControlEvents:UIControlEventTouchDown];
        UIImage* annImage = [UIImage imageNamed:@"MapIcon_v2.png"];
        
        annImage = [UIImage imageWithCGImage:[annImage CGImage] scale:[annImage scale]*3 orientation:[annImage imageOrientation]];
        annView.image = annImage;
        
        return annView;
    }
    else {
        NSLog(@"Unidentified annotation class found: %@",[annotation class]);
        return nil;
    }
    
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    [self setLastSelectedAnnotation:[view annotation]];
    
}

-(void) goToSelectedNode {
    NSLog(@"User has clicked on a node of the map");
    //segue to the playback view for this node
    
    [self performSegueWithIdentifier:@"MapViewToPlaybackView" sender:[self lastSelectedAnnotation]];
    
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"MapViewToPlaybackView"]){
        //set item data for playback view
        AudioMobilePlaybackViewController* destViewController = segue.destinationViewController;
        AudioMobileMapViewAnnotation* annotation = (AudioMobileMapViewAnnotation*) sender;
        [destViewController setItemInfo:[annotation nodeInfo]];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (IBAction)mapTypeToggleAction:(id)sender {
    if ([self mapMode] == AMMAPMODESATELLITE) {
        [[self mapView] setMapType:MKMapTypeStandard];
//        [[self mapTypeToggleButton] setTitle:@"Satellite"];
//        [[self mapTypeToggleButton] set]

        [[self mapTypeToggleB] setTitle:@"Standard" forState:UIControlStateNormal];
        [self setMapMode:AMMAPMODESTANDARD];
    }
    else if ([self mapMode] == AMMAPMODESTANDARD) {
        [[self mapView] setMapType:MKMapTypeSatellite];
//        [[self mapTypeToggleButton] performSelectorOnMainThread:@selector(setTitle:) withObject:@"Standard" waitUntilDone:true];
//        self.mapTypeToggleButton.title = @"Standard";
//        [[self mapTypeToggleButton] setTitle:@"Standard"];
        [[self mapTypeToggleB] setTitle:@"Satellite" forState:UIControlStateNormal];
        [self setMapMode:AMMAPMODESATELLITE];
    }
    else {
        NSLog(@"Unhandled case for AMMapMode:  %d",[self mapMode]);
    }
}

@end

//
//  AudioMobileListenViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileListenViewController.h"
#import "AudioMobileAppDelegate.h"
#import "AudioMobileListenResultsTableViewCell.h"
#import "AudioMobilePostRecordViewController.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "AudioNode1.h"

@interface AudioMobileListenViewController ()

@end

@implementation AudioMobileListenViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldBeginEditing = true;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSManagedObjectContext* ctxt = [[AudioMobileAppDelegate sharedInstance] managedObjectContext];
    
    NSSortDescriptor *sortDescriptor =
    [[NSSortDescriptor alloc] initWithKey:@"date"
                                ascending:YES];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid == %@", @"979"];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = [NSEntityDescription entityForName:@"AudioNode1" inManagedObjectContext:ctxt];
    request.fetchBatchSize = 100;
    request.fetchLimit = 1000;
    request.sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    NSError* err = nil;
    
    request.predicate = predicate;
    NSArray *results = [ctxt executeFetchRequest:request error:&err];
    if (err) {
        NSLog(@"Error attempting to fetch audionode entries from database: %@",err);
    }
    else {
        for(AudioNode1* an1 in results) {
            NSLog(@"Title: %@; UID: %@",[an1 title],[an1 uid]);
        }
    }
    [[self searchResultsTable] reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //ensure user is logged in before attempting to query for followed user node list
    if ([[AudioMobileAppDelegate sharedInstance] loggedIn]) {
        [self retrieveListenedNodeListAndDisplayResults]; //show the nodes of the users the logged in user listens to
    }
    else {
        //display message about typing in search box to see results
    }
    
    //register observers on logged in status, reload results when user logs in, clear results when they log out
    [((AudioMobileAppDelegate*)[[UIApplication sharedApplication] delegate]) addObserver:self forKeyPath:@"loggedIn" options:0 context:nil];
    
    [((AudioMobileAppDelegate*)[[UIApplication sharedApplication] delegate]) addObserver:self forKeyPath:@"offlineNodeCount" options:0 context:nil];
}

- (NSMutableArray*) defaultNodeList {
    if (!_defaultNodeList) {
        _defaultNodeList = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return _defaultNodeList;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [AudioMobileAppDelegate sharedInstance] && [keyPath isEqualToString:@"loggedIn"]) {
        NSLog(@"logged in status changed, updating listen view");
        if ([[AudioMobileAppDelegate sharedInstance] loggedIn]) {
            [self retrieveListenedNodeListAndDisplayResults];
        }
        else {
            [self clearResults];
        }
    }
    else if (object == [AudioMobileAppDelegate sharedInstance] && [keyPath isEqualToString:@"offlineNodeCount"]) {
        //refresh the data, as we probably have had offline nodes either added or removed
        NSLog(@"number of offline nodes changed, updating results list in listen table if we're in default mode");

        if (![self customSearchMode] && [[AudioMobileAppDelegate sharedInstance] loggedIn]) {
            [self retrieveListenedNodeListAndDisplayResults];
        }
        else {
            [[self searchResultsTable] reloadData];
        }
    }
}

-(void) clearResults {
    [[self defaultNodeList] removeAllObjects];
    [[self searchResultsTable] reloadData];
}

- (void) retrieveListenedNodeListAndDisplayResults {
    
    if (![[AudioMobileAppDelegate sharedInstance] loggedIn]) {
        NSLog(@"User must be logged in to retrieve listened to node list");
        return;
    }

    UIActivityIndicatorView* actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [actInd setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [[self view] addSubview:actInd];
    [actInd startAnimating];
    
    dispatch_queue_t myQueue = dispatch_queue_create("My Queue",NULL);
    dispatch_async(myQueue, ^{
        // Perform long running process
        //create load indicator to show while we download featured items to show
        //clear the old values
        [[self defaultNodeList] removeAllObjects];
        //populate with the newly retrieved values
        
        if ([[AudioMobileAppDelegate sharedInstance] loggedIn]) {
            NSInteger loggedInUserID = [[AudioMobileRestAPIManager sharedInstance] uid];
            [[self defaultNodeList] addObjectsFromArray:[[AudioMobileRestAPIManager sharedInstance] getNodesForUsersFollowedBy:loggedInUserID includeSelfNodes:true]]; 
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            [actInd stopAnimating];
            [actInd removeFromSuperview];
            [[self searchResultsTable] reloadData];
            NSLog(@"Reloaded data, should be %d cells",[[self defaultNodeList] count]);
        });
    });
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



#pragma mark UISearchBarDelegate protocol methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [[self searchBar] setShowsCancelButton:true];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [[self searchBar] setShowsCancelButton:false];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(![searchBar isFirstResponder] ) {
        // user tapped the 'clear' button
        shouldBeginEditing = NO;
    }
    
    
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar {
    if ([[searchBar text] length] ==0 && [self customSearchMode]) {
        [self setCustomSearchMode:false];
        if ([[AudioMobileAppDelegate sharedInstance] loggedIn]) {
            [self retrieveListenedNodeListAndDisplayResults];
        }
    }
    [searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"Searching for %@",[searchBar text]);
    
    if ([[searchBar text] length]>0) {
        [self setCustomSearchMode:true];
        [self clearResults];
        //create load indicator to show while we download featured items to show
        UIActivityIndicatorView* actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [actInd setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [[self view] addSubview:actInd];
        [actInd startAnimating];
        
        //show activity indicator while we are executing the search
        dispatch_queue_t myQueue = dispatch_queue_create("My Queue",NULL);
        dispatch_async(myQueue, ^{
            // Perform long running process

            //execute the keyword based search
            NSArray* searchResultNodes = [[AudioMobileRestAPIManager sharedInstance] getNodesMatchingSearchPhrase:[searchBar text]];
            
            [self setCustomSearchResults:searchResultNodes];

            dispatch_async(dispatch_get_main_queue(), ^{
                // Update the UI
                [actInd stopAnimating];
                [actInd removeFromSuperview];
                [[self searchResultsTable] reloadData];
                NSLog(@"Reloaded data, should be %d cells",[[self customSearchResults] count]);
            });
        });
        

    }
    else {
        [self setCustomSearchMode:false];
        [self retrieveListenedNodeListAndDisplayResults];
    }
    
    [searchBar resignFirstResponder];
}

#pragma mark UITableViewDelegate methods

// Display customization

// Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"User selected index %d",[indexPath item]);
    AudioMobileListenResultsTableViewCell* cell = (AudioMobileListenResultsTableViewCell*)[[self searchResultsTable] cellForRowAtIndexPath:indexPath];
    
    if ([cell isOffline]) {
        //segue to the node details form for annotation, preview and upload
        [self performSegueWithIdentifier:@"ListenViewToPostRecordingView" sender:cell];        
    }
    else {
        [self performSegueWithIdentifier:@"ListenViewToPlaybackView" sender:cell];
    }
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"ListenViewToPlaybackView"]){
        //set item data for playback view
        
        AudioMobileListenResultsTableViewCell* cell = (AudioMobileListenResultsTableViewCell*) sender;
        AudioMobilePlaybackViewController* destViewController = segue.destinationViewController;

        [destViewController setItemInfo:[cell itemInfo]];
    }
    else if ([segue.identifier isEqualToString:@"ListenViewToPostRecordingView"]) {
        AudioMobileListenResultsTableViewCell* cell = (AudioMobileListenResultsTableViewCell*) sender;
        
        UIImage *image = [[cell thumbnailView] image];
        
        int offlineItemIndex = [cell offlineItemIndex];
        AudioNode1* offlineNode = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:offlineItemIndex];
        
        NSURL* imageFileCurrentURL = [AudioMobileAppDelegate reformatDocumentsURLForCurrentAppDirectory:[NSURL fileURLWithPath:[offlineNode imageFileURL]]];
        
        NSLog(@"loading post record editor view using offline node with image url %@",imageFileCurrentURL);

        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageFileCurrentURL]];
        
        AudioMobilePostRecordViewController *destViewController = segue.destinationViewController;
        destViewController.displayImage = image;
        [destViewController.displayImageView setImage: image];
        
        AudioNode1* offlineItemInfo = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[cell offlineItemIndex]];
        
        [destViewController setOfflineNodeIndex:[cell offlineItemIndex]];
        [destViewController setNodeStartLocation:CLLocationCoordinate2DMake([[offlineItemInfo latitude] doubleValue], [[offlineItemInfo longitude] doubleValue])];
        
        //the sender object should be the file url of the wav recording, so set it in the destviewcontroller
        NSString* wavFilePath = [offlineItemInfo audioFileURL];
        NSURL* oldWaveFileURL = [NSURL fileURLWithPath:wavFilePath];
        NSURL* currentWaveFileURL = [AudioMobileAppDelegate reformatDocumentsURLForCurrentAppDirectory:oldWaveFileURL];
        NSLog(@"Wav file url is %@",wavFilePath);
        [destViewController setWavFileRecordingURL:currentWaveFileURL];
        [destViewController setRecordingLength:[[offlineItemInfo length] doubleValue]];
    }
}

#pragma mark UITableViewDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([self customSearchMode]) {
        
        return [self customSearchResults]!=nil?[[self customSearchResults] count]:0;
    }
    else {
        return [[self defaultNodeList] count] + [[AudioMobileAppDelegate sharedInstance] offlineNodeCount];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AudioMobileListenResultsTableViewCell* cell = [[self searchResultsTable] dequeueReusableCellWithIdentifier:@"listenCell" forIndexPath:indexPath];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    [[cell thumbnailView] setClipsToBounds:YES];
    NSDictionary* itemDict;
    if ([self customSearchMode]) {
        if ([self customSearchResults] && [[self customSearchResults] objectAtIndex:[indexPath item]]) {
            NSDictionary* searchResultItemInfo = [[self customSearchResults] objectAtIndex:[indexPath item]];
            //note:  the results item returned by the search api does not contain many of the elements returned by the other query formats, e.g. the image url is not included.
            itemDict = searchResultItemInfo;
            NSURL* imageURL =[NSURL URLWithString:itemDict[@"image"]];
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                imageURL = [AudioMobileAppDelegate getURLOfImage:imageURL atScale:AMIMAGESCALEMEDIUM];
            }
            else {
                imageURL = [AudioMobileAppDelegate getURLOfImage:imageURL atScale:AMIMAGESCALETHUMBNAIL];
                
            }
            [[cell thumbnailView] setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"LoadingTexture"]];
            
            [cell setItemInfo:itemDict];
            
            [[cell titleLabel] setText:itemDict[@"title"]];
            [[cell subtitleLabel] setText:itemDict[@"name"]];
        }
        return cell;
    }
    else {
        //if the index is within the count of the offline nodes which are to be uploaded, grab one of those; else, grab one of the user's uploaded files

        NSUInteger offlineNodeCount = [[AudioMobileAppDelegate sharedInstance] offlineNodeCount];
        if ([indexPath item] <offlineNodeCount) {
            //retrieve node with given index from [reverse chronological] list of offline nodes
            [cell setIsOffline:true];
            
            AudioNode1* offlineNode = [[AudioMobileAppDelegate sharedInstance] getOfflineNodeAtIndex:[indexPath item]];
            
            NSLog(@"Image file path is %@",[offlineNode imageFileURL]);
            
            //strip the first part of the node image url, which could be changed between app installs, and regenerate using the current documents directory location
            
            NSString* imageFilePathOld = [offlineNode imageFileURL];
            NSURL* imageFileURLOld = [NSURL fileURLWithPath:imageFilePathOld ];
            
            NSURL* imageFileCurrentURL = [AudioMobileAppDelegate reformatDocumentsURLForCurrentAppDirectory:imageFileURLOld];
            
            [[cell thumbnailView] setImage:[UIImage imageWithContentsOfFile:[imageFileCurrentURL path] ]];
            
             NSDate* recordingDate = [offlineNode date];
             NSString* title = [offlineNode title];
             if (title) {
             }
             else {
                 title = [NSString stringWithFormat:@"Untitled Recording - %@",recordingDate]; //TODO consider using a different formatter for the date 
             }
             [[cell titleLabel] setText:title];
            [[cell subtitleLabel] setText:@"Ready for upload"];
            NSLog(@"Wav file url for offline node is %@",[offlineNode audioFileURL]);
            
            [cell setOfflineItemInfo:offlineNode];
            [cell setOfflineItemIndex:[indexPath item]];
        }
        else {
            if ([[self defaultNodeList] count] >0) {
                itemDict = [[self defaultNodeList] objectAtIndex:[indexPath item]- offlineNodeCount];
                NSURL* imageURL =[NSURL URLWithString:itemDict[@"image"]];

                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                    imageURL = [AudioMobileAppDelegate getURLOfImage:imageURL atScale:AMIMAGESCALEMEDIUM];
                }
                else {
                    imageURL = [AudioMobileAppDelegate getURLOfImage:imageURL atScale:AMIMAGESCALETHUMBNAIL];
                    
                }
                [[cell thumbnailView] setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"LoadingTexture"]];
                
                [cell setItemInfo:itemDict];
                
                [[cell titleLabel] setText:itemDict[@"title"]];
                [[cell subtitleLabel] setText:itemDict[@"name"]];
            }
        }
        return cell;
    }
}

- (void)scrollViewDidScroll: (UIScrollView*)scroll {
    NSInteger currentOffset = scroll.contentOffset.y;
    NSInteger maximumOffset = scroll.contentSize.height - scroll.frame.size.height;
    
    // Change 10.0 to adjust the distance from bottom
    if (maximumOffset - currentOffset <= 10.0) {
        NSLog(@"hit bottom!");
    }
}


@end

//
//  AudioMobileFeaturedViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileFeaturedViewController.h"
#import "UIImageView+AFNetworking.h"

@interface AudioMobileFeaturedViewController ()

@end

@implementation AudioMobileFeaturedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.currentlySelectedItemIndex = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //retrieve initial set of featured records and cache them locally, then update the view
    dispatch_queue_t myQueue = dispatch_queue_create("FeaturedItemRetrievalQueue",NULL);
    dispatch_async(myQueue, ^{
        // Perform long running process
        //create load indicator to show while we download featured items to show
        UIActivityIndicatorView* actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [actInd setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        [[self view] addSubview:actInd];
        [actInd startAnimating];
        [[self featuredItems] addObjectsFromArray:[[AudioMobileRestAPIManager sharedInstance] getFeaturedItems:0]];
        [self setFeaturedItemPagesRetrieved:1];

        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            [actInd stopAnimating];
            [actInd removeFromSuperview];
            [[self collectionView] reloadData];
            NSLog(@"Reloaded data");
        });
    });
    

}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark accessor methods

-(NSMutableArray*) featuredItems {
    if (!_featuredItems) { //initialize our mutable array if it hasn't been already initialized
        _featuredItems = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return _featuredItems;
}

-(NSMutableDictionary*) imageCache {
    if (!_imageCache) {
        _imageCache = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return _imageCache;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    NSLog(@"featured item view received memory warning");
    NSLog(@"nsurlcache memory capacity: %u",[[NSURLCache sharedURLCache] memoryCapacity]);
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setMemoryCapacity:1024*1024];
    
}

-(void) viewDidAppear:(BOOL)animated {
}

-(void) viewDidDisappear:(BOOL)animated {
}

- (void)scrollViewDidScroll: (UIScrollView*)scroll {
    // UITableView only moves in one direction, y axis
    NSInteger currentOffset = scroll.contentOffset.y;
    NSInteger maximumOffset = scroll.contentSize.height - scroll.frame.size.height;
    
    // Change 10.0 to adjust the distance from bottom
    if (maximumOffset - currentOffset <= 10.0) {
//        [self methodThatAddsDataAndReloadsTableView];
        //query for more data from server
//        [[self collectionView] reloadData];
//        NSLog(@"Would be updating right now");
//
//        if ([self retrieivingItems]) {
//            return;
//        }
//        else {
//            @synchronized (self) {
//                [self setRetrieivingItems:true];
//                [[self featuredItems] addObjectsFromArray:[[AudioMobileRestAPIManager sharedInstance] getFeaturedItems:[self featuredItemPagesRetrieved]]];
//                [self setFeaturedItemPagesRetrieved:[self featuredItemPagesRetrieved]+1];
//                
//                [[self collectionView] reloadData];
//                [self setRetrieivingItems:false];
//            }
//        }

        

    }
}

#pragma mark UICollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSLog(@"%d featured items to be displayed",[[self featuredItems] count]);
    return [[self featuredItems] count];
    return 8;
}



// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    bool fakeMode = false;
    
    AudioMobileFeaturedItemCellView* cell = [[self collectionView] dequeueReusableCellWithReuseIdentifier:@"2dGridCell" forIndexPath:indexPath];

    if (fakeMode) {
        switch ([indexPath item]) {
            case 0:
            {
                UIImage* nodeMainImage = [UIImage imageNamed:@"featured_cell_1.png"];
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
                [[cell titleLabel] setText:@"Sunsoaked"];
                [[cell creatorNameLabel] setText:@"John Q"];
                [cell setNodeMainImage:nodeMainImage];
                break;
            }
            case 1:
            {
                UIImage* nodeMainImage = [UIImage imageNamed:@"featured_cell_2.png"];
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
                [[cell titleLabel] setText:@"Skyway"];
                [[cell creatorNameLabel] setText:@"Mable Lane"];
                [cell setNodeMainImage:nodeMainImage];
                break;
            }
            case 2:
            {
                UIImage* nodeMainImage = [UIImage imageNamed:@"featured_cell_3.png"];
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
                [[cell titleLabel] setText:@"Twilight"];
                [[cell creatorNameLabel] setText:@"Mix Mast"];
                [cell setNodeMainImage:nodeMainImage];
                break;
            }
            case 3:
            {
                UIImage* nodeMainImage = [UIImage imageNamed:@"featured_cell_4.png"];
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
                [[cell titleLabel] setText:@"Colour Sounds"];
                [[cell creatorNameLabel] setText:@"Shelly Sea"];
                [cell setNodeMainImage:nodeMainImage];
                break;
            }
            case 4:
            {
                UIImage* nodeMainImage = [UIImage imageNamed:@"featured_cell_1.png"];
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
                [[cell titleLabel] setText:@"Sunsoaked"];
                [[cell creatorNameLabel] setText:@"John Q"];
                [cell setNodeMainImage:nodeMainImage];
                break;
            }
            case 5:
            {
                UIImage* nodeMainImage = [UIImage imageNamed:@"featured_cell_2.png"];
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
                [[cell titleLabel] setText:@"Skyway"];
                [[cell creatorNameLabel] setText:@"Mable Lane"];
                [cell setNodeMainImage:nodeMainImage];
                break;
            }
            case 6:
            {
                UIImage* nodeMainImage = [UIImage imageNamed:@"featured_cell_3.png"];
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
                [[cell titleLabel] setText:@"Twilight"];
                [[cell creatorNameLabel] setText:@"Mix Mast"];
                [cell setNodeMainImage:nodeMainImage];
                break;
            }
            case 7:
            {
                UIImage* nodeMainImage = [UIImage imageNamed:@"featured_cell_4.png"];
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
                [[cell titleLabel] setText:@"Colour Sounds"];
                [[cell creatorNameLabel] setText:@"Shelly Sea"];
                [cell setNodeMainImage:nodeMainImage];
                break;
            }
                
            default:
                break;
        }
        
    }
    else {
        
        //retrieve the featured item description from our featured item array
        NSDictionary* featuredItemDict = [[self featuredItems] objectAtIndex:[indexPath item]];
        
        NSURL* imageURL =[NSURL URLWithString:featuredItemDict[@"image"]];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            imageURL = [AudioMobileAppDelegate getURLOfImage:imageURL atScale:AMIMAGESCALELARGE];
            [[cell backgroundImageView] setContentMode:UIViewContentModeScaleAspectFill]; //need to change the content mode because the large images are not square and get distorted using the default mode.
        }
        else {
            imageURL = [AudioMobileAppDelegate getURLOfImage:imageURL atScale:AMIMAGESCALEMEDIUM];
        }

        UIImage* __block nodeMainImage;
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [indicator setFrame:CGRectMake(0, 0, 160, 160)];
        [cell setBackgroundView:indicator];
        
        //first check to see if the image for this node has already been downloaded
        AudioMobileAppDelegate* appDelegate =(AudioMobileAppDelegate*)[[UIApplication sharedApplication] delegate];
        if ([[appDelegate urlImageCache] objectForKey:[imageURL path]]) {
            [cell setNodeMainImage:[[appDelegate urlImageCache] objectForKey:[imageURL path]]];
        }
        else {
            bool useAFNetworking = false;
            useAFNetworking = true;
            if (useAFNetworking) {

                NSLog(@"Retrieving thumbnail version of image: %@",imageURL);
                [[cell backgroundImageView] setImageWithURL:imageURL placeholderImage:[UIImage imageNamed:@"LoadingTexture.png"]];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:imageURL];
                [request addValue:@"image/*" forHTTPHeaderField:@"Accept"];
                
                [[cell backgroundImageView] setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"LoadingTexture.png"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image){
                    
                    [[cell backgroundImageView] setImage:[AudioMobileAppDelegate convertToGreyscale:image]];
                    
                } failure:nil];
            }
            else {
                //set a placeholder image for our placeholder while we download the real one
                [cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoadingTexture.png"]]];
                //background queue a block which will retrieve our image from the server and then notify the cell when it is ready
                
                dispatch_async([appDelegate imageRequestQueue], ^{
                    AudioMobileAppDelegate* appDelegate =(AudioMobileAppDelegate*)[[UIApplication sharedApplication] delegate];
                    UIImage* nodeImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
                    
                    NSLog(@"old image has width and height: %f, %f", nodeImage.size.width,nodeImage.size.height);
                    [[appDelegate urlImageCache] setObject:nodeImage forKey:[imageURL path]];
                    NSLog(@"Downloading node image at URL: %@",imageURL);
                    NSLog(@"new image has width and height: %f, %f", nodeImage.size.width,nodeImage.size.height);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // Update the UI
                        
                        AudioMobileFeaturedItemCellView* myCell  = (id) [collectionView cellForItemAtIndexPath:indexPath];
                        
                        //the cell may be reused for other nodes as the user scrolls through the collection, so we pass the imageURL from this call for the cell to compare   against the imageURL it is currently set to display; it will only load the newly cached image if the urls match.
                        if (myCell) {
                            [myCell cachedImageAvailableForURL:imageURL];
                        }
                        
                    });
                });
            }
        }
        [cell setFeaturedItemIndex:[indexPath item]];

        [[cell titleLabel] setText:featuredItemDict[@"title"]];
        
        [cell setCreatorID:featuredItemDict[@"author uid"]];
        [[cell creatorNameLabel] setText:featuredItemDict[@"name"]];
        [cell setNodeMainImage:nodeMainImage];
    }
    
    if ([self currentlySelectedItemIndex] && [[self currentlySelectedItemIndex] compare:indexPath] == NSOrderedSame) {
        //this item is the currently selected item, so make it's labels visible
        [cell setLabelAlpha:1.0];
    }
    
    return cell;
}

#pragma mark UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    bool twoStageSelection = false;
    
    if (twoStageSelection) {
        //first deselect the previous selection
        if ([self currentlySelectedItemIndex] && [[self currentlySelectedItemIndex] compare:indexPath] == NSOrderedSame) {
            //user has tapped on an item they have already selected, therefore take the user to the playback page for this content item
            
            AudioMobileFeaturedItemCellView* cell = (AudioMobileFeaturedItemCellView*) [[self collectionView] cellForItemAtIndexPath:indexPath];
            
            [self performSegueWithIdentifier:@"FeaturedToItemPlayback" sender:cell];
            return;
        }
        if ([self currentlySelectedItemIndex] && [[self currentlySelectedItemIndex] item]>-1) { //ensure this is a valid selection index; this property is initialized to -1 during controller object construction, when nothing has been selected
            
            //user has selected a different item from the one they previously selected, therefore we need to remove the title and creator labels from the previously selected item before showing them for the newly selected item.
            
            AudioMobileFeaturedItemCellView* previouslySelectedCell =  (AudioMobileFeaturedItemCellView*)[[self collectionView] cellForItemAtIndexPath:[self currentlySelectedItemIndex]];
            [previouslySelectedCell setLabelAlpha:0];
            
            
        }
        
        AudioMobileFeaturedItemCellView* cell = (AudioMobileFeaturedItemCellView*) [[self collectionView] cellForItemAtIndexPath:indexPath];
        [cell setLabelAlpha:1.0];
        [self setCurrentlySelectedItemIndex:[indexPath copy]];
        
    }
    else {
        //take user directly to playback screen for selected item
        AudioMobileFeaturedItemCellView* cell = (AudioMobileFeaturedItemCellView*) [[self collectionView] cellForItemAtIndexPath:indexPath];
        
        [self performSegueWithIdentifier:@"FeaturedToItemPlayback" sender:cell];
    }
    
}

- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark uiviewcontroller storyboard methods

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([segue.identifier isEqualToString:@"FeaturedToItemPlayback"]){
        //set item data for playback view
        
        AudioMobileFeaturedItemCellView* cell = (AudioMobileFeaturedItemCellView*) sender;
        UIImage* nodeMainImage = [cell nodeMainImage];
        AudioMobilePlaybackViewController* destViewController = segue.destinationViewController;
        [destViewController setNodeImage:nodeMainImage];
        
        [destViewController setItemInfo:[[self featuredItems] objectAtIndex:[cell featuredItemIndex]]];
        
        //retrieve the creator thumbnail
        
        if ([cell creatorID]) {
            UIImage* creatorThumbnail;
            if ([self.imageCache objectForKey:[cell creatorID]]) {
                creatorThumbnail = [self.imageCache objectForKey:[cell creatorID]];
            }
            else {
                creatorThumbnail = [[AudioMobileRestAPIManager sharedInstance] getCreatorThumbnail:[cell creatorID]];
                //cache the image for later use
                [self.imageCache setObject:creatorThumbnail forKey:[cell creatorID]];
            }
            
            if (creatorThumbnail) {
                [destViewController setCreatorThumbnail:creatorThumbnail];
            }
            else {
                //use placeholder image because we could not retrieve the creator thumbnail
                [destViewController setCreatorThumbnail:[UIImage imageNamed:@"creator_thumbnail.png"]];
            }
        }
        else {

            [destViewController setCreatorThumbnail:[UIImage imageNamed:@"creator_thumbnail.png"]];
        }
        
        [destViewController setCreatorName:[[cell creatorNameLabel] text]];
        [destViewController setTitle:[[cell titleLabel] text]];
    }
}

@end

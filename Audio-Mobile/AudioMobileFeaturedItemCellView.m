//
//  AudioMobileFeaturedItemCellView.m
//  Audio-Mobile
//
//

#import "AudioMobileFeaturedItemCellView.h"
#import "UIImageView+AFNetworking.h"

@implementation AudioMobileFeaturedItemCellView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
//        [self setBackgroundColor:[UIColor purpleColor]];

        [self setBackgroundView:        [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LoadTexture.png"]]];
        
        
    }
    return self;
}

#pragma mark UIView methods

#pragma mark UICollectionViewCell methods

-(void) prepareForReuse {
    [self setCustomViewColor:nil];
    [self setNodeMainImage:nil];
    [self setFeaturedItemIndex:-1];//TODO consider setting this to a less ambiguous, possibly error prone value
}

#pragma mark custom methods

-(void) setLabelAlpha:(CGFloat) alpha {
    [[self titleLabel] setAlpha:alpha];
    [[self creatorNameLabel] setAlpha:alpha];
}

- (void) setNodeMainImageURL:(NSURL *)nodeMainImageURL {
    //asynchronously download this image and display it once it is
    dispatch_queue_t myQueue = dispatch_queue_create([[nodeMainImageURL path] UTF8String],NULL);
    dispatch_async(myQueue, ^{
        // Perform long running process
        UIImage* nodeMainImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:nodeMainImageURL]];
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            [self setNodeMainImage:nodeMainImage];
            NSLog(@"set image for cell with url %@",[self nodeMainImageURL]);
            [self setBackgroundView:[[UIImageView alloc] initWithImage:nodeMainImage]];
        });
    });
}

-(void) cachedImageAvailableForURL:(NSURL*)imageURL {
    @synchronized (self) {
        if ([imageURL isEqual:[self nodeMainImageURL]]) {
            //retrieve the image from the cache and set it as our background image
            UIImage* nodeImage = [[((AudioMobileAppDelegate*)[[UIApplication sharedApplication] delegate]) urlImageCache] objectForKey:[[self nodeMainImageURL] path]];
            [self setNodeMainImage:nodeImage];
            UIImageView* imageView = [[UIImageView alloc] initWithImage:nodeImage];
            [imageView setBackgroundColor:[UIColor clearColor]];
            [[self contentView] addSubview:imageView];
        }
        else {
            //do nothing, we no longer need this image
        }
        
    }
}

-(void) initBackgroundImageView {
    _backgroundImageView = [[UIImageView alloc] init];
    [[self contentView] addSubview:_backgroundImageView];
}

//-(UIImageView*) backgroundImageView {
//    if (!_backgroundImageView) {
////        _backgroundImageView = [[UIImageView alloc] init];
////        [[self contentView] addSubview:_backgroundImageView];
////        [[self contentView] performSelectorOnMainThread:@selector(addSubview:) withObject:_backgroundImageView waitUntilDone:true];
//        [self  performSelectorOnMainThread:@selector(initBackgroundImageView) withObject:nil waitUntilDone:true];
//
//    }
//    return _backgroundImageView;
//}

@end

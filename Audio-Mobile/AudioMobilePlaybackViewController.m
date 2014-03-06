//
//  AudioMobilePlaybackViewController.m
//  Audio-Mobile
//
//

#import "AudioMobilePlaybackViewController.h"
#import "UIImageView+AFNetworking.h"
#import "AudioMobileAppDelegate.h"
#import <AVFoundation/AVFoundation.h>


@interface AudioMobilePlaybackViewController ()

@end

@implementation AudioMobilePlaybackViewController

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

-(void) viewWillDisappear:(BOOL)animated {
    //stop playback to prevent runtime error
    
    if ([self player]) {
        [[self player] stop];
    }
    
}

NSString* oggPlaybackFilename = @"currentPlaybackSelection.ogg";

-(void) viewWillAppear:(BOOL)animated {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    [audioSession setCategory :AVAudioSessionCategoryPlayback error:&err];
    if(err){
        NSLog(@"audioSession: %@ %d %@", [err domain], [err code], [[err userInfo] description]);
    }
    
    if ([self itemInfo]) {
        
        if ([[self itemInfo] objectForKey:@"image"]) {
            NSURL* nodeMainImageURL = [NSURL URLWithString:[[self itemInfo] objectForKey:@"image"]];
            [[self nodeImageView] setImageWithURL:nodeMainImageURL placeholderImage:[UIImage imageNamed:@"LoadingTexture.png"]];
        }
        else {
            if ([ self nodeImage]) {
                [[self nodeImageView] setImage:[self nodeImage]];
            }
        }
        NSString* authorUID = [[self itemInfo] objectForKey:@"author uid"];
        
        internetReachable = [Reachability reachabilityWithHostname:@"www.audiomobile.org"];
        
        UIImageView* creatorThumbnailView = [self creatorThumbnailView];
        // Internet is reachable
        internetReachable.reachableBlock = ^(Reachability*reach)
        {
            // Update the UI on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL* creatorImageURL = [[AudioMobileRestAPIManager sharedInstance] getCreatorThumbnailURL:authorUID] ;
                if (creatorImageURL!=nil) {
                    [creatorThumbnailView setImageWithURL:creatorImageURL placeholderImage:[UIImage imageNamed:@"LoadingTexture.png"]];
                }
                else {
                    [creatorThumbnailView setImage:[UIImage imageNamed:@"LoadingTexture.png"]];
                }
            });
        };

        // Internet is not reachable
        internetReachable.unreachableBlock = ^(Reachability*reach)
        {
            // Update the UI on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"No internet access, cannot query for creator thumbnail image");
                [creatorThumbnailView setImage:[UIImage imageNamed:@"LoadingTexture.png"]];
            });
        };
        
        [internetReachable startNotifier];
        
        [[self creatorNameLabel] setText:[NSString stringWithFormat:@"by %@",[[self itemInfo] objectForKey:@"name"]]];
        
        if ([self titleBarNavItem]) {
            [[self titleBarNavItem] setTitle:[[self itemInfo] objectForKey:@"title"]];
        }
    }
    
    if ([self title]) {
        [[self titleLabel] setText:[self title]];
        if ([self titleBarNavItem]) {
            [[self titleBarNavItem] setTitle:[self title]];
        }
    }
    
    if (!_beganBuffering) {
        //begin downloading our audio file

        //show loading indicator and message that we are buffer
        __block UIActivityIndicatorView* actInd = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [actInd setFrame:[self nodeImageView].frame];
        
        [[self view] addSubview:actInd];
        [actInd startAnimating];
        
        __block float  progress = 0.0;
        
        NSString* audioFileURLPath = [[self itemInfo] objectForKey:@"audio"];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:oggPlaybackFilename];
        
        NSURL* audioFileURL = [NSURL URLWithString:audioFileURLPath];
        if ([audioFileURL isFileURL]) {
            //don't need to download, just use the local version
            NSLog(@"File url passed for playback, don't download");
            [actInd stopAnimating];
            [actInd removeFromSuperview];
            [[self playPauseButton] setEnabled:true];
            [self setBufferingComplete:true];
            [self setOggFileURL:audioFileURL];
            return;
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:audioFileURL];
        
        AFURLConnectionOperation *operation =   [[AFHTTPRequestOperation alloc] initWithRequest:request];
        
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
        
        [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
            progress = (float)totalBytesRead / totalBytesExpectedToRead;
            
        }];
        
        [operation setCompletionBlock:^{
            NSLog(@"download of ogg file Complete!");
            [actInd stopAnimating];
            [actInd removeFromSuperview];
            [[self playPauseButton] setEnabled:true];
            [self setBufferingComplete:true];
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:oggPlaybackFilename];
            
            NSURL* oggPlaybackFileURL = [NSURL fileURLWithPath:filePath];
            [self setOggFileURL:oggPlaybackFileURL];
        }];
        [self setOggDownloadOperation:operation]; //save it so we can cance if we leave this view
        [operation start];
        
        [self setBeganBuffering:true];
    }
    
}

-(void) viewDidDisappear:(BOOL)animated {
    if ([self oggDownloadOperation] && [[self oggDownloadOperation] isExecuting]) {
        [[self oggDownloadOperation] cancel];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)heartPressed:(id)sender {
    if ([self isLiked]) {
        [[self heartButton] setImage:[UIImage imageNamed:@"Heart.png"] forState:UIControlStateNormal];
        [self setIsLiked:false];
        
        //update state on server
        [[AudioMobileRestAPIManager sharedInstance] likeNode:[[self itemInfo] objectForKey:@"nid"] doLike:false];
    }
    else {
        [[self heartButton] setImage:[UIImage imageNamed:@"Heart_ON.png"] forState:UIControlStateNormal];
        [self setIsLiked:true];
        
        //update state on server
        [[AudioMobileRestAPIManager sharedInstance] likeNode:[[self itemInfo] objectForKey:@"nid"] doLike:true];
    }
    
}
- (IBAction)playPausePressed:(id)sender {
    if ([self isPlaying]) {
        [[self playPauseButton] setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
        [self setIsPlaying:false];
        
        if ([self player]) {
            [[self player] pause];
        }
    }
    else {
        [[self playPauseButton] setImage:[UIImage imageNamed:@"Pause.png"] forState:UIControlStateNormal];
        [self setIsPlaying:true];
        if (![self bufferingComplete]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:@"Audio file buffering is not completed."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        if ([self player]) {
            //we've already created a player, so just resume playing
            [[self player] play];
        }
        else {
            //initialize audio player
            //disable the play/pause button while we do this
            [[self playPauseButton] setEnabled:false];
            
            NSURL* oggPlaybackFileURL = [self oggFileURL];
            
            NSError* err;
            
            IDZOggVorbisFileDecoder* decoder = [[IDZOggVorbisFileDecoder alloc] initWithContentsOfURL:oggPlaybackFileURL error:&err];
            
            if (err) {
                NSLog(@"Failed to initialize ogg vorbis decoder due to error: %@", err);
                return;
            }
            
            IDZAQAudioPlayer* player = [[IDZAQAudioPlayer alloc] initWithDecoder:decoder error:&err];
            [player setDelegate:self];
            
            if (err) {
                NSLog(@"Failed to initialize ogg vorbis player due to error: %@", err);
                return;
            }
            
            [self setPlayer:player];
            
            [player play];
            //reenable the playpause button
            [[self playPauseButton] setEnabled:true];
        }
    }
}

/**
 * @brief Called when playback ends.
 */
- (void)audioPlayerDidFinishPlaying:(id<IDZAudioPlayer>)player
                       successfully:(BOOL)flag {
    NSLog(@"playback finished");
    [[self playPauseButton] setImage:[UIImage imageNamed:@"Play.png"] forState:UIControlStateNormal];
}
/**
 * @brief Called when a decode error occurs.
 */
- (void)audioPlayerDecodeErrorDidOccur:(id<IDZAudioPlayer>)player
                                 error:(NSError *)error {
    NSLog(@"decoder error %@",error);
}

@end

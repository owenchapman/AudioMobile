//
//  AudioMobileRestyViewController.m
//  Audio-Mobile
//
//

#import "AudioMobileRestyViewController.h"

@interface AudioMobileRestyViewController ()

@end

@implementation AudioMobileRestyViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)uploadFile:(id)sender {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    NSString* oggVorbisFileURLPath = [NSString pathWithComponents:@[basePath,@"vorbisForUpload.ogg"]];
    NSURL* oggVorbisURL = [[NSURL alloc] initFileURLWithPath:oggVorbisFileURLPath];
    
    NSError* err = nil;
    NSDictionary* fileUploadResponse = [[AudioMobileRestAPIManager sharedInstance] uploadFile:oggVorbisURL withName:@"DevUploadTest02.ogg" error:&err];
    
    if (err) {
        NSLog(@"Failed to upload file due to error: %@",err);
        return;
    }
    
    [[self resultsTextView] setText:[NSString stringWithFormat:@"Successfully uploaded file to server, file ID is %@, file url is %@",[fileUploadResponse objectForKey:@"fid"],[fileUploadResponse objectForKey:@"uri"]]];
}




- (IBAction)getListenedToList:(id)sender {
    NSArray* listenedToList = [[AudioMobileRestAPIManager sharedInstance] getUsersFollowedBy:979];
    
    [[self resultsTextView] setText:[NSString stringWithFormat:@"User listens to users %@",[listenedToList componentsJoinedByString:@","]]];
}

- (IBAction)getListenedToNodes:(id)sender {
    NSArray* nodes = [[AudioMobileRestAPIManager sharedInstance] getNodesForUsersFollowedBy:979 includeSelfNodes:true];
    NSLog(@"nodes listened to by user: %@",nodes);
    
}

- (IBAction)getFeaturedContent:(id)sender {
    bool doLog = false;
    doLog = true;
    NSArray* featuredItems = [[AudioMobileRestAPIManager sharedInstance] getFeaturedItems:0];
    NSMutableString* featuredContentString = [[NSMutableString alloc] init]; 
    for (NSDictionary* featuredItem in featuredItems) {
        [featuredContentString appendFormat:@"Featured item title: %@\n",featuredItem[@"title"],nil];
        if (doLog) NSLog(@"Featured content entry: %@",featuredItem);
    }
    [[self resultsTextView] setText:featuredContentString];
    return;
    
    
    

    NSError *anError;
    NSData *apiCallResponseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://audio-mobile.org/rest/user.json"]];
    if (doLog) {
        NSLog(@"featured content data: %@",[[NSString alloc] initWithData:apiCallResponseData encoding:NSUTF8StringEncoding]);;
    }
    
    NSArray* response = [NSJSONSerialization JSONObjectWithData:apiCallResponseData options:kNilOptions error:&anError];
    //Lets say result is { "key" : "value" }

    NSDictionary* item0 = [response objectAtIndex:0];
    NSString *userName = item0[@"name"];
    NSLog(@"user name for first item is: %@",userName);
    
}

- (IBAction)login:(id)sender {
    
    [self loginPost];
    return;
    
    NSError *anError;
    NSURL* requestURL =[NSURL URLWithString:@"http://audio-mobile.org/rest/user/login.json?username=testusername&password=testpassword"];
    
    NSString* jsonContent = [NSString stringWithContentsOfURL:requestURL encoding:NSUTF8StringEncoding error:&anError];
    if (anError) {
        NSLog(@"Error: %@",anError);
        NSLog(@"Error: %@",[anError localizedDescription]);
        NSDictionary *userInfo = [anError userInfo];
        NSString *errorDesc = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        NSLog(@"Underlying error description: %@", errorDesc);
        
    }
    else {
        NSLog(@"no error occured");
    }
    [[self resultsTextView] setText:jsonContent];
}

-(void) loginPost {
    [[AudioMobileRestAPIManager sharedInstance] login:@"testusername" password:@"testpassword" AndNotify:self];

}

-(void) loginCompletedWithResult:(AMLOGINSTATUS)loginStatus {
    if (loginStatus == AMLOGINFAIL) {
        NSLog(@"Failed to login to audio-mobile server");
        
    }
    else {
        NSLog(@"Successfully logged into audio-mobile server");
    }
    
}


- (IBAction)logout:(id)sender {
    bool posty = false;
    if (posty) {
        
    }
    else {
        NSError *anError;
        NSURL* requestURL =[NSURL URLWithString:@"http://audio-mobile.org/rest/user/logout"];
        
        NSString* jsonContent = [NSString stringWithContentsOfURL:requestURL encoding:NSUTF8StringEncoding error:&anError];
        NSLog(@"logout return content: %@",jsonContent);
        if (anError) {
            NSLog(@"Error: %@",anError);
            NSLog(@"Error: %@",[anError localizedDescription]);
            NSDictionary *userInfo = [anError userInfo];
            NSString *errorDesc = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
            NSLog(@"Underlying error description: %@", errorDesc);
        }
        else {
            NSLog(@"no error occured");
        }
    }
}

- (IBAction)gimmeCookies:(id)sender {
    NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://audio-mobile.org"]];
    
    for(NSHTTPCookie* cookie in cookies) {
        NSLog(@"Cookie! %@:%@",[cookie name],[cookie value]);
    }
}

- (IBAction)clearCookies:(id)sender {
    NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://audio-mobile.org"]];
    
    for(NSHTTPCookie* cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

- (IBAction)getCSRFToken:(id)sender {
    NSError *anError;
    NSURL* requestURL =[NSURL URLWithString:@"http://audio-mobile.org/services/session/token"];
    
    NSString* jsonContent = [NSString stringWithContentsOfURL:requestURL encoding:NSUTF8StringEncoding error:&anError];
    if (anError) {
        NSLog(@"Error: %@",anError);
        NSLog(@"Error: %@",[anError localizedDescription]);
        NSDictionary *userInfo = [anError userInfo];
        NSString *errorDesc = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        NSLog(@"Underlying error description: %@", errorDesc);
        
    }
    else {
        NSLog(@"no error occured");
        [[self resultsTextView] setText:jsonContent];
    }

}

- (IBAction)getListenToContent:(id)sender {
    
    NSError *anError;
    NSURL* requestURL =[NSURL URLWithString:@"http://audio-mobile.org/rest/views/followed_users.json?uid=979"];
    
    NSString* jsonContent = [NSString stringWithContentsOfURL:requestURL encoding:NSUTF8StringEncoding error:&anError];
    if (anError) {
        NSLog(@"Error: %@",anError);
        NSLog(@"Error: %@",[anError localizedDescription]);
        NSDictionary *userInfo = [anError userInfo];
        NSString *errorDesc = [[userInfo objectForKey:NSUnderlyingErrorKey] localizedDescription];
        NSLog(@"Underlying error description: %@", errorDesc);
        
    }
    else {
        NSLog(@"no error occured");
        [[self resultsTextView] setText:jsonContent];
    }
    
}




#pragma mark NSURLConnectionDelegate methods (optional)

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"faied with error %@",error);
}
//- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;
//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

// Deprecated authentication delegates.
//- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
//- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;


#pragma mark NSURLConnectionDataDelegate methods (optional) 

//- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response;
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
//    NSLog(@"Received data: %@", data);
    NSLog(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

//- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request;
//- (void)connection:(NSURLConnection *)connection   didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten
//totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;

//- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end

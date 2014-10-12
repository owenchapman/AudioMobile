//
//  AudioMobileRestAPIManager.m
//  Audio-Mobile
//
//

#import "AudioMobileRestAPIManager.h"
#import "AFNetworking.h"
#import "AFURLRequestSerialization.h"
#import "NSString+URLEncoding.h"
#import "AudioMobileDataModel.h"
#import "AudioMobileAppDelegate.h"

@implementation AudioMobileRestAPIManager


NSString* restEndpoint = @"http://audio-mobile.org/rest/";

NSString* csrfTokenHeaderName = @"X-CSRF-Token";

NSString* getNodesForUIDList = @"http://audio-mobile.org/rest/views/getcontentbypage.json?page=0&args%5B0%5D=all&args%5B1%5D="; //Note: url should be appended with comma separated list of UIDs

NSString* likeNodeURLFormatString = @"http://audio-mobile.org/rest/flag/flag?flag_name=like&entity_id=%d&action=%@"; //Note: url should be appended with comma

bool doLog = false;


#pragma mark singleton accessor method, returns a singleton object of this class for use across the application

+ (AudioMobileRestAPIManager*)sharedInstance {
    static AudioMobileRestAPIManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {

    }
    return self;
}

-(UIImage*) getCreatorThumbnail:(NSString*)creatorID {
    
    NSError *apiError;
    
    NSURL* creatorInfoURL = [NSURL URLWithString:[restEndpoint stringByAppendingFormat:@"views/getusers.json?args=%@",creatorID]];
    
    NSData* creatorInfoJsonData = [NSData dataWithContentsOfURL:creatorInfoURL];
    
    NSArray* creatorInfoArray = [NSJSONSerialization JSONObjectWithData:creatorInfoJsonData options:kNilOptions error:&apiError];
    if (apiError) {
        NSLog(@"error attempting to retrieve and decode json data for user id %@",creatorID);
        return nil;
    }
    
    if (!creatorInfoArray || [creatorInfoArray count]==0) {
        NSLog(@"creator info array was null or had size 0, could not retrieve creator infor to retrieve creator thumbnail image");
        return nil;
    }
    NSDictionary* creatorInfo = [creatorInfoArray objectAtIndex:0];
    

    
    NSString* pictureID = creatorInfo[@"user image"];
    if (!pictureID) {
        NSLog(@"error, user object for user id %@ contains no 'picture' element",creatorID);
        return nil;
    }
    else if ([pictureID isEqualToString:@"0"] || [pictureID isEqualToString:@"null"]) {
        NSLog(@"error, picture element for user id %@ contains '0' of 'null' value",creatorID);
        return nil;
    }
    
    
    UIImage* creatorPic = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:pictureID]]];
    return creatorPic;
}

-(void) uploadProfilePic:(NSData*)pic notify:(id<AudioMobileRestAsyncResponseNotifier>)responder {
//    NSString* imageFileName = [[pic pathComponents] objectAtIndex:[[pic pathComponents] count]-1];
    
    //first upload the profile pic
    NSError* error = nil;
    //    [[image pathComponents] objectAtIndex:[[image pathComponents] count]-1];
    
    //TODO determine if png is the correct file type
    NSString* titledImageFileName = @"userProfilePic.png";
    NSDictionary* imageFileInfo = [self uploadFileData:pic withName:titledImageFileName fileSize:[NSNumber numberWithUnsignedInteger:[pic length]] error:&error];
    if (error || imageFileInfo == nil) {
        NSLog(@"Failed to upload image file for node due to error: %@",error);
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return;
    }
    
    //now send the message to the server indicating that this picture should be used as the user's profile image
    
    
    NSString* requestURL = [restEndpoint stringByAppendingString:[NSString stringWithFormat:@"user/%ld",(long)[self uid]]];
    
//    NSLog(@"Request url to server is %@",requestURL);
    
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
    
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self setCsrfTokenOn:request];
    
    

    
    NSDictionary* postDataDict0 = @{@"current_pass":[NSString stringWithFormat:@"%@",[[AudioMobileAppDelegate sharedInstance] getSavedPassword]]  ,
                                    @"field_userdata_image[und][0][fid]":[NSString stringWithFormat:@"%@",[imageFileInfo objectForKey:@"fid"]],
                                    @"field_userdata_image[und][0][uri]":[NSString stringWithFormat:@"http://audio-mobile.org/rest/file/%@",[imageFileInfo objectForKey:@"fid"]],
                                    };
    //TODO consider padding month and day fields, in case they are expected by drupal to be two character values.
    NSMutableDictionary* postDataDict = [[NSMutableDictionary alloc] initWithDictionary:postDataDict0];
    
    bool sendJsonBody = false;
    bool useExampleJson = false;
    NSData* postData ;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"node_upload_example" ofType:@"json"];
    
    if (!sendJsonBody) {
        if (useExampleJson) {
            postData = [NSData dataWithContentsOfFile:filePath];
            error = nil;
            postDataDict = [NSJSONSerialization JSONObjectWithData:postData options:0 error:&error];
            if (error) {
                NSLog(@"Failed to deserialize example json to dictionary object due to error %@",error);
                if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
                return;
            }
            
        }
        
        postData= [self urlEncodeDictionaryWithJSONValues:postDataDict];
        
    }
    else {
        error = nil;
        postData = [NSJSONSerialization dataWithJSONObject:postDataDict options:0 error:&error];
        
        if (useExampleJson) {
            postData = [NSData dataWithContentsOfFile:filePath];
        }
        
        
        if (error) {
            NSLog(@"Failed to serialize post data as json due to error %@",error);
            if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
            return;
        }
        NSString* postJsonString = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
//        NSLog(@"postData json is %@",postJsonString);
        postData = [[postJsonString urlEncodeUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    }
    
//    NSLog(@"Here is the post data for our node post attempt: %@",postDataDict);
    [request setHTTPMethod:@"PUT"];
    
//    NSLog(@"Here is the url encoded post data for our profile pic upload attempt: %@",[[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLResponse* response;
    error = nil;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error || !responseData) {
        NSLog(@"Error occured in post file request: %@",error);
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return ;
        
    }
    else {
//        NSLog(@"Response data from node post was: %@, and response status code was %ld",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding],(long)[((NSHTTPURLResponse*) response) statusCode]);
    }
    error = nil;
    NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    
    if (error) {
        NSLog(@"failed to deserialize json resposne for file post due to error: %@, response was %@",error,[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return ;
    }
    NSLog(@"json response was %@",responseDict);
    
    if (![responseDict objectForKey:@"field_userdata_image"]) {
        NSLog(@"ERROR:  Failed to upload node, server returned invalid response;  expected 'nid' field, but found none");
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return ;
    }
    
    if (responder) [responder uploadCompletedWithResult:AMUPLOADSUCCESS];
    return;

}


-(void) uploadNode:(NSString*)title notes:(NSString*)notes imageFile:(NSURL*)image audioFile:(NSURL*)audio recordingLength:(NSTimeInterval) duration weather:(NSString*)weatherCode geodata:(CLLocationCoordinate2D)geodata secondaryGeodata:(NSSet*) subsequentLocations subsequentLocationTimepoints:(NSArray*) timepointIntervals private:(BOOL) isPrivate date:(NSDate*) date locationDescription:(NSString*) locationDescription error:(NSError**) error notify:(id<AudioMobileRestAsyncResponseNotifier>)responder{
    
    NSString* imageFileName = [[image pathComponents] objectAtIndex:[[image pathComponents] count]-1];
    
    //first upload the two files
    //first upload the image, because it's probably the smaller of the two files and we'd prefer to fail sooner rather than later if there is a generic problem with file uploads
    error = nil;
//    [[image pathComponents] objectAtIndex:[[image pathComponents] count]-1];
    
    NSString* titledImageFileName = [title stringByAppendingString:[NSString stringWithFormat:@".%@",[image pathExtension]]];
    NSDictionary* imageFileInfo = [self uploadFile:image withName:titledImageFileName error:error];
    if (error) {
        NSLog(@"Failed to upload image file for node due to error: %@",*error);
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return;
    }

    
    
    NSString* titledAudioFileName = [title stringByAppendingString:[NSString stringWithFormat:@".%@",[audio pathExtension]]];
    
    NSString* audioFileName = [[audio pathComponents] objectAtIndex:[[audio pathComponents] count]-1];
    //then upload the audio file
    error = nil;
    NSDictionary* audioFileInfo = [self uploadFile:audio withName:titledAudioFileName error:error];
    if (error) {
        NSLog(@"Failed to upload audio file for node due to error: %@",*error);
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return;
    }
    
    //now that we have the audio and image files uploaded, create the node which encapsulates the audio and visual data

    [self uploadNode:title notes:notes imageID:[imageFileInfo objectForKey:@"fid"] imageURL:[imageFileInfo objectForKey:@"uri"] audioID:[audioFileInfo objectForKey:@"fid"] audioURL:[audioFileInfo objectForKey:@"uri"] recordingLength:duration weather:weatherCode geodata:geodata secondaryGeodata: subsequentLocations subsequentLocationTimepoints:timepointIntervals private:isPrivate date:date locationDescription:locationDescription error:error notify:responder];
    
    
}

-(NSString*) getComponent:(NSString*)dateComponentFormat fromDate:(NSDate*) date {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateFormat:dateComponentFormat];
    return [dateFormatter stringFromDate:date];
}


//this creates the node entry on the server, expecting that the component audio and photo files have been uploaded, and so only the file ids of those files are sent
-(void) uploadNode:(NSString*)title notes:(NSString*)notes imageID:(NSString*)imageID imageURL:(NSString*) imageURL  audioID:(NSString*)audioID audioURL:(NSString*) audioURL recordingLength:(NSTimeInterval) duration weather:(NSString*)weatherCode geodata:(CLLocationCoordinate2D)geodata secondaryGeodata:(NSSet*) subsequentLocations subsequentLocationTimepoints:(NSArray*) timepointIntervals private:(BOOL) isPrivate date:(NSDate*) date locationDescription:(NSString*) locationDescription error:(NSError**) error notify:(id<AudioMobileRestAsyncResponseNotifier>)responder{
    
    NSString* requestURL = [restEndpoint stringByAppendingString:@"node"];
    
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self setCsrfTokenOn:request];

    NSString* dateComponentString = [NSString stringWithFormat:@"{month:'%@',year:'%@',day:'%@',hour:'%@',minute:'%@',second:'%@'}",
                                     [self getComponent:@"M" fromDate:date],
                                     [self getComponent:@"y" fromDate:date],
                                     [self getComponent:@"d" fromDate:date],
                                     [self getComponent:@"H" fromDate:date],
                                     [self getComponent:@"mm" fromDate:date],
                                     [self getComponent:@"ss" fromDate:date]];
    
    //create subsequent locations entry, if any
    NSMutableString* subsequentLocationsPostValue = [[NSMutableString alloc] init];

//    subsequentLocationsPostValue appendFormat:@"field_geodata_linestring[und][0][wkt]"
    [subsequentLocationsPostValue appendFormat:@"LINESTRING ("];
    [subsequentLocationsPostValue appendString:[NSString stringWithFormat:@"%f %f",geodata.longitude,geodata.latitude]];
    
     NSSortDescriptor * sortByDate =
     [[NSSortDescriptor alloc] initWithKey:@"timeVisited" ascending:YES];
     
     NSArray * descriptors = [NSArray arrayWithObject:sortByDate];

    for(LocationVisit* subsequentLocation in [subsequentLocations sortedArrayUsingDescriptors:descriptors]) {
        double subsLat = [[subsequentLocation latitude] doubleValue];
        double subsLon = [[subsequentLocation longitude] doubleValue];
        [subsequentLocationsPostValue appendString:[NSString stringWithFormat:@",%f %f",[[subsequentLocation longitude] doubleValue],[[subsequentLocation latitude] doubleValue]]];
    }
    
    [subsequentLocationsPostValue appendString:@")"];
    
//    NSLog(@"uploading seriallocation data %@", subsequentLocationsPostValue);
    
    NSDictionary* postDataDict0 = @{@"type": @"audio_node",
                                   @"language":@"und",
                                   @"title":title,
                                   @"body[und][0][value]":notes,
                                   @"field_audionode_audio[und][0][filepath]":audioURL,
                                   @"field_audionode_audio[und][0][fid]":audioID,
                                   @"field_audionode_image[und][0][filepath]":imageURL,
                                   @"field_audionode_image[und][0][fid]":imageID,
//                                   @"field_geodata_linestring[und][0][wkt]":subsequentLocationsPostValue,
                                   @"field_geodata_linestring[und][0][geo_type]":@"linestring",
                                   @"field_geodata[und][0][wkt]":[NSString stringWithFormat:@"Point (%f,%f)",geodata.longitude,geodata.latitude],
                                   @"field_geodata[und][0][geo_type]":@"point",
                                   @"field_geodata[und][0][lon]":[NSString stringWithFormat:@"%f",geodata.longitude],
                                   @"field_geodata[und][0][lat]":[NSString stringWithFormat:@"%f",geodata.latitude],
                                   @"field_audionode_privacy[und][0][value]":isPrivate?@"private":@"public",
//                                   @"field_audionode_weather[und][0][tid]":weatherCode,
                                   @"field_audionode_weather[und]":weatherCode,                                    
                                   @"field_duration[und][0][value]":[NSString stringWithFormat:@"%f",duration],
                                   @"field_non_geo_location[und][0][value]":locationDescription,

                                   @"field_recording_datetime[und][0][value][month]":[self getComponent:@"M" fromDate:date],
                                   @"field_recording_datetime[und][0][value][year]":[self getComponent:@"y" fromDate:date],
                                   @"field_recording_datetime[und][0][value][day]":[self getComponent:@"d" fromDate:date],
                                   @"field_recording_datetime[und][0][value][hour]":[self getComponent:@"H" fromDate:date],
                                   @"field_recording_datetime[und][0][value][minute]":[self getComponent:@"mm" fromDate:date],
                                   @"field_recording_datetime[und][0][value][second]":[self getComponent:@"ss" fromDate:date],
                                    @"field_time_interval[und][0][value]":[NSString stringWithFormat:@"%@",[subsequentLocations count]==0?@"0":@"1"]
                                   };
    //TODO consider padding month and day fields, in case they are expected by drupal to be two character values.
     NSMutableDictionary* postDataDict = [[NSMutableDictionary alloc] initWithDictionary:postDataDict0];
    
    //add linestring of subsequent coordinate geodata, but only if it wasn't a static recording.
    if ([subsequentLocations count] >0) {
        [postDataDict setObject:subsequentLocationsPostValue forKey:@"field_geodata_linestring[und][0][wkt]"];
        
        //record the values for the subsequent location timepoints
        //set timepoint for first location value
        int subsequentLocationIndex = 0;
        [postDataDict setObject:[NSString stringWithFormat:@"%lu",(unsigned long) [date timeIntervalSince1970] ] forKey:[NSString stringWithFormat:@"field_time_array[und][%d][value]",subsequentLocationIndex]];
        subsequentLocationIndex++;
        
        
        for(LocationVisit* subsequentLocation in [subsequentLocations sortedArrayUsingDescriptors:descriptors]) {
            [postDataDict setObject:[NSString stringWithFormat:@"%lu",(unsigned long) [[subsequentLocation timeVisited] timeIntervalSince1970] ] forKey:[NSString stringWithFormat:@"field_time_array[und][%d][value]",subsequentLocationIndex]];
            subsequentLocationIndex++;
        }
    }
    


    
    bool sendJsonBody = false;
    bool useExampleJson = false;
    NSData* postData ;
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"node_upload_example" ofType:@"json"];
    
    if (!sendJsonBody) {
        if (useExampleJson) {
            postData = [NSData dataWithContentsOfFile:filePath];
            error = nil;
            postDataDict = [NSJSONSerialization JSONObjectWithData:postData options:0 error:error];
            if (error) {
                NSLog(@"Failed to deserialize example json to dictionary object due to error %@",*error);
                if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
                return;
            }
            
        }

        postData= [self urlEncodeDictionaryWithJSONValues:postDataDict];
        
    }
    else {
        error = nil;
        postData = [NSJSONSerialization dataWithJSONObject:postDataDict options:0 error:error];
        
        if (useExampleJson) {
            postData = [NSData dataWithContentsOfFile:filePath];
        }

        
        if (error) {
            NSLog(@"Failed to serialize post data as json due to error %@",*error);
            if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
            return;
        }
        NSString* postJsonString = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
//        NSLog(@"postData json is %@",postJsonString);
        postData = [[postJsonString urlEncodeUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSLog(@"Here is the post data for our node post attempt: %@",postDataDict);
    [request setHTTPMethod:@"POST"];

    NSLog(@"Here is the url encoded post data for our node post attempt: %@",[[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);
    [request setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLResponse* response;
    error = nil;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
    
    if (error || !responseData) {
        NSLog(@"Error occured in post file request: %@",*error);
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return ;
        
    }
    else {
//        NSLog(@"Response data from node post was: %@, and response status code was %d",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding],[((NSHTTPURLResponse*) response) statusCode]);
    }
    error = nil;
    NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:error];

    if (error) {
        NSLog(@"failed to deserialize json resposne for file post due to error: %@, response was %@",*error,[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return ;
    }
//    NSLog(@"json response was %@",responseDict);
    
    if (![responseDict objectForKey:@"nid"]) {
        NSLog(@"ERROR:  Failed to upload node, server returned invalid response;  expected 'nid' field, but found none");
        if (responder) [responder uploadCompletedWithResult:AMUPLOADFAIL];
        return ;
    }
    
    if (responder) [responder uploadCompletedWithResult:AMUPLOADSUCCESS];
    return;
    
}


- (NSData*)urlEncodeDictionary:(NSDictionary*)dictionary {
    
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSString *key in dictionary) {
        NSString *encodedValue = [[dictionary objectForKey:key] urlEncodeUsingEncoding:NSUTF8StringEncoding]; //alternate encoding method from category which will do proper url encoding
        NSString *encodedKey = [key urlEncodeUsingEncoding:NSUTF8StringEncoding]; //alternate encoding method from category which will do proper url encoding
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    NSString *encodedDictionary = [parts componentsJoinedByString:@"&"];
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData*)urlEncodeDictionaryWithJSONValues:(NSDictionary*)dictionary {
    
    NSMutableArray *parts = [[NSMutableArray alloc] init];
    for (NSString *key in dictionary) {
        id value = [dictionary objectForKey:key];
        NSString *encodedValue;
        if ([value isKindOfClass:[NSString class]]) {
            
            encodedValue = [[dictionary objectForKey:key] urlEncodeUsingEncoding:NSUTF8StringEncoding]; //alternate encoding method from category which will do proper url encoding
            NSLog(@"Here is the value string for key %@: %@, and the url encoded value: %@",key,value,encodedValue);
        }
        else {
            //object is not a string, should be a nsdictionary or an nsarray which we must convert to a json string before url encoding it
            if (![NSJSONSerialization isValidJSONObject:value]) {
                NSLog(@"error:  invalid json object passed to url encoder: %@",value);
                return nil;
            }
            NSError* err;
            value = [NSJSONSerialization dataWithJSONObject:value options:NSJSONWritingPrettyPrinted error:&err];
            if (err) {
                NSLog(@"Failed to serialize json to string due to error %@",err);
                return nil;
            }
            NSLog(@"Here is the json serialized value string for key %@: %@",key,[[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding]);
            NSString* valueString = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            if ([[NSNull null] isEqual:valueString]) {
               encodedValue = @"";
            }
            else {
               encodedValue = [valueString urlEncodeUsingEncoding:NSUTF8StringEncoding];
            }
            NSLog(@"Here is the url encoded json string for key %@: %@",key,encodedValue);
            
        }
        
        NSString *encodedKey = [key urlEncodeUsingEncoding:NSUTF8StringEncoding]; //alternate encoding method from category which will do proper url encoding
        NSString *part = [NSString stringWithFormat: @"%@=%@", encodedKey, encodedValue];
        [parts addObject:part];
    }
    NSString *encodedDictionary = [parts componentsJoinedByString:@"&"];
    return [encodedDictionary dataUsingEncoding:NSUTF8StringEncoding];
}


-(NSDictionary*) uploadFileData:(NSData*) fileData withName:(NSString*)fileName fileSize:(NSNumber*) originalFileSize error:(NSError**)error {
    if (![self csrfToken]) {
        NSLog(@"Cannot upload without csrf token");
        return nil;
    }
    
    if ([self uid] ==0) {
        NSLog(@"UID is 0, UID has not been set, user is not logged in");
        return nil;
    }
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[restEndpoint stringByAppendingString:@"file.json"]]];
    
    
    NSData* fileContentsBase64 = [fileData base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString* filepath = [NSString stringWithFormat:@"public://%@",fileName];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"]; //consider trying this alternate content-type with charset info
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [self setCsrfTokenOn:request];
    
    
    NSDictionary* postDataDict = @{@"filename":fileName,
                                   @"filesize":[originalFileSize stringValue],
                                   @"filepath":filepath,
                                   @"file":[[NSString alloc] initWithData:fileContentsBase64 encoding:NSUTF8StringEncoding]
                                   };
    NSLog(@"attempting to post file with filename %@ to path %@ with filesize %@",postDataDict[@"filename"],postDataDict[@"filepath"],postDataDict[@"filesize"]);
    
    
    
    [request setHTTPMethod:@"POST"];
    
    NSData* postData = [self urlEncodeDictionary:postDataDict];
    [request setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    NSURLResponse* response;
    error = nil;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:error];
    
    if (error) {
        NSLog(@"Error occured in post file request: %@",*error);
        
        return nil;
    }
    NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:error];
    error = nil;
    if (error) {
        NSLog(@"failed to deserialize json resposne for file post due to error: %@, response was %@",*error,[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        return nil;
    }
    
    return responseDict;
    
}

-(NSDictionary*) uploadFile:(NSURL*) fileURL withName:(NSString*)fileName error:(NSError**)error {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
        NSLog(@"upload file does not exist!");
    }
    
    NSNumber* originalFileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:[fileURL path] error:error] objectForKey:NSFileSize];
    
    return [self uploadFileData:[NSData dataWithContentsOfURL:fileURL] withName:fileName fileSize:originalFileSize  error:error];
    
    
    
}


-(NSURL*) getCreatorThumbnailURL:(NSString*)creatorID {
    
    NSError *apiError;
    
    NSURL* creatorInfoURL = [NSURL URLWithString:[restEndpoint stringByAppendingFormat:@"views/getusers.json?args=%@",creatorID]];
    
    NSData* creatorInfoJsonData = [NSData dataWithContentsOfURL:creatorInfoURL];
    
    NSArray* creatorInfoArray = [NSJSONSerialization JSONObjectWithData:creatorInfoJsonData options:kNilOptions error:&apiError];
    if (apiError) {
        NSLog(@"error attempting to retrieve and decode json data for user id %@",creatorID);
        return nil;
    }
    
    if (!creatorInfoArray || [creatorInfoArray count]==0) {
        NSLog(@"creator info array was null or had size 0, could not retrieve creator infor to retrieve creator thumbnail image");
        return nil;
    }
    NSDictionary* creatorInfo = [creatorInfoArray objectAtIndex:0];
    
    
    
    NSString* pictureID = creatorInfo[@"user image"];
    if (!pictureID || [pictureID isKindOfClass:[NSNull class]]) {
        NSLog(@"error, user object for user id %@ contains no 'picture' element",creatorID);
        return nil;
    }
    else if ([pictureID isEqualToString:@"0"] || [pictureID isEqualToString:@"null"]) {
        NSLog(@"error, picture element for user id %@ contains '0' of 'null' value",creatorID);
        return nil;
    }
    
    return [NSURL URLWithString:pictureID];
}




-(NSArray*) getFeaturedItems:(NSUInteger) pageNumber { //TODO revise to take a limit to number of results


    NSError *apiError;
    
    NSString* requestURLPath = [[restEndpoint stringByAppendingString:@"views/getcontentbypage.json?featured=1&page="] stringByAppendingFormat:@"%d",pageNumber ];
    
    NSLog(@"featured item request url: %@",requestURLPath);
    
    
    NSData *apiCallResponseData = [NSData dataWithContentsOfURL:[NSURL URLWithString:requestURLPath]];
    if (doLog) {
        NSLog(@"featured content data: %@",[[NSString alloc] initWithData:apiCallResponseData encoding:NSUTF8StringEncoding]);;
    }
    if (!apiCallResponseData) {
        NSLog(@"Error: call to retrieve featured item returned no data");
        return nil;
    }
    NSArray* response = [NSJSONSerialization JSONObjectWithData:apiCallResponseData options:kNilOptions error:&apiError];
    if (apiError) {
        NSLog(@"Error retrieving page %d of Featured content: %@",pageNumber,apiError);
    }
    
    if ([response count] == 0) {
        NSLog(@"Warning: request for featured items returned an array of size zero; no featured items on server.");
        return @[];
    }
    
    NSDictionary* item0 = [response objectAtIndex:0];
    NSString *userName = item0[@"name"];
    NSLog(@"user name for first item is: %@",userName);
    
    return response;
}

-(void) setCsrfTokenOn:(NSMutableURLRequest*) request {
    if (![self csrfToken]) {
        NSLog(@"Cannot upload without csrf token");
        return;
    }
    
    NSLog(@"setting csrf token %@ in get users followed by call",[self csrfToken]);
    [request setValue:[self csrfToken] forHTTPHeaderField:csrfTokenHeaderName];
}

-(NSArray*) getUsersFollowedBy:(NSUInteger)uid {
    NSError* err;
    
    NSString* requestURLString = [restEndpoint stringByAppendingString:@"flag/following.json"];
    NSLog(@"retrieving list of users followed by user through url %@",requestURLString);
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURLString]];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/xml"
   forHTTPHeaderField:@"Content-type"];
    
    //set csrf header
    if (![self csrfToken]) {
        NSLog(@"Cannot upload without csrf token");
        return nil;
    }
    NSLog(@"setting csrf token %@ in get users followed by call",[self csrfToken]);
    [request setValue:[self csrfToken] forHTTPHeaderField:csrfTokenHeaderName];
    
    NSString *xmlString = [NSString stringWithFormat:@"<data><flag_name>follow</flag_name><content_id>%d</content_id></data>",uid];
    
    [request setValue:[NSString stringWithFormat:@"%d",
                       [xmlString length]]
   forHTTPHeaderField:@"Content-length"];
    
    [request setHTTPBody:[xmlString
                          dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLResponse* response;
    err = nil;
    NSData* followedUserList = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (err) {
        NSLog(@"Failed to retrieve list of users followed by user due to error: %@",err);
    }
    NSLog(@"Retrieved the following list of users followed by user: %@",[[NSString alloc] initWithData:followedUserList encoding:NSUTF8StringEncoding]);
    NSArray* userList = [NSJSONSerialization JSONObjectWithData:followedUserList options:kNilOptions error:&err];
    if (err) {
        NSLog(@"Failed to deserialize user list due to error %@",err);
        return nil;
    }
    return userList;
}

-(NSArray*) getNodesInRegionLatMin:(double) latMin latMax:(double)latMax lonMin:(double)lonMin lonMax:(double) lonMax {
    NSError* err;
    //TODO refactor to take page number into account
    
    NSURL* requestURL = [NSURL URLWithString:[restEndpoint stringByAppendingFormat:@"views/boundingbox.json?lat[min]=%f&lat[max]=%f&lon[min]=%f&lon[max]=%f",latMin,latMax,lonMin,lonMax]];
    NSLog(@"URL for retrieving nodes in region: %@",requestURL);
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    
    [self setCsrfTokenOn:request];
    
    NSURLResponse* response;
    NSData* nodeData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (err) {
        NSLog(@"Failed to retrieve nodes within region due to error %@",err );
        return nil;
    }
    
    NSArray* nodesGeneratedByUsers = [NSJSONSerialization JSONObjectWithData:nodeData options:kNilOptions error:&err];
    if (err) {
        NSLog(@"Failed to deserialize node list due to error %@",err);
        return nil;
    }
    
    return nodesGeneratedByUsers;
}

-(bool) likeNode:(NSString*) nodeID doLike:(bool) like {
    NSMutableURLRequest* request;
    NSString *xmlString;
    if (like) {
        request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:likeNodeURLFormatString,[nodeID intValue],@"flag" ]]];
        xmlString = [NSString stringWithFormat:@"<data><flag_name>%@</flag_name><entity_id>%@</entity_id><action>%@</action></data>",@"like",nodeID,@"flag"];
        NSLog(@"%@",xmlString);
//        NSLog(@"%@",[request ])
    }
    else {
        //unlike the node
        request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:likeNodeURLFormatString,[nodeID intValue],@"unflag" ]]];
        xmlString = [NSString stringWithFormat:@"<data><flag_name>%@</flag_name><entity_id>%@</entity_id><action>%@</action></data>",@"like",nodeID,@"unflag"];
        NSLog(@"%@",xmlString);
    }

    [self setCsrfTokenOn:request];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/xml"
   forHTTPHeaderField:@"Content-type"];
    

    [request setValue:[NSString stringWithFormat:@"%d",
                       [xmlString length]]
   forHTTPHeaderField:@"Content-length"];
    
    [request setHTTPBody:[xmlString
                          dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    //create background queue on which to run ogg vorbis encoding
    dispatch_queue_t myQueue = dispatch_queue_create("LikeQueue",NULL);
    
    dispatch_async(myQueue, ^{
        // Perform long running process
        NSError* err;
        NSURLResponse* response;
        NSData* nodeData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
        if (err) {
            NSLog(@"Failed to like node due to error %@",err );
//            return false;
        }
        
        NSLog(@"Result of liking node was %@",[[NSString alloc] initWithData:nodeData encoding:NSUTF8StringEncoding]);

        dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            NSLog(@"like completed");
            
        });
    });

    return false;
}

-(NSArray*) getNodes:(NSArray*) nodeIDs {
    NSError* err;
    //TODO refactor to take page number into account
    if (nodeIDs==nil) {
        return nil;
    }
    
    NSURL* requestURL = [NSURL URLWithString:[restEndpoint stringByAppendingFormat:@"views/getcontentbypage.json?args[0]=%@&args[1]=all",[nodeIDs componentsJoinedByString:@","]]];
    NSLog(@"URL for retrieving nodes in region: %@",requestURL);
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    
    NSURLResponse* response;
    NSData* nodeData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (err) {
        NSLog(@"Failed to retrieve nodes within region due to error %@",err );
        return nil;
    }
    
    NSArray* nodesGeneratedByUsers = [NSJSONSerialization JSONObjectWithData:nodeData options:kNilOptions error:&err];
    if (err) {
        NSLog(@"Failed to deserialize node list due to error %@",err);
        return nil;
    }
    
    return nodesGeneratedByUsers;
}

-(NSArray*) getNodesMatchingSearchPhrase:(NSString*) searchPhrase {
    NSError* err;
    //TODO refactor to take page number into account
    if (searchPhrase==nil || [searchPhrase isEqualToString:@""]) {
        return nil;
    }
    NSURL* requestURL = [NSURL URLWithString:[restEndpoint stringByAppendingFormat:@"sitesearch.json?keys=%@",[searchPhrase urlEncodeUsingEncoding:NSUTF8StringEncoding]]];
    NSLog(@"URL for retrieving nodes by keyword(s): %@",requestURL);
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:requestURL];
    
    NSURLResponse* response;
    NSData* nodeData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (err) {
        NSLog(@"Failed to retrieve nodes by search phrase due to error %@",err );
        return nil;
    }
    
    NSArray* nodesForSearch = [NSJSONSerialization JSONObjectWithData:nodeData options:kNilOptions error:&err];
    if (err) {
        NSLog(@"Failed to deserialize node list due to error %@",err);
        return nil;
    }
    
    return [self augmentAndReformatSearchResults:nodesForSearch]  ;
}

//this will take the results returned by the siteSearch.json endpoint and convert it into the format returned by getcontentbypage format.
-(NSArray*) augmentAndReformatSearchResults:(NSArray*) searchResults {
    
    NSMutableArray* nodeIDs = [[NSMutableArray alloc] initWithCapacity:[searchResults count]];
    for(int i=0;i<[searchResults count];i++) {
        [nodeIDs addObject:[[searchResults objectAtIndex:i] objectForKey:@"nid"]];
    }
    
    return [self getNodes:nodeIDs];
}




-(NSArray*) getNodesForUsers:(NSArray*) users {
    NSError* err;
    //TODO refactor to take page number into account
    if (users == nil) {
        return nil;
    }
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[getNodesForUIDList stringByAppendingString:[users componentsJoinedByString:@","]]]];
    
    [self setCsrfTokenOn:request];
    
    NSURLResponse* response;
    NSData* nodeData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    if (err) {
        NSLog(@"Failed to retrieve nodes genereated by for users due to error %@",err );
        return nil;
    }
    
    NSArray* nodesGeneratedByUsers = [NSJSONSerialization JSONObjectWithData:nodeData options:kNilOptions error:&err];
    if (err) {
        NSLog(@"Failed to deserialize node list due to error %@",err);
        return nil;
    }
    
    return nodesGeneratedByUsers;
}

-(NSArray*) getNodesForUsersFollowedBy:(NSUInteger) userID includeSelfNodes:(bool) includeSelf {

    NSArray* followedUserIDs = [self getUsersFollowedBy:userID];
    if (includeSelf) {
        NSMutableArray* inclusiveFollowedUserIDs = [NSMutableArray arrayWithArray:followedUserIDs];
        [inclusiveFollowedUserIDs addObject:[NSString stringWithFormat:@"%u",userID]];
        return [self getNodesForUsers:inclusiveFollowedUserIDs];
    }
    else {
        return [self getNodesForUsers:followedUserIDs];
    }
}



NSString* loginURL = @"http://audio-mobile.org/rest/user/login.json";      //TODO IMPORTANT SECURITY: revise to use https url once server has been configured to support that mode.
NSString* csrfTokenRequestURL = @"http://audio-mobile.org/services/session/token";      //TODO IMPORTANT SECURITY: revise to use https url once server has been configured to support that mode.

-(void) login:(NSString*)username password:(NSString*) password AndNotify:(id<AudioMobileRestAsyncResponseNotifier>) responder {
    if (!responder) {
        NSLog(@"No responder provided for login request");
        return;
    }
    //TODO IMPORTANT SECURITY: revise to use https url once server has been configured to support that mode.
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]
                                    initWithURL:[NSURL
                                                 URLWithString:loginURL]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/xml"
   forHTTPHeaderField:@"Content-type"];
    
    NSString *xmlString = [NSString stringWithFormat:@"<data><username>%@</username><password>%@</password></data>",username,password];
    
    [request setValue:[NSString stringWithFormat:@"%d",
                       [xmlString length]]
   forHTTPHeaderField:@"Content-length"];
    
    [request setHTTPBody:[xmlString
                          dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError* err;
    NSURLResponse* responseObj;
    NSData* responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseObj error:&err];
    if (err) {
        NSLog(@"Failed to login due to error: %@",err);
        if (responder) [responder loginCompletedWithResult:AMLOGINFAIL];
        return;
    }
    else {
        NSLog(@"Logged in with response  %@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] );
        NSDictionary* responseDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&err];
        
        if (![responseDict isKindOfClass:[NSDictionary class]]) {
            NSLog(@"Failed to login due to error: %@",err);
            if (responder) [responder loginCompletedWithResult:AMLOGINFAIL];
            return;
        }
        else if (![responseDict objectForKey:@"user"] || ![[responseDict objectForKey:@"user"] objectForKey:@"uid"]) {
            NSLog(@"Failed to login, response object did not contain user uid information");
            if (responder) [responder loginCompletedWithResult:AMLOGINFAIL];
            return;
        }
        NSInteger uidFromLoginResponse = [((NSNumber*)[[responseDict objectForKey:@"user"] objectForKey:@"uid"]) integerValue];
        [self setUid:uidFromLoginResponse];
        
        NSString* userNameFromLoginResponse = [[responseDict objectForKey:@"user"] objectForKey:@"name"];
        [self setUserName:userNameFromLoginResponse];
        
        //retrieve the csrf token
        NSURLRequest* csrfTokenRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:csrfTokenRequestURL]];
        NSURLResponse* csrfTokenResponse;
        NSData* csrfTokenD = [NSURLConnection sendSynchronousRequest:csrfTokenRequest returningResponse:&csrfTokenResponse error:&err];
        if (err) {
            NSLog(@"Failed to retrieve csrf token due to err %@",err);
            [responder loginCompletedWithResult:AMLOGINFAIL];
            return;
        }
        NSString* csrfToken = [[NSString alloc] initWithData:csrfTokenD encoding:NSUTF8StringEncoding];
        [self setCsrfToken:csrfToken];
        [responder loginCompletedWithResult:AMLOGINSUCCESS];
    }
}

-(void) logout:(id<AudioMobileRestAsyncResponseNotifier>) responder {
    NSLog(@"user has logged out");
}

-(void) downloadNodeAudioToDisk:(NSUInteger) nid {
    
}


#pragma mark NSURLConnectionDelegate methods (optional)

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Request %@ failed with error %@",[[[connection originalRequest] URL ] path ],error);

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
//    NSLog(@"Received data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    NSLog(@"Received data from: %@", [[[connection originalRequest] URL] path]);
    
    if ([[[connection originalRequest] URL] path] == loginURL ) {
        NSLog(@"login request returned, requesting csrf token");
        //create request for csrf token which will be required for further interaction, particularly file downloads
    }
}

//- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request;
//- (void)connection:(NSURLConnection *)connection   didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten
//totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse;

//- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

- (void)clearCookies {
    NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://audio-mobile.org"]];
    
    for(NSHTTPCookie* cookie in cookies) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

@end

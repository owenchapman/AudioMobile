//
//  AudioMobileMapViewAnnotation.m
//  Audio-Mobile
//
//

#import "AudioMobileMapViewAnnotation.h"

@implementation AudioMobileMapViewAnnotation

-(CLLocationCoordinate2D) coordinate {
    return [self nodeCoordinate];
}

-(NSString*) title {
    if ([self nodeInfo]) {
        return [[self nodeInfo] objectForKey:@"title"];
    }
    else {
        return @"Unknown title";
    }
}

-(NSString*) subtitle {
    if ([self nodeInfo]) {
        return [NSString stringWithFormat:@"by %@",[[self nodeInfo] objectForKey:@"name"] ];
    }
    else {
        return @"Unknown Author";
    }
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    [self setNodeCoordinate:newCoordinate];
    [[self delegate] newCoordinate:newCoordinate];
}

@end

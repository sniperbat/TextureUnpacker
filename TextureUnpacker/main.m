//
//  main.m
//  TextureUnpacker
//
//  Created by sniperbat on 1/15/14.
//  Copyright (c) 2014 sniperbat. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

void unpackTextureFromeAtlasByPlist( NSString * plistFullPathName ){
    NSDictionary * plist = [NSDictionary dictionaryWithContentsOfFile:plistFullPathName];
    NSDictionary * metadata = [plist objectForKey:@"metadata"];
    NSSize texSize = NSSizeFromString([metadata objectForKey:@"size"]);
    
    NSString * path = [[plistFullPathName stringByDeletingLastPathComponent] stringByAppendingString:@"/"];
    NSString * texFileName = [path stringByAppendingString:[metadata objectForKey:@"textureFileName"]];
    NSImage * atlasImg = [[NSImage alloc] initWithContentsOfFile: texFileName];
    
    NSDictionary * frames = [plist objectForKey:@"frames"];
    NSArray * keys = [frames allKeys];
    for( NSString * key in keys ){
        NSDictionary * img = [frames objectForKey:key];
        NSRect sprFrame = NSRectFromString([img objectForKey:@"frame"]);
        NSRect texFrame = sprFrame;
        NSPoint offset = NSPointFromString([img objectForKey:@"offset"]);
        NSSize sourceSize = NSSizeFromString([img objectForKey:@"sourceSize"]);
        BOOL isRotated = [[img objectForKey:@"rotated"] boolValue];
        NSPoint targetPoint = NSMakePoint( ( sourceSize.width - sprFrame.size.width)/2 + offset.x ,
                                          (sourceSize.height - sprFrame.size.height )/2  + offset.y);
        if(isRotated){
            CGFloat temp = texFrame.size.width;
            texFrame.size.width = texFrame.size.height;
            texFrame.size.height = temp;
            targetPoint.x += sprFrame.size.width;
        }
        texFrame.origin.y = texSize.height - texFrame.origin.y - texFrame.size.height;
        
        NSBitmapImageRep *imgRep = [[NSBitmapImageRep alloc]initWithBitmapDataPlanes:nil
                                                                          pixelsWide:sourceSize.width
                                                                          pixelsHigh:sourceSize.height
                                                                       bitsPerSample:8
                                                                     samplesPerPixel:4
                                                                            hasAlpha:YES
                                                                            isPlanar:NO
                                                                      colorSpaceName:NSCalibratedRGBColorSpace
                                                                        bitmapFormat:0
                                                                         bytesPerRow:sourceSize.width * 4
                                                                        bitsPerPixel:32];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:imgRep] ];
        
        CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
        NSAffineTransform * scaleTrans = [NSAffineTransform transform];
        [scaleTrans scaleBy:1.0 / scale];
        [scaleTrans concat];
        
        NSAffineTransform * moveTrans = [NSAffineTransform transform];
        [moveTrans translateXBy:targetPoint.x yBy:targetPoint.y];
        [moveTrans concat];
        
        if(isRotated){
            NSAffineTransform * rotateTrans = [NSAffineTransform transform];
            [rotateTrans rotateByDegrees:90];
            [rotateTrans concat];
        }
        
        [atlasImg drawAtPoint:NSMakePoint( 0, 0)
                     fromRect:texFrame
                    operation:NSCompositeSourceOver
                     fraction:1.0f];
        
        [NSGraphicsContext restoreGraphicsState];
        NSData *sprImageData = [imgRep representationUsingType:NSPNGFileType properties:nil];
        [sprImageData writeToFile:key atomically:NO];
    }
}

int main(int argc, const char * argv[]){
    @autoreleasepool {
        unpackTextureFromeAtlasByPlist( @"../tiles-hd.plist" );
    }
    return 0;
}


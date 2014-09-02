#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AVCaptureDeviceFormat (DescriptionAdditions)

@property (readonly) NSString *localizedName;
- (CMTime)maxFrameDurationLessThanTimeInterval:(NSTimeInterval)aTimeInterval;
@end

#import <ApplicationServices/ApplicationServices.h>
//#import <Foundation/NSThread.h>

#define SIGN(x) (((x) > 0) - ((x) < 0))


//bool isFakeScroll = false;
int64_t scrollDelta = 0;
#define MAXLINE 100
#define MAXPIXEL 5

bool smooth = false;

void smoothTask(){
    dispatch_queue_t q = dispatch_queue_create("My Queue",NULL);
    dispatch_async(q,^{
        while(true){
            if( scrollDelta > 0){
                int speed = (int)((scrollDelta) * MAXPIXEL)/(1.5*MAXLINE);
                if(speed <= 0 ){
                    speed = 1;
                }
                int userdata = 1234; //magic number
                CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
                CGEventSourceSetUserData(source, (intptr_t)&userdata);
                CGEventRef scroll = CGEventCreateScrollWheelEvent(source, kCGScrollEventUnitPixel, 1, speed);
                CGEventPost(kCGHIDEventTap, scroll);
                CFRelease(scroll);
                CFRelease(source);
                scrollDelta--;
            } else if( scrollDelta < 0){
                long div = (-1) * scrollDelta;
                int speed = (int)((div) * MAXPIXEL)/(1.5*MAXLINE);
                if(speed <= 0 ){
                    speed = 1;
                }
                speed = (-1) * speed;
                int userdata = 1234; //magic number
                CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
                CGEventSourceSetUserData(source, (intptr_t)&userdata);
                CGEventRef scroll = CGEventCreateScrollWheelEvent(source, kCGScrollEventUnitPixel, 1, speed);
                CGEventPost(kCGHIDEventTap, scroll);
                CFRelease(scroll);
                CFRelease(source);
                scrollDelta++;
            }
            usleep(5000);
        }
    });
    
}


CGEventRef cgEventCallback(CGEventTapProxy proxy, CGEventType type,
                           CGEventRef event, void *refcon)
{
    int64_t delta = CGEventGetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis1);
    int64_t lineDelta = CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1);
    
    if(type == kCGEventOtherMouseDown) {
        long mouseButton = CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber);
        if (mouseButton == 3) {
            //printf("3\n");
            //animate(20);
        }else if(mouseButton == 4){
            //printf("4\n");
        }
        return event;
    } else if(type == kCGEventScrollWheel){
        if( smooth ) {
            if (!CGEventGetIntegerValueField(event, kCGScrollWheelEventIsContinuous)) {
                int64_t eventInfo = CGEventGetIntegerValueField(event, kCGEventSourceUserData);
                if(eventInfo == 0){ //eventInfo == 0 it mean scroll by real mouse
                    if( lineDelta > 0 ){
                        int64_t tmp = scrollDelta;
                        tmp += MAXLINE;
                        if( tmp > MAXLINE ){
                            scrollDelta = MAXLINE;
                        }else{
                            scrollDelta = tmp;
                        }
                        CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1, SIGN(delta) * 1);
                    } else if(lineDelta < 0 ){
                        int64_t tmp = scrollDelta;
                        tmp -= MAXLINE;
                        if( tmp < -MAXLINE ){
                            scrollDelta = -MAXLINE;
                        } else {
                            scrollDelta = tmp;
                        }
                        CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1, SIGN(delta) * 1);
                    }
                }
            }
        }else{
            int line = 3;
            if(delta > 0  ){  //up
                line = 4;
                printf("%d\n",delta);
                if(delta > 100){
                    delta = 100;
                }
            }else if(delta < 0){ //down
                if(delta < -50){
                    delta = -50;
                }
            }
            CGEventSetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1, SIGN(delta) * line);
        }
    }
    
    return event;
}


int main(void)
{
    if(smooth){
        smoothTask();
    }
    CFMachPortRef eventTap;
    CFRunLoopSourceRef runLoopSource;
    eventTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0,
                               ( 1 << kCGEventOtherMouseDown) | 1 << kCGEventScrollWheel, cgEventCallback, NULL);
    runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopCommonModes);
    CGEventTapEnable(eventTap, true);
    CFRunLoopRun();
    
    CFRelease(eventTap);
    CFRelease(runLoopSource);
    
    return 0;
}

//https://github.com/calftrail/TrackMagic/blob/710319fd40f213cd2b9eb8156994deb554e6d0f0/TouchTrackpad.m

//
//  CBUIGlobal.m
//  ArabianRaces2
//
//  Created by Christian Beer on 20.12.10.
//  Copyright 2010 Christian Beer. All rights reserved.
//

#import "CBUIGlobal.h"

BOOL CBIsIPad() {
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

#pragma mark BarButtons

UIBarButtonItem *CBUIBarButtonSetStyle(UIBarButtonItem *itm, UIBarButtonItemStyle style) {
    itm.style = style;
    return itm;
}

UIBarButtonItem *CBUIBarFlexibleSpace() {
	return [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
														  target:nil action:nil] autorelease];
}
UIBarButtonItem *CBUIBarButtonFixedSpace(CGFloat width) {
	UIBarButtonItem *fs = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                        target:nil action:nil];
	fs.width = width;
	return [fs autorelease];
}

UIBarButtonItem *CBUIBarButtonSystemItem(UIBarButtonSystemItem type, id target, SEL action) {
	UIBarButtonItem *itm = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:type
																		 target:target 
																		 action:action];
	return [itm autorelease];
}
UIBarButtonItem *CBUIBarButtonTextItem(NSString *title, id target, SEL action) {
	UIBarButtonItem *itm = [[UIBarButtonItem alloc] initWithTitle:title
															style:UIBarButtonItemStyleBordered
														   target:target
														   action:action];
	return [itm autorelease];
}
UIBarButtonItem *CBUIBarButtonImageItem(NSString *img, id target, SEL action) {
	UIBarButtonItem *itm = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:img] 
															style:UIBarButtonItemStylePlain
														   target:target
														   action:action];
	return [itm autorelease];
}
UIBarButtonItem *CBUIBarButtonCustomItem(UIView *view) {
	UIBarButtonItem *itm = [[UIBarButtonItem alloc] initWithCustomView:view];
	return [itm autorelease];
}

#pragma mark -
#pragma mark Internationalization

NSString *I18N(NSString *key) {
	return NSLocalizedString(key, @"");
}
NSString *I18N1(NSString *key, id param1) {
	return [NSString stringWithFormat:NSLocalizedString(key, @""), param1];
}
NSString *I18N2(NSString *key, id param1, id param2) {
	return [NSString stringWithFormat:NSLocalizedString(key, @""), param1, param2];
}

#pragma mark -

CGPathRef CreateRoundedRectPath(CGRect rect, CGFloat radius) {
    CGFloat minx = CGRectGetMinX(rect), midx = CGRectGetMidX(rect), maxx = CGRectGetMaxX(rect); 
    CGFloat miny = CGRectGetMinY(rect), midy = CGRectGetMidY(rect), maxy = CGRectGetMaxY(rect); 
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, nil, minx, midy); 
    // Add an arc through 2 to 3 
    CGPathAddArcToPoint(path, nil, minx, miny, midx, miny, radius); 
    // Add an arc through 4 to 5 
    CGPathAddArcToPoint(path, nil, maxx, miny, maxx, midy, radius); 
    // Add an arc through 6 to 7 
    CGPathAddArcToPoint(path, nil, maxx, maxy, midx, maxy, radius); 
    // Add an arc through 8 to 9 
    CGPathAddArcToPoint(path, nil, minx, maxy, minx, midy, radius);
    // Close the path 
    CGPathCloseSubpath(path);
    
    return path;
}

#pragma mark -

static int networkIndicatorCounter = 0;
void ShowNetworkIndicator() 
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    networkIndicatorCounter++;
}
void HideNetworkIndicator()
{
    networkIndicatorCounter--;
    if (networkIndicatorCounter <= 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}
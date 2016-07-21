//
//  KRNDrawView.m
//  TouchTracker
//
//  Created by Karan Jivani on 7/19/16.
//  Copyright © 2016 Karan Jivani. All rights reserved.
//

#import "KRNDrawView.h"
#import "KRNLine.h"

@interface KRNDrawView ()

@property(nonatomic,strong) NSMutableDictionary *linesInProgress;
@property(nonatomic,strong) NSMutableArray *finishedLines;

@property(nonatomic,weak) KRNLine *selectedLine;

@property(nonatomic) UITapGestureRecognizer *doubleTapRecognizer;

@end

@implementation KRNDrawView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.linesInProgress = [[NSMutableDictionary alloc]init];
        self.finishedLines = [[NSMutableArray alloc]init];
        self.backgroundColor = [UIColor grayColor];
        self.multipleTouchEnabled = YES;
        
        [self doubleTapGesture];
        [self singleTapGesture];
        [self longPressGesture];
    }
    return self;
}

-(void)strokeLines: (KRNLine *)line {
    
    UIBezierPath *bp = [UIBezierPath bezierPath];
    bp.lineWidth = 10;
    bp.lineCapStyle = kCGLineCapRound;

    [bp moveToPoint:line.begin];
    [bp addLineToPoint:line.end];
    [bp stroke];
}

-(void)drawRect:(CGRect)rect {
    
    //Draw finished line in Black
    [[UIColor blackColor]set];
    
    for (KRNLine *line in self.finishedLines) {
        [self strokeLines:line];
    }
    
    [[UIColor redColor]set];
    for (NSValue *key in self.linesInProgress) {
        [self strokeLines:[self.linesInProgress objectForKey:key]];
    }
    
    if (self.selectedLine) {
        [[UIColor greenColor]set];
        [self strokeLines:self.selectedLine];
    }
    
}

#pragma mark Touches Methods (UIResponder Methods)

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        //Get the location of the touch in view's coordinate system
        CGPoint location = [t locationInView:self];
        
        KRNLine *line = [[KRNLine alloc]init];
        line.begin = location;
        line.end = location;
        
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        [self.linesInProgress setObject:line forKey:key];
    
    }
    [self setNeedsDisplay];
    NSLog(@"touchesBegan");

}

-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        
        KRNLine *line = [self.linesInProgress objectForKey:key];
        line.end = [t locationInView:self];
    }
    [self setNeedsDisplay];
    NSLog(@"touchesMoved");

}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        
        KRNLine *line = [self.linesInProgress objectForKey:key];
        [self.finishedLines addObject:line];
        [self.linesInProgress removeObjectForKey:key];
    }
    [self setNeedsDisplay];
    NSLog(@"touchesEnded");

}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *t in touches) {
        NSValue *key = [NSValue valueWithNonretainedObject:t];
        [self.linesInProgress removeObjectForKey:key];
    }
    [self setNeedsDisplay];
}

-(void)doubleTapGesture {
    
    self.doubleTapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTap:)];
    self.doubleTapRecognizer.numberOfTapsRequired = 2;
    self.doubleTapRecognizer.delaysTouchesBegan = YES;
    [self addGestureRecognizer:self.doubleTapRecognizer];
}

-(void)doubleTap :(UITapGestureRecognizer *)gr {
    NSLog(@"Recognized Double Tap");
    
    [self.linesInProgress removeAllObjects];
    [self.finishedLines removeAllObjects];
    [self setNeedsDisplay];
}

-(void)singleTapGesture {
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tap:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.delaysTouchesBegan = YES;
    [tapRecognizer requireGestureRecognizerToFail:self.doubleTapRecognizer];
    [self addGestureRecognizer:tapRecognizer];
}

-(void)tap: (UITapGestureRecognizer *)gr {
    NSLog(@"Recognized tap");
    
    CGPoint point = [gr locationInView:self];
    self.selectedLine = [self lineAtPoint:point];
    
    if (self.selectedLine) {
        //Make ourselves the target of menu item action message
        [self becomeFirstResponder];
        //Grab the Menu Controller
        UIMenuController *menu = [UIMenuController sharedMenuController];
        //Create a new "Delete" UIMenuItem
        UIMenuItem *deleteItem = [[UIMenuItem alloc]initWithTitle:@"Delete" action:@selector(deleteLine:)];
        menu.menuItems = @[deleteItem];
        //Tell the menu where it should come from and show it
        [menu setTargetRect:CGRectMake(point.x, point.y, 2, 2) inView:self];
        [menu setMenuVisible:YES animated:YES];
    }
    else {
        //Hide Menu if no line is selected
        [[UIMenuController sharedMenuController]setMenuVisible:NO animated:YES];
    }
    [self setNeedsDisplay];
    
}

-(KRNLine *)lineAtPoint: (CGPoint)p {
    //Find a line close to p
    
    for (KRNLine *l in self.finishedLines) {
        CGPoint start = l.begin;
        CGPoint end = l.end;
        
        //Check a few points on the line
        
        for(float t = 0.0; t<= 1.0;t = t+0.05) {
            
            float x = start.x + t * (end.x - start.x);
            float y = start.y + t * (end.y - start.x);
            
            //If the tapped point is within 20 points, Lets return this line
            if (hypot(x - p.x, y - p.y) < 20.0) {
                return l;
            }
        }
    }
    //If nothing is close enough to the tapped point, then we did not select line
    return nil;
}

//If you have a custom view class that needs to become the first responder, you must override following method
-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(void)deleteLine: (id)sender {
    
    //Remove the selected libe from the list of finishedline
    
    [self.finishedLines removeObject:self.selectedLine];
    //Redraw Everything
    [self setNeedsDisplay];
}

-(void)longPressGesture{
 
    UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPress:)];
    [self addGestureRecognizer:pressRecognizer];
}

-(void) longPress: (UIGestureRecognizer *)gr {
    
    //When view receive this method and long press has begun, you will select the closest line to where the gesture occured
    if (gr.state == UIGestureRecognizerStateBegan) {
        
        CGPoint point = [gr locationInView:self];
        self.selectedLine = [self lineAtPoint:point];
        
        if (self.selectedLine) {
            [self.linesInProgress removeAllObjects];
        }
    }
    //when the longpress ended, you will deselect the line 
    else if (gr.state == UIGestureRecognizerStateEnded) {
        self.selectedLine = nil;
    }
    [self setNeedsDisplay];
}

@end

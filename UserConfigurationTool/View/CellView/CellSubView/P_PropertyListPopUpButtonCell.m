//
//  P_PropertyListPopUpButtonCell.m
//  UserConfigurationTool
//
//  Created by TsanFeng Lam on 2019/4/23.
//  Copyright © 2019 gzmiracle. All rights reserved.
//

#import "P_PropertyListPopUpButtonCell.h"

static NSColor* __enabledTextColor;
static NSColor* __enabledTextColorHighlight;
static NSColor* __disabledTextColor;
static NSColor* __disabledTextColorHighlight;
static NSAppearance* __darkAppearanceCache;

@implementation P_PropertyListPopUpButtonCell

+ (void)initialize
{
    __enabledTextColor = NSColor.controlTextColor;
    __enabledTextColorHighlight = NSColor.alternateSelectedControlTextColor;
    __disabledTextColor = NSColor.disabledControlTextColor;
    __disabledTextColorHighlight = [NSColor valueForKey:@"_alternateDisabledSelectedControlTextColor"];
    __darkAppearanceCache = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView
{
    BOOL isHighlited = self.backgroundStyle == NSBackgroundStyleDark;
    //All this to get the damn colors to match a text field. Ridiculous
    NSColor* controlColor = self.isEnabled ? (isHighlited ? __enabledTextColorHighlight : (controlView.effectiveAppearance == __darkAppearanceCache ? NSColor.whiteColor : __enabledTextColor)) : (isHighlited ? __disabledTextColorHighlight : __disabledTextColor);
    NSMutableAttributedString* attr = self.attributedTitle.mutableCopy;
    [attr addAttribute:NSForegroundColorAttributeName value:controlColor range:NSMakeRange(0, attr.length)];
    
    [attr drawInRect:frame];
    
    return frame;
}

- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag
{
    [self.controlView.window makeFirstResponder:self.controlView.superview];
    
    return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:flag];
}

@end

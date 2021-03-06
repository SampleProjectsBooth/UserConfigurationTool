//
//  P_PropertyListBasicCellView.m
//  UserConfigurationTool
//
//  Created by TsanFeng Lam on 2019/4/24.
//  Copyright © 2019 gzmiracle. All rights reserved.
//

#import "P_PropertyListBasicCellView.h"

@interface P_PropertyListBasicCellView () <NSTextFieldDelegate>

@property (nonatomic, assign) BOOL textFieldEditing;

@end

@implementation P_PropertyListBasicCellView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //点击的时候显示蓝色外框
    self.textField.focusRingType = NSFocusRingTypeDefault;
    //自动换行
    [[self.textField cell] setLineBreakMode:NSLineBreakByCharWrapping];
    //最大行数
    self.textField.maximumNumberOfLines = 1;
    //设置是否启用单行模式
    [self.textField cell].usesSingleLineMode = NO;
    //设置超出行数是否隐藏
//    [self.textField cell].truncatesLastVisibleLine = YES;
}

#pragma mark - overwrite
- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    /** 禁止系统自动改变文字颜色 */
}

- (NSArray<NSDraggingImageComponent *> *)draggingImageComponents
{
    NSArray<NSDraggingImageComponent *> *s_draggingImageComponents = [super draggingImageComponents];
    NSDraggingImageComponent *imageComponent = [NSDraggingImageComponent draggingImageComponentWithKey:NSDraggingImageComponentLabelKey];
    imageComponent.contents = self.textField.stringValue;
    imageComponent.frame = self.textField.frame;
    
    if (s_draggingImageComponents) {
        return [s_draggingImageComponents arrayByAddingObjectsFromArray:@[imageComponent]];
    } else {
        return @[imageComponent];
    }
}

- (void)p_setControlWithString:(NSString *)str
{
    self.textField.stringValue = str;
    self.toolTip = str;
}

- (void)p_setControlWithString:(NSString *)str toolTip:(NSString *)toolTip
{
    self.textField.stringValue = str;
    self.toolTip = toolTip;
}

- (void)p_setControlEditable:(BOOL)editable
{
    self.textField.selectable = self.textField.editable = editable;
    
    NSColor* controlColor = editable ? NSColor.labelColor : NSColor.disabledControlTextColor;
    
    self.textField.textColor = controlColor;
}

- (void)p_setControlEditableWithOutTextColor:(BOOL)editable
{
    self.textField.selectable = self.textField.editable = editable;
    
}

#pragma mark NSTextFieldDelegate
- (void)controlTextDidBeginEditing:(NSNotification *)obj
{
    self.textFieldEditing = YES;
}

- (void)controlTextDidEndEditing:(NSNotification *)obj
{
    if (self.textFieldEditing == NO) {
        return;
    }
    self.textFieldEditing = NO;
    
    NSTextField *textField = obj.object;
    if ([self.delegate respondsToSelector:@selector(p_propertyListCellDidEndEditing:value:)]) {
        id realValue = [self.delegate p_propertyListCellDidEndEditing:self value:textField.stringValue];
        if ([realValue isKindOfClass:[NSString class]]) {
            [self p_setControlWithString:realValue];
        }
    }
}


- (BOOL)control:(NSControl *)control isValidObject:(nullable id)obj
{
    if ([obj isKindOfClass:[NSString class]]) {
        if ([self.delegate respondsToSelector:@selector(p_propertyListCell:isValidObject:)]) {
            return [self.delegate p_propertyListCell:self isValidObject:obj];
        }
    }
    return YES;
}

@end

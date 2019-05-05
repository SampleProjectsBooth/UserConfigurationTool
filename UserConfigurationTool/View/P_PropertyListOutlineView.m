//
//  P_PropertyListOutlineView.m
//  UserConfigurationTool
//
//  Created by TsanFeng Lam on 2019/4/23.
//  Copyright © 2019 gzmiracle. All rights reserved.
//

#import "P_PropertyListOutlineView.h"
#import "P_Data.h"

#import "P_PropertyListBasicCellView.h"
#import "P_PropertyList2ButtonCellView.h"
#import "P_PropertyListPopUpButtonCellView.h"
#import "P_PropertyListDatePickerCellView.h"

static NSPasteboardType P_PropertyListPasteboardType = @"com.gzmiracle.UserConfigurationTool";

@interface P_PropertyListOutlineView ()
{
    NSUndoManager* _undoManager;
}
@property (nonatomic, copy) NSString *pasteboardType;

@end

@implementation P_PropertyListOutlineView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.enclosingScrollView.wantsLayer = YES;
    self.enclosingScrollView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    self.usesAlternatingRowBackgroundColors = YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    [self registerForDraggedTypes:[NSArray arrayWithObject:[NSBundle mainBundle].bundleIdentifier]];
    _pasteboardType = [NSBundle mainBundle].bundleIdentifier;
    
    _undoManager = [NSUndoManager new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popUpButtonWillPopUpNotification:) name:NSPopUpButtonWillPopUpNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(comboBoxWillPopUpNotification:) name:NSComboBoxWillPopUpNotification object:nil];
    
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)mouseDown:(NSEvent *)event
{
    if (event.clickCount > 1) {
        NSInteger row = self.selectedRow;
        NSInteger column = [self columnAtPoint:event.locationInWindow];
        NSTableCellView *cellView = [self viewAtColumn:column row:row makeIfNecessary:NO];
        if ([cellView.textField acceptsFirstResponder]) {
            [cellView.textField becomeFirstResponder];
        }
    } else {
        [super mouseDown:event];
    }
}


- (void)drawGridInClipRect:(NSRect)clipRect
{
    NSRect lastRowRect = [self rectOfRow:[self numberOfRows] - 1];
    NSRect myClipRect = NSMakeRect(0, 0, lastRowRect.size.width, NSMaxY(lastRowRect));
    NSRect finalClipRect = NSIntersectionRect(clipRect, myClipRect);
    [super drawGridInClipRect:finalClipRect];
}

#pragma mark - NSPopUpButtonWillPopUpNotification
- (void)popUpButtonWillPopUpNotification:(NSNotification *)notify
{
    NSPopUpButton *button = notify.object;
    NSInteger row = [self rowForView:button];
    if (row > -1) {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:false];
    }
    
}

#pragma mark - NSComboBoxWillPopUpNotification
- (void)comboBoxWillPopUpNotification:(NSNotification *)notify
{
    NSComboBox *box = notify.object;
    NSInteger row = [self rowForView:box];
    if (row > -1) {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:false];
    }
}

#pragma mark - NSMenuItemValidation
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if(menuItem.action == @selector(undo:))
    {
        return _undoManager.canUndo;
    }
    
    if(menuItem.action == @selector(redo:))
    {
        return _undoManager.canRedo;
    }
    
    BOOL extraCase = YES;
    if(menuItem.action == @selector(add:))
    {
        extraCase = [self canAdd:menuItem];
    }
    
    else if(menuItem.action == @selector(delete:))
    {
        extraCase = [self canDelete:menuItem];
    }
    
    else if(menuItem.action == @selector(cut:))
    {
        extraCase = [self canCut:menuItem];
    }
    
    else if(menuItem.action == @selector(copy:))
    {
        extraCase = [self canCopy:menuItem];
    }
    
    else if(menuItem.action == @selector(paste:))
    {
        extraCase = [self canPaste:menuItem];
    }
    
    return extraCase && (menuItem.action && [self respondsToSelector:menuItem.action] && [self selectedRow] != -1);
}

#pragma mark - can do sth
- (BOOL)canAdd:(NSMenuItem *)menuItem
{
    return YES;
}
- (BOOL)canDelete:(NSMenuItem *)menuItem
{
    return YES;
}
- (BOOL)canCut:(NSMenuItem *)menuItem
{
    return YES;
}
- (BOOL)canCopy:(NSMenuItem *)menuItem
{
    return YES;
}
- (BOOL)canPaste:(NSMenuItem *)menuItem
{
    return YES;
}

#pragma mark - doing sth / menu action

- (void)undo:(id)sender
{
    [_undoManager undo];
}

- (void)redo:(id)sender
{
    [_undoManager redo];
}

- (void)add:(id)sender
{
    P_Data *p = [[P_Data alloc] init];
    [self insertItem:p];
#warning 激活key的输入框
}

/** 删除 */
- (void)delete:(id)sender
{
    NSInteger selectedRow = self.selectedRow;
    [self deleteItem:[self itemAtRow:selectedRow]];
}

/** 剪切 */
- (void)cut:(id)sender
{
    [self copy:sender];
    [self delete:sender];
}

/** 拷贝 */
- (void)copy:(id)sender
{
    [NSPasteboard.generalPasteboard clearContents];
    
    NSInteger operationIndex = [self selectedRow];
    P_Data *p = [self itemAtRow:operationIndex];
    [NSPasteboard.generalPasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:p] forType:P_PropertyListPasteboardType];
}

- (void)paste:(id)sender
{
    P_Data *p = [NSKeyedUnarchiver unarchiveObjectWithData:[NSPasteboard.generalPasteboard dataForType:P_PropertyListPasteboardType]];
#warning key 的复用判断
    [self insertItem:p];
}

#pragma mark - 插入值key、type、value
- (void)insertItem:(id)newItem
{
    P_Data *new_p = newItem;
    P_Data *parent_p = nil;
    
    /** willChangeNode */
    
    [self beginUpdates];
    
    NSUInteger insertionRow;
    P_Data *p = [self itemAtRow:self.selectedRow];
    
    if([self isItemExpanded:p])
    {
        parent_p = p;
        insertionRow = 0;
    }
    else
    {
        parent_p = p.parentData;
        insertionRow = [parent_p.childDatas indexOfObject:p] + 1;
    }
    [parent_p insertChildData:new_p atIndex:insertionRow];
    
    [self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:insertionRow] inParent:parent_p withAnimation:NSTableViewAnimationEffectNone];
    
    
    [self endUpdates];
    
    NSInteger insertedRow = [self rowForItem:newItem];
    
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:insertedRow] byExtendingSelection:NO];
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView* _Nonnull target) {
        [target deleteItem:newItem];
    }];
    
    /** didChangeNode */
    
    NSLog(@"%@", newItem);
}

#pragma mark - 删除值key、type、value
- (void)deleteItem:(id)item
{
    P_Data *p = item;
    
    /** willChangeNode */
    
    [self beginUpdates];
    
    NSInteger selectedRow = [self rowForItem:item];
    
    P_Data *parent_p = p.parentData.level > 0 ? p.parentData : nil;
    
    NSUInteger deletionIndex = [parent_p.childDatas indexOfObject:p];
    [parent_p removeChildDataAtIndex:deletionIndex];
    [self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:deletionIndex] inParent:parent_p withAnimation:NSTableViewAnimationEffectNone];
    
    [self endUpdates];
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView* _Nonnull target) {
        [target insertItem:item];
    }];
    
    if(selectedRow != -1)
    {
        if(selectedRow > 0)
        {
            selectedRow -= 1;
        }
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    }
    
    /** didChangeNode */
    
    NSLog(@"%@", item);
}

#pragma mark - 更新值key、type、value

- (void)updateItem:(id)newItem ofItem:(id)item
{
    P_Data *new_p = newItem;
    P_Data *p = item;
    if([p.key isEqualToString:new_p.key])
    {
        return;
    }
    
    /** willChangeNode */
    
    
    [self beginUpdates];
    
    P_Data *parentData = p.parentData;
    NSInteger index = [parentData.childDatas indexOfObject:p];
    [parentData removeChildDataAtIndex:index];
    [parentData insertChildData:new_p atIndex:index];
    
    NSPoint point = self.enclosingScrollView.documentVisibleRect.origin;
    [self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parentData withAnimation:NSTableViewAnimationEffectNone];
    [self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parentData withAnimation:NSTableViewAnimationEffectNone];
    [self endUpdates];
    
    NSInteger selectionRow = [self rowForItem:new_p];
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selectionRow] byExtendingSelection:NO];
    [self scrollPoint:point];
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView * _Nonnull target) {
        [target updateItem:item ofItem:newItem];
    }];
    
    /** didChangeNode */
    
    NSLog(@"%@", new_p);
}

- (void)updateKey:(NSString *)key ofItem:(id)item withView:(BOOL)withView
{
    P_Data *p = item;
    if([p.key isEqualToString:key])
    {
        return;
    }
    /** willChangeNode */
    
    NSString* oldKey = p.key;
    p.key = key;
    
    
    if (withView) {
        NSUInteger row = [self rowForItem:item];
        NSUInteger column = 0;
        
        P_PropertyListBasicCellView *cellView = [self viewAtColumn:column row:row makeIfNecessary:NO];
        [cellView p_setControlWithString:key];
    }
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView * _Nonnull target) {
        [target updateKey:oldKey ofItem:item withView:YES];
    }];
    
    /** didChangeNode */
    
    NSLog(@"%@", p);
}

- (void)updateType:(P_PlistTypeName)type value:(id)value childDatas:(NSArray <P_Data *> *_Nullable)childDatas ofItem:(id)item
{
    P_Data *p = item;
    if([p.type isEqualToString:type])
    {
        return;
    }
    
    /** willChangeNode */
    
    P_PlistTypeName oldType = p.type;
    id oldValue = p.value;
    NSArray <P_Data *> *oldChildDatas = p.childDatas;
    
    p.type = type;
    p.value = value;
    p.childDatas = childDatas;
    
    NSPoint point = self.enclosingScrollView.documentVisibleRect.origin;
    [self reloadItem:p reloadChildren:YES];
    [self scrollPoint:point];
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView * _Nonnull target) {
        [target updateType:oldType value:oldValue childDatas:oldChildDatas ofItem:item];
    }];
    
    /** didChangeNode */
    
    NSLog(@"%@", p);
}

- (void)updateValue:(id)value ofItem:(id)item withView:(BOOL)withView
{
    P_Data *p = item;
    if ([p.valueDesc isEqual: value]) {
        return;
    }
    
    /** willChangeNode */
    
    id oldValue = p.value;
    p.value = value;
    
    
    if(withView)
    {
        NSUInteger row = [self rowForItem:item];
        NSUInteger column = 2;
        
        P_PropertyListBasicCellView *cell = [self viewAtColumn:column row:row makeIfNecessary:NO];
        
        if ([p.type isEqualToString: Plist.Boolean]) {
            [(P_PropertyListPopUpButtonCellView *)cell p_setControlWithBoolean:[p.value boolValue]];
        } else if ([p.type isEqualToString: Plist.Date]) {
            [(P_PropertyListDatePickerCellView *)cell p_setControlWithDate:p.value];
        } else {
            [cell p_setControlWithString:p.valueDesc];
        }
    }
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView * _Nonnull target) {
        [target updateValue:oldValue ofItem:item withView:YES];
    }];
    
    /** didChangeNode */
    
    NSLog(@"%@", p);
}

@end

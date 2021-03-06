//
//  P_PropertyListOutlineView.m
//  UserConfigurationTool
//
//  Created by TsanFeng Lam on 2019/4/23.
//  Copyright © 2019 gzmiracle. All rights reserved.
//

#import "P_PropertyListOutlineView.h"
#import "P_Data.h"
#import "P_Data+P_Exten.h"
#import "P_Config.h"

#import "P_PropertyListBasicCellView.h"
#import "P_PropertyList2ButtonCellView.h"
#import "P_PropertyListPopUpButtonCellView.h"
#import "P_PropertyListDatePickerCellView.h"

#import <Carbon/Carbon.h>

static NSPasteboardType P_PropertyListPasteboardType = @"com.gzmiracle.UserConfigurationTool";

@interface P_PropertyListOutlineView () <NSDraggingDestination>
{
    NSUndoManager* _undoManager;
}

@property (nonatomic, assign) BOOL dragInSide;

@end

@implementation P_PropertyListOutlineView

@dynamic delegate;

- (void)setDelegate:(id<P_PropertyListOutlineViewDelegate>)delegate
{
    super.delegate = delegate;
}

- (id<P_PropertyListOutlineViewDelegate>)delegate
{
    id curDelegate = super.delegate;
    return curDelegate;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.enclosingScrollView.wantsLayer = YES;
    self.enclosingScrollView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
    [self setDoubleAction:@selector(doubleClick:)];
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
    
    _undoManager = [NSUndoManager new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popUpButtonWillPopUpNotification:) name:NSPopUpButtonWillPopUpNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(comboBoxWillPopUpNotification:) name:NSComboBoxWillPopUpNotification object:nil];
    
}

- (NSPasteboardType)pasteboardType
{
    return [NSBundle mainBundle].bundleIdentifier;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public
- (BOOL)canAddItem:(id)item
{
    P_Data *p = item;
    if ([self isItemExpanded:p]) {
        /** 自身是否允许添加 */
        return p.operation & P_Data_Operation_Insert;
    }
    /** 上级是否允许添加 */
    else {
        if (p.parentData) {
            return p.parentData.operation & P_Data_Operation_Insert;
        } else {
            /** 如果没有上级，返回自身情况 */
            return p.operation & P_Data_Operation_Insert;
        }
    }
    return NO;
}

- (void)addItem:(id)p
{
    id item = nil;
    NSInteger selectedRow = self.selectedRow;
    if (selectedRow != -1) {
        item = [self itemAtRow:selectedRow];
    } else {
        item = [self itemAtRow:0];
    }
    [self insertItem:p ofItem:item];
}

- (void)doubleClick:(id)object {
    // This gets called after following steps 1-3.
    NSInteger row = [self clickedRow];
    NSInteger column = [self clickedColumn];
    // Do something...
    if (row != -1 && column != -1) {
        P_PropertyListBasicCellView *cellView = [self viewAtColumn:column row:row makeIfNecessary:NO];
        if ([cellView.textField acceptsFirstResponder]) {
            [cellView.textField becomeFirstResponder];
        }        
    }
}

- (BOOL)validateProposedFirstResponder:(NSResponder *)responder forEvent:(NSEvent *)event
{
    switch (event.type) {
        case NSEventTypeLeftMouseDown:
        case NSEventTypeOtherMouseDown:
        case NSEventTypeRightMouseDown:
        case NSEventTypeKeyDown:
        {
            /** 获取当然window的响应者 */
            NSResponder *firstResponder = self.window.firstResponder;
            if ([firstResponder respondsToSelector:@selector(delegate)]) {
                /** 获取代理对象 */
                id delegateObj = [firstResponder performSelector:@selector(delegate)];
                if ([delegateObj isKindOfClass:[NSTextField class]]) {
                    /** 对象是outlineView的成员之一 */
                    NSInteger row = [self rowForView:delegateObj];
                    if (row != -1) {
                        /** 禁止其他响应者激活 */
                        return NO;
                    }
                }
            }
        }
            break;
        default:
            break;
    }
    
    return [super validateProposedFirstResponder:responder forEvent:event];
}

- (void)keyDown:(NSEvent *)event
{
    if (event.keyCode == kVK_Return && self.selectedRow != -1) { //回车
        [self add:nil];
    } else {
        [super keyDown:event];
    }
}


- (void)drawGridInClipRect:(NSRect)clipRect
{
    NSRect lastRowRect = [self rectOfRow:[self numberOfRows] - 1];
    NSRect myClipRect = NSMakeRect(0, 0, lastRowRect.size.width, NSMaxY(lastRowRect));
    NSRect finalClipRect = NSIntersectionRect(clipRect, myClipRect);
    [super drawGridInClipRect:finalClipRect];
}

- (void)endEditing
{
    [self.window endEditingFor:self];
}

- (void)expandItem:(id)item
{
    if ([item isKindOfClass:[P_Data class]]) {
        [self __expandItem:item];
    } else {
        [super expandItem:item];
    }
}

- (BOOL)__expandItem:(P_Data *)p
{
    BOOL expand = NO;
    
    if (p == nil) {
        return YES;
    }
    
    if (![self isItemExpanded:p]) {
        
        expand = [self __expandItem:p.parentData];
        
        if (expand) {
            [super expandItem:p];
        }
        
    } else {
        expand = YES;
    }
    return expand;
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
        return [self canUndo:menuItem];
    }
    
    if(menuItem.action == @selector(redo:))
    {
        return [self canRedo:menuItem];
    }
    
    BOOL extraCase = NO;
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
    
    else if(menuItem.action == @selector(menuDidSelecter:))
    {
        extraCase = YES;
    }
    
    return extraCase && (menuItem.action && [self respondsToSelector:menuItem.action] && [self selectedRow] != -1);
}

#pragma mark - can do sth
- (BOOL)canUndo:(NSMenuItem *)menuItem
{
    return _undoManager.canUndo;
}

- (BOOL)canRedo:(NSMenuItem *)menuItem
{
    return _undoManager.canRedo;
}

- (BOOL)canAdd:(NSMenuItem *)menuItem
{
    NSInteger selectedRow = self.selectedRow;
    if (selectedRow == -1) {
        selectedRow = 0;
    }
    id item = [self itemAtRow:selectedRow];
    
    return [self canAdd:item];
}
- (BOOL)canDelete:(NSMenuItem *)menuItem
{
    NSInteger selectedRow = self.selectedRow;
    if (selectedRow != -1) {
        P_Data *p = [self itemAtRow:selectedRow];
        return p.operation & P_Data_Operation_Delete;
    }
    return NO;
}
- (BOOL)canCut:(NSMenuItem *)menuItem
{
    return [self canCopy:menuItem] && [self canDelete:menuItem];
}
- (BOOL)canCopy:(NSMenuItem *)menuItem
{
    return YES;
}
- (BOOL)canPaste:(NSMenuItem *)menuItem
{
    return [NSPasteboard.generalPasteboard canReadItemWithDataConformingToTypes:@[P_PropertyListPasteboardType]];
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

- (IBAction)add:(id)sender
{
    P_Data *p = [[P_Data alloc] init];
    [self addItem:p];
}

/** 删除 */
- (IBAction)delete:(id)sender
{
    NSInteger selectedRow = self.selectedRow;
    P_Data *p = [self itemAtRow:selectedRow];
    [self deleteItem:p];
}

/** 剪切 */
- (IBAction)cut:(id)sender
{
    [self copy:sender];
    [self delete:sender];
}

/** 拷贝 */
- (IBAction)copy:(id)sender
{
    [NSPasteboard.generalPasteboard clearContents];
    
    NSInteger selectedRow = [self selectedRow];
    P_Data *p = [self itemAtRow:selectedRow];
    [NSPasteboard.generalPasteboard setData:[NSKeyedArchiver archivedDataWithRootObject:p] forType:P_PropertyListPasteboardType];
}

- (IBAction)paste:(id)sender
{
    P_Data *p = [NSKeyedUnarchiver unarchiveObjectWithData:[NSPasteboard.generalPasteboard dataForType:P_PropertyListPasteboardType]];

    [self insertItem:p ofItem:[self itemAtRow:self.selectedRow]];
}

- (IBAction)menuDidSelecter:(NSMenuItem *)sender
{
    NSInteger selectedRow = [self selectedRow];
    P_Data *p = [self itemAtRow:selectedRow];
    [self updateType:sender.title value:p.value childDatas:nil ofItem:p];
}

#pragma mark - 移动
- (void)moveItem:(id)item toIndex:(NSUInteger)toIndex inParent:(id)parent
{
    /** 关闭输入框 */
    [self endEditing];
    
    P_Data *p = item;
    P_Data *parentItem = parent;
    
    /** willChangeNode */
    
    [self beginUpdates];
    
    P_Data *parent_p = p.level > 0 ? p.parentData : nil;
    NSInteger index = [parent_p.childDatas indexOfObject:p];
    
    /** 修复自身数组的处理位置 */
    if (parentItem == parent_p) {
        toIndex = (toIndex > index ? toIndex -1 : toIndex);
    }
    
    [self moveItemAtIndex:index inParent:parent_p toIndex:toIndex inParent:parentItem];
    [parent_p removeChildDataAtIndex:index];
    [parentItem insertChildData:p atIndex:toIndex];
    
    [self endUpdates];
    
    void (^handleParentItem)(P_Data *, NSInteger) = ^(P_Data *b_parentItem, NSInteger b_idx){
        
        if (b_parentItem) {
            [self reloadItem:b_parentItem];
        }
        
        if(b_parentItem.type == Plist.Array)
        {
            /** key 重新排序 */
            NSArray <P_Data *> *children = b_parentItem.childDatas;
            [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(b_idx, children.count - b_idx)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                [self reloadItem:children[idx]];
            }];
        }
    };
    
    if (parentItem == parent_p) {
        handleParentItem(parentItem, MIN(index, toIndex));
    } else {
        handleParentItem(parent_p, index);
        handleParentItem(parentItem, toIndex);
    }
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView* _Nonnull target) {
        [target moveItem:item toIndex:index inParent:parent_p];
    }];
    
    NSInteger selectedRow = [self rowForItem:item];
    if(selectedRow != -1)
    {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    }
    
    /** didChangeNode */
    
    NSLog(@"move %@", item);
    [self callDelegate:item];
}

#pragma mark - 插入值key、type、value
- (void)insertItem:(id)newItem ofItem:(id)item
{
    /** 关闭输入框 */
    [self endEditing];
    
    NSAssert(item != nil, @"Item is nil.");
    NSAssert([self rowForItem:item] != -1, @"Item is not in the list.");
    
    P_Data *new_p = newItem;
    P_Data *p = item;
    P_Data *parent_p = nil;
    
    BOOL isEmptyKey = new_p.key.length == 0;
    
    /** willChangeNode */
    
    NSInteger index;
    
    
    
    if([self isItemExpanded:p])
    {
        parent_p = p;
        index = 0;
    }
    else
    {
        if (p.level == 0) { //root
            [self expandItem:p];
            parent_p = p;
            index = 0;
        } else {
            parent_p = p.parentData;
            index = [parent_p.childDatas indexOfObject:p] + 1;
        }
    }
    
    if (isEmptyKey) {
        /** 给一个默认配置的key，如果没有，可以给一个默认的key */
        P_Config *config = [[P_Config config] configAtKey: parent_p.key];
        NSArray<P_Config *> *configChildren = config.childDatas;
        P_Config *c = nil;
        NSInteger idx = 0;
        P_Data *tmpP = parent_p.childDatas.firstObject;
        do {
            if (idx == configChildren.count) {
                break;
            }
            c = configChildren[idx];
            idx++;
        } while ([tmpP containsChildrenWithKey:c.key]);
        
        if (c) {
            [new_p copyP_Data:c.data];
        } else {
            new_p.key = PlistGlobalConfig.defaultKey;
        }
    }
    
    if (parent_p.type == Plist.Dictionary) {
        //key 的复用判断
        
        P_Data *tmpP = parent_p.childDatas.firstObject;
        
        NSUInteger count = 2;
        NSString* originalKey = new_p.key;
        
        while([tmpP containsChildrenWithKey:new_p.key])
        {
            new_p.key = [NSString stringWithFormat:@"%@ - %lu", originalKey, count];
            count += 1;
        }
    }
    
    [self beginUpdates];
    
    [self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parent_p withAnimation:NSTableViewAnimationEffectNone];
    [parent_p insertChildData:new_p atIndex:index];

    
    [self endUpdates];
    
    if (parent_p) {
        [self reloadItem:parent_p];
    }
    
    if(parent_p.type == Plist.Array)
    {
        /** key 重新排序 */
        NSArray <P_Data *> *children = parent_p.childDatas;
        [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, children.count - index)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [self reloadItem:children[idx]];
        }];
    }
    
    NSInteger insertedRow = [self rowForItem:new_p];
    
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:insertedRow] byExtendingSelection:NO];
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView* _Nonnull target) {
        [target deleteItem:new_p];
    }];
    
    /** didChangeNode */
    
    if (isEmptyKey) {
        P_PropertyListBasicCellView *cellView = [self viewAtColumn:0 row:insertedRow makeIfNecessary:NO];
        // 激活key的输入框
        [cellView.textField becomeFirstResponder];
    }
    
    NSLog(@"insert %@", new_p);
    [self callDelegate:new_p];
}

#pragma mark - 删除值key、type、value
- (void)deleteItem:(id)item
{
    /** 关闭输入框 */
    [self endEditing];
    
    NSAssert(item != nil, @"Item is nil.");
    NSAssert([self rowForItem:item] != -1, @"Item is not in the list.");
    
    P_Data *p = item;
    
    /** willChangeNode */
    
    [self beginUpdates];
    
    NSInteger selectedRow = [self rowForItem:item];
    
    P_Data *parent_p = p.level > 0 ? p.parentData : nil;
    
    NSInteger index = [parent_p.childDatas indexOfObject:p];
    [self removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:index] inParent:parent_p withAnimation:NSTableViewAnimationEffectNone];
    [parent_p removeChildDataAtIndex:index];
    
    
    [self endUpdates];
    
    if (parent_p) {
        [self reloadItem:parent_p];
    }
    
    if(parent_p.type == Plist.Array)
    {
        /** key 重新排序 */
        NSArray <P_Data *> *children = parent_p.childDatas;
        [[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index, children.count - index)] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [self reloadItem:children[idx]];
        }];
    }
    
    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView* _Nonnull target) {
        [target insertItem:item ofItem:[self itemAtRow:selectedRow-1]];
    }];
    
    if(selectedRow != -1)
    {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
    }
    
    /** didChangeNode */
    
    NSLog(@"delete %@", item);
    [self callDelegate:p];
}

#pragma mark - 更新值key、type、value

- (void)updateItem:(id)newItem ofItem:(id)item
{
    /** 关闭输入框 */
    [self endEditing];
    
    NSAssert(item != nil, @"Item is nil.");
    NSAssert([self rowForItem:item] != -1, @"Item is not in the list.");
    
    P_Data *new_p = newItem;
    P_Data *p = item;
    
    if([p isEqualToP_Data:new_p])
    {
        return;
    }
    
    /** willChangeNode */
    
    P_Data *old_p = [p copy];
    [p copyP_Data:new_p];
    
    [self reloadItem:p];

    [_undoManager registerUndoWithTarget:self handler:^(P_PropertyListOutlineView * _Nonnull target) {
        [target updateItem:old_p ofItem:p];
    }];
    
    /** didChangeNode */
    
    NSLog(@"update %@", item);
    [self callDelegate:p];
}

- (void)updateKey:(NSString *)key ofItem:(id)item withView:(BOOL)withView
{
    NSAssert(item != nil, @"Item is nil.");
    NSAssert([self rowForItem:item] != -1, @"Item is not in the list.");
    
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
    
    NSLog(@"update %@", p);
    [self callDelegate:p];
}

- (void)updateType:(P_PlistTypeName)type value:(id)value childDatas:(NSArray <P_Data *> *_Nullable)childDatas ofItem:(id)item
{
    NSAssert(item != nil, @"Item is nil.");
    NSAssert([self rowForItem:item] != -1, @"Item is not in the list.");
    
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
    
    NSLog(@"update %@", p);
    [self callDelegate:p];
}

- (void)updateValue:(id)value ofItem:(id)item withView:(BOOL)withView
{
    NSAssert(item != nil, @"Item is nil.");
    NSAssert([self rowForItem:item] != -1, @"Item is not in the list.");
    
    P_Data *p = item;
    if ([p.value isEqual:value] || [p.valueDesc isEqual: value]) {
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
    
    NSLog(@"update %@", p);
    [self callDelegate:p];
}

#pragma mark - call delegate
- (void)callDelegate:(id)item
{
    if ([self.delegate respondsToSelector:@selector(p_propertyListOutlineView:didEditable:)]) {
        [self.delegate p_propertyListOutlineView:self didEditable:item];
    }
}

#pragma mark - NSDraggingDestination
// 拖放显示图标
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    _dragInSide = YES;
    if (self.delegate) {
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender {
    _dragInSide = YES;
    if (self.delegate) {
        return NSDragOperationGeneric;
    }
    return NSDragOperationNone;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    if (self.dragInSide) {
        NSPasteboard *pasteboard = [sender draggingPasteboard];
        NSArray *files = [pasteboard propertyListForType:NSFilenamesPboardType];
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:files.count];
        for (NSString *filePath in files) {
            if ([self.delegate respondsToSelector:@selector(p_propertyListOutlineViewSupportFileExtension:)]) {
                NSString *pathExtension = [filePath pathExtension];
                NSArray *array = [self.delegate p_propertyListOutlineViewSupportFileExtension:self];
                if ([array containsObject:pathExtension]) {
                    [results addObject:filePath];
                }
            }
        }
        if ([self.delegate respondsToSelector:@selector(p_propertyListOutlineView:didDragFiles:)]) {
            [self.delegate p_propertyListOutlineView:self didDragFiles:[results copy]];
        }
    }
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
    _dragInSide = NO;
}

// 拖放操作
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    NSArray *files = [pasteboard propertyListForType:NSFilenamesPboardType];
    for (NSString *filePath in files) {
        if ([self.delegate respondsToSelector:@selector(p_propertyListOutlineViewSupportFileExtension:)]) {
            NSString *pathExtension = [filePath pathExtension];
            NSArray *array = [self.delegate p_propertyListOutlineViewSupportFileExtension:self];
            if (![array containsObject:pathExtension]) {
                return NO;
            }
        }
    }
    return YES;
}

@end

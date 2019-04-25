//
//  P_Data.m
//  UserConfigurationTool
//
//  Created by TsanFeng Lam on 2019/4/22.
//  Copyright © 2019 gzmiracle. All rights reserved.
//

#import "P_Data.h"
#import "P_TypeHeader.h"

@interface P_Data ()

@property (nullable, weak) P_Data *parentData;
@property (nonatomic, strong) NSMutableArray <P_Data *>*m_childDatas;

#pragma mark - extern
/** 展开状态 */
@property (nonatomic, assign) BOOL expandState;

/** 编辑类型 */
@property (nonatomic, assign) P_Data_EditableType editable;
/** 操作类型 */
@property (nonatomic, assign) P_Data_OperationType operation;

@end

@implementation P_Data

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _expandState = NO;
        _editable = P_Data_Editable_All;
        _operation = P_Data_Operation_All;
    }
    return self;
}

+ (instancetype)rootWithPlistUrl:(NSURL *)plistUrl
{
    id obj = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:plistUrl] options:0 format:nil error:NULL];
    if ([obj isKindOfClass:[NSDictionary class]]) {
        P_Data *p = [[[self class] alloc] initWithPlistKey:@"Root" value:obj];
        p.expandState = YES;
        p.editable ^= P_Data_Editable_Key;
        return p;
    } else if ([obj isKindOfClass:[NSArray class]]) {
        P_Data *p = [[[self class] alloc] initWithPlistKey:@"Root" value:obj];
        p.expandState = YES;
        p.editable ^= P_Data_Editable_Key;
        return p;
    } else {
        NSLog(@"The plistUrl is not a plist file url.");
    }
    return nil;
}

- (instancetype)initWithPlistKey:(NSString *)key value:(id)value
{
    self = [self init];
    if (self) {
        _key = key;
        _value = value;
        if ([value isKindOfClass:[NSDictionary class]]) {
            _type = Plist.Dictionary;
            _m_childDatas = [self dealWithChildDatas:value];
        } else if ([value isKindOfClass:[NSArray class]]) {
            _type = Plist.Array;
            _m_childDatas = [self dealWithChildDatas:value];
        } else if ([value isKindOfClass:[NSString class]]) {
            _type = Plist.String;
        } else if ([value isKindOfClass:[NSNumber class]]) {
            NSString *descripe = [NSString stringWithFormat:@"%@", [value class]];
            if ([descripe rangeOfString:@"Boolean"].location == NSNotFound) {
                _type = Plist.Number;
            } else {
                _type = Plist.Boolean;
            }
        } else if ([value isKindOfClass:[NSDate class]]) {
            _type = Plist.Date;
        } else if ([value isKindOfClass:[NSData class]]) {
            _type = Plist.Data;
        }
    }
    return self;
}

- (NSMutableArray <P_Data *>*)dealWithChildDatas:(id)contents
{
    NSMutableArray *childDatas = nil;
    if ([contents isKindOfClass:[NSDictionary class]]) {
        childDatas = [NSMutableArray arrayWithCapacity:1];
        NSDictionary *plistData = (NSDictionary *)contents;
        for (NSString *key in plistData) {
            id value = plistData[key];
            P_Data *p = [[[self class] alloc] initWithPlistKey:key value:value];
            if (p) {
                p.parentData = self;
                [childDatas addObject:p];
            }
        }
    } else if ([contents isKindOfClass:[NSArray class]]) {
        childDatas = [NSMutableArray arrayWithCapacity:1];
        NSArray *plistData = (NSArray *)contents;
        for (NSInteger i=0; i<plistData.count; i++) {
            NSString *key = [NSString stringWithFormat:@"Item %lu", (unsigned long)i];
            id value = plistData[i];
            P_Data *p = [[[self class] alloc] initWithPlistKey:key value:value];
            if (p) {
                p.parentData = self;
                [childDatas addObject:p];
            }
        }
    }
    return childDatas;
}

#pragma mark - getter
- (NSMutableArray<P_Data *> *)m_childDatas
{
    if (_m_childDatas == nil) {
        _m_childDatas = [NSMutableArray arrayWithCapacity:1];
    }
    return _m_childDatas;
}

- (id)value
{
    return _value == nil ? @"" : _value;
}

- (NSString *)valueDesc
{
    if ([self.type isEqualToString: Plist.Dictionary]) {
        return [NSString stringWithFormat:@"(%lu items)",(unsigned long)[(NSDictionary *)self.value count]];
    } else if ([self.type isEqualToString: Plist.Array]) {
        return [NSString stringWithFormat:@"(%lu items)",(unsigned long)[(NSArray *)self.value count]];
    } else if ([self.type isEqualToString: Plist.String]) {
        return self.value;
    } else if ([self.type isEqualToString: Plist.Number]) {
        if ([self.value isKindOfClass:[NSNumber class]]) {
            return [self.value stringValue];
        } else {
            return @"0";
        }
    } else if ([self.type isEqualToString: Plist.Boolean]) {
        if ([self.value isKindOfClass:[NSNumber class]]) {
            return [self.value boolValue] ? PlistBoolean.Y : PlistBoolean.N;
        } else {
            return PlistBoolean.N;
        }
    } else if ([self.type isEqualToString: Plist.Date]) {
        return [self.value description];
    } else if ([self.type isEqualToString: Plist.Data]) {
        if ([self.value isKindOfClass:[NSData class]]) {
            return @"<DATA开发>";
        }
    }
    return @"";
}

- (BOOL)hasChild
{
    return _m_childDatas.count > 0;
}

- (BOOL)isExpandable
{
    return ([self.type isEqualToString: Plist.Dictionary] || [self.type isEqualToString: Plist.Array]);
}

- (int)level
{
    int level = 0;
    if (self.parentData) {
        level = self.parentData.level + 1;
    }
    return level;
}

- (NSArray<P_Data *> *)childDatas
{
    return [_m_childDatas copy];
}

- (void)setChildDatas:(NSArray<P_Data *> *)childDatas
{
    if (childDatas) {
        [_m_childDatas setArray:childDatas];
    } else {
        _m_childDatas = nil;
    }
}

- (void)sortWithSortDescriptors:(NSArray<NSSortDescriptor *> *)sortDescriptors recursively:(BOOL)recursively
{
    [_m_childDatas sortUsingDescriptors:sortDescriptors];
    if (recursively) {
        for (P_Data *p in _m_childDatas) {
            [p sortWithSortDescriptors:sortDescriptors recursively:recursively];
        }
    }
}

- (void)insertChildData:(P_Data *)data atIndex:(NSUInteger)idx
{
    [self.m_childDatas insertObject:data atIndex:idx];
    data.parentData = self;
}
- (void)removeChildDataAtIndex:(NSUInteger)idx
{
    P_Data *p = [_m_childDatas objectAtIndex:idx];
    [_m_childDatas removeObjectAtIndex:idx];
    p.parentData = nil;
}

#pragma mark - conver to plist

- (id)plist
{
    id plist = nil;
    if ([self.type isEqualToString: Plist.Dictionary]) {
        NSMutableDictionary *tmpPlist = [NSMutableDictionary dictionary];
        for (P_Data *p in self.childDatas) {
            [tmpPlist setObject:p.plist forKey:p.key];
        }
        plist = tmpPlist;
    } else if ([self.type isEqualToString: Plist.Array]) {
        NSMutableArray *tmpPlist = [NSMutableArray array];
        for (P_Data *p in self.childDatas) {
            [tmpPlist addObject:p.plist];
        }
        plist = tmpPlist;
    } else {
        plist = self.value;
    }
    return plist;
}

@end

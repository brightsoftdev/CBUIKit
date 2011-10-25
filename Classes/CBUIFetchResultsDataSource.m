//
//  CBUIFetchResultsDataSource.m
//  CBUIKit
//
//  Created by Christian Beer on 14.01.10.
//  Copyright 2010 Christian Beer. All rights reserved.
//

#import "CBUIFetchResultsDataSource.h"

#import "CBUIGlobal.h"

#define DEBUG

#define StringFromIndexPath(indexPath) [NSString stringWithFormat:@"[%lu, %lu]", indexPath.section, indexPath.row]

@implementation CBUIFetchResultsDataSource

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize loading = _loading;
@synthesize ignoreForUpdateIndexPath = _ignoreForUpdateIndexPath;

- (id) initWithTableView:(UITableView*)tableView
            fetchRequest:(NSFetchRequest*)fetchRequest managedObjectContext:(NSManagedObjectContext*)context 
      sectionNameKeyPath:(NSString*)sectionNameKeyPath
               cacheName:(NSString*)cacheName 
{
	self = [super initWithTableView:tableView];
    if (!self) return nil;
    
    if (CBUIMinimumVersion(4.0)) {
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:sectionNameKeyPath
                                                                                   cacheName:cacheName];
        self.fetchedResultsController.delegate = self;    
    } else {
        _fetchedResultsController = [[SafeFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                          managedObjectContext:context
                                                                            sectionNameKeyPath:sectionNameKeyPath
                                                                                     cacheName:cacheName];
        [(SafeFetchedResultsController*)self.fetchedResultsController setSafeDelegate:self];
    }

    self.loading = NO;
    
	return self;
}
- (id) initWithTableView:(UITableView*)tableView
            fetchRequest:(NSFetchRequest*)fetchRequest managedObjectContext:(NSManagedObjectContext*)context 
               cacheName:(NSString*)cacheName 
{
    return [self initWithTableView:tableView
                      fetchRequest:fetchRequest 
              managedObjectContext:context 
                sectionNameKeyPath:nil 
                         cacheName:cacheName];
}

+ (CBUIFetchResultsDataSource*) dataSourceWithTableView:(UITableView*)tableView
                                           fetchRequest:(NSFetchRequest*)fetchRequest managedObjectContext:(NSManagedObjectContext*)context
                                        sectionNameKeyPath:(NSString*)sectionNameKeyPath cacheName:(NSString*)cacheName {
	CBUIFetchResultsDataSource *ds = [[[self class] alloc] initWithTableView:tableView
                                                                fetchRequest:fetchRequest
                                                           managedObjectContext:context
                                                             sectionNameKeyPath:sectionNameKeyPath
                                                                      cacheName:cacheName];
	
	return [ds autorelease];
    
}

+ (CBUIFetchResultsDataSource*) dataSourceWithTableView:(UITableView*)tableView fetchRequest:(NSFetchRequest*)fetchRequest 
                                   managedObjectContext:(NSManagedObjectContext*)context cacheName:(NSString*)cacheName {
    return [self dataSourceWithTableView:tableView fetchRequest:fetchRequest managedObjectContext:context 
                         sectionNameKeyPath:nil cacheName:cacheName];
}

- (void) dealloc {
    [_fetchedResultsController dealloc], _fetchedResultsController = nil;
    [_ignoreForUpdateIndexPath release], _ignoreForUpdateIndexPath = nil;
    
    [super dealloc];
}

- (BOOL) performFetch:(NSError**)error
{
    self.loading = YES;
    BOOL result = [_fetchedResultsController performFetch:error];
    self.loading = NO;
    return result;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    id object = [self objectAtIndexPath:indexPath];
    
    if ([object isKindOfClass:[NSManagedObject class]]) {
        NSManagedObject *managedObject = (NSManagedObject*)object;
        
        [managedObject.managedObjectContext deleteObject:managedObject];
        
        NSError *error = nil;
        if (![managedObject.managedObjectContext save:&error]) {
            NSLog(@"Was unable to delete object: %@", error);
        }
    }
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	DLog(@"controllerWillChangeContent");
	
	[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
	 forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
	DLog(@"controller:didChangeObject::::");
    
    if ([_ignoreForUpdateIndexPath isEqual:indexPath]) return;
	
    switch(type)
	{
		case NSFetchedResultsChangeInsert:
		{
			DLog(@"Insert: %@", StringFromIndexPath(newIndexPath));
			
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
		case NSFetchedResultsChangeDelete:
		{
			DLog(@"Delete: %@", StringFromIndexPath(indexPath));
			
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
		case NSFetchedResultsChangeUpdate:
		{
			if (newIndexPath == nil || [newIndexPath isEqual:indexPath])
			{
				DLog(@"Update: %@", StringFromIndexPath(indexPath));
				
				[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
			}
			else
			{
				DLog(@"Update: %@ -> %@", StringFromIndexPath(indexPath), StringFromIndexPath(newIndexPath));
				
                [self.tableView moveRowAtIndexPath:indexPath
                                       toIndexPath:newIndexPath];
			}
			
			break;
		}
		case NSFetchedResultsChangeMove:
		{
			DLog(@"Move: %@ -> %@", StringFromIndexPath(indexPath), StringFromIndexPath(newIndexPath));
			
			[self.tableView moveRowAtIndexPath:indexPath
                                   toIndexPath:newIndexPath];
			
			break;
		}
	}
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
	DLog(@"controller:didChangeSection:::");
	
	switch(type)
	{
		case NSFetchedResultsChangeInsert:
		{
			DLog(@"NSFetchedResultsChangeInsertSection: %u", sectionIndex);
            
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
		case NSFetchedResultsChangeDelete:
		{
			DLog(@"NSFetchedResultsChangeDeleteSection: %u", sectionIndex);
			
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
			break;
		}
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	DLog(@"controllerDidChangeContent");
	
	[self.tableView endUpdates];
}

- (void)controllerDidMakeUnsafeChanges:(NSFetchedResultsController *)controller
{
	DLog(@"controllerDidMakeUnsafeChanges");
	
	[self.tableView reloadData];
}

#pragma mark CBUITableViewDataSource

- (id) objectAtIndexPath:(NSIndexPath*)indexPath {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
	return managedObject;
}

#pragma mark -

- (NSIndexPath*) indexPathForObject:(id)object
{
    return [self.fetchedResultsController indexPathForObject:object];
}

#pragma mark -

// ONLY WORKS WITH ONE SECTION!!
- (BOOL) performFetchAndUpdateTableView:(NSError **)error
{
    NSArray *objectsBefore = [self.fetchedResultsController.fetchedObjects retain];
    
    BOOL result = [self.fetchedResultsController performFetch:error];
    if (result) {
        
        NSArray *objectsAfter = self.fetchedResultsController.fetchedObjects;
        
        NSMutableArray *insertedObjects = [[objectsAfter mutableCopy] autorelease];
        [insertedObjects removeObjectsInArray:objectsBefore];
        
        NSMutableArray *removedObjects = [[objectsBefore mutableCopy] autorelease];
        [removedObjects removeObjectsInArray:objectsAfter];
        
        NSMutableArray *insertedIndexPaths = [NSMutableArray arrayWithCapacity:insertedObjects.count];
        [insertedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [insertedIndexPaths addObject:[NSIndexPath indexPathForRow:[objectsAfter indexOfObject:obj] inSection:0]];
        }];
        
        NSMutableArray *removedIndexPaths = [NSMutableArray arrayWithCapacity:removedObjects.count];
        [removedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [removedIndexPaths addObject:[NSIndexPath indexPathForRow:[objectsBefore indexOfObject:obj] inSection:0]];
        }];
        
        if (insertedIndexPaths.count > 0 || removedIndexPaths.count > 0) {
            [_tableView beginUpdates];
            
            [_tableView insertRowsAtIndexPaths:insertedIndexPaths 
                              withRowAnimation:UITableViewRowAnimationFade];
            [_tableView deleteRowsAtIndexPaths:removedIndexPaths 
                              withRowAnimation:UITableViewRowAnimationFade];
            
            [_tableView endUpdates];
        }
    }
    
    [objectsBefore release];
    return result;
}

@end



@implementation CBUIFetchResultsByKeyPathDataSource 

@synthesize objectKeyPath;

- (void) dealloc {
    [objectKeyPath release], objectKeyPath = nil;
    [super dealloc];
}

#pragma mark CBUITableViewDataSource

- (id) objectAtIndexPath:(NSIndexPath*)indexPath {
    NSManagedObject *managedObject = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (!objectKeyPath) return managedObject;
    
	return [managedObject valueForKeyPath:objectKeyPath];
}

@end
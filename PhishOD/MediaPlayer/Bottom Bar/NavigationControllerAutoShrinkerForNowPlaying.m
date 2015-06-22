//
//  CenterPanelAutoShrinker.m
//  Phish Tracks
//
//  Created by Alec Gorge on 1/25/14.
//  Copyright (c) 2014 Alec Gorge. All rights reserved.
//

#import "NavigationControllerAutoShrinkerForNowPlaying.h"

#import "NowPlayingBarViewController.h"
#import "AppDelegate.h"
#import "AGMediaPlayerViewController.h"
#import "PHODTabbedHomeViewController.h"
#import "SearchViewController.h"
#import "SettingsViewController.h"

@interface NavigationControllerAutoShrinkerForNowPlaying ()

@property (nonatomic) UISearchController *searchController;

@end

@implementation NavigationControllerAutoShrinkerForNowPlaying

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
					animated:(BOOL)animated {
	self.lastViewController = viewController;
	[self fixForViewController:viewController];
	
	UIViewController *rootViewController = navigationController.viewControllers[0];
	
	if(rootViewController) {
		if(rootViewController.navigationItem.leftBarButtonItem == nil) {
			[self addSettingsButtonToViewController:rootViewController];
		}
	}
	
	if (viewController.navigationItem.rightBarButtonItem == nil) {
//		[self addSearchButtonToViewController:viewController];
	}
}

- (void)addSettingsButtonToViewController:(UIViewController *)viewController {
	viewController.navigationItem.leftBarButtonItem = [UIBarButtonItem.alloc initWithImage:[UIImage settingsNavigationIcon]
																					 style:UIBarButtonItemStylePlain
																					target:self
																					action:@selector(showSettings)];
}

- (void)showSettings {
	UINavigationController *navController = [UINavigationController.alloc initWithRootViewController:SettingsViewController.new];
	
	[AppDelegate.sharedDelegate.window.rootViewController presentViewController:navController
												  animated:YES
												completion:nil];
}

- (void)addSearchButtonToViewController:(UIViewController *)viewController {
	viewController.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
																						 target:self
																								   action:@selector(startSearch:)];
}

- (void)startSearch {
	// Create the search controller and make it perform the results updating.
	
	SearchViewController *s = SearchViewController.new;
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:s];
	self.searchController.searchResultsUpdater = s;
	self.searchController.hidesNavigationBarDuringPresentation = NO;
	
	// Present the view controller.
//	[self presentViewController:self.searchController animated:YES completion:nil];
}

- (void)addBarToView:(UIView *)view {
    if([view viewWithTag:NowPlayingBarViewController.sharedInstance.view.tag] == nil) {
        UIView *v = NowPlayingBarViewController.sharedInstance.view;
        [v removeFromSuperview];
        
        CGRect r = v.bounds;
        
        r.origin.y = view.bounds.size.height - AppDelegate.sharedDelegate.tabBar.bounds.size.height;
        r.size.width = view.bounds.size.width;
        
//        if (NowPlayingBarViewController.sharedInstance.shouldShowBar) {
//            r.origin.y = view.bounds.size.height - r.size.height;
//        }
        
        v.frame = r;
        
        [view addSubview:v];
        [view bringSubviewToFront:v];
    }
    
	[view bringSubviewToFront:NowPlayingBarViewController.sharedInstance.view];
    
    [UIView animateWithDuration:0.3
                     animations:^{
                         if (NowPlayingBarViewController.sharedInstance.shouldShowBar) {
                             CGRect r = NowPlayingBarViewController.sharedInstance.view.frame;
                             r.origin.y = view.bounds.size.height - r.size.height - AppDelegate.sharedDelegate.tabBar.bounds.size.height;
                             NowPlayingBarViewController.sharedInstance.view.frame = r;
                         }
                         else {
                             CGRect r = NowPlayingBarViewController.sharedInstance.view.frame;
                             r.origin.y = view.bounds.size.height;
                             NowPlayingBarViewController.sharedInstance.view.frame = r;
                         }
                     }];
}

- (void)addBarToViewController:(UIViewController *)vc {
	[self addBarToView:AppDelegate.sharedDelegate.window.rootViewController.view];
}

- (void)fixForViewController:(UIViewController *)viewController {
    if (!NowPlayingBarViewController.sharedInstance.shouldShowBar) {
        return;
    }
    
    if([viewController isKindOfClass:UINavigationController.class]) {
		for(UIViewController *vc2 in ((UINavigationController*)viewController).viewControllers) {
			[self fixForViewController:vc2];
		}
	}
	else if([viewController isKindOfClass:[UITableViewController class]]) {
		UITableView *t = [(UITableViewController*)viewController tableView];
        
		UIEdgeInsets edges = t.contentInset;
        
		if((edges.bottom - AppDelegate.sharedDelegate.tabBar.bounds.size.height) < NowPlayingBarViewController.sharedInstance.view.bounds.size.height)
			edges.bottom += NowPlayingBarViewController.sharedInstance.view.bounds.size.height;
        
		t.contentInset = edges;
        
		edges = t.scrollIndicatorInsets;
        
		if((edges.bottom - AppDelegate.sharedDelegate.tabBar.bounds.size.height) < NowPlayingBarViewController.sharedInstance.view.bounds.size.height)
			edges.bottom += NowPlayingBarViewController.sharedInstance.view.bounds.size.height;
        
		t.scrollIndicatorInsets = edges;
	}
	else if ([viewController.view isKindOfClass:[UIScrollView class]]) {
		UIScrollView *t = (UIScrollView*)viewController.view;
        
		UIEdgeInsets edges = t.contentInset;
        
		if(edges.bottom < NowPlayingBarViewController.sharedInstance.view.bounds.size.height)
			edges.bottom += NowPlayingBarViewController.sharedInstance.view.bounds.size.height;
        
		t.contentInset = edges;
        
		edges = t.scrollIndicatorInsets;
        
		if(edges.bottom < NowPlayingBarViewController.sharedInstance.view.bounds.size.height)
			edges.bottom += NowPlayingBarViewController.sharedInstance.view.bounds.size.height;
        
		t.scrollIndicatorInsets = edges;
	}
}

@end

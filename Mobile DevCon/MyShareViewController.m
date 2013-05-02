/*
 * Copyright 2012 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "MyShareViewController.h"
#import <FacebookSDK/FacebookSDK.h>

NSString *const kPlaceholderPostMessage = @"Say something about this...";

@interface MyShareViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *userMessageTextView;
@property (weak, nonatomic) IBOutlet UIImageView *storyImageView;
@property (weak, nonatomic) IBOutlet UILabel *storyTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *storyDescriptionLabel;
@property (strong, nonatomic) NSMutableDictionary *storyObject;
@property (strong, nonatomic) NSString *objectType;
@property (strong, nonatomic) NSString *actionType;

@end

@implementation MyShareViewController

- (id)initWithItem:(NSDictionary *)object objectType:(NSString *)objectTypeName
        actionType:(NSString *) actionTypeName
{
    self = [super init];
    if (self) {
        self.storyObject = [[NSMutableDictionary alloc] initWithDictionary:object
                                                                 copyItems:NO];
        self.objectType = objectTypeName;
        self.actionType = actionTypeName;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Show placeholder text
    [self resetPostMessage];
    
    // Set story image
    if (self.storyObject[@"image"]) {
        self.storyImageView.image = self.storyObject[@"image"];
    }
    
    // Set story title
    if (self.storyObject[@"object"][@"title"]) {
        self.storyTitleLabel.text = self.storyObject[@"object"][@"title"];
    }
    
    // Set story description
    if (self.storyObject[@"object"][@"description"]) {
        self.storyDescriptionLabel.text = self.storyObject[@"object"][@"description"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 * A simple way to dismiss the message text view:
 * whenever the user clicks outside the view.
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *) event
{
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.userMessageTextView isFirstResponder] &&
        (self.userMessageTextView != touch.view))
    {
        [self.userMessageTextView resignFirstResponder];
    }
}

#pragma mark Helper methods
/*
 * This sets up the placeholder text.
 */
- (void)resetPostMessage
{
    self.userMessageTextView.text = kPlaceholderPostMessage;
    self.userMessageTextView.textColor = [UIColor lightGrayColor];
}

#pragma mark Share methods
/*
 * Publish the story
 */
- (void)publishStory
{
    // Iniitalize a connection for making a batch request
    FBRequestConnection *connection = [[FBRequestConnection alloc] init];
    
    // Request: Image upload (optional)
    if (!self.storyObject[@"object"][@"image"]) {
        // If there is no image attached to the object but there
        // is a local copy then kick off the image upload to the
        // staging resources
        
        // Set debugging so we can see the staging
        // resource URL come back
        [FBSettings setLoggingBehavior:
         [NSSet setWithObjects:FBLoggingBehaviorFBRequests,
          FBLoggingBehaviorFBURLConnections,
          nil]];
        // Create the image upload request
        FBRequest *imageUploadRequest =
        [FBRequest requestForUploadStagingResourceWithImage:
         self.storyObject[@"image"]];
        // Add the request to the batch
        [connection addRequest:imageUploadRequest
             completionHandler:
         ^(FBRequestConnection *connection, id result, NSError *error) {
             if (error) {
                 NSLog(@"Error: %@", error.description);
             }
             // Stop request debug
             [FBSettings setLoggingBehavior:nil];
         }
                batchEntryName:@"imageUpload"];
    }
    
    // Request: Object creation
    NSMutableDictionary<FBOpenGraphObject> *object = [FBGraphObject openGraphObjectForPost];
    object[@"type"] = self.storyObject[@"object"][@"type"];
    object[@"title"] = self.storyObject[@"object"][@"title"];
    // Set the image for the object
    if (self.storyObject[@"object"][@"image"]) {
        object[@"image"] = self.storyObject[@"object"][@"image"];
    } else {
        // Image URL is the result of the image upload batch request
        object[@"image"] = @"{result=imageUpload:$.uri}";
    }
    object[@"description"] = self.storyObject[@"object"][@"description"];
    if (self.storyObject[@"object"][@"data"]) {
        object[@"data"] = self.storyObject[@"object"][@"data"];
    }
    
    // Add the request to the batch
    FBRequest *objectRequest = [FBRequest
                                requestForPostOpenGraphObject:object];
    [connection addRequest:objectRequest
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             if (error) {
                 NSLog(@"Error: %@", error.description);
             }
         }
            batchEntryName:@"objectCreate"];
    
    
    // Create an action
    NSMutableDictionary<FBOpenGraphAction> *action = [FBGraphObject openGraphActionForPost];
    
    // Attach the id from the object created to the action's object
    action[self.objectType] = @"{result=objectCreate:$.id}";
    
    // Add user message parameter if user filled it in
    if (![self.userMessageTextView.text
          isEqualToString:kPlaceholderPostMessage] &&
        ![self.userMessageTextView.text isEqualToString:@""]) {
        action[@"message"] = self.userMessageTextView.text;
    }
    
    // Since the user has explicitly shared the action, turn on the flag
    action[@"fb:explicitly_shared"] = @"true";
    
    // Request: Publish action
    FBRequest *actionRequest = [FBRequest requestForPostWithGraphPath:
                                [NSString stringWithFormat:@"me/%@", self.actionType]
                                                          graphObject:action];
    [connection addRequest:actionRequest
         completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
             if (error) {
                 NSLog(@"Error: %@", error.description);
             } else {
                 NSLog(@"Posted OG action with id: %@", result[@"id"]);
             }
             // Dismiss the share view
             [[self presentingViewController] dismissViewControllerAnimated:YES
                                                                 completion:nil];
         }];
    
    [connection start];
}

#pragma Button Actions
- (IBAction)cancelAction:(id)sender {
    [[self presentingViewController] dismissViewControllerAnimated:YES
                                                        completion:nil];
}

- (IBAction)postAction:(id)sender {
    // Hide keyboard if showing when button clicked
    if ([self.userMessageTextView isFirstResponder]) {
        [self.userMessageTextView resignFirstResponder];
    }
    
    // Ask for publish_actions permissions in context
    if ([FBSession.activeSession.permissions
         indexOfObject:@"publish_actions"] == NSNotFound) {
        // No permissions found in session, ask for it
        [self requestPermissionAndPost];
    } else {
        // If permissions present, publish the story
        [self publishStory];
    }
}

- (void) requestPermissionAndPost {
    [FBSession.activeSession
     requestNewPublishPermissions:
     [NSArray arrayWithObject:@"publish_actions"]
     defaultAudience:FBSessionDefaultAudienceFriends
     completionHandler:^(FBSession *session, NSError *error) {
         if (!error) {
             // If permissions granted, publish the story
             [self publishStory];
         }
     }];
}

- (void)handlePostOpenGraphActionError:(NSError *) error{
    // Facebook SDK * pro-tip *
    // Users can revoke post permissions on your app externally so it
    // can be worthwhile to request for permissions again at the point
    // that they are needed. This sample assumes a simple policy
    // of re-requesting permissions.
    if (error.fberrorCategory == FBErrorCategoryPermissions) {
        NSLog(@"Re-requesting permissions");
        [self requestPermissionAndPost];
        return;
    }
}

#pragma mark - UITextViewDelegate methods
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // Clear the message text when the user starts editing
    if ([textView.text isEqualToString:kPlaceholderPostMessage]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    // Reset to placeholder text if the user is done
    // editing and no message has been entered.
    if ([textView.text isEqualToString:@""]) {
        [self resetPostMessage];
    }
}

@end
//
//  ProjectObservationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import AFNetworking;
@import UIColor_HTMLColors;
@import ActionSheetPicker_3_0;
@import FontAwesomeKit;

#import "ProjectObservationsViewController.h"
#import "ProjectObservationHeaderView.h"
#import "Analytics.h"
#import "ObsFieldSimpleValueCell.h"
#import "ObsFieldLongTextValueCell.h"
#import "ProjectObsFieldViewController.h"
#import "TaxaSearchViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "ExploreTaxonRealm.h"
#import "INatReachability.h"
#import "ExploreUserRealm.h"
#import "UIColor+INaturalist.h"
#import "InsetLabel.h"
#import "ExploreProjectRealm.h"
#import "ProjectsAPI.h"

static NSString *SimpleFieldIdentifier = @"simple";
static NSString *LongTextFieldIdentifier = @"longtext";

@interface ProjectObservationsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, TaxaSearchViewControllerDelegate> {
    
    UIToolbar *_keyboardToolbar;
}

@property RLMResults *joinedProjects;
@property RLMNotificationToken *joinedToken;

@property NSIndexPath *taxaSearchIndexPath;
@property UITapGestureRecognizer *tapAwayGesture;
@property (readonly) UIToolbar *keyboardToolbar;
@end

@implementation ProjectObservationsViewController

- (ProjectsAPI *)projectsApi {
    static ProjectsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ProjectsAPI alloc] init];
    });
    return _api;
}

#pragma mark - UIViewController lifecycle

- (void)syncUserProjectsUserId:(NSInteger)userId page:(NSInteger)page {

    __weak typeof(self)weakSelf = self;
    [[self projectsApi] projectsForUser:userId page:page handler:^(NSArray *results, NSInteger totalCount, NSError *error) {
        ExploreUserRealm *meUser = [ExploreUserRealm objectForPrimaryKey:@(userId)];
        if (!meUser) { return; }        // can't join projects if we don't have a me user
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        for (ExploreProject *eg in results) {
            NSDictionary *value = [ExploreProjectRealm valueForMantleModel:eg];
            ExploreProjectRealm *project = [ExploreProjectRealm createOrUpdateInDefaultRealmWithValue:value];
            [meUser.joinedProjects addObject:project];
        }
        [realm commitWriteTransaction];

        // update tableview
        [weakSelf.tableView reloadData];
        
        NSInteger totalReceived = results.count + ((page-1) * [[weakSelf projectsApi] projectsPerPage]);
        if (totalReceived < totalCount) {
            // recursively fetch another page of joined projects
            [weakSelf syncUserProjectsUserId:userId page:page+1];
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *sorts = @[
        [RLMSortDescriptor sortDescriptorWithKeyPath:@"type" ascending:NO],
        [RLMSortDescriptor sortDescriptorWithKeyPath:@"title" ascending:YES],
    ];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loginController.isLoggedIn) {
        ExploreUserRealm *meUser = appDelegate.loginController.meUserLocal;
        if (meUser) {
            self.joinedProjects = [[meUser joinedProjects] sortedResultsUsingDescriptors:sorts];
            __weak typeof(self)weakSelf = self;
            self.joinedToken = [self.joinedProjects addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
                [weakSelf.tableView reloadData];
            }];
        }
    }
    
    self.title = NSLocalizedString(@"Choose Projects", @"title for project observations chooser");
    
    self.tableView.tableHeaderView = ({
        InsetLabel *label = [InsetLabel new];
        label.insets = UIEdgeInsetsMake(10, 10, 10, 10);
        label.text = NSLocalizedString(@"Please note: Observations will be automatically included in a collection project if they meet its requirements.",
                                       @"helpful note about observations and collection projects on the screen where you can add observations to projects.");
        label.numberOfLines = 0;
        label.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
        label;
    });
    [self.tableView.tableHeaderView sizeToFit];

    self.navigationItem.leftBarButtonItem = ({
        FAKIcon *backIcon = [FAKIonIcons iosArrowBackIconWithSize:34];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[backIcon imageWithSize:CGSizeMake(14, 34)]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(backPressed:)];
        
        item;
    });
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.estimatedRowHeight = 44.0f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.tableView registerClass:[ObsFieldSimpleValueCell class] forCellReuseIdentifier:SimpleFieldIdentifier];
    [self.tableView registerClass:[ObsFieldLongTextValueCell class] forCellReuseIdentifier:LongTextFieldIdentifier];
    
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if ([appDelegate.loginController isLoggedIn]) {
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            // start by clearing all joined projects
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            [me.joinedProjects removeAllObjects];
            [realm commitWriteTransaction];
            
            // sync first page, that will trigger page 2 if
            // necessary and so on
            [self syncUserProjectsUserId:me.userId page:1];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
}

- (void)dealloc {
    [self.joinedToken invalidate];
}

#pragma mark - UIBarButton targets

- (void)backPressed:(UIBarButtonItem *)button {
    // end editing on any rows
    [self.tableView endEditing:YES];
    
    // save the ofvs
    [self saveVisibleObservationFieldValues];
    
    NSString *projectNameFailingValidation = [NSString string];
    NSString *projectFieldFailingValidation = [NSString string];
    
    BOOL validated = [self validateProjectObservationsForObservation:self.observation
                                                       failedProject:&projectNameFailingValidation
                                                         failedField:&projectFieldFailingValidation];
    
    if (validated) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"'%@' requires that you fill out the '%@' field.",nil),
                         projectNameFailingValidation,
                         projectFieldFailingValidation];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Missing Required Field",nil)
                                                                       message:msg
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - ProjectObs & OFV helpers

- (BOOL)validateProjectObservationsForObservation:(ExploreObservationRealm *)observation
                                    failedProject:(out NSString **)failedProjectName
                                      failedField:(out NSString **)failedFieldName {
    
    for (ExploreProjectObservationRealm *po in self.observation.projectObservations) {
        for (ExploreProjectObsFieldRealm *pof in po.project.projectObsFields) {
            if (pof.required) {
                ExploreObsFieldValueRealm *ofv = [self.observation valueForObsField:pof.obsField];
                if (!ofv || ofv.value == nil || ofv.value.length == 0) {
                    *failedProjectName = po.project.title;
                    *failedFieldName = pof.obsField.name;
                    return NO;
                }
            }
        }
    }
        
    return YES;
}

- (void)saveVisibleObservationFieldValues {
    RLMRealm *realm = [RLMRealm defaultRealm];

    for (NSIndexPath *indexPath in self.tableView.indexPathsForVisibleRows) {
        ExploreProjectRealm *project = [self projectForSection:indexPath.section];
        if (!project) return;
        
        ExploreProjectObsFieldRealm *pof = [[project sortedProjectObservationFields] objectAtIndex:indexPath.item];
        
        
        ExploreObsFieldValueRealm *ofv = [self.observation valueForObsField:pof.obsField];
        if (ofv) {
            if (![ofv.value isEqualToString:[self currentValueForIndexPath:indexPath]]) {
                [realm beginWriteTransaction];
                ofv.value = [self currentValueForIndexPath:indexPath];
                ofv.timeUpdatedLocally = [NSDate date];
                [realm commitWriteTransaction];
            }
        } else {
            ofv = [ExploreObsFieldValueRealm new];
            ofv.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
            ofv.obsField = pof.obsField;
            ofv.value = [self currentValueForIndexPath:indexPath];
            ofv.timeUpdatedLocally = [NSDate date];

            [realm beginWriteTransaction];
            [realm addObject:ofv];
            [self.observation.observationFieldValues addObject:ofv];
            [realm commitWriteTransaction];
        }
    }
}

#pragma mark - UITextField delegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.superview.superview isKindOfClass:[ObsFieldSimpleValueCell class]]) {
        // this textfield needs to be cleared and the value set
        ObsFieldSimpleValueCell *cell = (ObsFieldSimpleValueCell *)textField.superview.superview;
        cell.valueLabel.text = textField.text;
        [textField removeFromSuperview];
        cell.valueLabel.hidden = NO;
    }
    
    [self saveVisibleObservationFieldValues];
}

- (void)tapAway:(UITapGestureRecognizer *)gesture {
    [gesture.view endEditing:YES];
    [gesture.view removeGestureRecognizer:gesture];
}

- (UIToolbar *)keyboardToolbar {
    if (!_keyboardToolbar) {
        _keyboardToolbar = [[UIToolbar alloc] init];
        _keyboardToolbar.barStyle = UIBarStyleDefault;
        [_keyboardToolbar sizeToFit];

        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                              target:nil
                                                                              action:nil];
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(keyboardDone)];
        _keyboardToolbar.items = @[ flex, done ];
    }
    
    return _keyboardToolbar;
}

- (void)keyboardDone {
    [self.tableView endEditing:YES];
}

#pragma mark UITextFieldDelegate methods
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [textField setInputAccessoryView:self.keyboardToolbar];
    return YES;
}

#pragma mark - TaxaSearchViewControllerDelegate

- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxon chosenViaVision:(BOOL)visionFlag {
    [self.navigationController popToViewController:self animated:YES];
    
    if (!self.taxaSearchIndexPath) { return; }
    
    
    ExploreProjectRealm *project = [self projectForSection:self.taxaSearchIndexPath.section];
    if (!project) return;
    
    ExploreProjectObsFieldRealm *pof = [project.sortedProjectObservationFields objectAtIndex:self.taxaSearchIndexPath.item];
    
    ExploreObsFieldValueRealm *ofv = [self.observation valueForObsField:pof.obsField];
    if (ofv) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        ofv.value = [NSString stringWithFormat:@"%ld", (long)taxon.taxonId];
        ofv.timeUpdatedLocally = [NSDate date];
        [realm commitWriteTransaction];
    }
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ self.taxaSearchIndexPath ]
                          withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    
    self.taxaSearchIndexPath = nil;
    [self saveVisibleObservationFieldValues];
}

- (void)taxaSearchViewControllerCancelled {
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - UITableView delegate & datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreProjectRealm *project = [self projectForSection:indexPath.section];
    ExploreProjectObsFieldRealm *pof = [[project sortedProjectObservationFields] objectAtIndex:indexPath.item];
    
    if ([pof.obsField canBeTreatedAsText]) {
        if (pof.obsField.allowedValues.count > 1) {
            // simple value cell
            ObsFieldSimpleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleFieldIdentifier];
            [self configureSimpleCell:cell forProjectObsField:pof];
            return cell;
        } else {
            ObsFieldLongTextValueCell *cell = [tableView dequeueReusableCellWithIdentifier:LongTextFieldIdentifier];
            [self configureLongTextCell:cell forProjectObsField:pof];
            return cell;
        }
    } else if (pof.obsField.dataType == ExploreObsFieldDataTypeNumeric ||
               pof.obsField.dataType == ExploreObsFieldDataTypeDate ||
               pof.obsField.dataType == ExploreObsFieldDataTypeTime ||
               pof.obsField.dataType == ExploreObsFieldDataTypeDateTime ||
               pof.obsField.dataType == ExploreObsFieldDataTypeTaxon) {

        ObsFieldSimpleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:SimpleFieldIdentifier];
        [self configureSimpleCell:cell forProjectObsField:pof];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
        [self configureCell:cell forIndexPath:indexPath];
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {

    ExploreProjectRealm *project = [self projectForSection:section];
    BOOL projectIsSelected = [self projectIsSelected:project];
    
    CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
    
    UINib *nib = [UINib nibWithNibName:@"ProjectObservationHeaderView" bundle:[NSBundle mainBundle]];
    ProjectObservationHeaderView *header = [[nib instantiateWithOwner:nil options:nil] firstObject];
    header.frame = CGRectMake(0, 0, tableView.bounds.size.width, height);
    
    header.projectTitleLabel.text = project.title;
    header.projectTypeLabel.text = [project titleForTypeOfProject];
    
    if ([project isNewStyleProject]) {
        header.selectedSwitch.hidden = YES;
        header.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2];
    } else {
        header.selectedSwitch.hidden = NO;
        [header.selectedSwitch setOn:projectIsSelected animated:NO];
        header.selectedSwitch.tag = section;
        [header.selectedSwitch addTarget:self action:@selector(selectedChanged:) forControlEvents:UIControlEventValueChanged];
        header.backgroundColor = [UIColor whiteColor];
    }
    
    
    if ([project iconUrl]) {
        header.projectThumbnailImageView.backgroundColor = [UIColor clearColor];
        header.projectThumbnailImageView.contentMode = UIViewContentModeScaleAspectFill;
        [header.projectThumbnailImageView setImageWithURL:[project iconUrl]];
    } else {
        // use standard projects icon
        header.projectThumbnailImageView.backgroundColor = [UIColor colorWithHexString:@"#cccccc"];

        FAKIcon *briefcase = [FAKIonIcons iosBriefcaseOutlineIconWithSize:16.0f];
        [briefcase addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        [header.projectThumbnailImageView setImage:[briefcase imageWithSize:CGSizeMake(16, 16)]];
        header.projectThumbnailImageView.contentMode = UIViewContentModeCenter;
    }
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 55;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreProjectRealm *project = [self projectForSection:indexPath.section];
    ExploreProjectObsFieldRealm *pof = [[project sortedProjectObservationFields] objectAtIndex:indexPath.item];
   
    UIFont *fieldFont = pof.required ? [UIFont boldSystemFontOfSize:17] : [UIFont systemFontOfSize:17];
    
    if ([[pof obsField] canBeTreatedAsText] && [[[pof obsField] allowedValues] count] > 1) {
        return [self heightForSimpleProjectField:pof inTableView:tableView font:fieldFont];
    } else {
        return [self heightForLongTextProjectField:pof inTableView:tableView font:fieldFont];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    ExploreProjectRealm *project = [self projectForSection:section];
    if ([project isNewStyleProject]) {
        // don't show fields for new style projects
        return 0;
    }
    
    if ([self projectIsSelected:project]) {
        return project.projectObsFields.count;
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.joinedProjects count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ExploreProjectRealm *project = [self projectForSection:indexPath.section];
    
    if ([project isNewStyleProject]) {
        // there shouldn't be any rows for new style projects
        // bail just in case
        return;
    }
    
    ExploreProjectObsFieldRealm *pof = [[project sortedProjectObservationFields] objectAtIndex:indexPath.item];
    ExploreObsFieldValueRealm *ofv = [self.observation valueForObsField:pof.obsField];
    
    NSInteger initialSelection = 0;
    
    if (ofv) {
        // will be set to NSNotFound if it's not in the allowed values
        initialSelection = [pof.obsField.allowedValues indexOfObject:ofv.value];
    }
    
    if ([pof.obsField canBeTreatedAsText]) {
        if (pof.obsField.allowedValues.count > 1) {
            // text field, multiselect
            ProjectObsFieldViewController *pofVC = [[ProjectObsFieldViewController alloc] initWithNibName:nil bundle:nil];
            pofVC.pof = pof;
            pofVC.ofv = ofv;
            
            [self.navigationController pushViewController:pofVC animated:YES];
        } else {
            // text field, raw entry
            
            // activate the textfield
            ObsFieldLongTextValueCell *cell = (ObsFieldLongTextValueCell *)[tableView cellForRowAtIndexPath:indexPath];
            [cell.textField becomeFirstResponder];
            
            self.tapAwayGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAway:)];
            [self.tableView addGestureRecognizer:self.tapAwayGesture];
        }
    } else if (pof.obsField.dataType == ExploreObsFieldDataTypeNumeric) {
        // numeric text entry
        
        // setup a textfield above the label
        ObsFieldSimpleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.valueLabel.hidden = YES;
        
        UITextField *tf = [[UITextField alloc] initWithFrame:cell.valueLabel.frame];
        tf.keyboardType = UIKeyboardTypeDecimalPad;
        tf.textAlignment = NSTextAlignmentRight;
        tf.returnKeyType = UIReturnKeyDone;
        tf.text = cell.valueLabel.text;
        tf.delegate = self;
        [cell.contentView addSubview:tf];
        
        [tf becomeFirstResponder];
        
        self.tapAwayGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAway:)];
        [self.tableView addGestureRecognizer:self.tapAwayGesture];
    } else if (pof.obsField.dataType == ExploreObsFieldDataTypeTaxon) {
        // taxon picker
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        
        TaxaSearchViewController *search = [storyboard instantiateViewControllerWithIdentifier:@"TaxaSearchViewController"];
        search.hidesDoneButton = YES;
        search.delegate = self;
        // only prime the query if there's a placeholder, not a taxon)
        if (self.observation.speciesGuess && ! self.observation.taxon) {
            search.query = self.observation.speciesGuess;
        }
        [self.navigationController pushViewController:search animated:YES];
        
        // stash the selected index path so we know what ofv to update
        self.taxaSearchIndexPath = indexPath;
    } else if (pof.obsField.dataType == ExploreObsFieldDataTypeDate
               || pof.obsField.dataType == ExploreObsFieldDataTypeDateTime) {
        
        ObsFieldSimpleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        static NSDateFormatter *dateFormatter;
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"dd MMM yyyy HH:mm:ss ZZZ";
        }
        NSDate *date;
        if (cell.valueLabel.text && cell.valueLabel.text.length > 0) {
            date = [dateFormatter dateFromString:cell.valueLabel.text];
        }
        if (!date) {
            date = [NSDate date];
        }
        
        __weak typeof(self) weakSelf = self;
        [[[ActionSheetDatePicker alloc] initWithTitle:pof.obsField.name
                                       datePickerMode:UIDatePickerModeDateAndTime
                                         selectedDate:date
                                            doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                                NSDate *date = (NSDate *)selectedDate;
                                                cell.valueLabel.text = [dateFormatter stringFromDate:date];
                                                [weakSelf saveVisibleObservationFieldValues];
                                         } cancelBlock:nil
                                               origin:self.view] showActionSheetPicker];
        
    } else if (pof.obsField.dataType == ExploreObsFieldDataTypeTime) {
        
        ObsFieldSimpleValueCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        static NSDateFormatter *dateFormatter;
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateFormat = @"HH:mm:ss";
        }
        NSDate *date;
        if (cell.valueLabel.text && cell.valueLabel.text.length > 0) {
            date = [dateFormatter dateFromString:cell.valueLabel.text];
        }
        if (!date) {
            date = [NSDate date];
        }
        
        __weak typeof(self) weakSelf = self;
        [[[ActionSheetDatePicker alloc] initWithTitle:pof.obsField.name
                                       datePickerMode:UIDatePickerModeTime
                                         selectedDate:date
                                            doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                                NSDate *date = (NSDate *)selectedDate;
                                                cell.valueLabel.text = [dateFormatter stringFromDate:date];
                                                [weakSelf saveVisibleObservationFieldValues];
                                            } cancelBlock:nil
                                               origin:self.view] showActionSheetPicker];
        
    }
}

#pragma mark - UITableView helpers

- (CGFloat)heightForSimpleProjectField:(ExploreProjectObsFieldRealm *)pof inTableView:(UITableView *)tableView font:(UIFont *)font {
    NSDictionary *attrs = @{
                            NSFontAttributeName: font,
                            };
    
    CGFloat usableWidth = tableView.bounds.size.width * .6;
    NSString *fieldName = pof.obsField.name;
    CGRect fieldBoundingRect = [fieldName boundingRectWithSize:CGSizeMake(usableWidth, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:attrs
                                                       context:nil];
    return fieldBoundingRect.size.height + 24;
}

- (CGFloat)heightForLongTextProjectField:(ExploreProjectObsFieldRealm *)pof inTableView:(UITableView *)tableView font:(UIFont *)font {
    NSDictionary *attrs = @{
                            NSFontAttributeName: font,
                            };

    CGFloat usableWidth = tableView.bounds.size.width - 14;
    NSString *fieldName = pof.obsField.name;
    CGRect fieldBoundingRect = [fieldName boundingRectWithSize:CGSizeMake(usableWidth, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes:attrs
                                                       context:nil];
    // 44 for the value
    return fieldBoundingRect.size.height + 44;
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    ExploreProjectRealm *project = [self projectForSection:indexPath.section];
    ExploreProjectObsFieldRealm *pof = [[project sortedProjectObservationFields] objectAtIndex:indexPath.item];
    
    cell.textLabel.text = pof.obsField.name;
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
    cell.textLabel.numberOfLines = 2;
    cell.indentationLevel = 3;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
}

- (void)configureSimpleCell:(ObsFieldSimpleValueCell *)cell forProjectObsField:(ExploreProjectObsFieldRealm *)pof {
    
    cell.fieldLabel.text = pof.obsField.name;
    if (pof.required) {
        cell.fieldLabel.font = [UIFont boldSystemFontOfSize:cell.fieldLabel.font.pointSize];
    } else {
        cell.fieldLabel.font = [UIFont systemFontOfSize:cell.fieldLabel.font.pointSize];
    }
    
    ExploreObsFieldValueRealm *ofv = [self.observation valueForObsField:pof.obsField];
    if (ofv) {
        if (pof.obsField.dataType == ExploreObsFieldDataTypeTaxon) {
            ExploreTaxonRealm *taxon = [ExploreTaxonRealm objectForPrimaryKey:@(ofv.value.integerValue)];
            if (taxon) {
                cell.valueLabel.text = taxon.commonName ?: taxon.scientificName;
            } else {
                cell.valueLabel.text = (ofv.value.length == 0) ? @"unknown" : ofv.value;
            }
        } else {
            cell.valueLabel.text = ofv.value ?: pof.obsField.allowedValues.firstObject;
        }
    } else {
        // show default
        cell.valueLabel.text = pof.obsField.allowedValues.firstObject;
    }
        
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)configureLongTextCell:(ObsFieldLongTextValueCell *)cell forProjectObsField:(ExploreProjectObsFieldRealm *)pof {
    cell.fieldLabel.text = pof.obsField.name;
    
    if (pof.required) {
        cell.fieldLabel.font = [UIFont boldSystemFontOfSize:cell.fieldLabel.font.pointSize];
    } else {
        cell.fieldLabel.font = [UIFont systemFontOfSize:cell.fieldLabel.font.pointSize];
    }
    
    cell.textField.delegate = self;
    
    ExploreObsFieldValueRealm *ofv = [self.observation valueForObsField:pof.obsField];
    if (ofv) {
        cell.textField.text = ofv.value ?: ofv.obsField.allowedValues.firstObject;
    } else {
        cell.textField.text = nil;
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
}
 
- (BOOL)projectIsSelected:(ExploreProjectRealm *)project {
    for (ExploreProjectObservationRealm *po in self.observation.projectObservations) {
        if (po.project.projectId == project.projectId) {
            return YES;
        }
    }
    
    return NO;
}

- (ExploreProjectRealm *)projectForSection:(NSInteger)section {
    if (self.joinedProjects.count > 0) {
        return [self.joinedProjects objectAtIndex:section];
    } else {
        return nil;
    }
}

- (void)selectedChanged:(UISwitch *)switcher {
    NSInteger section = switcher.tag;
    ExploreProjectRealm *project = [self projectForSection:section];
    if (!project) return;
    
    NSIndexPath *sectionIp = [NSIndexPath indexPathForRow:NSNotFound inSection:section];
    
    if (switcher.isOn) {
        // have to create a ProjectObs and some OFVs for this observation
        
        // create and add project observation
        ExploreProjectObservationRealm *po = [ExploreProjectObservationRealm new];
        po.project = project;
        po.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [realm addOrUpdateObject:po];
        [self.observation.projectObservations addObject:po];
        [realm commitWriteTransaction];
        
        for (ExploreProjectObsFieldRealm *pof in project.sortedProjectObservationFields) {
            ExploreObsFieldValueRealm *ofv = [ExploreObsFieldValueRealm new];
            ofv.uuid = [[[NSUUID UUID] UUIDString] lowercaseString];
            ofv.obsField = pof.obsField;
            ofv.value = pof.obsField.allowedValues.firstObject;
            
            [realm beginWriteTransaction];
            [realm addOrUpdateObject:ofv];
            [self.observation.observationFieldValues addObject:ofv];
            [realm commitWriteTransaction];
        }
    } else {
        ExploreProjectObservationRealm *poToDelete = nil;
        for (ExploreProjectObservationRealm *po in self.observation.projectObservations) {
            if (po.project.projectId == project.projectId) {
                poToDelete = po;
            }
        }
                
        // delete the project observation
        if (poToDelete) {
            NSInteger indexOfPo = [self.observation.projectObservations indexOfObject:poToDelete];

            // delete it from the observation
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            [self.observation.projectObservations removeObjectAtIndex:indexOfPo];
            [realm commitWriteTransaction];
            
            if ([poToDelete timeSynced]) {
                [ExploreProjectObservationRealm syncedDelete:poToDelete];
            } else {
                [ExploreProjectObservationRealm deleteWithoutSync:poToDelete];
            }
        }
        
        // do the ofvs for this project's pofs
        for (ExploreProjectObsFieldRealm *pof in project.projectObsFields) {
            ExploreObsFieldValueRealm *ofvToDelete = [self.observation valueForObsField:pof.obsField];
            if (!ofvToDelete) { continue; }                 // nothing to do
            NSInteger indexOfOfv = [self.observation.observationFieldValues indexOfObject:ofvToDelete];
            if (indexOfOfv == NSNotFound) { continue; }     // nothing to do
                        
            if ([ofvToDelete timeSynced]) {
                [ExploreObsFieldValueRealm syncedDelete:ofvToDelete];
            } else {
                [ExploreObsFieldValueRealm deleteWithoutSync:ofvToDelete];
            }
        }
    }
    
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:sectionIp
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
}

- (id)currentValueForIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell isKindOfClass:[ObsFieldSimpleValueCell class]]) {
        return [[((ObsFieldSimpleValueCell *)cell) valueLabel] text];
    } else if ([cell isKindOfClass:[ObsFieldLongTextValueCell class]]) {
        return [[((ObsFieldLongTextValueCell *)cell) textField] text];
    } else {
        return nil;
    }
}

@end

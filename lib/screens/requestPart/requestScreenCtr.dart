import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/database/models/notifierModelDb.dart';
import '/database/models/requestHybridModelDb.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/managers/foodMaterialManager.dart';
import '/managers/foodProgramManager.dart';
import '/managers/userAdvancedManager.dart';
import '/managers/userNotifierManager.dart';
import '/managers/userRequestManager.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/foodModels/materialModel.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/designProgramPart/sendProgram/sendProgramsScreen.dart';
import '/screens/loginPart/loginScreen.dart';
import '/screens/requestPart/answer/answerWarningScreen.dart';
import '/screens/requestPart/requestDataShowScreen.dart';
import '/screens/requestPart/requestScreen.dart';
import '/system/keys.dart';
import '/system/queryFiltering.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/broadcastCenter.dart';
import '/tools/centers/directoriesCenter.dart';
import '/tools/centers/sheetCenter.dart';

class RequestScreenCtr implements ViewController {
  late RequestScreenState state;
  UserModel? user;
  late FilterRequest filterRequest;
  UserRequestManager? requestManager;
  UserNotifierManager? notifierManager;
  List<RequestHybridModelDb> requestList = [];
  bool pendingRequestOp = true;
  bool acceptRequestOp = true;
  bool rejectRequestOp = false;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as RequestScreenState;

    filterRequest = FilterRequest();
    Session.addLoginListener(onLogin);
    Session.addLogoffListener(onLogout);

    prepareFilterOptions();
    checkFiltering();

    if(Session.hasAnyLogin()){
      userActions(Session.getLastLoginUser()!);
    }
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    Session.removeLoginListener(onLogin);
    Session.removeLogoffListener(onLogout);
    BroadcastCenter.newNotifyNotifier.removeListener(onNewRequest);
  }

  void onLogin(UserModel user){
    userActions(user);

    state.stateController.updateMain();
  }

  void onLogout(UserModel user){
    this.user = null;
    requestManager = null;
    notifierManager = null;

    BroadcastCenter.newNotifyNotifier.removeListener(onNewRequest);

    state.stateController.updateMain();
  }

  void userActions(UserModel user){
    this.user = user;
    requestManager = UserRequestManager.managerFor(user.userId);
    notifierManager = UserNotifierManager.managerFor(user.userId);

    BroadcastCenter.newNotifyNotifier.addListener(onNewRequest);
    UserAdvancedManager.loadAllRecords();

    requestManager!.fetchTrainerRequest();
    prepareList();

    state.addPostOrCall(() {
      requestListRequest();
    });
  }

  bool filterLimit(RequestHybridModelDb req){
    final pending = filterRequest.getFilterViewFor(FilterKeys.pendingRequestOp)!.selectedValue != null;
    final accept = filterRequest.getFilterViewFor(FilterKeys.acceptedRequestOp)!.selectedValue != null;
    final reject = filterRequest.getFilterViewFor(FilterKeys.rejectedRequestOp)!.selectedValue != null;

    return (accept && req.isAccept) || (reject && req.isReject) || (pending && !req.isAccept && !req.isReject);
  }

  void prepareList(){
    requestList.clear();
    requestList.addAll(requestManager!.requestList.where((element) => filterLimit(element)).toList());
    bool asc = false;

    requestList.sort((RequestHybridModelDb p1, RequestHybridModelDb p2){
      final d1 = p1.requestDate;
      final d2 = p2.requestDate;

      if(d1 == null){
        return asc? 1: 1;
      }

      if(d2 == null){
        return asc? 1: 1;
      }

      return asc? d1.compareTo(d2) : d2.compareTo(d1);
    });

    //requestManager!.sortList(false);
  }

  void onNewRequest(){
    requestManager?.fetchTrainerRequest();
    prepareList();

    state.stateController.updateMain();
  }

  void prepareFilterOptions(){
    filterRequest.addSortView(SortKeys.registrationKey, isAsc: false,  isDefault: true);
    filterRequest.addSortView(SortKeys.registrationKey, isAsc: true);

    //filterRequest.addSearchView(SearchKeys.userNameKey);
    //filterRequest.selectedSearchKey = SearchKeys.userNameKey;

    final f1 = FilteringViewModel();
    f1.key = FilterKeys.pendingRequestOp;
    f1.type = FilterType.checkbox;
    f1.hasNotView = true;

    final f2 = FilteringViewModel();
    f2.key = FilterKeys.acceptedRequestOp;
    f2.type = FilterType.checkbox;
    f2.hasNotView = true;

    final f3 = FilteringViewModel();
    f3.key = FilterKeys.rejectedRequestOp;
    f3.type = FilterType.checkbox;
    f3.hasNotView = true;

    filterRequest.addFilterView(f1);
    filterRequest.addFilterView(f2);
    filterRequest.addFilterView(f3);
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is RequestScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
      requestListRequest();
    }
  }

  void tryLogin(State state){
    if(state is RequestScreenState) {
      AppNavigator.pushNextPage(state.context, LoginScreen(), name: LoginScreen.screenName);
    }
  }

  void gotoAnswerPage(RequestHybridModelDb model){
    AppNavigator.pushNextPage(state.context,
        AnswerWarningScreen(courseRequestModel: model,),
        name: AnswerWarningScreen.screenName
    ).then((value){
        state.stateController.updateMain();
    });
  }

  void gotoSendProgramPage(RequestHybridModelDb model) async {
    state.showLoading();

    final res = await requestManager?.requestRequestExtraInfo(model, true);
    await state.hideLoading();

    if(res != null){
      final pupilData = res[Keys.userData];
      final questions = res['questions_data'];
      final programs = res['programs_data']?? <Map>[];
      final materials = res['material_data']?? <Map>[];
      final domain = res[Keys.domain];

      final pupil = UserAdvancedModelDb.fromMap(pupilData, domain: domain);
      final q = CourseQuestionModel.fromMap(questions['questions_js'], domain: domain);

      for (final element in q.experimentPhotos) {element.genPath(DirectoriesCenter.getCourseDir$ex());}
      for (final element in q.bodyPhotos) {element.genPath(DirectoriesCenter.getCourseDir$ex());}
      for (final element in q.bodyAnalysisPhotos) {element.genPath(DirectoriesCenter.getCourseDir$ex());}

      if(q.cardPhoto != null){
        q.cardPhoto!.genPath(DirectoriesCenter.getCourseDir$ex());
      }

      UserAdvancedManager.addItem(pupil);
      UserAdvancedManager.sinkItems([pupil]);

      for(final m in materials){
        final mat = MaterialModel.fromMap(m);
        FoodMaterialManager.addItem(mat);
        FoodMaterialManager.sinkItems([mat]);
      }

      final pManager = FoodProgramManager.managerFor(user!.userId);

      for(final p in programs){
        final pro = FoodProgramModel.fromMap(p);
        pManager.addItem(pro);
        pManager.sinkItems([pro]);
      }

      // ignore: unawaited_futures
      AppNavigator.pushNextPage(
          state.context,
          SendProgramsScreen(
            pupilUser: pupil,
            requestModel: model,
            questionModel: q,
          ),
          name: SendProgramsScreen.screenName
      );
    }
    else {
      SheetCenter.showSheet$OperationFailed(state.context);
    }
  }

  void resetRequest(){
    requestManager?.requestList.clear();
    //pullLoadCtr.resetNoData();

    requestListRequest();
  }

  void checkFiltering(){
    final f1 = filterRequest.getFilterViewFor(FilterKeys.pendingRequestOp);
    final f2 = filterRequest.getFilterViewFor(FilterKeys.acceptedRequestOp);
    final f3 = filterRequest.getFilterViewFor(FilterKeys.rejectedRequestOp);
    f1?.selectedValue = null;
    f2?.selectedValue = null;
    f3?.selectedValue = null;

    if(pendingRequestOp){
      f1?.selectedValue = FilterKeys.pendingRequestOp;
      //isSelectedOnce = true;
    }

    if(acceptRequestOp){
      f2?.selectedValue = FilterKeys.acceptedRequestOp;
      //isSelectedOnce = true;
    }

    if(rejectRequestOp){
      f3?.selectedValue = FilterKeys.rejectedRequestOp;
      //isSelectedOnce = true;
    }

    /*if(!isSelectedOnce){
      f2?.selectedValue = FilterKeys.acceptedRequestOp;
    }*/
  }

  void requestListRequest() async {
    FocusHelper.hideKeyboardByService();

    checkFiltering();
    final res = await requestManager?.requestTrainerRequest(filterRequest);

    if(res != null && res){
      prepareList();
      //requestManager!.sortList(false);
    }

    state.stateController.mainStateAndUpdate(StateXController.state$normal);

    await notifierManager!.seenAndSaveNotifiers(NotifiersBatch.courseRequest);
    BroadcastCenter.prepareBadgesAndRefresh();
    notifierManager!.requestSyncSeen();
  }

  void requestCourseInfo(RequestHybridModelDb model) async {
    state.showLoading();

    final res = await requestManager?.requestRequestExtraInfo(model, false);
    await state.hideLoading();

    if(res != null){
      final pupilData = res[Keys.userData];
      final questions = res['questions_data'];
      final domain = res[Keys.domain];

      final pupil = UserAdvancedModelDb.fromMap(pupilData, domain: domain);
      final q = CourseQuestionModel.fromMap(questions['questions_js'], domain: domain);

      for (final element in q.experimentPhotos) {element.genPath(DirectoriesCenter.getCourseDir$ex());}
      for (final element in q.bodyPhotos) {element.genPath(DirectoriesCenter.getCourseDir$ex());}
      for (final element in q.bodyAnalysisPhotos) {element.genPath(DirectoriesCenter.getCourseDir$ex());}

      if(q.cardPhoto != null){
        q.cardPhoto!.genPath(DirectoriesCenter.getCourseDir$ex());
      }

      UserAdvancedManager.addItem(pupil);
      UserAdvancedManager.sinkItems([pupil]);

      // ignore: unawaited_futures
      AppNavigator.pushNextPage(
          state.context,
          RequestDataShowScreen(
            courseRequestModel: model,
            userInfo: pupil,
            questionInfo: q,
          ),
          name: RequestDataShowScreen.screenName
      );
    }
    else {
      SheetCenter.showSheet$OperationFailed(state.context);
    }
  }

}

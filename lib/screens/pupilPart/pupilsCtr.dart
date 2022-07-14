import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart' as pull;

import '/abstracts/viewController.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/pupilPart/ListBuilderPupils.dart';
import '/screens/pupilPart/pupilsScreen.dart';
import '/system/keys.dart';
import '/system/multiViewDialog.dart';
import '/system/queryFiltering.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/views/filterViews/filterPanelView.dart';
import '/views/filterViews/searchPanelView.dart';
import '/views/filterViews/sortPanelView.dart';

class UserListCtr implements ViewController {
  late UserListScreenState state;
  Requester? commonRequester;
  late UserModel user;
  late TextEditingController searchEditController;
  late FilterRequest filterRequest;
  final listChildren = <ListBuilderPupilsState>[];
  List<UserAdvancedModelDb> userList = [];
  //late StreamSubscription downloadListenerSubscription;
  var pullLoadCtr = pull.RefreshController();
  bool notActivePupil = false;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as UserListScreenState;

    state.stateController.mainState = StateXController.state$loading;
    filterRequest = FilterRequest();

    commonRequester = Requester();
    commonRequester!.requestPath = RequestPath.GetData;

    searchEditController = TextEditingController();
    //downloadListenerSubscription = DownloadUpload.downloadManager.addListener(onDownloadListener);

    Session.addLoginListener(onLogin);
    Session.addLogoffListener(onLogout);

    if(Session.hasAnyLogin()){
      user = Session.getLastLoginUser()!;
    }

    prepareFilterOptions();

    state.addPostOrCall((){
      requestUsers();
    });
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester?.httpRequester);
    Session.removeLoginListener(onLogin);
    Session.removeLogoffListener(onLogout);
  }

  void onLogin(user){
    this.user = user;

    state.stateController.updateMain();
  }

  void onLogout(user){
    HttpCenter.cancelAndClose(commonRequester?.httpRequester);
    state.stateController.updateMain();
  }

  /*void onDownloadListener(DownloadItem di) {
    if(di.isInCategory(DownloadCategory.userProfile.toString())){
      if(!di.isComplete()){
        return;
      }

      ServerUserModel model = di.attach;
      var f = FileHelper.getFile(model.profileImagePath!);
      model.profileFile = f;

      for(var v in listChildren){
        if(v.widget.model.userId.toString() == di.subCategory){

          v.update();
          break;
        }
      }
    }
  }*/

  void prepareFilterOptions(){
    filterRequest.addSortView(SortKeys.ageKey, isAsc: false,  isDefault: true);
    filterRequest.addSortView(SortKeys.ageKey, isAsc: true);

    filterRequest.addSearchView(SearchKeys.userNameKey);
    filterRequest.addSearchView(SearchKeys.family);
    filterRequest.addSearchView(SearchKeys.mobile);
    filterRequest.selectedSearchKey = SearchKeys.userNameKey;

    final f1 = FilteringViewModel();
    f1.key = FilterKeys.byGender;
    f1.type = FilterType.radio;
    f1.subViews.add(FilterSubViewModel()..key = FilterKeys.maleOp);
    f1.subViews.add(FilterSubViewModel()..key = FilterKeys.femaleOp);

    final f2 = FilteringViewModel();
    f2.hasNotView = true;
    f2.key = FilterKeys.byInActivePupilMode;
    f2.type = FilterType.checkbox;

    filterRequest.addFilterView(f1);
    filterRequest.addFilterView(f2);
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is UserListScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void onSortClick(){
    var oldItem = filterRequest.getSortViewSelected();

    MultiViewDialog fd = MultiViewDialog(
      SortPanelView(filterRequest),
      'Sort',
      screenBackground: Colors.black.withAlpha(100),
      useExpanded: false,
    );

    fd.showWithCloseButton(
      state.context,
      canBack: true,
      alignment: Alignment.topCenter,
      padding: EdgeInsets.fromLTRB(0, 50, 0, 10),
    ).then((value) {
      if(oldItem != filterRequest.getSortViewSelected()) {
        resetRequest();
      }
    });
  }

  void onSearchOptionClick(){
    MultiViewDialog fd = MultiViewDialog(
        SearchPanelView(filterRequest),
        'SearchBy',
        screenBackground: Colors.black.withAlpha(100)
    );

    fd.showWithCloseButton(
      state.context,
      canBack: true,
      alignment: Alignment.topCenter,
      padding: EdgeInsets.fromLTRB(0, 50, 0, 10),
    ).then((value) {
      state.appBarRefresher.update();
    });
  }

  void onFilterOptionClick(){
    final oldValue = filterRequest.toMapFiltering();

    MultiViewDialog fd = MultiViewDialog(
      FilterPanelView(filterRequest),
      'FilterBy',
      screenBackground: Colors.black.withAlpha(100),
      useExpanded: true,
    );

    fd.showWithCloseButton(
      state.context,
      canBack: true,
      alignment: Alignment.topCenter,
      padding: EdgeInsets.fromLTRB(0, 50, 0, 10),
    ).then((value) {
      state.appBarRefresher.update();

      if(!DeepCollectionEquality.unordered().equals(oldValue, filterRequest.toMapFiltering())) {
        resetRequest();
      }
    });
  }

  void onRefresh() async{
    userList.clear();

    requestUsers();
  }

  Future<void> onLoadMore() async{
    requestUsers();
    return Future.value();
  }

  void resetRequest(){
    userList.clear();
    pullLoadCtr.resetNoData();

    requestUsers();
  }

  String? findLastCaseTs() {
    if(userList.isEmpty){
      return null;
    }

    String? res;
    final compTs = userList.first.answerDateTs!;
    final comp = DateHelper.tsToSystemDate(compTs)!;

    for (final element in userList) {
      if(filterRequest.getSortViewSelectedForce().isASC){
        final w = DateHelper.tsToSystemDate(element.answerDateTs)!;

        if (w.compareTo(comp) > 0) {
          res = element.answerDateTs;
        }
      }
      else {
        final w = DateHelper.tsToSystemDate(element.answerDateTs)!;

        if (w.compareTo(comp) < 0) {
          res = element.answerDateTs;
        }
      }
    }

    return res;
  }

  void requestUsers() {
    FocusHelper.hideKeyboardByUnFocus(state.context);

    filterRequest.lastCase = findLastCaseTs();

    // condition: answer_date is NOT NULL AND (answer_js->'accept')::bool = true
    final js = <String, dynamic>{};
    js[Keys.request] = 'GetTrainerPupilUsers';
    js[Keys.userId] = user.userId;
    js[Keys.filtering] = filterRequest.toMap();

    commonRequester?.bodyJson = js;

    commonRequester?.httpRequestEvents.onFailState = (req) async {
      if(pullLoadCtr.isRefresh) {
        pullLoadCtr.refreshFailed();
      }
      else {
        pullLoadCtr.loadFailed();
      }

      state.stateController.mainStateAndUpdate(StateXController.state$normal);
      SnackCenter.showSnack$serverNotRespondProperly(state.context);
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      List? itemList = data[Keys.resultList];
      var domain = data[Keys.domain];

      if(pullLoadCtr.isRefresh){
        userList.clear();
        pullLoadCtr.refreshToIdle();
      }

      if(itemList != null) {
        if (itemList.length < filterRequest.limit) {
          pullLoadCtr.loadNoData();
        }
        else {
          pullLoadCtr.loadComplete();
        }

        for (var row in itemList) {
          var r = UserAdvancedModelDb.fromMap(row, domain: domain);
          userList.add(r);
        }
      }

      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    };

    commonRequester?.request(state.context);
  }
}

import 'package:brandfit_trainer/screens/pupilPart/pupilProgramsViewPart/programViewScreen.dart';
import 'package:brandfit_trainer/tools/app/appNavigator.dart';
import 'package:flutter/material.dart';

import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/database/models/requestHybridModelDb.dart';
import '/managers/userRequestManager.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/pupilPart/requestsViewPart/requestsScreen.dart';
import '/system/queryFiltering.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/centers/httpCenter.dart';

class ProgramsCtr implements ViewController {
  late RequestsScreenState state;
  late Requester commonRequester;
  late UserModel user;
  late FilterRequest filterRequest;
  late UserRequestManager requestManager;
  List<RequestHybridModelDb> requestList = [];

  @override
  void onInitState<E extends State>(E state){
    this.state = state as RequestsScreenState;

    filterRequest = FilterRequest();
    commonRequester = Requester();
    user = Session.getLastLoginUser()!;

    requestManager = UserRequestManager.managerFor(user.userId);
    requestList = requestManager.requestList.where((element) => element.isAccept).toList();

    prepareFilterOptions();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }

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
    if(state is RequestsScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void gotoPupilOperation(RequestHybridModelDb request){
    AppNavigator.pushNextPage(
        state.context,
        ProgramViewScreen(requestHybModel: request),
        name: ProgramViewScreen.screenName
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/managers/courseManager.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/coursePart/courseScreen.dart';
import '/screens/coursePart/fullInfoScreen/courseFullInfoScreen.dart';
import '/screens/loginPart/loginScreen.dart';
import '/screens/profile/paymentPart/paymentsScreen.dart';
import '/system/icons.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import 'addCoursePart/addCourseScreen.dart';

class CourseScreenCtr implements ViewController {
  late CourseScreenState state;
  late Requester commonRequester;
  UserModel? user;
  late CourseManager courseManager;


  @override
  void onInitState<E extends State>(E state){
    this.state = state as CourseScreenState;

    Session.addLoginListener(onLogin);
    Session.addLogoffListener(onLogout);

    commonRequester = Requester();

    if(Session.hasAnyLogin()){
      user = Session.getLastLoginUser()!;
      courseManager = CourseManager.managerFor(user!.userId);

      if(!courseManager.isUpdated() || courseManager.courseList.isEmpty) {
        state.stateController.mainState = StateXController.state$loading;
        requestCourses();
      }
    }
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
    Session.removeLoginListener(onLogin);
    Session.removeLogoffListener(onLogout);
  }

  void onLogin(user){
    this.user = user;
    courseManager = CourseManager.managerFor(user);

    if(!courseManager.isUpdated() || courseManager.courseList.isEmpty) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
      requestCourses();
    }
  }

  void onLogout(user){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
    this.user = null;

    state.stateController.mainStateAndUpdate(StateXController.state$normal);
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is CourseScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);

      requestCourses();
    }
  }

  void tryLogin(State state){
    if(state is CourseScreenState) {
      AppNavigator.pushNextPage(state.context, LoginScreen(), name: LoginScreen.screenName);
    }
  }

  void addNewCourseClick() async {
    if(user!.bankCardModel == null){
      final canContinue = await requestHasBankCard();

      if(canContinue == null){
        SheetCenter.showSheet$ServerNotRespondProperly(state.context);
        return;
      }
      else if(!canContinue){

        DialogCenter.instance.showYesNoDialog(
            state.context,
          desc: '${state.tInMap('coursePage', 'youMustAddCard')}',
          yesText: '${state.tInMap('coursePage', 'addCard')}',
          noText: '${state.t('cancel')}',
          yesFn: (){
              AppNavigator.pushNextPage(
                  state.context,
                  PaymentsScreen(),
                  name: PaymentsScreen.screenName
              );
          },
        );
        return;
      }
    }

    AppNavigator.pushNextPage(
        state.context,
        AddCourseScreen(),
        name: AddCourseScreen.screenName
    ).then((value){
          state.stateController.mainStateAndUpdate(StateXController.state$loading);
          requestCourses();
    });
  }

  void showEditScreen(CourseModel cm) {
    AppNavigator.pushNextPage(
        state.context,
        AddCourseScreen(courseModel: cm,),
        name: AddCourseScreen.screenName,
    ).then((value) {
      state.stateController.updateMain();
    });
  }

  void gotoFullScreen(CourseModel cm) {
    AppNavigator.pushNextPage(
        state.context,
        CourseFullInfoScreen(courseModel: cm,),
        name: CourseFullInfoScreen.screenName,
    ).then((value) {
      state.stateController.updateMain();
    });
  }

  void showItemMenu(CourseModel cm){
    final wList = <Map>[];

    wList.add({
      'title': '${state.t('edit')}',
      'icon': IconList.pencil,
      'fn': (){showEditScreen(cm);}}
    );

    wList.add({
      'title': '${state.t('delete')}',
      'icon': IconList.delete,
      'fn': (){
        yesFn(){
          AppNavigator.pop(state.context);
          //deleteCourse(cm);
        }

        DialogCenter().showYesNoDialog(state.context,
            yesFn: yesFn,
            desc: state.t('wantToDeleteThisItem'));
      }
    });


    Widget genView(elm){
      return ListTile(
        title: Text(elm['title']),
        leading: Icon(elm['icon']),
        onTap: (){
          SheetCenter.closeSheetByName(state.context, 'EditMenu');
          elm['fn']?.call();
        },
      );
    }

    SheetCenter.showSheetMenu(
        state.context,
        wList.map(genView).toList(),
        'EditMenu',
    );
  }

  Future<bool?> requestHasBankCard() async {
    FocusHelper.hideKeyboardByService();
    final res = Completer<bool?>();

    final js = <String, dynamic>{};
    js[Keys.request] = 'UserHasBankCard';
    js[Keys.forUserId] = user?.userId;

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.GetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      res.complete(null);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      final result = data[Keys.data];
      res.complete(result);
    };

    commonRequester.request(state.context);
    state.showLoading();

    return res.future;
  }

  void requestCourses() async {
    FocusHelper.hideKeyboardByService();
    //FocusHelper.hideKeyboardByUnFocus(state.context);

    Map<String, dynamic> js = {};
    js[Keys.request] = 'GetCursesForTrainer';
    js[Keys.requesterId] = user?.userId;
    js[Keys.forUserId] = user?.userId;

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.GetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      //AppManager.timeoutCache.deleteTimeout('GetCurses');
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      state.stateController.mainStateAndUpdate(StateXController.state$serverNotResponse);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      //state.stateController.mainStateAndUpdate(StateXController.state$serverNotResponse);
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      var list = data[Keys.resultList];

      if(list != null){
        for(var i in list){
          var c = CourseModel.fromMap(i);
          courseManager.addItem(c);
        }

        courseManager.sortList(false);
        courseManager.setUpdate();
      }

      state.stateController.mainStateAndUpdate(StateXController.state$normal);
    };

    commonRequester.request(state.context);
  }
}

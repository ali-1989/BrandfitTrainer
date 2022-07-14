import 'dart:io';

import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';

import '/abstracts/viewController.dart';
import '/managers/courseManager.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/commons/imageFullScreen.dart';
import '/screens/coursePart/addCoursePart/addCourseScreen.dart';
import '/screens/coursePart/fullInfoScreen/courseFullInfoScreen.dart';
import '/system/enums.dart';
import '/system/httpCodes.dart';
import '/system/icons.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';

class CourseFullInfoCtr implements ViewController {
  late CourseFullInfoScreenState state;
  late UserModel user;
  late CourseModel courseModel;
  late Requester commonRequester;
  late CourseManager courseManager;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as CourseFullInfoScreenState;

    commonRequester = Requester();
    user = Session.getLastLoginUser()!;
    courseModel = state.widget.courseModel;
    courseManager = CourseManager.managerFor(user.userId);
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }
  ///========================================================================================================
  void tryAgain(State state){
  }

  void showFullScreenImage(){
    if(courseModel.imageUri == null){
      return;
    }

    final view = ImageFullScreen(
      imageType: ImageType.File,
      heroTag: 'h${courseModel.id}',
      imageObj: File(courseModel.imagePath!),
    );

    AppNavigator.pushNextPageExtra(state.context, view, name: ImageFullScreen.screenName);
  }

  void showEditSheet(){
    final wList = <Map>[];

    wList.add({
      'title': '${state.t('edit')}',
      'icon': IconList.pencil,
      'fn': (){showEditScreen(courseModel);}}
    );

    wList.add({
      'title': '${state.t('delete')}',
      'icon': IconList.delete,
      'fn': (){
        yesFn(){
          AppNavigator.pop(state.context);
          deleteCourse(courseModel);
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

    //final sheet = SheetCenter.generateCloseSheet(state.context, v, 'EditUser', backColor: Colors.white);
    //SheetCenter.showModalSheet(state.context, (_)=> sheet, routeName: 'EditUser');
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

  void deleteCourse(CourseModel cm) {
    requestDeleteCourse(cm.id);
  }

  void requestDeleteCourse(int courseId) async {
    FocusHelper.hideKeyboardByUnFocus(state.context);

    final js = <String, dynamic>{};
    js[Keys.request] = 'DeleteCourse';
    js[Keys.requesterId] = user.userId;
    js['course_id'] = courseId;

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.SetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onNetworkError = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester.httpRequestEvents.onResponseError = (req, isOk) async {
      if(isOk){
        SnackCenter.showSnack$errorInServerSide(state.context);
      } else {
        SnackCenter.showSnack$serverNotRespondProperly(state.context);
      }
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      //final cause = data[Keys.cause];
      final causeCode = data[Keys.causeCode];

      if(causeCode == HttpCodes.error_operationCannotBePerformed){
        SheetCenter.showSheet$OperationCannotBePerformed(state.context);
        return true;
      }

      return false;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      courseManager.removeItem(courseId, true);
      AppNavigator.pop(state.context);
    };

    state.showLoading();
    commonRequester.request(state.context);
  }
}

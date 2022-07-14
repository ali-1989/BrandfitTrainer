import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '/abstracts/viewController.dart';
import '/database/models/requestHybridModelDb.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/managers/foodMaterialManager.dart';
import '/managers/foodProgramManager.dart';
import '/managers/userRequestManager.dart';
import '/models/dataModels/foodModels/materialModel.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/pupilPart/requestsViewPart/requestsScreen.dart';
import '/screens/pupilPart/ListBuilderPupils.dart';
import '/screens/pupilPart/statusViewPart/statusScreen.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/snackCenter.dart';

class ListBuilderPupilsCtr implements ViewController {
  late ListBuilderPupilsState state;
  late Requester commonRequester;
  late UserAdvancedModelDb pupilModel;
  late UserModel user;


  @override
  void onInitState<E extends State>(E state){
    this.state = state as ListBuilderPupilsState;

    commonRequester = Requester();
    
    state.widget.stateList.add(state);
    pupilModel = state.widget.pupilModel;
    user = state.widget.user;
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    state.widget.stateList.remove(state);
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }
  ///========================================================================================================
  void gotoChartPage(UserModel pupil){
    AppNavigator.pushNextPage(
        state.context,
        StatusScreen(userModel: pupil,),
        name: StatusScreen.screenName
    );
  }

  Future gotoProgramsPage(UserModel pupil) async {
    // condition: answer_date IS NOT NULL AND (answer_js->'accept')
    final js = <String, dynamic>{};
    js[Keys.request] = 'GetPupilRequestsAndProgramsForTrainer';
    js[Keys.requesterId] = user.userId;
    js[Keys.forUserId] = user.userId;
    js['pupil_id'] = pupilModel.userId;

    commonRequester.requestPath = RequestPath.GetData;
    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onNetworkError = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester.httpRequestEvents.onResponseError = (req, isOk) async {
      SnackCenter.showSnack$errorInServerSide(state.context);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return false;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      final List? requestList = data['request_list'];
      final programList = data['program_list'];
      final materialList = data['material_list'];
      final domain = js[Keys.domain];

      final requestManager = UserRequestManager.managerFor(user.userId);

      if(requestList != null) {
        for(final m in requestList){
          final cr = RequestHybridModelDb.fromMap(m, domain: domain);
          cr.sink();

          requestManager.addItem(cr);
        }
      }

      for(final m in materialList){
        final mat = MaterialModel.fromMap(m);
        FoodMaterialManager.addItem(mat);
        FoodMaterialManager.sinkItems([mat]);
      }

      final pManager = FoodProgramManager.managerFor(user.userId);

      for(final p in programList){
        final pro = FoodProgramModel.fromMap(p);
        pManager.addItem(pro);
        pManager.sinkItems([pro]);
      }

      AppNavigator.pushNextPage(
          state.context,
          RequestsScreen(pupilModel: pupil,),
          name: RequestsScreen.screenName
      );
    };

    state.showLoading();
    commonRequester.request(state.context);
  }
}

import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/modules/stateManagers/selfRefresh.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/database/models/requestHybridModelDb.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/managers/foodProgramManager.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/programModels/IProgramModel.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/designProgramPart/planScreen/planChartScreen.dart';
import '/screens/designProgramPart/sendProgram/sendProgramsScreen.dart';
import '/screens/designProgramPart/treeScreen/treeScreen.dart';
import '/system/extensions.dart';
import '/system/httpCodes.dart';
import '/system/icons.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';
import '/tools/dateTools.dart';
import '/views/dateViews/selectDateCalendarView.dart';

class SendProgramsScreenCtr implements ViewController {
  late SendProgramsScreenState state;
  Requester? commonRequester;
  late UserModel user;
  late UserAdvancedModelDb pupilUser;
  late RequestHybridModelDb requestModel;
  late CourseQuestionModel questionModel;
  late FoodProgramManager programManager;
  List<IProgramModel> programs = [];


  @override
  void onInitState<E extends State>(E state){
    this.state = state as SendProgramsScreenState;

    user = Session.getLastLoginUser()!;
    requestModel = state.widget.requestModel;
    questionModel = state.widget.questionModel;
    pupilUser = state.widget.pupilUser;

    programManager = FoodProgramManager.managerFor(user.userId);
    programs = programManager.getForRequestId(requestModel.id);

    sortList();

    commonRequester = Requester();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester?.httpRequester);
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is SendProgramsScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void sortList(){
    programs.sort((e1, e2){
      return DateHelper.compareDates(e1.registerDate, e2.registerDate, asc: false);
    });
  }

  Future onPressForSelectDate(FoodProgramModel model) async {
    final content = SelectDateCalendarView(
      currentDate: model.cronDate,
      onChange: (dt){
        final tStyle = TextStyle(color: Colors.black);

        if(dt.compareTo(DateTime.now()) < 1){
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${state.tInMap('sendProgramPage', 'invalid')}', style: tStyle.copyWith(color: Colors.red),),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${dt.difference(DateTime.now()).inDays +1} ${state.tInMap('sendProgramPage', 'day')}', style: tStyle,),
        );
      },
    );

    final res = await SheetCenter.showSheetCustom(
        state.context,
        content,
        routeName: 'SelectDate'
    );

    if(res is DateTime) {
      if (res.compareTo(DateTime.now()) > 0) {
        model.cronDate = res;
      }
    }
  }

  Future<String?> showAddNewProgramDialog(FoodProgramModel model) async {
    final dialogName = 'newProgramDialog';
    final nameCtr = TextEditingController(text: model.title);
    var showError = false;

    final content = SelfRefresh(
        builder: (context, ctr) {
          String btnText;

          if(model.cronDate == null){
            btnText = state.t('select')!;
          }
          else {
            btnText = DateTools.dateOnlyRelative(model.cronDate);
          }

          return Align(
            child: FractionallySizedBox(
              widthFactor: 0.88,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26.0, 16, 26.0, 26.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${state.tInMap('sendProgramPage', 'createNewProgram')}')
                          .boldFont().fsR(2),

                      SizedBox(height: 16,),
                      TextField(
                        controller: nameCtr,
                        onChanged: (s){
                          if(s.isNotEmpty && showError){
                            showError = false;
                            ctr.update();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: state.tInMap('sendProgramPage', 'programName'),
                        ),
                      ),

                      SizedBox(height: 5,),
                      Visibility(
                          visible: showError,
                          child: Text('${state.tInMap('sendProgramPage', 'enterTitle')}')
                              .color(AppThemes.currentTheme.errorColor)
                      ),

                      /// date section
                      SizedBox(height: 16,),
                      Row(
                        children: [
                          Text('${state.tInMap('sendProgramPage', 'sendDateOpt')}: '),
                          SizedBox(width: 5,),

                          Expanded(
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await onPressForSelectDate(model);
                                      ctr.update();
                                    },
                                    child: Text(btnText),
                                  ),

                                  Visibility(
                                    visible: model.cronDate != null,
                                    child: IconButton(
                                        onPressed: (){
                                          model.cronDate = null;
                                          ctr.update();
                                        },
                                        icon: Icon(IconList.delete)
                                    ),
                                  ),
                                ],
                              ),
                          ),
                        ],
                      ),

                      /// buttons
                      SizedBox(height: 30,),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (){
                                if(nameCtr.text.trim().isEmpty){
                                  showError = true;
                                  ctr.update();
                                  return;
                                }

                                model.title = nameCtr.text.trim();
                                OverlayDialog().hideByPop(state.context, data: 'save');
                              },
                              child: Text('${state.t('save')}'),
                            ),
                          ),

                          SizedBox(width: 12,),

                          Expanded(
                            child: TextButton(
                              onPressed: (){
                                OverlayDialog().hideByPop(state.context);
                              },
                              child: Text('${state.t('back')}'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );

    final dialog = OverlayScreenView(content: content,
      routingName: dialogName,
      backgroundColor: Colors.black54,
    );

    return await OverlayDialog().show(state.context, dialog, canBack: true);
  }

  void addNewProgram() async {
    final program = FoodProgramModel();
    program.trainerId = user.userId;
    program.requestId = state.widget.requestModel.id;

    final res = await showAddNewProgramDialog(program);

    if(res!= null) {
      requestAddProgram(program);
    }
  }

  void editProgram(FoodProgramModel program) async {
    final res = await showAddNewProgramDialog(program);

    if(res!= null) {
      requestEditProgram(program);
    }
  }

  void showDeleteProgramDialog(FoodProgramModel p){
    final desc = state.tC('wantToDeleteThisItem')!;

    void yesFn(){
      requestDeleteProgram(p);
    }

    DialogCenter().showYesNoDialog(state.context, desc: desc, yesFn: yesFn,);
  }

  void repeatProgram(FoodProgramModel program){
    if(program.isEmpty()){
      SheetCenter.showSheetNotice(state.context, state.tInMap('sendProgramPage', 'designProgramFirstForRepeat')!);
      return;
    }

    showRepeatPrompt(program);
  }

  void showRepeatPrompt(FoodProgramModel oldProgram) async {
    final program = FoodProgramModel();
    program.trainerId = user.userId;
    program.requestId = state.widget.requestModel.id;

    final res = await showRepeatProgramDialog(program, oldProgram);

    if(res == 'repeat') {
      program.pcl = oldProgram.pcl;
      program.updateDaysBy(oldProgram.daysToMap());
      requestRepeatProgram(program, oldProgram);
    }
  }

  Future<String?> showRepeatProgramDialog(FoodProgramModel model, FoodProgramModel oldProgram) async {
    final dialogName = 'repeatProgramDialog';
    final nameCtr = TextEditingController(text: oldProgram.title);
    var showError = false;

    final content = SelfRefresh(
        builder: (context, ctr) {
          String btnText;

          if(model.cronDate == null){
            btnText = state.t('select')!;
          }
          else {
            btnText = DateTools.dateOnlyRelative(model.cronDate);
          }

          return Align(
            child: FractionallySizedBox(
              widthFactor: 0.88,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26.0, 16, 26.0, 26.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${state.tInMap('sendProgramPage', 'repeatProgram')}')
                          .boldFont().fsR(2),

                      SizedBox(height: 16,),
                      TextField(
                        controller: nameCtr,
                        onChanged: (s){
                          if(s.isNotEmpty && showError){
                            showError = false;
                            ctr.update();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: state.tInMap('sendProgramPage', 'programName'),
                        ),
                      ),

                      SizedBox(height: 5,),
                      Visibility(
                          visible: showError,
                          child: Text('${state.tInMap('sendProgramPage', 'enterTitle')}')
                              .color(AppThemes.currentTheme.errorColor)
                      ),

                      /// date section
                      SizedBox(height: 16,),
                      Row(
                        children: [
                          Text('${state.tInMap('sendProgramPage', 'sendDateOpt')}: '),
                          SizedBox(width: 5,),

                          Expanded(
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await onPressForSelectDate(model);
                                    ctr.update();
                                  },
                                  child: Text(btnText),
                                ),

                                Visibility(
                                  visible: model.cronDate != null,
                                  child: IconButton(
                                      onPressed: (){
                                        model.cronDate = null;
                                        ctr.update();
                                      },
                                      icon: Icon(IconList.delete)
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      /// buttons
                      SizedBox(height: 30,),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (){
                                if(nameCtr.text.trim().isEmpty){
                                  showError = true;
                                  ctr.update();
                                  return;
                                }

                                model.title = nameCtr.text.trim();
                                OverlayDialog().hideByPop(state.context, data: 'repeat');
                              },
                              child: Text('${state.t('repeat')}'),
                            ),
                          ),

                          SizedBox(width: 12,),

                          Expanded(
                            child: TextButton(
                              onPressed: (){
                                OverlayDialog().hideByPop(state.context);
                              },
                              child: Text('${state.t('cancel')}'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }
    );


    final dialog = OverlayScreenView(content: content,
      routingName: dialogName,
      backgroundColor: Colors.black54,
    );

    return await OverlayDialog().show(state.context, dialog, canBack: true);
  }

  void gotoDesign(FoodProgramModel p){
    if(!p.isSetPcl()){
      AppNavigator.pushNextPage(
          state.context,
          PlanChartScreen(
            courseRequestModel: requestModel,
            pupilUser: pupilUser,
            questionModel: questionModel,
            programModel: p,
          ),
          name: PlanChartScreen.screenName
      );
    }
    else {
      AppNavigator.pushNextPage(
          state.context,
          TreeFoodProgramScreen(
            courseRequestModel: state.widget.requestModel,
            pupilUser: state.widget.pupilUser,
            questionModel: state.widget.questionModel,
            programModel: p,
          ),
          name: TreeFoodProgramScreen.screenName
      ).then((value) {
        state.stateController.updateMain();
      });
    }
  }

  void requestAddProgram(FoodProgramModel program){
    FocusHelper.hideKeyboardByUnFocus(state.context);

    final js = <String, dynamic>{};
    js[Keys.request] = 'AddFoodProgram';
    js[Keys.userId] = user.userId;
    js['program_data'] = program.toMap(withDays:false);

    commonRequester?.bodyJson = js;
    commonRequester?.requestPath = RequestPath.SetData;

    commonRequester?.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester?.httpRequestEvents.onFailState = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      program.id = data['program_id'];
      program.registerDate = DateHelper.tsToSystemDate(data['register_date']);

      programs.add(program);
      programManager.sinkItems([program]);

      sortList();
      state.stateController.updateMain();

      /*
      if(res == 'design'){
      AppNavigator.pushNextPage(state.context,
          PlanChartScreen(
            courseRequestModel: courseRequestModel,
            pupilUser: pupilUser,
            questionModel: questionModel,
            programModel: program,
          ),
          name: PlanChartScreen.screenName
      );
    } */
    };

    state.showLoading();
    commonRequester?.request(state.context);
  }

  void requestEditProgram(FoodProgramModel program){
    FocusHelper.hideKeyboardByUnFocus(state.context);

    final js = <String, dynamic>{};
    js[Keys.request] = 'EditFoodProgram';
    js[Keys.userId] = user.userId;
    js['program_id'] = program.id;
    js['program_data'] = program.toMap(withDays:false);

    commonRequester?.bodyJson = js;
    commonRequester?.requestPath = RequestPath.SetData;

    commonRequester?.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester?.httpRequestEvents.onNetworkError = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResponseError = (req, isOk) async {
      if(isOk){
        SnackCenter.showSnack$errorInServerSide(state.context);
      } else {
        SnackCenter.showSnack$serverNotRespondProperly(state.context);
      }
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      SnackCenter.showSnack$errorInServerSide(state.context);

      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      state.stateController.updateMain();
    };

    state.showLoading();
    commonRequester?.request(state.context);
  }

  void requestDeleteProgram(FoodProgramModel program){
    FocusHelper.hideKeyboardByUnFocus(state.context);

    final js = <String, dynamic>{};
    js[Keys.request] = 'DeleteFoodProgram';
    js[Keys.userId] = user.userId;
    js['program_id'] = program.id;

    commonRequester?.bodyJson = js;
    commonRequester?.requestPath = RequestPath.SetData;

    commonRequester?.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester?.httpRequestEvents.onNetworkError = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResponseError = (req, isOk) async {
      if(isOk){
        SnackCenter.showSnack$errorInServerSide(state.context);
      } else {
        SnackCenter.showSnack$serverNotRespondProperly(state.context);
      }
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      final int causeCode = data[Keys.causeCode] ?? 0;
      final String cause = data[Keys.cause] ?? Keys.error;

      if(causeCode == HttpCodes.error_operationCannotBePerformed){
        if(cause == 'this is send') {
          SheetCenter.showSheetNotice(state.context, state.tInMap('sendProgramPage', 'canNotDeleteAfterSend')!);
        }
      }

      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      programs.removeWhere((element) => element.id == program.id);
      state.stateController.updateMain();
    };

    state.showLoading();
    commonRequester?.request(state.context);
  }

  void showSendPrompt(FoodProgramModel program){
    DialogCenter.instance.showYesNoDialog(
        state.context,
      yesText: state.t('send'),
      noText: state.t('cancel'),
      desc: state.tInMap('sendProgramPage', 'warningBeforeSend'),
      yesFn: (){
        sendProgram(program);
      }
    );
  }

  void sendProgram(FoodProgramModel program){
    //FocusHelper.hideKeyboardByUnFocus(state.context);

    final js = <String, dynamic>{};
    js[Keys.request] = 'SendFoodProgram';
    js[Keys.requesterId] = user.userId;
    js[Keys.forUserId] = user.userId;
    js['program_id'] = program.id;

    commonRequester?.bodyJson = js;
    commonRequester?.requestPath = RequestPath.SetData;

    commonRequester?.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester?.httpRequestEvents.onNetworkError = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResponseError = (req, isOk) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      final causeCode = data[Keys.causeCode];

      if(causeCode == HttpCodes.error_operationCannotBePerformed){
        program.sendDate = DateHelper.getNowToUtc();
        programManager.sinkItems([program]);

        SheetCenter.showSheet$OperationCannotBePerformed(state.context);
        state.stateController.updateMain();
        return true;
      }

      return false;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      program.sendDate = DateHelper.tsToSystemDate(data['send_date']);
      program.cronDate = DateHelper.tsToSystemDate(data['cron_date']);
      programManager.sinkItems([program]);

      SheetCenter.showSheet$SuccessOperation(state.context);
      state.stateController.updateMain();
    };

    state.showLoading();
    commonRequester?.request(state.context);
  }

  void requestRepeatProgram(FoodProgramModel program, FoodProgramModel oldProgram){
    //FocusHelper.hideKeyboardByUnFocus(state.context);

    final js = <String, dynamic>{};
    js[Keys.request] = 'RepeatFoodProgram';
    js[Keys.userId] = user.userId;
    js['old_program_id'] = oldProgram.id;
    js['program_data'] = program.toMap(withDays: false);

    commonRequester?.bodyJson = js;
    commonRequester?.requestPath = RequestPath.SetData;

    commonRequester?.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester?.httpRequestEvents.onFailState = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      program.id = data['program_id'];
      program.registerDate = DateHelper.tsToSystemDate(data['register_date']);

      programs.add(program);
      programManager.sinkItems([program]);

      SheetCenter.showSheet$SuccessOperation(state.context);

      sortList();
      state.stateController.updateMain();
    };

    state.showLoading();
    commonRequester?.request(state.context);
  }
}

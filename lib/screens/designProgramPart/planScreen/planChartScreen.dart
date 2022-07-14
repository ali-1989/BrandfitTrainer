import 'package:flutter/material.dart';

import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_sticky_section_list/sticky_section_list.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/widgets/optionsRow/radioRow.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/database/models/requestHybridModelDb.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/screens/designProgramPart/planScreen/planChartScreenCtr.dart';
import '/screens/requestPart/requestDataShowScreen.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/views/messageViews/communicationErrorView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

enum RadioType {
  pro,
  car,
  fat
}

class PlanChartScreen extends StatefulWidget {
  static const screenName = 'PlanChartScreen';
  final RequestHybridModelDb courseRequestModel;
  final UserAdvancedModelDb pupilUser;
  final CourseQuestionModel questionModel;
  final FoodProgramModel programModel;

  PlanChartScreen({
    required this.courseRequestModel,
    required this.pupilUser,
    required this.questionModel,
    required this.programModel,
    Key? key,
    }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PlanChartScreenState();
  }
}
///=========================================================================================================
class PlanChartScreenState extends StateBase<PlanChartScreen> {
  var stateController = StateXController();
  var controller = PlanChartScreenCtr();

  @override
  void initState() {
    super.initState();
    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();
    controller.onBuild();

    return getScaffold();
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => Future.value(true),//onWillBack(this),
      child: SizedBox(
        width: AppSizes.getScreenWidth(context),
        height: AppSizes.getScreenHeight(context),
        child: Scaffold(
          appBar: AppBar(
            title: Text('${tInMap('planChartPage', 'pageTitle')}'),
            actions: [
              IconButton(
                icon: Icon(IconList.questionProgress),
                onPressed: (){
                  controller.showHelpView();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: getMainBuilder(),
          ),
        ),
      ),
    );
  }

  Widget getMainBuilder(){
    return StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          switch(ctr.mainState){
            case StateXController.state$loading:
              return PreWidgets.flutterLoadingWidget$Center();
            case StateXController.state$netDisconnect:
              return CommunicationErrorView(this, tryAgain: controller.tryAgain);
            case StateXController.state$serverNotResponse:
              return ServerResponseWrongView(this, tryAgain: controller.tryAgain);
            default:
              return getBody();
          }
        }
    );
  }

  Widget getBody(){
    return StickySectionList(
        delegate: StickySectionListDelegate(
          getSectionCount: () => 1,
          getItemCount: (sectionIndex) => 1,
          buildSection: (context, sectionIndex) {
            return ColoredBox(
              color: AppThemes.currentTheme.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                child: SizedBox(
                  height: 150,
                  child: Row(
                    children: [
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(IconList.lightBulb, color: Colors.white,)
                              .wrapMaterial(
                              materialColor: AppThemes.currentTheme.primaryColor,
                              onTapDelay: (){
                                AppNavigator.pushNextPage(
                                    context,
                                    RequestDataShowScreen(
                                      courseRequestModel: widget.courseRequestModel,
                                      userInfo: widget.pupilUser,
                                      questionInfo: widget.questionModel,
                                    ),
                                    name: RequestDataShowScreen.screenName
                                );
                              }
                          ),
                        ),
                      ),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            UnconstrainedBox(
                              child: SizedBox(
                                width: 150,
                                height: 150,
                                child: PieChart(controller.chartData),
                              ),
                            ),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TabPageSelectorIndicator(
                                      backgroundColor: Colors.lightGreenAccent.shade200,
                                      borderColor: Colors.lightGreenAccent.shade200,
                                      size: 15,
                                    ),
                                    Text('${tInMap('materialFundamentals', 'protein')}'),
                                  ],
                                ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TabPageSelectorIndicator(
                                      backgroundColor: Colors.lightBlue.shade200,
                                      borderColor: Colors.lightBlue.shade200,
                                      size: 15,
                                    ),
                                    Text('${tInMap('materialFundamentals', 'carbohydrate')}'),
                                  ],
                                ),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TabPageSelectorIndicator(
                                      backgroundColor: Colors.redAccent.shade200,
                                      borderColor: Colors.redAccent.shade200,
                                      size: 15,
                                    ),
                                    Text('${tInMap('materialFundamentals', 'fat')}'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          buildItem: (context, sectionIndex, itemIndex) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Column(
                children: [
                  Card(
                    color: AppThemes.currentTheme.primaryColor,
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          SizedBox(height: 10,),
                          genItem('${t('heightMan')}', '${MathHelper.getDecimal(widget.questionModel.height)}'),

                          SizedBox(height: 10,),
                          genItem('${t('weight')}', '${MathHelper.getDecimal(widget.questionModel.weight)}'),

                          SizedBox(height: 10,),
                          genItem('${t('age')}', '${controller.age}'),

                          SizedBox(height: 10,),
                          genItem('${t('gender')}', '${widget.questionModel.sex == 1? t('man'): t('woman')}'),

                          SizedBox(height: 10,),
                          genItem('${tInMap('planChartPage', 'goalOf')}', '${tInMap('goalOfBuyCourse', widget.questionModel.goalOfBuy!)}'),

                          SizedBox(height: 10,),
                          genItem('${tInMap('planChartPage', 'bmr')}', '${MathHelper.getDecimal(controller.bmr)}'),

                          SizedBox(height: 10,),
                          genItem('${tInMap('planChartPage', 'tdee')}', '${MathHelper.getDecimal(controller.tdee)}'),


                          SizedBox(height: 10,),
                          Row(
                            children: [
                              SizedBox(
                                width: 115,
                                child: Text(tInMap('planChartPage', 'caloriesOfProgram')!)
                                    .color(Colors.white).bold().fsR(3),
                              ),

                              SizedBox(
                                width: 50,
                                child: GestureDetector(
                                  onTap: (){
                                    controller.caloriesStart = controller.caloriesValue;
                                    final view = Text('${tInMap('planChartPage', 'enterCalories')}');

                                    DialogCenter().showTextInputDialog(
                                        context,
                                        descView: view,
                                        initValue: '${controller.caloriesValue}',
                                        textInputType: TextInputType.number,
                                        yesFn: (t){
                                          final inp = MathHelper.clearToInt(t);
                                          controller.caloriesValue = MathHelper.absInt(inp);

                                          if(controller.caloriesValue > 7000){
                                            controller.caloriesValue = 7000;
                                          }

                                          AppNavigator.pop(context);

                                          controller.calcPCL();
                                          stateController.updateMain();
                                        });
                                  },
                                  child: Text('${controller.caloriesValue}')
                                      .color(Colors.white),
                                ),
                              )
                                  .wrapBoxBorder(color: Colors.white, padding: EdgeInsets.all(8)),
                            ],
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: controller.caloriesValue.toDouble(),
                                  min: 0.0,
                                  max: 7000.0,
                                  label: '',
                                  //divisions: 1,
                                  onChangeStart: (v){
                                    controller.caloriesStart = v.toInt();
                                  },
                                  onChanged: (v){
                                    controller.caloriesValue = v.toInt();
                                    stateController.updateMain();
                                  },
                                  onChangeEnd: (v){
                                    controller.caloriesValue = v.toInt();
                                    controller.calcPCL();
                                    stateController.updateMain();
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 10,),
                          Row(
                            children: [
                              Expanded(
                                child: RadioRow(
                                  color: Colors.white,
                                  mainAxisSize: MainAxisSize.max,
                                  description: SizedBox(
                                    width: 115,
                                    child: Text('${tInMap('planChartPage', 'proteinValue')}')
                                        .color(Colors.white).bold(),
                                  ),
                                    groupValue: controller.radioType,
                                    value: RadioType.pro,
                                    onChanged: (v){
                                      controller.radioType = v;
                                      stateController.updateMain();
                                    },
                                ),
                              ),

                              SizedBox(
                                width: 50,
                                child: GestureDetector(
                                  onTap: (){
                                    controller.radioType = RadioType.pro;
                                    final view = Text('${tInMap('planChartPage', 'enterProtein')}');

                                    DialogCenter().showTextInputDialog(
                                        context,
                                        descView: view,
                                        initValue: '${controller.proteinValue}',
                                        textInputType: TextInputType.number,
                                        yesFn: (t){
                                          var inp = MathHelper.clearToInt(t);
                                          inp = MathHelper.absInt(inp);
                                          var o2 = (controller.carbohydrateValue *4);
                                          o2 += (controller.fatValue *9);

                                          if(o2 + (inp*4) > 7000){
                                            final x = (7000 - o2) - (inp*4);
                                            controller.proteinValue = inp - (x ~/4);
                                          }
                                          else {
                                            controller.proteinValue = inp;
                                          }

                                          controller.calcChartData();
                                          AppNavigator.pop(context);

                                          stateController.updateMain();
                                        });
                                  },
                                  child: Text('${controller.proteinValue}')
                                      .color(Colors.white),
                                ),
                              )
                                  .wrapBoxBorder(color: Colors.white, padding: EdgeInsets.all(8)),
                            ],
                          ),

                          SizedBox(height: 8,),
                          Row(
                            children: [
                              Expanded(
                                child: RadioRow(
                                  color: Colors.white,
                                  mainAxisSize: MainAxisSize.max,
                                  description: Text('${tInMap('planChartPage', 'carbohydrateValue')}')
                                      .color(Colors.white).bold(),
                                  groupValue: controller.radioType,
                                  value: RadioType.car,
                                  onChanged: (v){
                                    controller.radioType = v;
                                    stateController.updateMain();
                                  },
                                ),
                              ),

                              SizedBox(
                                width: 50,
                                child: GestureDetector(
                                  onTap: (){
                                    controller.radioType = RadioType.car;
                                    final view = Text('${tInMap('planChartPage', 'enterCarbohydrate')}');

                                    DialogCenter().showTextInputDialog(context,
                                        descView: view,
                                        initValue: '${controller.carbohydrateValue}',
                                        textInputType: TextInputType.number,
                                        yesFn: (t){
                                          var inp = MathHelper.clearToInt(t);
                                          inp = MathHelper.absInt(inp);
                                          var o2 = (controller.proteinValue *4);
                                          o2 += (controller.fatValue *9);

                                          if(o2 + (inp*4) > 7000){
                                            final x = (7000 - o2) - (inp*4);
                                            controller.carbohydrateValue = inp - (x ~/4);
                                          }
                                          else {
                                            controller.carbohydrateValue = inp;
                                          }

                                          controller.calcChartData();
                                          AppNavigator.pop(context);

                                          stateController.updateMain();
                                        });
                                  },
                                  child: Text('${controller.carbohydrateValue}')
                                      .color(Colors.white),
                                ),
                              )
                                  .wrapBoxBorder(color: Colors.white, padding: EdgeInsets.all(8)),
                            ],
                          ),

                          SizedBox(height: 8,),
                          Row(
                            children: [
                              Expanded(
                                child: RadioRow(
                                  color: Colors.white,
                                  mainAxisSize: MainAxisSize.min,
                                  description: Text('${tInMap('planChartPage', 'fatValue')}')
                                      .color(Colors.white).bold(),
                                  groupValue: controller.radioType,
                                  value: RadioType.fat,
                                  onChanged: (v){
                                    controller.radioType = v;
                                    stateController.updateMain();
                                  },
                                ),
                              ),

                              SizedBox(
                                width: 50,
                                child: GestureDetector(
                                  onTap: (){
                                    controller.radioType = RadioType.fat;
                                    final view = Text('${tInMap('planChartPage', 'enterFat')}');

                                    DialogCenter().showTextInputDialog(
                                        context,
                                        descView: view,
                                        initValue: '${controller.fatValue}',
                                        textInputType: TextInputType.number,
                                        yesFn: (t){
                                          var inp = MathHelper.clearToInt(t);
                                          inp = MathHelper.absInt(inp);
                                          var o2 = (controller.proteinValue *4);
                                          o2 += (controller.carbohydrateValue *4);

                                          if(o2 + (inp*4) > 7000){
                                            final x = (7000 - o2) - (inp*4);
                                            controller.fatValue = inp - (x ~/4);
                                          }
                                          else {
                                            controller.fatValue = inp;
                                          }

                                          controller.calcChartData();
                                          AppNavigator.pop(context);

                                          stateController.updateMain();
                                        });
                                  },
                                  child: Text('${controller.fatValue}')
                                      .color(Colors.white),
                                ),
                              )
                                  .wrapBoxBorder(color: Colors.white, padding: EdgeInsets.all(8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30,),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: (){
                          controller.gotoNextPage();
                        },
                        child: Text(t('register&continue')!)
                    ),
                  ),
                  SizedBox(height: 10,),
                ],
              ),
            );
          },
        )
    );
  }
  ///==========================================================================================================
  Widget genItem(String title, String value){
    return FlipInX(
      delay: Duration(milliseconds: 500),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title)
              .color(Colors.white).bold().fsR(3),
          Text(value)
              .color(Colors.white).bold().fsR(3),
        ],
      ).wrapBoxBorder(
        color: Colors.white70,
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8)
      ),
    );
  }
}

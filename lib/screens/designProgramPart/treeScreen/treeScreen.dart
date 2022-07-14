import 'package:flutter/material.dart';

import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/database/models/requestHybridModelDb.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/programModels/foodDay.dart';
import '/models/dataModels/programModels/foodMeal.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/screens/designProgramPart/treeScreen/treeScreenCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/views/messageViews/communicationErrorView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class TreeFoodProgramScreen extends StatefulWidget {
  static const screenName = 'TreeFoodProgramScreen';
  final RequestHybridModelDb courseRequestModel;
  final UserAdvancedModelDb pupilUser;
  final CourseQuestionModel questionModel;
  final FoodProgramModel programModel;

  TreeFoodProgramScreen({
    required this.courseRequestModel,
    required this.pupilUser,
    required this.questionModel,
    required this.programModel,
    Key? key,
    }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TreeFoodProgramScreenState();
  }
}
///=========================================================================================================
class TreeFoodProgramScreenState extends StateBase<TreeFoodProgramScreen> {
  var stateController = StateXController();
  var controller = TreeFoodProgramScreenCtr();

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

  @override
  Future<bool> onWillBack<S extends StateBase>(S state){
    if(controller.programHash != controller.programModel.hashCode) {
      final msg = Text(
        tInMap('treeFoodProgramPage', 'programNotSavedIfClose')!,
        style: AppThemes.baseTextStyle().copyWith(
          fontSize: 16,
        ),
      );

      DialogCenter.instance.showDialog$wantClose(context, view: msg).then((value) {
          if(value){
            controller.programModel.foodDays.clear();
            controller.programModel.foodDays.addAll(controller.programOriginal.map((e) => FoodDay.fromMap(e)).toList());
            AppNavigator.pop(context);
          }
      });

      return Future.value(false);
    }

    return Future.value(true);
  }

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => onWillBack(this),
      child: SizedBox(
        width: AppSizes.getScreenWidth(context),
        height: AppSizes.getScreenHeight(context),
        child: Scaffold(
          appBar: getAppbar(),
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

  PreferredSizeWidget getAppbar(){
    return AppBar(
      title: Text('${tInMap('treeFoodProgramPage', 'pageTitle')}'),
      actions: [
        TextButton(
          child: Text('${t('save')}').color(Colors.white),
          onPressed: controller.uploadData,
        ),
      ],
    );
  }

  Widget getBody(){
    return Column(
      children: [
        getHeader(),
        SizedBox(height: 10,),
        Expanded(child: getTreeView()),
        SizedBox(height: 10,),
      ],
    );
  }
  ///==========================================================================================================
  Widget getHeader(){
    var nameInfo = t('pupil')!;
    nameInfo += ': ${controller.pupilUser?.userName?? ''}';
    var courseInfo = tInMap('sendProgramPage', 'course')!;
    courseInfo += ': ${controller.courseRequestModel.title}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Card(
              color: AppThemes.currentTheme.accentColor,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nameInfo).color(Colors.white).boldFont(),
                    SizedBox(height: 8,),
                    Text(courseInfo,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        overflow: TextOverflow.fade,),
                    ).color(Colors.white),
                  ],
                ),
              ),
            ),
          ),

          /// add button
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: (){
                    controller.addNewDay();
                  },
                  icon: Icon(IconList.add, size: 16, color: Colors.white,)
                      .wrapBackground(
                    radius: 22,
                    padding: EdgeInsets.all(2),
                    backColor: AppThemes.textButtonColor(),
                  ),
                  label: Text('${tInMap('treeFoodProgramPage', 'createDay')}'),
                ),

                SizedBox(width: 5,),

                TextButton(
                    onPressed: (){
                      controller.showRepeatDaysPrompt();
                    },
                    child: Text('${tInMap('treeFoodProgramPage','batchRepeat')}')
                ),

                TextButton(
                    onPressed: (){
                      controller.showDeleteDaysPrompt();
                    },
                    child: Text('${tInMap('treeFoodProgramPage','batchDelete')}')
                ),

                TextButton(
                    onPressed: (){
                      controller.showBaseChart();
                    },
                    child: Text('${tInMap('treeFoodProgramPage', 'chart')}')
                ),

                TextButton(
                    onPressed: (){
                      controller.showPupilInfo();
                    },
                    child: Text('${tInMap('treeFoodProgramPage', 'pupilInfo')}')
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget getTreeView(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TreeView(
        //key: ValueKey(Generator.generateName(10)),
        controller: controller.treeViewController,
        theme: controller.treeViewTheme,
        allowParentSelect: true,
        onNodeTap: onNodeTap,
        nodeBuilder: genNodeView,
        onExpansionChanged: (key, state){
          Node? node = controller.treeViewController.getNode(key);

          if (node != null) {
            node.expanded = state;
            stateController.updateMain();
          }
        },
      ),
    );
  }

  Widget genNodeView(BuildContext ctx, Node node){
    if(node.label == 'meal_add'){
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 25,),
            Icon(IconList.add, size: 15, color: Colors.orange,),
            Text('${tInMap('treeFoodProgramPage', 'addMeal')}').color(Colors.green.shade700,)
          ],
        ),
      );
    }

    if(node.label == 'suggestion_add'){
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 55,),
            Icon(IconList.add, size: 15, color: Colors.orange,),
            Text('${tInMap('treeFoodProgramPage', 'addSuggestion')}').color(Colors.green.shade700,)
          ],
        ),
      );
    }

    Color color;
    final isDay = node.data is FoodDay;
    final isMeal = node.data is FoodMeal;

    if(isDay){
      color = AppThemes.currentTheme.infoColor;
      return Row(
        children: [
          Text(node.label).boldFont().fsR(3).color(color),
          SizedBox(width: 10,),
          IconButton(
              onPressed: (){
                controller.showFoodDayPrompt(node);
              },
              icon: Icon(IconList.settings, color: AppThemes.currentTheme.primaryColor,)
          ),
        ],
      );
    }
    else if(isMeal) {
      color = AppThemes.currentTheme.textColor;
      final meal = node.data as FoodMeal;

      return Row(
        children: [
          SizedBox(width: 30,),
          Row(
            children: [
              Text(meal.title?? node.label).boldFont().color(color),
              SizedBox(width: 5,),
              IconButton(
                  onPressed: (){
                    controller.showFoodMealPrompt(node);
                  },
                  icon: Icon(IconList.settings, color: AppThemes.currentTheme.primaryColor)
              ),
              SizedBox(width: 5,),
              Text('(${meal.percentOfCalories(controller.programModel.getPlanCalories()!)} % ${tInMap('materialFundamentals', 'calories')})')
              .alpha(),
            ],
          ),
        ],
      );
    }
    else {
      color = AppThemes.currentTheme.textColor.withAlpha(150);
      final suggestion = node.data as FoodSuggestion;
      var name = node.label;

      if(suggestion.title != null){
        name += ' (${suggestion.title})';
      }

      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 60,),
            Row(
              children: [
                Text(name).boldFont().color(color),

                SizedBox(width: 4,),
                Visibility(
                    visible: suggestion.isBase,
                    child: Icon(IconList.pushPin, size: 18,).toColor(Colors.orange)
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  void onNodeTap(String nodeKey){
    controller.currentNodeKey = nodeKey;
    Node node = controller.treeViewController.getNode(nodeKey)!;
    //controller.treeViewController = controller.treeViewController.copyWith(selectedKey: nodeKey);

    void resetExpand(List<Node> list){
      for (var element in list) {
        element.expanded = false;
      }
    }

    if(node.data is FoodDay){
      if(!node.expanded) {
        resetExpand(controller.nodeList);
      }

      node.expanded = !node.expanded;
      stateController.updateMain();
    }
    else if(node.data is FoodMeal){
      if(!node.expanded) {
        resetExpand(controller.getParent(node.key)!.children);
      }

      node.expanded = !node.expanded;
      stateController.updateMain();
    }
    else if(node.data is FoodSuggestion){
      controller.showFoodSuggestionPrompt(node);
    }
    else {
      if(node.label == 'meal_add'){
        Node? parent = controller.getParent(node.key);
        controller.addNewMeal(parent!, parent.data);
      }

      else if(node.label == 'suggestion_add'){
        Node? parent = controller.getParent(node.key);
        controller.addNewSuggestion(parent!, parent.data);
      }
    }
  }
}

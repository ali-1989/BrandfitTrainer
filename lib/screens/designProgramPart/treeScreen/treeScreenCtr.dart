import 'package:flutter/material.dart';

import 'package:auto_size_text_pk/auto_size_text_pk.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:iris_tools/api/generator.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/features/overlayDialog.dart';
import 'package:iris_tools/widgets/backForwardArrow.dart';
import 'package:iris_tools/modules/stateManagers/selfRefresh.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/viewController.dart';
import '/database/models/requestHybridModelDb.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/programModels/foodDay.dart';
import '/models/dataModels/programModels/foodMeal.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/commons/topInputFieldScreen.dart';
import '/screens/designProgramPart/planScreen/planChartScreen.dart';
import '/screens/designProgramPart/treeScreen/selectMaterialScreen.dart';
import '/screens/designProgramPart/treeScreen/treeScreen.dart';
import '/screens/requestPart/requestDataShowScreen.dart';
import '/system/extensions.dart';
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

class TreeFoodProgramScreenCtr implements ViewController {
  late TreeFoodProgramScreenState state;
  late Requester commonRequester;
  late UserModel user;
  late UserAdvancedModelDb? pupilUser;
  late RequestHybridModelDb courseRequestModel;
  late CourseQuestionModel questionModel;
  late FoodProgramModel programModel;
  bool isEditMode = false;
  List<Node> nodeList = [];
  String currentNodeKey = '';
  late TreeViewController treeViewController;
  TreeViewTheme? treeViewTheme;
  late ExpanderPosition expanderPosition;
  late ExpanderType expanderType;
  late ExpanderModifier expanderWrap;
  late Map<ExpanderModifier, Widget> expansionWrapOptions;
  late String dayLabel;
  late String mealLabel;
  late String suggestLabel;
  late PieChartData chartData;
  int caloriesValue = 0;
  int proteinValue = 0;
  int carValue = 0;
  int fatValue = 0;
  int programHash = 0;
  List<Map> programOriginal = [];

  @override
  void onInitState<E extends State>(E state){
    this.state = state as TreeFoodProgramScreenState;

    user = Session.getLastLoginUser()!;
    courseRequestModel = state.widget.courseRequestModel;
    questionModel = state.widget.questionModel;
    pupilUser = state.widget.pupilUser;
    programModel = state.widget.programModel;

    programHash = programModel.hashCode;
    programOriginal = programModel.daysToMap();

    commonRequester = Requester();
    treeViewController = TreeViewController(children: nodeList);
    isEditMode = programModel.foodDays.isNotEmpty;

    dayLabel = state.tInMap('treeFoodProgramPage', 'day')!;
    mealLabel = state.tInMap('treeFoodProgramPage', 'meal')!;
    suggestLabel = state.tInMap('treeFoodProgramPage', 'suggestion')!;

    prepareTree();
    prepareNodes();
  }

  @override
  void onBuild(){
    buildTheme();
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }
  ///=====================================================================================================
  void prepareNodes(){
    if(!isEditMode){
      final day1 = FoodDay();
      day1.ordering = 1;

      programModel.foodDays.add(day1);
    }

    nodeList.clear();
    programModel.sortChildren();
    nodeList.addAll(buildNodes(programModel.foodDays, 0, null));
  }

  Node genAddMealNode(Node parent){
    return Node(
      label: 'meal_add',
      key: '${parent.key}_meal_add',
      data: null,
    );
  }

  Node genAddSuggestionNode(Node parent){
    return Node(
      label: 'suggestion_add',
      key: '${parent.key}_suggestion_add',
      data: null,
    );
  }

  /*buildNodes(List foods, int level, Node? parent){
    var label = dayLabel;

    if(level == 1){
      label = mealLabel;
    }
    else if(level == 2){
      label = suggestLabel;
    }

    for(int i =0; i < foods.length; i++){
      final item = foods[i];

      final node = Node(
        label: '$label ${item.ordering}',
        key: '${item.id}',
        data: item,
        children: <Node>[],
        expanded: i == foods.length-1,
      );

      if(level == 0) {
        nodeList.add(node);
      }
      else {
        parent!.children.add(node);
      }

      if(level == 0) {
        item.sortChildren();
        buildNodes(item.mealList, level + 1, node);
      }
      else if(level == 1) {
        item.sortChildren();
        buildNodes(item.suggestionList, level + 1, node);
      }
    }

    if(level == 1){
      parent!.children.add(genAddMealNode(parent));
    }
    else if(level == 2){
      parent!.children.add(genAddSuggestionNode(parent));
    }
  }
*/

  List<Node> buildNodes(List foods, int level, Node? parent){
    final res = <Node>[];

    var label = dayLabel;

    if(level == 1){
      label = mealLabel;
    }
    else if(level == 2){
      label = suggestLabel;
    }

    for(int i =0; i < foods.length; i++){
      final item = foods[i];

      final node = Node(
        label: '$label ${item.ordering}',
        key: '${Generator.generateName(8)}_${item.id}',
        data: item,
        children: <Node>[],
        expanded: level == 0? (i == foods.length-1): false,
      );

      res.add(node);

      if(level == 0) {
        item.sortChildren();
        node.children = buildNodes(item.mealList, level + 1, node);
      }
      else if(level == 1) {
        item.sortChildren();
        node.children = buildNodes(item.suggestionList, level + 1, node);
      }
    }

    if(level == 1){
      res.add(genAddMealNode(parent!));
    }
    else if(level == 2){
      res.add(genAddSuggestionNode(parent!));
    }

    return res;
  }

  void prepareTree(){
    /*expansionPositionOptions = const {
      ExpanderPosition.start: Text('Start'),
      ExpanderPosition.end: Text('End'),
    };

    expansionTypeOptions = {
      ExpanderType.none: SizedBox(),
      ExpanderType.caret: Icon(Icons.arrow_drop_down, size: 28,),
      ExpanderType.arrow: Icon(Icons.arrow_downward),
      ExpanderType.chevron: Icon(Icons.expand_more),
      ExpanderType.plusMinus: Icon(Icons.add),
    };*/

    expansionWrapOptions = const {
      ExpanderModifier.none: ExpanderWrap(ExpanderModifier.none),
      ExpanderModifier.circleFilled: ExpanderWrap(ExpanderModifier.circleFilled),
      ExpanderModifier.circleOutlined: ExpanderWrap(ExpanderModifier.circleOutlined),
      ExpanderModifier.squareFilled: ExpanderWrap(ExpanderModifier.squareFilled),
      ExpanderModifier.squareOutlined: ExpanderWrap(ExpanderModifier.squareOutlined),
    };

    expanderPosition = ExpanderPosition.end;
    expanderType = ExpanderType.caret;
    expanderWrap = ExpanderModifier.circleFilled;
  }

  void buildTheme(){
    if(treeViewTheme != null){
      return;
    }

    treeViewTheme = TreeViewTheme(
      dense: true,
      verticalSpacing: 0,
      //horizontalSpacing: 0,
      //levelPadding: 0,
      expanderTheme: ExpanderThemeData(
          type: expanderType,
          modifier: expanderWrap,
          position: expanderPosition,
          size: 18,
          color: Colors.grey,//AppThemes.currentTheme.primaryColor
      ),
      labelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.3,
      ),
      parentLabelStyle: TextStyle(
        fontSize: 16,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w800,
        //color: Colors.blue.shade700,
        color: AppThemes.currentTheme.primaryColor,
      ),
      iconTheme: IconThemeData(
        size: 18,
        color: Colors.grey.shade800,
      ),
      colorScheme: Theme.of(state.context).colorScheme,
    );
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is TreeFoodProgramScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  Node? getParent(String key, {Node? parent}) {
    Node? _found;
    List<Node> _children = parent != null ? parent.children : nodeList;
    Iterator iter = _children.iterator;

    while (iter.moveNext()) {
      Node child = iter.current;

      if (child.key == key) {
        _found = parent?? child;
        break;
      }
      else {
        if (child.isParent) {
          _found = getParent(key, parent: child);

          if (_found != null) {
            break;
          }
        }
      }
    }

    return _found;
  }

  void resetCaloriesPrompt(){
    final t1 = state.tInMap('treeFoodProgramPage', 'resetPcl_L1')!;
    final t2 = state.tInMap('treeFoodProgramPage', 'resetPcl_L2')!;
    final title = state.tInMap('treeFoodProgramPage', 'resetPclTitle')!;

    final view = Column(
      children: [
        Text(t1),
        SizedBox(height: 6,),
        Text(t2).color(AppThemes.currentTheme.errorColor).bold(),
      ],
    );
    DialogCenter.instance.showYesNoDialog(
        state.context,
      title: title,
      descView: view,
      yesText: state.t('reset'),
      noText: state.t('no'),
      yesFn: (){
         resetCaloriesPcl(programModel);
      }
    );
  }

  void addNewDay(){
    final day = FoodDay();
    day.ordering = programModel.getLastOrdering() +1;

    for(final k in nodeList){
      k.expanded = false;
    }

    final node = Node(
      label: '$dayLabel ${day.ordering}',
      key: '${day.id}',
      data: day,
      children: <Node>[],
      expanded: true,
    );

    node.children.add(genAddMealNode(node));
    nodeList.add(node);

    programModel.foodDays.add(day);
    programModel.sortChildren();
    currentNodeKey = node.key;

    state.stateController.updateMain();
  }

  void addNewMeal(Node node, FoodDay day) async {
    final meal = FoodMeal();
    meal.ordering = day.getLastOrdering() +1;
    meal.title = '$mealLabel ${meal.ordering}';

    final res = await showAddNewMealPrompt(meal);

    if(res != null && res == 'save') {
      final mealNode = Node(
        label: '$mealLabel ${meal.ordering}',
        key: '${meal.id}',
        data: meal,
        children: <Node>[],
        expanded: true,
      );

      mealNode.children.add(genAddSuggestionNode(mealNode));

      node.children.removeLast();
      node.children.add(mealNode);
      node.children.add(genAddMealNode(node));

      //final parentDay = parentNode.data as FoodDay;
      day.mealList.add(meal); //parentDay.mealList.add(meal);
      day.sortChildren();

      currentNodeKey = node.key;

      state.stateController.updateMain();
    }
  }

  void addNewSuggestion(Node node, FoodMeal meal) async {
    final sug = FoodSuggestion();
    sug.ordering = meal.getLastOrdering() +1;
    //sug.name = '$suggestLabel ${sug.ordering}';
    sug.isBase = sug.ordering == 1;

    final sugNode = Node(
      label: '$suggestLabel ${sug.ordering}',
      key: '${sug.id}',
      data: sug,
      children: <Node>[],
      expanded: true,
    );


    node.children.removeLast();
    node.children.add(sugNode);
    node.children.add(genAddSuggestionNode(node));

    //final parentDay = parentNode.data as FoodMeal;
    meal.suggestionList.add(sug); //parentDay.suggestionList.add(sug);
    meal.sortChildren();

    currentNodeKey = node.key;

    state.stateController.updateMain();
  }

  Future<String?> showAddNewMealPrompt(FoodMeal? model) async {
    final dialogName = 'newMealDialog';
    final nameCtr = TextEditingController(text: model?.title);

    final content = Align(
      child: FractionallySizedBox(
        widthFactor: 0.85,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26.0, 16, 26.0, 26.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${state.tInMap('treeFoodProgramPage', 'createNewMeal')}')
                    .boldFont().fsR(2),

                SizedBox(height: 16,),
                TextField(
                  controller: nameCtr,
                  decoration: InputDecoration(
                    hintText: state.tInMap('treeFoodProgramPage', 'mealName'),
                  ),
                ),
                SizedBox(height: 16,),

                SizedBox(height: 30,),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (){
                          model?.title = nameCtr.text.trim();
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

    final dialog = OverlayScreenView(content: content, routingName: dialogName,);
    return await OverlayDialog().show(state.context, dialog, canBack: true, background: Colors.black54);
  }

  void showFoodDayPrompt(Node node) async {
    final dialogName = 'DayDialog';

    FoodDay day = node.data;

    final content = Align(
      child: SelfRefresh(
        builder: (ctx, ctr) {
          var title = '$dayLabel ${day.ordering}';

          return FractionallySizedBox(
            widthFactor: 0.85,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26.0, 16, 26.0, 26.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(title)
                          .boldFont(),//.fsR(2),
                    ),

                    SizedBox(height: 15,),
                    Divider(color: Colors.grey,),
                    SizedBox(height: 12,),

                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(0),
                      ),
                      onPressed: (){
                        OverlayDialog().hideByPop(state.context, data: 'repeatAtBelow');
                      },
                      icon: Icon(IconList.copy, size: 20,),
                      label: Text('${state.tInMap('treeFoodProgramPage', 'repeatAtBelow')}').fsR(-2).color(Colors.lightBlue),
                    ),

                    SizedBox(height: 12,),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(0),
                      ),
                      onPressed: (){
                        OverlayDialog().hideByPop(state.context, data: 'repeatAtEnd');
                      },
                      icon: Icon(IconList.copy, size: 20,),
                      label: Text('${state.tInMap('treeFoodProgramPage', 'repeatAtEnd')}').fsR(-2).color(Colors.lightBlue),
                    ),

                    SizedBox(height: 12,),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.all(0),
                      ),
                      onPressed: (){
                        OverlayDialog().hideByPop(state.context, data: 'delete');
                      },
                      icon: Icon(IconList.delete, size: 20,),
                      label: Text('${state.t('delete')}').fsR(-2).color(Colors.lightBlue),
                    ),

                    SizedBox(height: 22,),
                    Row(
                      textDirection: AppThemes.getOppositeDirection(),
                      children: [
                        TextButton(
                          onPressed: (){
                            OverlayDialog().hideByPop(state.context);
                          },
                          child: Text('${state.t('back')}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );

    final dialog = OverlayScreenView(content: content, routingName: dialogName,);
    final result = await OverlayDialog().show(state.context, dialog, canBack: true, background: Colors.black54);

    if(result != null){
      if(result == 'delete'){
        DialogCenter.instance.showYesNoDialog(
            state.context,
          desc: state.t('wantToDeleteThisItem'),
          yesFn: (){
            programModel.foodDays.removeWhere((element) => element.id == day.id);
            programModel.reOrderingDec(day.ordering);

            nodeList.removeWhere((element) => element.key == node.key);

            for(final k in nodeList){
              if(k.data != null) {
                k.label = '$dayLabel ${k.data.ordering}';
              }
            }

            state.stateController.updateMain();
          }
        );
      }
      else if(result == 'repeatAtBelow'){
        repeatDay(node, day, nodeList.indexOf(node)+1);

        state.stateController.updateMain();

        var toastTxt = state.tInMap('treeFoodProgramPage', 'addNewDayByRepeat')!;
        toastTxt = toastTxt.replaceFirst('#', '${nodeList.indexOf(node)+2}');
        StateXController.globalUpdate(Keys.toast, stateData: toastTxt);
      }
      else if(result == 'repeatAtEnd'){
        repeatDay(node, day, nodeList.length);

        state.stateController.updateMain();

        var toastTxt = state.tInMap('treeFoodProgramPage', 'addNewDayByRepeat')!;
        toastTxt = toastTxt.replaceFirst('#', '${nodeList.length+1}');
        StateXController.globalUpdate(Keys.toast, stateData: toastTxt);
      }
    }
  }

  void showFoodMealPrompt(Node node) async {
    final dialogName = 'MealDialog';

    Node parent = getParent(node.key)!;
    FoodDay day = parent.data;
    FoodMeal meal = node.data;

    final content = Align(
      child: SelfRefresh(
        builder: (ctx, ctr) {
          var title = '$dayLabel ${day.ordering} - ${meal.title?? ''}';

          return FractionallySizedBox(
            widthFactor: 0.85,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26.0, 16, 26.0, 26.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(title)
                          .boldFont(),//.fsR(2),
                    ),

                    SizedBox(height: 15,),
                    Divider(color: Colors.grey,),
                    SizedBox(height: 12,),

                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(0),
                      ),
                      onPressed: (){
                        showRenameMeal(meal).then((value) {
                          if(value != null && (value as String).isNotEmpty) {
                            meal.title = value;
                            ctr.update();
                          }
                        });
                      },
                      icon: Icon(IconList.edit),
                      label: Text('${state.t('rename')}').fsR(-2).color(Colors.lightBlue),
                    ),

                    SizedBox(height: 12,),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(0),
                      ),
                      onPressed: (){
                        OverlayDialog().hideByPop(state.context, data: 'delete');
                      },
                      icon: Icon(IconList.delete, size: 20,),
                      label: Text('${state.t('delete')}').fsR(-2).color(Colors.lightBlue),
                    ),

                    SizedBox(height: 22,),
                    Row(
                      textDirection: AppThemes.getOppositeDirection(),
                      children: [
                        TextButton(
                          onPressed: (){
                            OverlayDialog().hideByPop(state.context);
                          },
                          child: Text('${state.t('back')}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );

    final dialog = OverlayScreenView(content: content, routingName: dialogName,);
    final result = await OverlayDialog().show(state.context, dialog, canBack: true, background: Colors.black54);

    if(result != null){
      if(result == 'delete'){
        DialogCenter.instance.showYesNoDialog(
            state.context,
            desc: state.t('wantToDeleteThisItem'),
            yesFn: (){
              day.mealList.removeWhere((element) => element.id == meal.id);
              day.reOrderingDec(meal.ordering);

              final parent = getParent(node.key)!;
              parent.children.removeWhere((element) => element.key == node.key);

              for(final k in parent.children){
                if(k.data != null) {
                  k.label = '$mealLabel ${k.data.ordering}';
                }
              }

              state.stateController.updateMain();
            }
        );
      }
    }
    else {
      state.stateController.updateMain();
    }
  }

  void showFoodSuggestionPrompt(Node node) async {
    final dialogName = 'SuggestionDialog';

    Node parent1 = getParent(node.key)!;
    Node parent2 = getParent(parent1.key)!;

    FoodSuggestion suggestion = node.data;
    FoodMeal meal = parent1.data;
    FoodDay day = parent2.data;
    final dayText = '$dayLabel ${day.ordering}';
    final suggestionText = '$suggestLabel ${suggestion.ordering}';

    final content = Align(
      child: SelfRefresh(
          builder: (ctx, ctr) {
            var suggestionLabel = '';

            if(suggestion.title != null) {
              suggestionLabel = '(${suggestion.title})';
            }

            var title = '$dayText - ${meal.title?? ''} - $suggestionText $suggestionLabel';

            return FractionallySizedBox(
              widthFactor: 0.85,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26.0, 16, 26.0, 26.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: AutoSizeText(title,
                                maxLines: 1,
                                minFontSize: 10,
                                overflow: TextOverflow.clip,
                                style: AppThemes.currentTheme.boldTextStyle,
                              ),
                            ),
                          ),

                          Visibility(
                              visible: suggestion.isBase,
                              child: Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: Icon(IconList.pushPin).toColor(Colors.orange)
                              )
                          ),
                        ],
                      ),

                      SizedBox(height: 15,),
                      Divider(color: Colors.grey,),
                      SizedBox(height: 12,),

                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.all(0),
                        ),
                        onPressed: (){
                          showSelectMaterialPage(day, meal, suggestion);
                        },
                        icon: Icon(IconList.apps2, size: 20,),
                        label: Text('${state.tInMap('treeFoodProgramPage', 'materialsList')}').fsR(-2).color(Colors.lightBlue),
                      ),

                      Visibility(
                        visible: !suggestion.isBase,
                        child: Column(
                          children: [
                            SizedBox(height: 12,),

                            TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.all(0),
                              ),
                              onPressed: (){
                                for (final element in meal.suggestionList) {
                                  element.isBase = false;
                                }

                                suggestion.isBase = true;
                                ctr.update();
                              },
                              icon: Icon(IconList.pushPin, size: 20,),
                              label: Text('${state.tInMap('treeFoodProgramPage', 'setMainSuggestion')}').fsR(-2).color(Colors.lightBlue),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 12,),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.all(0),
                        ),
                        onPressed: (){
                          showRenameSuggestion(suggestion).then((value) {
                            if(value != null) {
                              if ((value as String).isEmpty) {
                                suggestion.title = null;
                              }
                              else {
                                suggestion.title = value;
                              }
                            }

                            ctr.update();
                          });
                        },
                        icon: Icon(IconList.edit, size: 20,),
                        label: Text('${state.t('label')}').fsR(-2).color(Colors.lightBlue),
                      ),

                      SizedBox(height: 12,),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.all(0),
                        ),
                        onPressed: (){
                          OverlayDialog().hideByPop(state.context, data: 'repeatAtBelow');
                        },
                        icon: Icon(IconList.copy, size: 20,),
                        label: Text('${state.tInMap('treeFoodProgramPage', 'repeatAtBelow')}').fsR(-2).color(Colors.lightBlue),
                      ),

                      SizedBox(height: 12,),
                      Visibility(
                        visible: !suggestion.isBase || meal.suggestionList.length < 2,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.all(0),
                          ),
                          onPressed: (){
                            OverlayDialog().hideByPop(state.context, data: 'delete');
                          },
                          icon: Icon(IconList.delete, size: 20,),
                          label: Text('${state.t('delete')}').fsR(-2).color(Colors.lightBlue),
                        ),
                      ),

                      SizedBox(height: 22,),
                      Row(
                        textDirection: AppThemes.getOppositeDirection(),
                        children: [
                          TextButton(
                            onPressed: (){
                              OverlayDialog().hideByPop(state.context);
                            },
                            child: Text('${state.t('back')}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
      ),
    );

    final dialog = OverlayScreenView(content: content, routingName: dialogName,);
    final result = await OverlayDialog().show(state.context, dialog, canBack: true, background: Colors.black54);

    if(result != null){
      if(result == 'delete'){
        DialogCenter.instance.showYesNoDialog(
            state.context,
            desc: state.t('wantToDeleteThisItem'),
            yesFn: (){
              meal.suggestionList.removeWhere((element) => element.id == suggestion.id);
              meal.reOrderingDec(suggestion.ordering);

              final parent = getParent(node.key)!;
              parent.children.removeWhere((element) => element.key == node.key);

              for(final k in parent.children){
                if(k.data != null) {
                  k.label = '$suggestLabel ${k.data.ordering}';
                }
              }

              state.stateController.updateMain();
            }
        );
      }
      else if(result == 'repeatAtBelow'){
        repeatSuggestion(parent1, node, suggestion, parent1.children.indexOf(node)+1);
      }
    }
    else {
      state.stateController.updateMain();
    }
  }

  Future showRenameMeal(FoodMeal meal) async {
    final txtCtr = TextEditingController();
    txtCtr.text = meal.title?? '';

    final res = AppNavigator.pushNextPage(
        state.context, TopInputFieldScreen(editingController: txtCtr),
        name: TopInputFieldScreen.screenName
    );

    return res;
  }

  Future showRenameSuggestion(FoodSuggestion suggestion) async {
    final txtCtr = TextEditingController();
    txtCtr.text = suggestion.title?? '';

    final res = AppNavigator.pushNextPage(
        state.context, TopInputFieldScreen(editingController: txtCtr),
        name: TopInputFieldScreen.screenName
    );

    return res;
  }

  void showSelectMaterialPage(FoodDay foodDay, FoodMeal foodMeal, FoodSuggestion sug){
    AppNavigator.pushNextPage(
        state.context,
        SelectMaterialScreen(
          foodProgram: programModel,
          foodDay: foodDay,
          foodMeal: foodMeal,
          foodSuggestion: sug,
        ),
        name: SelectMaterialScreen.screenName
    );
  }

  void resetCaloriesPcl(FoodProgramModel programModel) async {
    //FocusHelper.hideKeyboardByUnFocus(state.context);

    programModel.pcl = null;

    final js = <String, dynamic>{};

    js[Keys.request] = 'EditFoodProgram';
    js[Keys.userId] = user.userId;
    js['program_id'] = programModel.id;
    js['program_data'] = programModel.toMap(withDays: false);

    commonRequester.requestPath = RequestPath.SetData;
    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      programModel.pcl = null;
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      programModel.foodDays.clear();
      //todo: must remove day in server

      AppNavigator.replaceCurrentRoute(
          state.context,
          PlanChartScreen(
            courseRequestModel: state.widget.courseRequestModel,
            pupilUser: state.widget.pupilUser,
            questionModel: state.widget.questionModel,
            programModel: programModel,
          ),
          name: PlanChartScreen.screenName
      );
    };

    state.showLoading();
    commonRequester.request(state.context);
  }

  List<FoodMeal> repeatMeal(List<FoodMeal> list){
    final res = <FoodMeal>[];

    for(final i in list){
      final n = FoodMeal.fromMap(i.toMap());
      n.reId();

      for(final s in n.suggestionList){
        s.reId();
      }

      res.add(n);
    }

    return res;
  }

  /*List<Node> cloneMealNodes(List meals, int level, Node parent){
    final res = <Node>[];

    for(final k in meals){
      final node = Node(
        label: '${level == 0? mealLabel: suggestLabel} ${k.ordering}',
        key: '${k.id}',
        data: k,
        children: <Node>[],
        expanded: false,
      );

      if(level == 0){
        node.children = cloneMealNodes(k.suggestionList, 1, node);
      }
      res.add(node);
    }

    if(level == 0) {
      res.add(genAddMealNode(parent));
    }
    else {
      res.add(genAddSuggestionNode(parent));
    }

    return res;
  }*/

  void deleteDay(Node node, FoodDay day) {
    programModel.foodDays.removeWhere((element) => element.id == day.id);
    programModel.reOrderingDec(day.ordering);

    nodeList.removeWhere((element) => element.key == node.key);

    for(final k in nodeList){
      if(k.data != null) {
        k.label = '$dayLabel ${k.data.ordering}';
      }
    }

    state.stateController.updateMain();
  }

  void repeatDay(Node upNode, FoodDay upDay, int lineNumber){
    final day = FoodDay();

    if(lineNumber >= nodeList.length) {
      day.ordering = programModel.getLastOrdering() + 1;
    }
    else {
      day.ordering = lineNumber+1; //ordering start of 1
      programModel.reOrderingInc(lineNumber);
    }

    day.mealList = repeatMeal(upDay.mealList);

    programModel.foodDays.add(day);
    programModel.sortChildren();

    final node = Node(
      label: '$dayLabel ${day.ordering}',
      key: '${Generator.generateName(8)}_${day.id}',
      data: day,
      children: <Node>[],
      expanded: true,
    );

    for(final k in nodeList){
      k.expanded = false;
      k.label = '$dayLabel ${k.data.ordering}'; //for [insert between] state
    }

    //node.children = cloneMealNodes(day.mealList, 0, node);
    node.children = buildNodes(day.mealList, 1, node);
    nodeList.insert(lineNumber, node);

    currentNodeKey = node.key;
  }

  void repeatSuggestion(Node parentNode, Node upNode, FoodSuggestion upSug, int lineNumber){
    FoodMeal meal = parentNode.data;
    final suggestion = FoodSuggestion();

    if(lineNumber >= meal.suggestionList.length) {
      suggestion.ordering = meal.getLastOrdering() + 1;
    }
    else {
      suggestion.ordering = lineNumber+1; //ordering start of 1
      meal.reOrderingInc(lineNumber);
    }

    suggestion.materialList = upSug.materialList;

    meal.suggestionList.add(suggestion);
    meal.sortChildren();

    final node = Node(
      label: '$suggestLabel ${suggestion.ordering}',
      key: '${Generator.generateName(8)}_${suggestion.id}',
      data: suggestion,
      children: <Node>[],
      expanded: true,
    );

    for(final k in parentNode.children){
      if(k.data != null) {
        k.label = '$suggestLabel ${k.data.ordering}';
      }
    }

    parentNode.children.insert(lineNumber, node);

    currentNodeKey = node.key;

    state.stateController.updateMain();

    var toastTxt = state.tInMap('treeFoodProgramPage', 'addNewSuggestionByRepeat')!;
    toastTxt = toastTxt.replaceFirst('#', '${suggestion.ordering}');
    StateXController.globalUpdate(Keys.toast, stateData: toastTxt);
  }

  void showPupilInfo(){
    AppNavigator.pushNextPage(
        state.context,
        RequestDataShowScreen(
          courseRequestModel: courseRequestModel,
          userInfo: pupilUser!,
          questionInfo: questionModel,
        ),
        name: RequestDataShowScreen.screenName
    );
  }

  void showRepeatDaysPrompt(){
    if(programModel.foodDays.length < 2){
      StateXController.globalUpdate(Keys.toast, stateData: '${state.tInMap('treeFoodProgramPage', 'mustCreateMoreThenOne')}');
      return;
    }

    int max = programModel.foodDays.length;
    int start = 1;
    int end = max;
    int rCount = 1;

    final view = SelfRefresh(
        builder: (ctx, ctr){
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${state.tInMap('treeFoodProgramPage', 'selectDaysForRepeat')}').boldFont(),

              SizedBox(height: 18,),
              Row(
                children: [
                  Text('${state.tInMap('treeFoodProgramPage', 'fromDay')}'),

                  SizedBox(width: 8,),
                  BackForwardArrow(
                    descriptionView: Text('$start'),
                    iconSize: 24,
                    onLeftClick: (ctx){
                      start++;

                      if(start >= max){
                        start--;
                      }

                      if(end <= start){
                        end = start + 1;
                      }

                      //ctr.set('start', start);
                      //ctr.set('end', end);
                      ctr.update();
                    },
                    onRightClick: (ctx){
                      start--;

                      if(start < 1){
                        start = 1;
                      }

                      //ctr.set('start', start);
                      ctr.update();
                    },
                  )
                ],
              ),

              SizedBox(height: 8,),
              Row(
                children: [
                  Text('${state.tInMap('treeFoodProgramPage', 'toDay')}'),

                  SizedBox(width: 8,),
                  BackForwardArrow(
                    descriptionView: Text('$end'),
                    iconSize: 24,
                    onLeftClick: (ctx){
                      end++;

                      if(end > max){
                        end--;
                      }

                      //ctr.set('end', end);
                      ctr.update();
                    },
                    onRightClick: (ctx){
                      end--;

                      if(end <= start){
                        end = start + 1;
                      }

                      //ctr.set('end', end);
                      ctr.update();
                    },
                  )
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: SizedBox(
                  width: 150,
                child: Divider(),
                ),
              ),

              Row(
                children: [
                  Text('${state.tInMap('treeFoodProgramPage', 'repeatCount')}'),

                  SizedBox(width: 8,),
                  BackForwardArrow(
                    descriptionView: Text('$rCount'),
                    arrowsBackColor: AppThemes.currentTheme.infoColor,
                    iconSize: 24,
                    onLeftClick: (ctx){
                      rCount++;

                      ctr.update();
                    },
                    onRightClick: (ctx){
                      rCount--;

                      if(rCount < 1){
                        rCount = 1;
                      }

                      ctr.update();
                    },
                  )
                ],
              ),
            ],
          );
        }
    );

    DialogCenter.instance.showYesNoDialog(
        state.context,
      descView: view,
      yesText: state.t('repeat'),
      noText: state.t('cancel'),
      yesFn: (){
          int ln = max;

          for(int i=0; i< rCount; i++){
            for(int i= start; i <= end; i++){
              final node = nodeList[i-1];
              final day = node.data as FoodDay;

              repeatDay(node, day, ln++);
            }
          }

          state.stateController.updateMain();
      },
    );
  }

  void showDeleteDaysPrompt(){
    if(programModel.foodDays.length < 2){
      StateXController.globalUpdate(Keys.toast, stateData: '${state.tInMap('treeFoodProgramPage', 'mustCreateMoreThenOne')}');
      return;
    }

    int max = programModel.foodDays.length;
    int start = 1;
    int end = max;

    final view = SelfRefresh(
        builder: (ctx, ctr){
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${state.tInMap('treeFoodProgramPage', 'selectDaysForDelete')}').boldFont(),

              SizedBox(height: 18,),
              Row(
                children: [
                  Text('${state.tInMap('treeFoodProgramPage', 'fromDay')}'),

                  SizedBox(width: 8,),
                  BackForwardArrow(
                    descriptionView: Text('$start'),
                    iconSize: 24,
                    onLeftClick: (ctx){
                      start++;

                      if(start >= max){
                        start--;
                      }

                      if(end <= start){
                        end = start + 1;
                      }

                      //ctr.set('start', start);
                      //ctr.set('end', end);
                      ctr.update();
                    },
                    onRightClick: (ctx){
                      start--;

                      if(start < 1){
                        start = 1;
                      }

                      //ctr.set('start', start);
                      ctr.update();
                    },
                  )
                ],
              ),

              SizedBox(height: 8,),
              Row(
                children: [
                  Text('${state.tInMap('treeFoodProgramPage', 'toDay')}'),

                  SizedBox(width: 8,),
                  BackForwardArrow(
                    descriptionView: Text('$end'),
                    iconSize: 24,
                    onLeftClick: (ctx){
                      end++;

                      if(end > max){
                        end--;
                      }

                      //ctr.set('end', end);
                      ctr.update();
                    },
                    onRightClick: (ctx){
                      end--;

                      if(end <= start){
                        end = start + 1;
                      }

                      //ctr.set('end', end);
                      ctr.update();
                    },
                  )
                ],
              ),
            ],
          );
        }
    );

    DialogCenter.instance.showYesNoDialog(
        state.context,
      descView: view,
      yesText: state.t('delete'),
      noText: state.t('cancel'),
      yesFn: (){
          var fix = 0;

          for(int i= start; i <= end; i++){
            final node = nodeList[i-1- fix];
            final day = node.data as FoodDay;

            deleteDay(node, day);
            fix++;
          }

          state.stateController.updateMain();
      },
    );
  }

  void showBaseChart(){
    proteinValue = 0;
    carValue = 0;
    fatValue = 0;
    calcChartData();

    void reCalc(){
      proteinValue = programModel.getPlanProtein()?? 0;
      carValue = programModel.getPlanCarbohydrate()?? 0;
      fatValue = programModel.getPlanFat()?? 0;
      calcChartData();
    }

    final content = GestureDetector(
      behavior: HitTestBehavior.translucent,
        child: GestureDetector(
          onTap: (){},
          child: Align(
            child: SelfRefresh(
                builder: (ctx, ctr) {
                  Future.delayed(Duration(milliseconds: 500), (){
                    if(ctr.exist('reCall')){
                      return;
                    }

                    reCalc();

                    ctr.set('reCall', true);
                    ctr.update();
                  });

                  return FractionallySizedBox(
                    widthFactor: 0.85,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(26.0, 16, 26.0, 26.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${state.tInMap('treeFoodProgramPage', 'mainValuesForAnyDayByTrainer')}')
                                .boldFont(),

                            Center(
                              child: SizedBox(
                                width: 150,
                                height: 150,
                                child: PieChart(chartData),
                              ),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TabPageSelectorIndicator(
                                      backgroundColor: Colors.lightGreenAccent.shade200,
                                      borderColor: Colors.lightGreenAccent.shade200,
                                      size: 15,
                                    ),
                                    Text('${state.tInMap('materialFundamentals', 'protein')}'),
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
                                    Text('${state.tInMap('materialFundamentals', 'carbohydrate')}'),
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
                                    Text('${state.tInMap('materialFundamentals', 'fat')}'),
                                  ],
                                ),
                              ],
                            ),

                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(indent: 30, endIndent: 30,),
                            ),

                            Text('${state.tInMap('materialFundamentals', 'calories')} : $caloriesValue').bold(),
                            Text('${state.tInMap('materialFundamentals', 'protein')} : $proteinValue').bold(),
                            Text('${state.tInMap('materialFundamentals', 'carbohydrate')} : $carValue').bold(),
                            Text('${state.tInMap('materialFundamentals', 'fat')} : $fatValue').bold(),

                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                child: Text('${state.tInMap('treeFoodProgramPage', 'resetPcl')}'),//.color(Colors.white),
                                onPressed: (){
                                  AppNavigator.pop(state.context);
                                  resetCaloriesPrompt();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
            ),
          ),
        ),
        onTap: (){
          AppNavigator.pop(state.context);
        },
    );

    final dialog = OverlayScreenView(content: content, routingName: 'charDialog',);
    OverlayDialog().show(state.context, dialog, canBack: true, background: Colors.black54);
  }

  void calcChartData(){
    final sections = <PieChartSectionData>[];
    final pro = (proteinValue *4);
    final car = (carValue *4);
    final fat = (fatValue *9);
    caloriesValue = fat + pro + car;

    final proPercent = MathHelper.percentFix(caloriesValue.toDouble(), pro);
    final carPercent = MathHelper.percentFix(caloriesValue.toDouble(), car);
    final fatPercent = MathHelper.percentFix(caloriesValue.toDouble(), fat);

    final p = PieChartSectionData(
      title: '',
      value: pro.toDouble(),
      color: Colors.lightGreenAccent.shade200,
      radius: 60,
      badgeWidget: Text('$proPercent %'),
    );

    final c = PieChartSectionData(
      title: '',
      value: car.toDouble(),
      color: Colors.lightBlue.shade200,
      radius: 60,
      badgeWidget: Text('$carPercent %'),
    );

    final l = PieChartSectionData(
      title: '',
      value: fat.toDouble(),
      color: Colors.redAccent.shade200,
      radius: 60,
      badgeWidget: Text('$fatPercent %'),
    );

    final empty = PieChartSectionData(
      title: '',
      value: 100.0,
      color: Colors.grey.shade300,
      radius: 60,
    );

    sections.add(l);
    sections.add(p);
    sections.add(c);

    if(caloriesValue < 5) {
      sections.add(empty);
    }

    chartData = PieChartData(
      sections: sections,
      borderData: FlBorderData(border: Border.all(color: Colors.transparent)),
      centerSpaceColor: Colors.black,
      centerSpaceRadius: 0,
      sectionsSpace: 0,
      pieTouchData: PieTouchData(),
    );
  }

  void uploadData() async {
    //FocusHelper.hideKeyboardByUnFocus(state.context);
    
    if(programModel.foodDays.isEmpty){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('treeFoodProgramPage', 'haveNotAnyDay')}');
      return;
    }
    
    if(programModel.hasEmptyDay()){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('treeFoodProgramPage', 'someDaysHaveNotSuggestion')}');
      return;
    }

    if(programHash == programModel.hashCode) {
      SheetCenter.showSheet$SuccessOperation(state.context);
      return;
    }

    final js = <String, dynamic>{};

    js[Keys.request] = 'UpdateFoodProgramDays';
    js[Keys.userId] = user.userId;
    js['program_id'] = programModel.id;
    js['days'] = programModel.daysToMap();

    commonRequester.requestPath = RequestPath.SetData;
    commonRequester.bodyJson = js;
    
    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
      //state.StateXController.mainStateAndUpdate(StateXController.state$netDisconnect);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      programHash = programModel.hashCode;
      programOriginal = programModel.daysToMap();

      await SheetCenter.showSheet$SuccessOperation(state.context);
    };

    state.showLoading();
    commonRequester.request(state.context);
  }
}
///=================================================================================
class ExpanderWrap extends StatelessWidget {
  final ExpanderModifier modifier;

  const ExpanderWrap(this.modifier, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double _borderWidth = 0;
    BoxShape _shapeBorder = BoxShape.rectangle;
    Color _backColor = Colors.transparent;
    Color _backAltColor = Colors.grey.shade700;

    switch (modifier) {
      case ExpanderModifier.none:
        break;
      case ExpanderModifier.circleFilled:
        _shapeBorder = BoxShape.circle;
        _backColor = _backAltColor;
        break;
      case ExpanderModifier.circleOutlined:
        _borderWidth = 1;
        _shapeBorder = BoxShape.circle;
        break;
      case ExpanderModifier.squareFilled:
        _backColor = _backAltColor;
        break;
      case ExpanderModifier.squareOutlined:
        _borderWidth = 1;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        shape: _shapeBorder,
        border: _borderWidth == 0
            ? null
            : Border.all(
          width: _borderWidth,
          color: _backAltColor,
        ),
        color: _backColor,
      ),
      width: 15,
      height: 15,
    );
  }
}

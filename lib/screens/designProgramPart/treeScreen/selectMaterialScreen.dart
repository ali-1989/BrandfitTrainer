import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/programModels/foodDay.dart';
import '/models/dataModels/programModels/foodMeal.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/models/dataModels/programModels/fundamentalTypes.dart';
import '/screens/designProgramPart/treeScreen/selectMaterialCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appThemes.dart';

class SelectMaterialScreen extends StatefulWidget {
  static const screenName = 'SelectMaterialScreen';
  final FoodProgramModel foodProgram;
  final FoodDay foodDay;
  final FoodMeal foodMeal;
  final FoodSuggestion foodSuggestion;

  const SelectMaterialScreen({
    required this.foodProgram,
    required this.foodDay,
    required this.foodMeal,
    required this.foodSuggestion,
    Key? key,
  }) : super(key: key);

  @override
  State<SelectMaterialScreen> createState() => SelectMaterialScreenState();
}
///================================================================================================
class SelectMaterialScreenState extends StateBase<SelectMaterialScreen> {
  StateXController stateController = StateXController();
  SelectMaterialCtr controller = SelectMaterialCtr();


  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    controller.onBuild();

    return Scaffold(
      //appBar: getAppBar(),
      body: StateX(
        controller: stateController,
        isMain: true,
        builder: (context, ctr, data) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 85,
                left: 0,
                right: 0,
                bottom: 0,
                child: Builder(
                  builder: (context) {
                    if(controller.foodDay.sumFundamentalInt(FundamentalTypes.calories) < 1){
                      return Center(
                        child: Text('${tInMap('treeFoodProgramPage', 'searchAndAddMaterial')}')
                            .boldFont().alpha(),
                      );
                    }

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: PieChart(controller.chartData),
                              ),

                              SizedBox(width: 16,),
                              DataTable(
                                columnSpacing: 8,
                                horizontalMargin: 0,
                                dividerThickness: 0,
                                  checkboxHorizontalMargin: 0,
                                  dataRowHeight: 20,
                                  headingRowHeight: 20,
                                headingTextStyle: AppThemes.baseTextStyle(),
                                  dataTextStyle: AppThemes.subTextStyle(),

                                headingRowColor: MaterialStateProperty.all(Colors.transparent),
                                dataRowColor: MaterialStateProperty.all(Colors.transparent),
                                //minWidth: 600,
                                columns: [
                                  DataColumn(
                                    label: Text('    '),
                                  ),
                                  DataColumn(
                                    label: Text('وعده'),
                                    //size: ColumnSize.L,
                                  ),
                                  DataColumn(
                                    label: Text('وعده ها'),
                                  ),
                                  DataColumn(
                                    label: Text('حد مجاز'),
                                  ),
                                ],
                                rows:[
                                  DataRow(
                                    cells: [
                                      DataCell(Text('${tInMap('materialFundamentals', 'calories')}')
                                          .subFont().bold()),
                                      DataCell(Text('${controller.foodSuggestion.sumFundamentalInt(FundamentalTypes.calories)}')),
                                      DataCell(Text('${controller.foodDay.sumFundamentalInt(FundamentalTypes.calories, suggestionId: controller.foodSuggestion.id)}')),
                                      DataCell(Text('${controller.foodProgram.getPlanCalories()}')),
                                    ],
                                    color: MaterialStateProperty.all(Colors.grey.shade200),
                                  ),
                                  DataRow(
                                      cells: [
                                        DataCell(Text('${tInMap('materialFundamentals', 'protein')}')
                                            .subFont().color(Colors.green)),
                                        DataCell(Text('${controller.foodSuggestion.sumFundamentalInt(FundamentalTypes.protein)}')),
                                        DataCell(Text('${controller.foodDay.sumFundamentalInt(FundamentalTypes.protein, suggestionId: controller.foodSuggestion.id)}')),
                                        DataCell(Text('${controller.foodProgram.getPlanProtein()}'),),
                                      ]
                                  ),
                                  DataRow(
                                    cells: [
                                      DataCell(Text('${tInMap('materialFundamentals', 'carbohydrate')}')
                                          .subFont().color(Colors.lightBlue.shade800)),
                                      DataCell(Text('${controller.foodSuggestion.sumFundamentalInt(FundamentalTypes.carbohydrate)}')),
                                      DataCell(Text('${controller.foodDay.sumFundamentalInt(FundamentalTypes.carbohydrate, suggestionId: controller.foodSuggestion.id)}')),
                                      DataCell(Text('${controller.foodProgram.getPlanCarbohydrate()}')),
                                    ],
                                    color: MaterialStateProperty.all(Colors.grey.shade200),
                                  ),
                                  DataRow(
                                      cells: [
                                        DataCell(Text('${tInMap('materialFundamentals', 'fat')}')
                                            .subFont().color(Colors.redAccent.shade200)),
                                        DataCell(Text('${controller.foodSuggestion.sumFundamentalInt(FundamentalTypes.fat)}')),
                                        DataCell(Text('${controller.foodDay.sumFundamentalInt(FundamentalTypes.fat, suggestionId: controller.foodSuggestion.id)}')),
                                        DataCell(Text('${controller.foodProgram.getPlanFat()}')),
                                      ]
                                  ),
                                ]
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 120,
                          child: ColoredBox(
                              color: Colors.blueGrey.shade100,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                ),
                                Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${tInMap('selectMaterialPage', 'thisMealQu')}'),
                                        Expanded(
                                          child: RotatedBox(
                                              quarterTurns: 3,
                                              child: genThisBar()
                                          ),
                                        ),
                                      ],
                                    ),
                                ),

                                SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${tInMap('selectMaterialPage', 'allMealQu')}'),
                                        Expanded(
                                          child: RotatedBox(
                                              quarterTurns: 3,
                                              child: genMealsBar()
                                          ),
                                        ),
                                      ],
                                    ),
                                ),
                                SizedBox(
                                  width: 4,
                                ),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          child: ListView.builder(
                              itemCount: controller.foodSuggestion.materialList.length,
                              shrinkWrap: true,
                              itemBuilder: (ctx, idx){
                                return genListItem(idx);
                              }
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),

              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 85,
                  width: double.infinity,
                  child: ColoredBox(
                    color: AppThemes.currentTheme.appBarBackColor,
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: getSearchBar(),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  PreferredSizeWidget getAppBar(){
    return AppBar();
  }

  Widget getSearchBar(){
    return FloatingSearchBar(
      hint: '${t('search')}...',
      controller: controller.searchBarCtr,
      scrollPadding: const EdgeInsets.only(top: 20, bottom: 30),
      transitionDuration: const Duration(milliseconds: 500),
      debounceDelay: const Duration(milliseconds: 800),//delay char type to call query
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: 0.0,
      openAxisAlignment: 0.0,
      automaticallyImplyBackButton: true,
      clearQueryOnClose: true,
      closeOnBackdropTap: true,
      progress: controller.showProgress,
      onQueryChanged: (query) {
        controller.requestSearchFood(query);
      },
      //transition: CircularFloatingSearchBarTransition(),
      transition: SlideFadeFloatingSearchBarTransition(),
      actions: [
        /*FloatingSearchBarAction(
          showIfOpened: false,
          child: CircularButton(
            icon: Icon(IconList.close),
            onPressed: () {
              //controller.showSearchbar = false;
              stateController.updateMain();
            },
          ),
        ),
        FloatingSearchBarAction.searchToClear(
          showIfClosed: false,
        ),*/
        IconButton(
            onPressed: (){
              controller.gotoAddMaterial();
            },
            icon: Icon(IconList.addCircle)),
      ],
      builder: (context, transition) {
        if(controller.foodMaterialList.isEmpty){
          return SizedBox();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Material(
            color: Colors.white,
            elevation: 4.0,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.foodMaterialList.length,
                itemBuilder: (ctx, idx){
                  return genSearchItem(idx);
                }
            ),
          ),
        );
      },
    );
  }

  Widget genSearchItem(int idx){
    final material = controller.foodMaterialList[idx];

    return GestureDetector(
      onTap: (){
        controller.onClickOnMaterial(material);
      },
      child: Card(
          color: AppThemes.currentTheme.accentColor,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${material.matchTitle}')
                        .fsR(6).bold()
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor),
                    SizedBox(height: 8,),
                    Text(material.getMainFundamentalsPrompt(context))
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),
                  ],
                ),

                SizedBox(height: 2,),
                Column(
                  children: [
                    Text('${material.getTypeTranslate(context)}')
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppThemes.currentTheme.whiteOrAppBarItemOnDifferent()),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.all(4),
                      child: Column(
                        children: [
                          Text(material.measure.unitValue)
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),

                          Text('${tInMap('materialUnits', material.measure.unit)}')
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
      ),
    );
  }

  Widget genListItem(int idx){
    final material = controller.foodSuggestion.materialList[idx];

    return GestureDetector(
      onTap: (){
        controller.showEditMaterialValuePrompt(material);
      },
      child: Card(
          color: AppThemes.currentTheme.accentColor,
          child: Padding(
            padding: EdgeInsets.all(7.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('${material.material?.matchTitle}')
                              .fsR(5).bold()
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor),

                          SizedBox(width: 16,),
                          Text('${material.materialValue}')
                              .fsR(2).subFont()
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor),

                          Text(' ${tInMap('materialUnits', material.material!.measure.unit)}')
                              .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor),
                        ],
                      ),
                      SizedBox(height: 8,),
                      Text(material.material!.getMainFundamentalsPromptFor(context, material.materialValue))
                          .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),
                    ],
                  ),
                ),

                SizedBox(width: 2,),

                IconButton(
                    onPressed: (){
                      controller.promptDeleteMaterial(material);
                    },
                    icon: Icon(IconList.remove, color: Colors.white,)
                ),
              ],
            ),
          )
      ),
    );
  }

  Widget genThisBar(){
    return BarChart(controller.thisCaloriesBarData);
  }

  Widget genMealsBar(){
    return BarChart(controller.mealsCaloriesBarData);
  }
}

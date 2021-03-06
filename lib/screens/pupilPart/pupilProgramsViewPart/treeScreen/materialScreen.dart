import 'package:brandfit_trainer/models/dataModels/foodModels/materialWithValueModel.dart';
import 'package:brandfit_trainer/screens/pupilPart/pupilProgramsViewPart/treeScreen/materialCtr.dart';
import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/programModels/foodDay.dart';
import '/models/dataModels/programModels/foodMeal.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/models/dataModels/programModels/fundamentalTypes.dart';
import '/system/extensions.dart';
import '/tools/app/appThemes.dart';

class MaterialScreen extends StatefulWidget {
  static const screenName = 'SelectMaterialScreen';
  final FoodProgramModel foodProgram;
  final FoodDay foodDay;
  final FoodMeal foodMeal;
  final FoodSuggestion foodSuggestion;

  const MaterialScreen({
    required this.foodProgram,
    required this.foodDay,
    required this.foodMeal,
    required this.foodSuggestion,
    Key? key,
  }) : super(key: key);

  @override
  State<MaterialScreen> createState() => MaterialScreenState();
}
///================================================================================================
class MaterialScreenState extends StateBase<MaterialScreen> {
  StateXController stateController = StateXController();
  SelectMaterialCtr controller = SelectMaterialCtr();


  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();
    controller.onBuild();

    return StateX(
        controller: stateController,
        isMain: true,
        builder: (context, ctr, data) {
        return Scaffold(
          appBar: getAppBar(),
          body: SafeArea(
              child: getBuilder()
          ),
        );
      }
    );
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  PreferredSizeWidget getAppBar(){
    final dayLabel = tInMap('treeFoodProgramPage', 'day')!;
    //final mealLabel = tInMap('treeFoodProgramPage', 'meal')!;
    final suggestLabel = tInMap('treeFoodProgramPage', 'suggestion')!;

    final dayText = '$dayLabel ${widget.foodDay.ordering}';
    final suggestionText = '$suggestLabel ${widget.foodSuggestion.ordering}';
    var suggestionLabel = '';

    if(widget.foodSuggestion.title != null) {
      suggestionLabel = '(${widget.foodSuggestion.title})';
    }

    var title = '$dayText - ${widget.foodMeal.title?? ''} - $suggestionText $suggestionLabel';

    return AppBar(
      title: Text(title),
    );
  }

  Widget getBuilder(){
    return Builder(
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: PieChart(controller.chartData),
                    ),

                    SizedBox(width: 16,),

                    Expanded(
                      child: SizedBox(
                        height: 100,
                          child: genThisBar()
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                            label: Text('???????? ??????'),
                            //size: ColumnSize.L,
                          ),
                          DataColumn(
                            label: Text('???? ????????'),
                          ),
                        ],
                        rows:[
                          DataRow(
                            cells: [
                              DataCell(Text('${tInMap('materialFundamentals', 'calories')}')
                                  .subFont().bold()),
                              DataCell(Text('${controller.foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.calories)}')),
                              DataCell(Text('${controller.foodProgram.getPlanCalories()}')),
                            ],
                            color: MaterialStateProperty.all(Colors.grey.shade200),
                          ),
                          DataRow(
                              cells: [
                                DataCell(Text('${tInMap('materialFundamentals', 'protein')}')
                                    .subFont().color(Colors.lightGreenAccent.shade700)),
                                DataCell(Text('${controller.foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.protein)}')),
                                DataCell(Text('${controller.foodProgram.getPlanProtein()}'),),
                              ]
                          ),
                          DataRow(
                            cells: [
                              DataCell(Text('${tInMap('materialFundamentals', 'carbohydrate')}')
                                  .subFont().color(Colors.lightBlue.shade800)),
                              DataCell(Text('${controller.foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.carbohydrate)}')),
                              DataCell(Text('${controller.foodProgram.getPlanCarbohydrate()}')),
                            ],
                            color: MaterialStateProperty.all(Colors.grey.shade200),
                          ),
                          DataRow(
                              cells: [
                                DataCell(Text('${tInMap('materialFundamentals', 'fat')}')
                                    .subFont().color(Colors.redAccent.shade200)),
                                DataCell(Text('${controller.foodSuggestion.sumUsedFundamentalInt(FundamentalTypes.fat)}')),
                                DataCell(Text('${controller.foodProgram.getPlanFat()}')),
                              ]
                          ),
                        ]
                    ),
                  ],
                ),

                SizedBox(height: 10,),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      if(controller.isNotReport){
                        return ListView.builder(
                            itemCount: controller.foodSuggestion.materialList.length,
                            shrinkWrap: true,
                            itemBuilder: (ctx, idx){
                              return genListItem(idx);
                            }
                        );
                      }

                      return ListView.builder(
                          itemCount: controller.foodSuggestion.usedMaterialList.length,
                          shrinkWrap: true,
                          itemBuilder: (ctx, idx){
                            return genListItemInReportState(idx);
                          }
                      );
                    }
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  Widget genListItem(int idx){
    final material = controller.foodSuggestion.materialList[idx];

    return Card(
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
            ],
          ),
        )
    );
  }

  Widget genListItemInReportState(int idx){
    final material = controller.foodSuggestion.usedMaterialList[idx];
    MaterialWithValueModel? orgMaterial;

    final orgIdx = controller.foodSuggestion.materialList
        .indexWhere((element) => element.materialId == material.materialId);

    final hasOriginal = orgIdx > -1;

    if(hasOriginal){
      orgMaterial = controller.foodSuggestion.materialList[orgIdx];
    }

    return Card(
        color: hasOriginal? AppThemes.currentTheme.accentColor : Colors.orangeAccent,
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

                        SizedBox(width: 30,),
                        Text('${orgMaterial?.materialValue?? '--'}')
                            .fsR(2).subFont()
                            .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor)
                        .wrapBoxBorder(
                            color: Colors.white,
                          radius: 2,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),

                        SizedBox(width: 14,),
                        Text('-->').color(Colors.white),

                        SizedBox(width: 14,),
                        Text('${material.materialValue}')
                            .fsR(2).subFont()
                            .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor)
                        .wrapBoxBorder(
                            color: Colors.white,
                          radius: 2,
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),

                        SizedBox(width: 6),
                        Text(' ${tInMap('materialUnits', material.material!.measure.unit)}')
                            .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor),

                        SizedBox(width: 6),
                      ],
                    ),
                    SizedBox(height: 8,),
                    Text(material.material!.getMainFundamentalsPromptFor(context, material.materialValue))
                        .whiteOrAppBarItemOn(AppThemes.currentTheme.accentColor).subFont(),
                  ],
                ),
              ),

              SizedBox(width: 2,),

            ],
          ),
        )
    );
  }

  Widget genThisBar(){
    return BarChart(controller.barChartData);
  }
}

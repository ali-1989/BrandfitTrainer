import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

import '/abstracts/viewController.dart';
import '/managers/foodMaterialManager.dart';
import '/models/dataModels/foodModels/materialModel.dart';
import '/models/dataModels/foodModels/materialWithValueModel.dart';
import '/models/dataModels/programModels/foodDay.dart';
import '/models/dataModels/programModels/foodMeal.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/programModels/foodSuggestion.dart';
import '/models/dataModels/programModels/fundamentalTypes.dart';
import '/screens/commons/topInputFieldScreen.dart';
import '/screens/designProgramPart/treeScreen/addMaterial/AddMaterialScreen.dart';
import '/screens/designProgramPart/treeScreen/selectMaterialScreen.dart';
import '/system/extensions.dart';
import '/system/keys.dart';
import '/system/queryFiltering.dart';
import '/system/requester.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';

class SelectMaterialCtr implements ViewController {
  late SelectMaterialScreenState state;
  late Requester commonRequester;
  late FloatingSearchBarController searchBarCtr;
  List<MaterialModel> foodMaterialList = [];
  bool showProgress = false;
  late FilterRequest filterRequest;
  late FoodProgramModel foodProgram;
  late FoodDay foodDay;
  late FoodMeal foodMeal;
  late FoodSuggestion foodSuggestion;
  late BarChartData thisCaloriesBarData;
  late BarChartData mealsCaloriesBarData;
  late PieChartData chartData;
  int proteinValue = 0;
  int carValue = 0;
  int fatValue = 0;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as SelectMaterialScreenState;

    filterRequest = FilterRequest();
    filterRequest.limit = 100;

    commonRequester = Requester();

    foodProgram = state.widget.foodProgram;
    foodDay = state.widget.foodDay;
    foodMeal = state.widget.foodMeal;
    foodSuggestion = state.widget.foodSuggestion;

    searchBarCtr = FloatingSearchBarController();

    prepareFilterOptions();
    calcChartData();
    calcThisBarChartsData();
    calcAllMealsBarChartsData();
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
  }

  void prepareFilterOptions(){
    filterRequest.addSearchView(SearchKeys.titleKey);
  }
  ///========================================================================================================
  void gotoAddMaterial(){
    AppNavigator.pushNextPage(
        state.context,
        AddFoodMaterialScreen(),
        name: AddFoodMaterialScreen.screenName
    );
  }

  void calcThisBarChartsData(){
    final groups = <BarChartGroupData>[];

    final caloriesGRods = <BarChartRodData>[];
    final proteinGRods = <BarChartRodData>[];
    final carGRods = <BarChartRodData>[];
    final fatGRods = <BarChartRodData>[];

    final caloriesPercent = MathHelper.percent(
        foodProgram.getPlanCalories()!.toDouble(), foodSuggestion.sumFundamentalInt(FundamentalTypes.calories));

    final proteinPercent = MathHelper.percent(
        foodProgram.getPlanProtein()!.toDouble(), foodSuggestion.sumFundamentalInt(FundamentalTypes.protein));

    final carbohydratePercent = MathHelper.percent(
        foodProgram.getPlanCarbohydrate()!.toDouble(), foodSuggestion.sumFundamentalInt(FundamentalTypes.carbohydrate));

    final fatPercent = MathHelper.percent(
        foodProgram.getPlanFat()!.toDouble(), foodSuggestion.sumFundamentalInt(FundamentalTypes.fat));

    final caloriesBar = BarChartRodData(
      y: MathHelper.minDouble(caloriesPercent, 100),
      colors: [caloriesPercent > 100 ? Colors.red: Colors.blue.shade900],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade100],
      ),
    );

    final proteinBar = BarChartRodData(
      y: MathHelper.minDouble(proteinPercent, 100),
      colors: [proteinPercent > 100 ? Colors.red: Colors.blue],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade100],
      ),
    );

    final carBar = BarChartRodData(
      y: MathHelper.minDouble(carbohydratePercent, 100),
      colors: [carbohydratePercent > 100 ? Colors.red: Colors.blue],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade100],
      ),
    );

    final fatBar = BarChartRodData(
      y: MathHelper.minDouble(fatPercent, 100),
      colors: [fatPercent > 100 ? Colors.red: Colors.blue],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade100],
      ),
    );

    caloriesGRods.add(caloriesBar);
    proteinGRods.add(proteinBar);
    carGRods.add(carBar);
    fatGRods.add(fatBar);

    final caloriesG = BarChartGroupData(
      x: 1,
      barRods: caloriesGRods,
    );

    final proteinG = BarChartGroupData(
      x: 2,
      barRods: proteinGRods,
    );

    final carG = BarChartGroupData(
      x: 3,
      barRods: carGRods,
    );

    final fatG = BarChartGroupData(
      x: 4,
      barRods: fatGRods,
    );

    groups.add(fatG);
    groups.add(carG);
    groups.add(proteinG);
    groups.add(caloriesG);

    thisCaloriesBarData = BarChartData(
      barGroups: groups,
      minY: 0,
      maxY: 100,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        checkToShowHorizontalLine: (v)=> true,
        drawVerticalLine: false,
        horizontalInterval: 10,
      ),
      //axisTitleData: FlAxisTitleData(show: false),
      titlesData: FlTitlesData(
          show: true,
        leftTitles: SideTitles(showTitles: false),
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
            showTitles: false,
            rotateAngle: 45,
          getTextStyles: (context, value){
              if(value.toInt() == 1){
                return AppThemes.boldTextStyle();
              }

              return AppThemes.subTextStyle();//009688
          },
          getTitles: (double axis){
              switch(axis.toInt()){
                case 1:
                  return 'کالری';
                case 2:
                  return 'پروتئین';
                case 3:
                  return 'کربو';
                case 4:
                  return 'چربی';
              }

              return '';
          }
        ),
      ),
    );
  }

  void calcAllMealsBarChartsData(){
    final groups = <BarChartGroupData>[];

    final caloriesGRods = <BarChartRodData>[];
    final proteinGRods = <BarChartRodData>[];
    final carGRods = <BarChartRodData>[];
    final fatGRods = <BarChartRodData>[];

    final caloriesPercent = MathHelper.percent(
        foodProgram.getPlanCalories()!.toDouble(), foodDay.sumFundamentalInt(FundamentalTypes.calories, suggestionId: foodSuggestion.id));

    final proteinPercent = MathHelper.percent(
        foodProgram.getPlanProtein()!.toDouble(), foodDay.sumFundamentalInt(FundamentalTypes.protein, suggestionId: foodSuggestion.id));

    final carbohydratePercent = MathHelper.percent(
        foodProgram.getPlanCarbohydrate()!.toDouble(), foodDay.sumFundamentalInt(FundamentalTypes.carbohydrate, suggestionId: foodSuggestion.id));

    final fatPercent = MathHelper.percent(
        foodProgram.getPlanFat()!.toDouble(), foodDay.sumFundamentalInt(FundamentalTypes.fat, suggestionId: foodSuggestion.id));

    final caloriesBar = BarChartRodData(
      y: MathHelper.minDouble(caloriesPercent, 100),
      colors: [caloriesPercent > 100 ? Colors.red: Colors.blue.shade900],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade100],
      ),
    );

    final proteinBar = BarChartRodData(
      y: MathHelper.minDouble(proteinPercent, 100),
      colors: [proteinPercent > 100 ? Colors.red: Colors.blue],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade100],
      ),
    );

    final carBar = BarChartRodData(
      y: MathHelper.minDouble(carbohydratePercent, 100),
      colors: [carbohydratePercent > 100 ? Colors.red: Colors.blue],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade100],
      ),
    );

    final fatBar = BarChartRodData(
      y: MathHelper.minDouble(fatPercent, 100),
      colors: [fatPercent > 100 ? Colors.red: Colors.blue],
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        y: 100,
        colors: [Colors.grey.shade100],
      ),
    );

    caloriesGRods.add(caloriesBar);
    proteinGRods.add(proteinBar);
    carGRods.add(carBar);
    fatGRods.add(fatBar);

    final caloriesG = BarChartGroupData(
      x: 1,
      barRods: caloriesGRods,
    );

    final proteinG = BarChartGroupData(
      x: 2,
      barRods: proteinGRods,
    );

    final carG = BarChartGroupData(
      x: 3,
      barRods: carGRods,
    );

    final fatG = BarChartGroupData(
      x: 4,
      barRods: fatGRods,
    );

    groups.add(fatG);
    groups.add(carG);
    groups.add(proteinG);
    groups.add(caloriesG);

    mealsCaloriesBarData = BarChartData(
      barGroups: groups,
      minY: 0,
      maxY: 100,
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        checkToShowHorizontalLine: (v)=> true,
        drawVerticalLine: false,
        horizontalInterval: 10,
      ),
      axisTitleData: FlAxisTitleData(show: false),
      titlesData: FlTitlesData(
        show: false,
        leftTitles: SideTitles(showTitles: false),
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
            showTitles: false,
            rotateAngle: 45,
            getTextStyles: (context, value){
              if(value.toInt() == 1){
                return AppThemes.boldTextStyle();
              }

              return AppThemes.subTextStyle();//009688
            },
            getTitles: (double axis){
              switch(axis.toInt()){
                case 1:
                  return 'کالری';
                case 2:
                  return 'پروتئین';
                case 3:
                  return 'کربو';
                case 4:
                  return 'چربی';
              }

              return '';
            }
        ),
      ),
    );
  }

  void calcChartData(){
    proteinValue = foodSuggestion.sumFundamentalInt(FundamentalTypes.protein);
    carValue = foodSuggestion.sumFundamentalInt(FundamentalTypes.carbohydrate);
    fatValue = foodSuggestion.sumFundamentalInt(FundamentalTypes.fat);

    final sections = <PieChartSectionData>[];
    final pro = (proteinValue *4);
    final car = (carValue *4);
    final fat = (fatValue *9);
    int sumCalories = fat + pro + car;

    final proPercent = MathHelper.percentFix(sumCalories.toDouble(), pro);
    final carPercent = MathHelper.percentFix(sumCalories.toDouble(), car);
    final fatPercent = MathHelper.percentFix(sumCalories.toDouble(), fat);

    final p = PieChartSectionData(
      title: '',
      value: pro.toDouble(),
      color: Colors.lightGreenAccent.shade200,
      radius: 48,
      badgeWidget: Text('$proPercent %').subFont(),
    );

    final c = PieChartSectionData(
      title: '',
      value: car.toDouble(),
      color: Colors.lightBlue.shade200,
      radius: 48,
      badgeWidget: Text('$carPercent %').subFont(),
    );

    final l = PieChartSectionData(
      title: '',
      value: fat.toDouble(),
      color: Colors.redAccent.shade200,
      radius: 48,
      badgeWidget: Text('$fatPercent %').subFont(),
    );

    final empty = PieChartSectionData(
      title: '',
      value: 100.0,
      color: Colors.grey.shade300,
      radius: 48,
    );

    sections.add(l);
    sections.add(p);
    sections.add(c);

    if(sumCalories < 5) {
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

  void promptDeleteMaterial(MaterialWithValueModel material){
    DialogCenter.instance.showYesNoDialog(
      state.context,
      desc: state.t('wantToDeleteThisItem')!,
      yesText: state.t('yes'),
      noText: state.t('no'),
      yesFn: (){
        deleteMaterial(material.materialId);
      },
    );
  }

  void deleteMaterial(int materialId){
    foodSuggestion.materialList.removeWhere((element) => element.materialId == materialId);

    reDraw();
  }

  void reDraw(){
    calcChartData();
    calcThisBarChartsData();
    calcAllMealsBarChartsData();
    state.stateController.updateMain();
  }

  void onClickOnMaterial(MaterialModel material){
    FocusHelper.hideKeyboardByService();

    for(final mat in foodSuggestion.materialList) {
      if (mat.materialId == material.id) {
        StateXController.globalUpdate(Keys.toast, stateData: '${state.t('thisItemExistInBasket')}');
        return;
      }
    }

    final des = state.t('enterValueOfThisMaterial')?.replaceFirst(RegExp('#'), material.matchTitle?? material.orgTitle);

    AppNavigator.pushNextTransparentPage(
        state.context,
        TopInputFieldScreen(
          description: des,
          textInputType: TextInputType.number,),
        name: TopInputFieldScreen.screenName).then((value) {
          int val = MathHelper.clearToInt(value);

          if(val > 0){
            foodMaterialList.clear();
            searchBarCtr.close();

            addMaterialToSuggestion(material, val);
            FoodMaterialManager.addItem(material);
            FoodMaterialManager.sinkItems([material]);

            reDraw();
          }
        });
  }

  void addMaterialToSuggestion(MaterialModel material, int val){
    final mw = MaterialWithValueModel();
    mw.material = material;
    mw.materialValue = val;
    mw.unit = material.measure.unit;

    foodSuggestion.materialList.add(mw);
  }

  void showEditMaterialValuePrompt(MaterialWithValueModel material){
    final des = state.t('enterValueOfThisMaterial')?.replaceFirst(RegExp('#'),
        material.material!.matchTitle?? material.material!.orgTitle);

    AppNavigator.pushNextTransparentPage(
        state.context,
        TopInputFieldScreen(
          description: des,
          textInputType: TextInputType.number,
          hint: '${material.materialValue}',
        ),
        name: TopInputFieldScreen.screenName
    )
        .then((value) {
          int val = MathHelper.clearToInt(value);

          if(val > 0){
            material.materialValue = val;

            reDraw();
          }
    });
  }

  void requestSearchFood(String searchText) {
    foodMaterialList.clear();

    if(searchText.length < 2){
      showProgress = false;
      state.stateController.updateMain();
      return;
    }

    filterRequest.setTextToSelectedSearch(searchText);

    final js = <String, dynamic>{};
    js[Keys.request] = 'SearchOnFoodMaterial';
    js[Keys.filtering] = filterRequest.toMap();

    commonRequester.requestPath = RequestPath.GetData;
    commonRequester.bodyJson = js;

    commonRequester.httpRequestEvents.onFailState = (req) async {
      showProgress = false;
      state.stateController.updateMain();
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      showProgress = false;

      List? list = data[Keys.resultList];
      //String? domain = data[Keys.domain];

      if(list != null) {
        for (final row in list) {
          final r = MaterialModel.fromMap(row);

          foodMaterialList.add(r);
        }
      }

      state.stateController.updateMain();
    };

    showProgress = true;
    state.stateController.updateMain();
    commonRequester.request(state.context);
  }
}

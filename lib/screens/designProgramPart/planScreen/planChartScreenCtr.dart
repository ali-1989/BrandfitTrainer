import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/dateSection/dateHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:simple_html_css/simple_html_css.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/designProgramPart/planScreen/planChartScreen.dart';
import '/screens/designProgramPart/treeScreen/treeScreen.dart';
import '/system/extensions.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appThemes.dart';
import '/tools/bmiTools.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/infoDisplayCenter.dart';
import '/tools/centers/sheetCenter.dart';
import '/tools/centers/snackCenter.dart';

class PlanChartScreenCtr implements ViewController {
  late PlanChartScreenState state;
  Requester? commonRequester;
  late UserModel user;
  late CourseModel courseModel;
  late PieChartData chartData;
  RadioType radioType = RadioType.pro;
  int proteinValue = 0;
  int fatValue = 0;
  int carbohydrateValue = 0;
  int caloriesValue = 0;
  int caloriesStart = 0;
  int ffm = 0;
  int age = 0;
  double bmr = 0;
  double tdee = 0;


  @override
  void onInitState<E extends State>(E state){
    this.state = state as PlanChartScreenState;

    user = Session.getLastLoginUser()!;

    commonRequester = Requester();
    calcValues();
    calcChartData();
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
    if(state is PlanChartScreenState) {
      state.stateController.mainStateAndUpdate(StateXController.state$loading);
    }
  }

  void showHelpView(){
    final style = AppThemes.baseTextStyle();

    InfoDisplayCenter.showMiniInfo(
        state.context,
        HTML.toRichText(state.context,
          state.tJoin('foodProgramChartDescriptions')!,
          defaultTextStyle: AppThemes.baseTextStyle(),
          overrideStyle:{
            'h1': style.copyWith(
                fontFamily: AppThemes.currentTheme.boldTextStyle.fontFamily,
              fontSize: style.fontSize!+2,
            ),
            'span': style.copyWith(
                fontFamily: AppThemes.currentTheme.boldTextStyle.fontFamily,
              color: AppThemes.currentTheme.infoColor,
            ),
          }
        ),
        //bottom: (AppSizes.getScreenHeight(ctx) - ctr.getPositionY()!) + 20,
        center: true,
    );
  }

  void calcValues(){
    final qm = state.widget.questionModel;
    age = DateHelper.calculateAge(qm.birthdate);

    bmr = BmiTools.calculateBmr(
      qm.height,
      qm.weight,
      age,
      qm.sex,
    );

    final job = <String, double>{
      'jobless' : 1.2,
      'lightWork' : 1.3,
      'balancedWork' : 1.5,
      'hardWork' : 1.9,
    };

    final workMan = <String, double>{
      'inactive' : 31,
      'littleActive' : 38,
      'active' : 41,
      'veryActive' : 50,
    };

    final workWoman = <String, double>{
      'inactive' : 30,
      'littleActive' : 35,
      'active' : 37,
      'veryActive' : 45,
    };

    tdee = bmr * (job[qm.jobType] ?? 1);
    tdee += (qm.sex == 1? workMan[qm.noneWorkActivity] : workWoman[qm.noneWorkActivity])?? 0;

    if(qm.exerciseHours >= 4 && qm.exerciseHours <= 8){
      tdee += 150;
    }

    else if(qm.exerciseHours > 8){
      tdee += 200;
    }
  }

  void calcPCL(){
    var dif = caloriesValue - caloriesStart;

    if(dif == 0){
      return;
    }

    final isPlus = dif > 0;
    var multi = 4;

    if(!isPlus){
      dif = -dif;
    }

    if(radioType == RadioType.fat){
      multi = 9;
    }

    final left = dif % multi;

    if(left > 0){
      caloriesValue - left;
    }

    // plus
    if(isPlus){
      if(radioType == RadioType.pro){
        proteinValue += dif ~/ multi;
      }
      else if(radioType == RadioType.car){
        carbohydrateValue += dif ~/ multi;
      }
      else {
        fatValue += dif ~/ multi;
      }
    }
    // minus
    else {
      final v = dif ~/ multi;

      if(radioType == RadioType.pro){
        if(v > proteinValue){
          caloriesValue += (v-proteinValue);
          proteinValue = 0;
        }
        else {
          proteinValue -= v;
        }
      }
      else if(radioType == RadioType.car){
        if(v > carbohydrateValue){
          caloriesValue += (v-carbohydrateValue);
          carbohydrateValue = 0;
        }
        else {
          carbohydrateValue -= v;
        }
      }
      else {
        if(v > fatValue){
          caloriesValue += (v-fatValue);
          fatValue = 0;
        }
        else {
          fatValue -= v;
        }
      }
    }

    calcChartData();
  }

  void calcChartData(){
    final sections = <PieChartSectionData>[];
    final pro = (proteinValue *4);
    final car = (carbohydrateValue *4);
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

  void gotoNextPage(){
    if(caloriesValue < 100){
      SheetCenter.showSheetNotice(state.context, state.tInMap('planChartPageP2', 'thisCaloriesNotAccept')!);
      return;
    }

    var msg1 = state.tInMap('planChartPageP2', 'notCaloriesForPupilGoal');
    String? msg2;

    if(state.widget.questionModel.goalOfBuy == 'burnFat'){
      if(caloriesValue < bmr || caloriesValue > tdee){
        msg2 = state.tInMap('planChartPageP2', 'forBurnFat');
      }
    }
    else if(state.widget.questionModel.goalOfBuy == 'muscleBuild'){
      if(caloriesValue < tdee){
        msg2 = state.tInMap('planChartPageP2', 'forMuscleBuild');
      }
    }
    else if(state.widget.questionModel.goalOfBuy == 'fixWeight'){
      final abs = MathHelper.abs(caloriesValue - tdee);

      if(abs > 10){
        msg2 = state.tInMap('planChartPageP2', 'forFixWeight');
      }
    }

    if(msg2 != null){
      DialogCenter.instance.showYesNoDialog(
          state.context,
        yesFn: (){
          requestSetPlc(state.widget.programModel);
        },
        yesText: state.tInMap('planChartPageP2', 'continue'),
        noText: state.tInMap('planChartPageP2', 'edit'),
        descView: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$msg1').boldFont(),
            SizedBox(height: 12,),
            Text(msg2),
          ],
        ),
      );
    }
    else {
      requestSetPlc(state.widget.programModel);
    }
  }

  void requestSetPlc(FoodProgramModel programModel) async {
    FocusHelper.hideKeyboardByUnFocus(state.context);

    final plc = {
      'protein': proteinValue,
      'carbohydrate': carbohydrateValue,
      'fat': fatValue,
    };

    programModel.pcl = plc;

    final js = <String, dynamic>{};

    js[Keys.request] = 'EditFoodProgram';
    js[Keys.userId] = user.userId;
    js['program_id'] = programModel.id;
    js['program_data'] = programModel.toMap(withDays:false);

    commonRequester?.requestPath = RequestPath.SetData;
    commonRequester?.bodyJson = js;

    commonRequester?.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester?.httpRequestEvents.onFailState = (req) async {
      programModel.pcl = null;
      SnackCenter.showSnack$errorCommunicatingServer(state.context);
    };

    commonRequester?.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester?.httpRequestEvents.onResultOk = (req, data) async {
      AppNavigator.replaceCurrentRoute(
          state.context,
          TreeFoodProgramScreen(
            courseRequestModel: state.widget.courseRequestModel,
            pupilUser: state.widget.pupilUser,
            questionModel: state.widget.questionModel,
            programModel: programModel,
          ),
          name: TreeFoodProgramScreen.screenName
      );
    };

    state.showLoading();
    commonRequester?.request(state.context);
  }
}

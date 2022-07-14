import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/inputFormatter.dart';
import 'package:iris_tools/api/helpers/localeHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/models/dataModels/colorTheme.dart';
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/widgets/optionsRow/checkRow.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:iris_tools/widgets/text/autoDirection.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/system/extensions.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/currencyTools.dart';
import '/views/brokenImageView.dart';
import '/views/messageViews/communicationErrorView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';
import 'addCourseScreenCtr.dart';

class AddCourseScreen extends StatefulWidget {
  static const screenName = 'AddCourseScreen';
  final CourseModel? courseModel;

  AddCourseScreen({
    this.courseModel,
    Key? key,
    }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AddCourseScreenState();
  }
}
///=========================================================================================================
class AddCourseScreenState extends StateBase<AddCourseScreen> {
  var stateController = StateXController();
  var controller = AddCourseScreenCtr();

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
            title: Text('${tInMap('addCoursePage', 'createCourse')}'),
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
          return Stack(
            fit: StackFit.expand,
            children: [
              Builder(
                builder: (context) {
                  switch(ctr.mainState){
                    case StateXController.state$loading:
                      return PreWidgets.flutterLoadingWidget$Center();
                    case StateXController.state$netDisconnect:
                      return CommunicationErrorView(this, tryAgain: controller.tryAgain,);
                    case StateXController.state$serverNotResponse:
                      return ServerResponseWrongView(this, tryAgain: controller.tryAgain);
                    default:
                      return getBody();
                  }
                },
              ),
            ],
          );
        }
    );
  }

  Widget getBody(){
    return ListView(
      padding: EdgeInsets.fromLTRB(18, 4, 18, 4),
      children: [
        SizedBox(height: 10,),

        Text('${t('title')}', style: AppThemes.infoHeadLineTextStyle(),),
        SizedBox(height: 10,),
        AutoDirection(
            builder: (context, directionController){
              return TextField(
                controller: controller.nameCtr,
                textDirection: directionController.getTextDirection(controller.nameCtr.text),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.name,
                maxLines: 1,
                expands: false,
                decoration: ColorTheme.noneBordersInputDecoration.copyWith(
                  //hintText: t('title'),
                ),
                onChanged: (t){
                  directionController.onChangeText(t);
                },
              );
            }
        ).wrapBoxBorder(color: Colors.black, alpha: 120),

        SizedBox(height: 25,),
        Text('${t('description')}', style: AppThemes.infoHeadLineTextStyle(),),
        SizedBox(height: 10,),
        Text('${tInMap('addCoursePage', 'programDescription')}:', style: AppThemes.infoTextStyle(),),
        SizedBox(height: 10,),
        AutoDirection(
            builder: (context, directionController){
              return TextField(
                controller: controller.descriptionCtr,
                textDirection: directionController.getTextDirection(controller.descriptionCtr.text),
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                minLines: 5,
                maxLines: 5,
                expands: false,
                decoration: ColorTheme.noneBordersInputDecoration.copyWith(
                  //hintText: t('description'),
                ),
                onChanged: (t){
                  directionController.onChangeText(t);
                },
              );
            }
        ).wrapBoxBorder(color: Colors.black, alpha: 120),

        SizedBox(height: 25,),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${tInMap('addCoursePage', 'includePrograms')}:', style: AppThemes.infoHeadLineTextStyle(),),
            SizedBox(height: 5,),

            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: CheckBoxRow(
                    value: controller.exerciseProgramChecked,
                    description: Text('${tC('exerciseProgram')}'),
                    onChanged: (value) {
                      controller.exerciseProgramChecked = value;
                      stateController.updateMain();
                    },
                  ),
                ),

                Flexible(
                  child: CheckBoxRow(
                    value: controller.foodProgramChecked,
                    description: Text('${tC('foodProgram')}'),
                    onChanged: (value) {
                      controller.foodProgramChecked = value;
                      stateController.updateMain();
                    },
                  ),
                ),

              ],
            ),
          ],
        ),

        SizedBox(height: 25,),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t('price')}', style: AppThemes.infoHeadLineTextStyle(),),
            SizedBox(height: 10,),
            Row(
              children: [
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: controller.priceCtr,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    maxLines: 1,
                    expands: false,
                    decoration: ColorTheme.noneBordersInputDecoration.copyWith(
                      //hintText: t('price'),
                    ),
                    onChanged: (t){
                      t = LocaleHelper.numberToEnglish(t.trim())!;
                      var t2 = LocaleHelper.removeMarks(t)!;

                      if(t2.isEmpty || t2 == '-'){
                        return;
                      }

                      final ch = CurrencyTools.formatCurrency(MathHelper.clearToDouble(t));
                      controller.priceCtr.value = InputFormatter.getTextEditingValue(ch);
                    },
                  ).wrapBoxBorder(color: Colors.black, alpha: 120),
                ),

                Text('    ${controller.currencyModel.currencySymbol} (${controller.currencyModel.currencyCode})  ').bold(),

                TextButton(
                  child: Text('${t('changeUnit')}', style: AppThemes.currentTheme.textUnderlineStyle,),
                  //icon: Icon(Icons.monetization_on),
                  onPressed: (){
                    controller.onChangeCurrency();
                  },
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 25,),
        Text('${tInMap('addCoursePage','courseDays')}', style: AppThemes.infoHeadLineTextStyle(),),
        SizedBox(height: 10,),
        Text('${tInMap('addCoursePage','courseDaysDescription')}', style: AppThemes.infoTextStyle(),),
        Row(
          children: [
            SizedBox(
              width: 50,
              child: AutoDirection(
                builder: (context, aCtr) {
                  return TextField(
                    controller: controller.durationCtr,
                    keyboardType: TextInputType.number,
                    decoration: ColorTheme.noneBordersInputDecoration,
                    onTap: (){
                      aCtr.manageSelection(controller.durationCtr);
                    },
                  );
                }
              ),
            ).wrapBoxBorder(color: Colors.black, alpha: 120),

            SizedBox(width: 12,),
            Text('${tInMap('addCoursePage','days')}'),
          ],
        ),

        SizedBox(height: 25,),
        Text('${tInMap('addCoursePage','saveState')}', style: AppThemes.infoHeadLineTextStyle(),),
        SizedBox(height: 10,),
        Text('${tInMap('addCoursePage','saveStateDescription')}', style: AppThemes.infoTextStyle(),),
        CheckBoxRow(
          value: controller.temporaryStorage,
          description: Text('${tC('temporaryStorage')}'),
          onChanged: (value) {
            controller.temporaryStorage = value;
            stateController.updateMain();
          },
        ),

        SizedBox(height: 25,),
        Text('${tInMap('addCoursePage', 'backgroundImageForCourse')}', style: AppThemes.infoHeadLineTextStyle(),),
        SizedBox(height: 15,),
        Builder(
            builder: (context) {
              if(!controller.courseModel.hasImage) {
                return Center(
                  child: IconButton(
                      iconSize: 80,
                      icon: Icon(Icons.camera_alt).siz(70).toColor(AppThemes.currentTheme.infoTextColor),
                      onPressed: (){
                        controller.addPhotoClick();
                      }
                  ).wrapDotBorder(color: AppThemes.currentTheme.infoTextColor),
                );
              }

              return GestureDetector(
                onLongPress: (){
                  controller.deleteDialog();
                },
                child: AspectRatio(
                  aspectRatio: 16/10,
                  /*child: Image(
                    errorBuilder: (ctx, e, s) => BrokenImageView(),
                    image: FileImage(FileHelper.getFile(controller.courseModel.imagePath!)),
                  ),*/
                  child: IrisImageView(
                    beforeLoadWidget: PreWidgets.flutterLoadingWidget$Center(),
                    errorWidget: BrokenImageView(center: true,),
                    imagePath: controller.courseModel.imagePath,
                    url: controller.courseModel.imageUri,
                  ),
                ),
              );
            }
        ),

        SizedBox(height: 20,),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            child: Text('${t('save')}'),
            onPressed: (){
              controller.onSaveClick();
            },
          ),
        ),

        SizedBox(height: 20,),
      ],
    );
  }
  ///==========================================================================================================
}

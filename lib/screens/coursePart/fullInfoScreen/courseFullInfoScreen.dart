import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/colorHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/widgets/irisImageView.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/courseModels/courseModel.dart';
import '/screens/coursePart/fullInfoScreen/courseFullInfoCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appThemes.dart';
import '/tools/currencyTools.dart';
import '/tools/dateTools.dart';

class CourseFullInfoScreen extends StatefulWidget {
  static const screenName = 'CourseFullInfoScreen';
  final CourseModel courseModel;

  const CourseFullInfoScreen({
    Key? key,
    required this.courseModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => CourseFullInfoScreenState();
}
///=====================================================================================
class CourseFullInfoScreenState extends StateBase<CourseFullInfoScreen> {
  StateXController stateController = StateXController();
  CourseFullInfoCtr controller = CourseFullInfoCtr();

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
    controller.onDispose();
    stateController.dispose();

    super.dispose();
  }

  Widget getScaffold(){
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.courseModel.title),
      ),
      body: SafeArea(
          child: getMainBuilder()
      ),
    );
  }

  Widget getMainBuilder(){
    return StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          return getBody();
        }
    );
  }

  Widget getBody(){
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: ColoredBox(
              color: ColorHelper.textToColor(controller.courseModel.title),
              child: GestureDetector(
                onTap: (){
                  if(controller.courseModel.hasImage) {
                    controller.showFullScreenImage();
                  }
                },
                child: Hero(
                  tag: 'h${controller.courseModel.id}',
                  child: IrisImageView(
                    height: 180,
                    imagePath: controller.courseModel.imageUri != null? controller.courseModel.imagePath : null,
                    url: controller.courseModel.imageUri,
                  ),
                ),
              ),
            ),
          ),

          Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          label: Text('ID: ${controller.courseModel.id}'),
                        ),
                      ],
                    ),

                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: IconButton(
                        icon: Icon(IconList.dotsVerM)
                            .primaryOrAppBarItemOnBackColor(),
                        alignment: Alignment.centerLeft,
                        onPressed: (){
                          controller.showEditSheet();
                        },
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 2,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  
                  children: [
                    Text('${tC('title')}')
                        .boldFont().color(AppThemes.currentTheme.primaryColor),

                    Text(controller.courseModel.title,)
                        .boldFont().color(AppThemes.currentTheme.primaryColor),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  
                  children: [
                    Text('${tC('price')}'),

                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('  ${CurrencyTools.formatCurrency(MathHelper.clearToInt(controller.courseModel.price))}  ')
                        .boldFont(),
                        Text(controller.courseModel.currencyModel.currencySymbol?? '', style: AppThemes.infoTextStyle(),),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  
                  children: [
                    Text('${tC('creationDate')}'),

                    Text(DateTools.dateAndHmRelative(controller.courseModel.creationDate)).boldFont(),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  
                  children: [
                    Text('${tInMap('addCoursePage','courseDays')}'),

                    Row(
                      //textDirection: TextDirection.ltr,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${controller.courseModel.durationDay}'.localeNum())
                            .boldFont(),

                        Text(' ${tInMap('addCoursePage', 'days')} ', style: AppThemes.infoTextStyle(),),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text('${tC('exerciseProgram')}'),

                    Text(controller.courseModel.hasExerciseProgram? '${t('yes')}': '${t('no')}')
                        .boldFont()
                    .color(controller.courseModel.hasExerciseProgram? Colors.green.shade800: Colors.black),
                  ],
                ),

                const SizedBox(height: 6,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text('${tC('foodProgram')}'),

                    Text(controller.courseModel.hasFoodProgram? '${t('yes')}': '${t('no')}')
                        .boldFont()
                        .color(controller.courseModel.hasFoodProgram? Colors.green.shade800: Colors.black),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Visibility(
                        visible: controller.courseModel.isPrivateShow,
                        child: Chip(
                          label: Text('${tC('temporaryStorage')}'),
                          backgroundColor: AppThemes.currentTheme.warningColor,
                        )
                    ),

                    const SizedBox(width: 4,),
                    Visibility(
                        visible: controller.courseModel.isBlock,
                        child: Chip(
                          label: Text('${tC('blocked')}'),
                          backgroundColor: AppThemes.currentTheme.errorColor,
                        )
                    ),
                  ],
                ),

                const SizedBox(height: 6,),
                Text('${tC('description')}:'),

                Card(
                  color: Colors.grey.shade300,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(controller.courseModel.description)
                        .boldFont(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

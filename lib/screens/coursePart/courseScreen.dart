import 'package:flutter/material.dart';

import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/widgets/icon/circularIcon.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/screens/coursePart/courseScreenCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/system/session.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/currencyTools.dart';
import '/views/messageViews/communicationErrorView.dart';
import '/views/messageViews/mustLoginView.dart';
import '/views/messageViews/notDataFoundView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class CourseScreen extends StatefulWidget {
  static const screenName = 'CourseScreen';

  CourseScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CourseScreenState();
  }
}
///=========================================================================================================
class CourseScreenState extends StateBase<CourseScreen> {
  var stateController = StateXController();
  var controller = CourseScreenCtr();

  @override
  void initState() {
    super.initState();
    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();
    controller.onBuild();

    return getUnScaffold();
  }

  @override
  void dispose() {
    controller.onDispose();
    stateController.dispose();

    super.dispose();
  }

  getUnScaffold() {
    return WillPopScope(
      onWillPop: () => Future.value(true),//onWillBack(this),
      child: SizedBox(
        width: AppSizes.getScreenWidth(context),
        height: AppSizes.getScreenHeight(context),
        child: getMainBuilder(),
        ),
      );
  }

  getMainBuilder() {
    return StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Builder(
                builder: (context) {
                  if(!Session.hasAnyLogin()) {
                    return MustLoginView(this, loginFn: controller.tryLogin,);
                  }

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

              getFab(),
            ],
          );
        }
    );
  }

  Widget getBody(){
    return StateX(
      isSubMain: true,
      controller: stateController,
      builder: (context, ctr, date) {
        if(controller.courseManager.courseList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NotDataFoundView(),
                SizedBox(height: 40,),
                Text('${tC('youHaveNoCourse')}',
                  textAlign: TextAlign.center,).subAlpha(),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: controller.courseManager.courseList.length,
          padding: EdgeInsets.only(bottom: 55),
            itemBuilder: (ctx, idx){
              return genListItem(idx);
            },
        );
      }
    );
  }
  ///========================================================================================================
  Widget getFab(){
    return Positioned(
        bottom: 30,
        right: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: (){
                controller.addNewCourseClick();
              },
              child: CircularIcon(
                backColor: AppThemes.currentTheme.fabBackColor,
                itemColor: AppThemes.currentTheme.fabItemColor,
                icon: IconList.addCircle,
                padding: 16,
                size: 42,
              ),
            ),
          ],
        )
    );
  }

  Widget genListItem(int idx){
    var course = controller.courseManager.courseList.elementAt(idx);

    return Card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            SizedBox(
              width: 10,
              height: double.infinity,
              child: ColoredBox(color:course.isPrivateShow? Colors.orangeAccent: Colors.green),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                            child: Text(course.title)
                                .boldFont().fsR(2).oneLineOverflow$Start()
                        ),

                        RotatedBox(
                          quarterTurns: AppThemes.isRtlDirection()? 2: 0,
                          child: Icon(IconList.arrowLeftIos, size: 12,)
                              .wrapMaterial(
                            onTapDelay: (){
                              //controller.showItemMenu(course);
                              controller.gotoFullScreen(course);
                            },
                            materialColor: Colors.black12,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12,),
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('  ${CurrencyTools.formatCurrency(MathHelper.clearToInt(course.price))}  ', style: AppThemes.infoTextStyle()),
                        Text(course.currencyModel.currencySymbol?? '', style: AppThemes.infoTextStyle(),),
                      ],
                    ),

                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(course.hasFoodProgram? IconList.checkedBoxM: IconList.checkBlankBoxM)
                                .info(),
                            Text('${tInMap('coursePage', 'foodProgram')}',
                                style: AppThemes.infoTextStyle()),
                          ],
                        ),

                        SizedBox(width: 12,),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                course.hasExerciseProgram? IconList.checkedBoxM: IconList.checkBlankBoxM,
                            ).info(),
                            Text('${tInMap('coursePage', 'exerciseProgram')}',
                                style: AppThemes.infoTextStyle()),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



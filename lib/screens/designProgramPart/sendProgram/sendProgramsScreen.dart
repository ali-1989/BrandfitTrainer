import 'package:flutter/material.dart';

import 'package:iris_tools/widgets/sizePosition/SizeListener.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/database/models/requestHybridModelDb.dart';
import '/database/models/userAdvancedModelDb.dart';
import '/models/dataModels/courseModels/courseQuestionModel.dart';
import '/models/dataModels/programModels/foodProgramModel.dart';
import '/screens/designProgramPart/sendProgram/sendProgramsScreenCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appSizes.dart';
import '/tools/app/appThemes.dart';
import '/tools/dateTools.dart';
import '/views/messageViews/communicationErrorView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class SendProgramsScreen extends StatefulWidget {
  static const screenName = 'SendProgramsScreen';
  final RequestHybridModelDb requestModel;
  final CourseQuestionModel questionModel;
  final UserAdvancedModelDb pupilUser;

  SendProgramsScreen({
    required this.requestModel,
    required this.questionModel,
    required this.pupilUser,
    Key? key,
    }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SendProgramsScreenState();
  }
}
///=========================================================================================================
class SendProgramsScreenState extends StateBase<SendProgramsScreen> {
  var stateController = StateXController();
  var controller = SendProgramsScreenCtr();
  var sizeController = SizeListenerController();

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
          //backgroundColor: Colors.grey.shade300,
          appBar: AppBar(
            title: Text('${tInMap('sendProgramPage', 'pageTitle')}'),
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
    return Column(
      children: [
        getHeader(),

        Expanded(
            child: Builder(
              builder: (context) {
                if(controller.programs.isEmpty){
                  return Center(
                    child: Text('${tInMap('sendProgramPage', 'notCreatedProgram')}')
                        .boldFont().alpha()
                        .wrapDotBorder(padding: EdgeInsets.all(20),
                    color: AppThemes.currentTheme.textColor),
                  );
                }

                return getListView();
              }
            )
        ),
      ],
    );
  }
  ///==========================================================================================================
  Widget getHeader(){
    var nameInfo = tInMap('sendProgramPage', widget.questionModel.sex == 1? 'programsForMan' : 'programsForWoman')!;
    nameInfo += ' ${controller.pupilUser.userName}';
    var courseInfo = tInMap('sendProgramPage', 'course')!;
    courseInfo += ': ${controller.requestModel.title}';
    courseInfo += ' (${controller.requestModel.durationDay} ${tInMap('sendProgramPage', 'days')})';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
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
        OutlinedButton(
            onPressed: (){
              controller.addNewProgram();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(IconList.add, size: 16, color: Colors.white,)
                    .wrapBackground(radius: 22,
                    padding: EdgeInsets.all(4),
                    backColor: AppThemes.currentTheme.infoColor,
                ),
                SizedBox(width: 8,),
                Text('${t('create')}')
              ],
            ),
          style: ButtonStyle(
              shape: MaterialStateProperty.all(RoundedRectangleBorder(side: BorderSide.none)),
            //side: MaterialStateProperty.all(BorderSide.none),
          ),
        )
      ],
    );
  }

  Widget getListView(){
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      itemCount: controller.programs.length,
        itemBuilder: (ctx, idx){
          final p = controller.programs[idx] as FoodProgramModel;
          var sendDateText = '';

          if(p.sendDate == null){
            sendDateText = '${tInMap('sendProgramPage', 'sendDate')}: ';

            if(p.cronDate != null) {
              sendDateText += DateTools.dateOnlyRelative(p.cronDate);
            }
            else {
              sendDateText += '-';
            }
          }
          else {
            sendDateText = '${tInMap('sendProgramPage', 'wasSendIn')}: ';
            sendDateText += DateTools.dateOnlyRelative(p.sendDate);
          }

          return Card(
            color: Colors.white,
            //color: ColorHelper.lightPlus(AppThemes.currentTheme.primaryColor),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppThemes.currentTheme.primaryColor.withAlpha(40),
                    AppThemes.currentTheme.primaryColor.withAlpha(50),
                    AppThemes.currentTheme.primaryColor.withAlpha(80),
                    AppThemes.currentTheme.primaryColor.withAlpha(180),
                  ]
                )
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizeListener(
                        controller: sizeController,
                        isListener: true,
                        builder: (ctx, ctr){
                          return SizedBox(
                            height: sizeController.size!.height,
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text('${p.title}').boldFont()
                                    ),
                                  ],
                                ),

                                SizedBox(height: 8,),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text(sendDateText)
                                    ),
                                  ],
                                ),

                                SizedBox(height: 8,),
                                Row(
                                  children: [
                                    Expanded(
                                        child: Text('${tInMap('sendProgramPage', 'daysCount')}: ${p.foodDays.length}')
                                    ),
                                  ],
                                ),

                                SizedBox(height: 8,),
                                Row(
                                  children: [
                                    TextButton.icon(
                                        onPressed: (){
                                          controller.showDeleteProgramDialog(p);
                                        },
                                        //style: TextButton.styleFrom(primary: Colors.white),
                                        icon: Icon(IconList.delete),
                                        label: Text('${t('delete')}')
                                    ),

                                    TextButton.icon(
                                        onPressed: (){
                                          controller.repeatProgram(p);
                                        },
                                        //style: TextButton.styleFrom(primary: Colors.black.withAlpha(180)),
                                        icon: Icon(IconList.copy),
                                        label: Text('${tInMap('sendProgramPage', 'repeat')}')
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizeListener(
                      controller: sizeController,
                      builder: (ctx, ctr){
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: ElevatedButton(
                                      onPressed: p.canEdit()? (){
                                        controller.editProgram(p);
                                      }: null,
                                      child: Text('${t('edit')}')
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 8,),
                            Row(
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: ElevatedButton(
                                      onPressed: p.canSend()? (){
                                        controller.showSendPrompt(p);
                                      } : null,
                                      child: Text('${t('send')}')
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 8,),
                            Row(
                              textDirection: TextDirection.ltr,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(primary: AppThemes.currentTheme.infoColor),
                                      onPressed:p.canEdit()? (){
                                        controller.gotoDesign(p);
                                      } : null,
                                      child: Text('${tInMap('sendProgramPage', 'design')}')
                                  ),
                                ),


                              ],
                            )
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

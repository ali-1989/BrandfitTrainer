import 'package:flutter/material.dart';

import 'package:iris_tools/widgets/optionsRow/checkRow.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/screens/requestPart/requestScreenCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appThemes.dart';
import '/tools/dateTools.dart';
import '/views/messageViews/mustLoginView.dart';
import '/views/messageViews/notDataFoundView.dart';
import '/views/messageViews/serverResponseWrongView.dart';
import '/views/preWidgets.dart';

class RequestScreen extends StatefulWidget {
  static const screenName = 'RequestScreen';

  RequestScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RequestScreenState();
  }
}
///=========================================================================================================
class RequestScreenState extends StateBase<RequestScreen> {
  StateXController stateController = StateXController();
  RequestScreenCtr controller = RequestScreenCtr();

  @override
  void initState() {
    super.initState();

    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    controller.onBuild();
    return getMainBuilder();
  }

  @override
  void dispose() {
    stateController.dispose();
    controller.onDispose();

    super.dispose();
  }

  Widget getMainBuilder(){
    return WillPopScope(
        onWillPop: () => onWillBack(this),
      child: StateX(
          isMain: true,
          controller: stateController,
          builder: (context, ctr, data) {
            if(controller.user == null) {
              return MustLoginView(this, loginFn: controller.tryLogin,);
            }

            switch(ctr.mainState){
              case StateXController.state$loading:
                return PreWidgets.flutterLoadingWidget$Center();
              case StateXController.state$netDisconnect:
              case StateXController.state$serverNotResponse:
                return ServerResponseWrongView(this, tryAgain: controller.tryAgain,);
              default:
                return getBody();
            }
          }
      ),
    );
  }

  Widget getBody(){
    return Column(
      children: [
        ColoredBox(
          color: AppThemes.currentTheme.appBarBackColor,
          child: Row(
            children: [
              CheckBoxRow(
                  value: controller.pendingRequestOp,
                tickColor: AppThemes.currentTheme.appBarBackColor,
                borderColor: Colors.white,
                  description: Text('${tInMap('optionsKeys', 'pendingRequestMode')}')
                      .color(Colors.white),
                  onChanged: (v){
                    controller.pendingRequestOp = v;

                    stateController.mainStateAndUpdate(StateXController.state$loading);
                    controller.resetRequest();
                  },
              ),

              CheckBoxRow(
                value: controller.acceptRequestOp,
                tickColor: AppThemes.currentTheme.appBarBackColor,
                borderColor: Colors.white,
                description: Text('${tInMap('optionsKeys', 'acceptedRequestMode')}')
                    .color(Colors.white),
                onChanged: (v){
                  controller.acceptRequestOp = v;

                  stateController.mainStateAndUpdate(StateXController.state$loading);
                  controller.resetRequest();
                },
              ),

              CheckBoxRow(
                value: controller.rejectRequestOp,
                tickColor: AppThemes.currentTheme.appBarBackColor,
                borderColor: Colors.white,
                description: Text('${tInMap('optionsKeys', 'rejectRequestMode')}')
                    .color(Colors.white),
                onChanged: (v){
                  controller.rejectRequestOp = v;

                  stateController.mainStateAndUpdate(StateXController.state$loading);
                  controller.resetRequest();
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: StateX(
            isSubMain: true,
            controller: stateController,
            builder: (ctx, ctr, data){
              if(controller.requestManager!.requestList.isEmpty){
                return NotDataFoundView();
              }

              return ListView.builder(
                itemCount: controller.requestList.length,
                  itemBuilder: (ctx, idx){
                    return genListItem(idx);
                  }
              );
            },
          ),
        ),
      ],
    );
  }
  ///=====================================================================================================
  Widget genListItem(int idx){
    final cr = controller.requestList[idx];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(IconList.apps2, color: AppThemes.currentTheme.primaryColor,),
                      const SizedBox(width: 8,),
                      Text(cr.title).bold().fsR(2),
                    ],
                  ),
                ),

                if(cr.isNearToAnswering() > 0)
                  TabPageSelectorIndicator(
                      backgroundColor: cr.isNearToAnswering() == 1? Colors.orange : Colors.red,
                      borderColor: cr.isNearToAnswering() == 1? Colors.orange : Colors.red,
                      size: 16
                  )
              ],
            ),

            const SizedBox(height: 20,),
            Text('${t('pupil')}: ${cr.requesterName()}').bold(),

            const SizedBox(height: 5,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t('requestDate')}: ${DateTools.dateOnlyRelative(cr.requestDate)}').bold(),
              ],
            ),

            Visibility(
              visible: cr.sendDeadline != null,
                child: Column(
                  children: [
                    const SizedBox(height: 5,),
                    Text('${t('sendDeadline')}: ${DateTools.dateOnlyRelative(cr.sendDeadline)}').bold(),
                  ],
                )
            ),

            const SizedBox(height: 10,),
            Text('${t('status')}: ${cr.getStatusText(context)}')
                .bold().color(cr.getStatusColor()),

            const SizedBox(height: 10,),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: (){
                          controller.requestCourseInfo(cr);
                        }, child: Text('${t('information')}')
                    )
                ),

                const SizedBox(width: 8,),
                if(cr.canResponse)
                Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(primary: AppThemes.currentTheme.infoColor),
                        onPressed: (){
                          controller.gotoAnswerPage(cr);
                        },
                        child: Text('${t('toResponse')}')
                    )
                ),

                Expanded(
                  child: Visibility(
                    visible: cr.canShowSendProgram,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: AppThemes.currentTheme.infoColor),
                        onPressed: !cr.hasTimeSendProgram? null : (){
                          controller.gotoSendProgramPage(cr);
                        },
                        child: Text('${t('sendProgram')}')
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


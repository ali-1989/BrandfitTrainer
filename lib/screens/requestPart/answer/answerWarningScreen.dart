import 'package:flutter/material.dart';

import 'package:animate_do/animate_do.dart';
import 'package:flutter_number_picker/flutter_number_picker.dart';
import 'package:iris_tools/api/helpers/colorHelper.dart';
import 'package:iris_tools/api/helpers/focusHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/database/models/requestHybridModelDb.dart';
import '/managers/chatManager.dart';
import '/managers/userAdvancedManager.dart';
import '/managers/userRequestManager.dart';
import '/screens/chatPart/chatScreenPart/chatScreen.dart';
import '/system/extensions.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/sheetCenter.dart';

class AnswerWarningScreen extends StatefulWidget {
  static const screenName = 'AnswerWarningScreen';
  final RequestHybridModelDb courseRequestModel;

  AnswerWarningScreen({
    Key? key,
    required this.courseRequestModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return AnswerWarningScreenState();
  }
}
///=========================================================================================================
class AnswerWarningScreenState extends StateBase<AnswerWarningScreen> {
  StateXController stateController = StateXController();
  UserRequestManager? courseRequestManager;
  String noticeText = '';


  @override
  void initState() {
    super.initState();

    courseRequestManager = UserRequestManager.managerFor(Session.getLastLoginUser()!.userId);
    noticeText = tInMap('requestAnswerPage', 'warning1')!;
    noticeText += ' ${tInMap('requestAnswerPage', 'warning2')!}';
  }

  @override
  Widget build(BuildContext context) {
    rotateToPortrait();

    return getScaffold();
  }

  @override
  void dispose() {
    stateController.dispose();

    super.dispose();
  }

  Widget getScaffold(){
    return Scaffold(
      appBar: AppBar(
        title: Text('${t('toResponse')}'),
      ),
      body: getMainBuilder(),
    );
  }

  Widget getMainBuilder(){
    return WillPopScope(
        onWillPop: () => onWillBack(this),
      child: StateX(
          isMain: true,
          controller: stateController,
          builder: (context, ctr, data) {
            return Builder(
              builder: (context) {
                return getBody();
              },
            );
          }
      ),
    );
  }

  Widget getBody(){
    return StateX(
      isSubMain: true,
      controller: stateController,
      builder: (ctx, ctr, data){
        return ListView(
          children: [
            FlipInY(
              child: Card(
                elevation: 0,
                color: AppThemes.currentTheme.primaryColor.withAlpha(50),
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                            ColorHelper.darkPlus(AppThemes.currentTheme.errorColor),
                            ColorHelper.lightPlus(AppThemes.currentTheme.errorColor),
                          ]
                      )
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${t('notice')}:').boldFont().fsR(3).color(Colors.white),
                        SizedBox(height: 8,),
                        Text(noticeText).boldFont().fsR(2).color(Colors.white)
                      ],
                    ),
                  ),
                ),
              ),
            ),

            FlipInY(
              child: Card(
                elevation: 0,
                color: AppThemes.currentTheme.primaryColor.withAlpha(50),
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [
                            ColorHelper.darkPlus(AppThemes.currentTheme.infoColor),
                            ColorHelper.lightPlus(AppThemes.currentTheme.infoColor),
                          ]
                      )
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${tInMap('requestAnswerPage', 'canChatToUser')}')
                            .boldFont().fsR(3).color(Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20,),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                        onPressed: (){
                          gotoChat();
                        },
                        child: Text('${t('chat')}')
                    ),
                  ),

                  SizedBox(width: 8,),
                  Expanded(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: AppThemes.currentTheme.successColor),
                        onPressed: (){
                          acceptDialog(widget.courseRequestModel);
                        },
                        child: Text('${t('accept')}')
                    ),
                  ),

                  SizedBox(width: 8,),
                  Expanded(
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(primary: AppThemes.currentTheme.warningColor),
                        onPressed: (){
                          rejectDialog(widget.courseRequestModel);
                        },
                        child: Text('${t('reject')}')
                    ),
                  )
                ],
              ),
            )
          ],
        );
      },
    );
  }
  ///==========================================================================================================
  void acceptDialog(RequestHybridModelDb model){
    var val = 5;

    final rejectView = Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${tInMap('requestAnswerPage', 'whatDaysToSendProgram')}')
          .boldFont(),
          SizedBox(height: 2,),
          Text('${tInMap('requestAnswerPage', 'ifNotSendTakeBadBadge')}')
          .color(AppThemes.currentTheme.errorColor).fsR(1),
          SizedBox(height: 15,),
          CustomNumberPicker(
            initialValue: val,
            maxValue: 15,
            minValue: 1,
            step: 1,
            onValue: (value) {
              val = value as int;
            },
            customAddButton: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ColoredBox(
                  color: AppThemes.currentTheme.buttonBackColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Text(' + ').color(Colors.white).bold(),
                  )
              ),
            ),
            customMinusButton: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ColoredBox(
                color: AppThemes.currentTheme.buttonBackColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text(' - ').color(Colors.white).bold(),
                )
              ),
            ),
          )
        ],
      ),
    );

    final dec = DialogCenter.instance.dialogDecoration.copy();
    dec.negativeButtonBackColor = Colors.transparent;
    dec.negativeButtonTextColor = Colors.black;

    DialogCenter().showYesNoDialog(
        context,
        descView: rejectView,
        dismissOnButtons: true,
        decoration: dec,
        yesText: '${t('send')}',
        noText: '${t('back')}',
        yesFn: (){
          requestCourseAccept(model, val);
        }
    );
  }

  void rejectDialog(RequestHybridModelDb model){
    final TextEditingController ctr = TextEditingController();

    final rejectView = Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${tInMap('requestAnswerPage', 'causeOfReject')}').boldFont(),
          SizedBox(height: 15,),
          TextField(
            controller: ctr,
          ),
        ],
      ),
    );

    final dec = DialogCenter.instance.dialogDecoration.copy();
    dec.negativeButtonBackColor = Colors.transparent;
    dec.negativeButtonTextColor = Colors.black;

    DialogCenter().showYesNoDialog(
        context,
        descView: rejectView,
        dismissOnButtons: false,
        decoration: dec,
        yesText: '${t('send')}',
        noText: '${t('back')}',
        yesFn: (){
          final cause = ctr.text.trim();

          if(cause.isNotEmpty) {
            AppNavigator.pop(context);
            requestCourseReject(model, cause);
          }
        },
      noFn: (){
        AppNavigator.pop(context);
      }
    );
  }

  void requestCourseReject(RequestHybridModelDb model, String cause) async {
    FocusHelper.hideKeyboardByService();

    showLoading();
    final res = await courseRequestManager?.requestCourseReject(model, cause);

    await hideLoading();

    if(res != null && res){
      AppNavigator.pop(context);
    }
    else {
      SheetCenter.showSheet$OperationFailed(context);
    }
  }

  void requestCourseAccept(RequestHybridModelDb model, int responseDay) async {
    FocusHelper.hideKeyboardByService();

    showLoading();
    final res = await courseRequestManager?.requestCourseAccept(model, responseDay);
    await hideLoading();

    if (res != null && res) {
      AppNavigator.pop(context);
      //afterAcceptDialog(model);
    }
    else {
      SheetCenter.showSheet$OperationFailed(context);
    }
  }

  void afterAcceptDialog(RequestHybridModelDb model){
    var val = 5;

    final rejectView = Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${tInMap('requestAnswerPage', 'canSendProgramNow')}')
              .boldFont(),
          SizedBox(height: 2,),
        ],
      ),
    );

    final dec = DialogCenter.instance.dialogDecoration.copy();
    dec.negativeButtonBackColor = Colors.transparent;
    dec.negativeButtonTextColor = Colors.black;

    DialogCenter().showYesNoDialog(
        context,
        descView: rejectView,
        dismissOnButtons: true,
        decoration: dec,
        yesText: '${t('sendProgram')}',
        noText: '${t('later')}',
        yesFn: (){
          requestCourseAccept(model, val);
        }
    );
  }

  void gotoChat() async {
    var userAdv = UserAdvancedManager.getById(widget.courseRequestModel.requesterUserId);

    if(userAdv == null) {
      showLoading();
      userAdv = await UserAdvancedManager.requestUserLimit(widget.courseRequestModel.requesterUserId);
      await hideLoading();
    }

    if(userAdv == null){
      SheetCenter.showSheet$OperationFailed(context);
      return;
    }

    final user = Session.getLastLoginUser()!;
    final chatManager = ChatManager.managerFor(user.userId);
    var chatModel = await chatManager.fetchChatsByReceiverId(widget.courseRequestModel.requesterUserId);

    /*final uLimit = UserLimitModelDb();
    uLimit.userId = widget.courseRequestModel.requesterUserId;
    uLimit.userName = widget.courseRequestModel.requesterName;

    UserLimitManager.addItem(uLimit);*/

    if(chatModel == null){
      chatModel = chatManager.generateDraftChat(
          user,
          receiverId: widget.courseRequestModel.requesterUserId,
          type: 10
      );
    }
    else {
      if(chatModel.isClose){
        chatModel.isClose = false;
        ChatManager.sendOpenChat(chatModel.id!);
      }
    }

    AppNavigator.pushNextPage(
        context,
        ChatScreen(chat: chatModel),
        name: ChatScreen.screenName
    );
  }
}

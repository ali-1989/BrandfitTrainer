import 'package:flutter/material.dart';

import '/abstracts/viewController.dart';
import '/models/dataModels/usersModels/bankCardModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/screens/profile/paymentPart/addCardScreen.dart';
import '/screens/profile/paymentPart/paymentsScreen.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';

class PaymentsCtr implements ViewController {
  late PaymentsScreenState state;
  late Requester commonRequester;
  late UserModel user;
  BankCardModel? bankCard;
  bool isSelected = false;

  @override
  void onInitState<E extends State>(E state){
    this.state = state as PaymentsScreenState;

    commonRequester = Requester();
    user = Session.getLastLoginUser()!;

    if(user.bankCardModel != null){
      bankCard = user.bankCardModel;
    }

    Session.addLogoffListener(onLogout);
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
    Session.removeLogoffListener(onLogout);
  }

  void onLogout(user){
    Session.removeLogoffListener(onLogout);
    HttpCenter.cancelAndClose(commonRequester.httpRequester);
    AppNavigator.popRoutesUntilRoot(state.context);
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is PaymentsScreenState) {
    }
  }

  void onAddCardClick(){
    gotoAddCardScreen().then((value){
      if(user.bankCardModel != null){
        bankCard = user.bankCardModel;
        state.update();
      }
    });
  }

  Future gotoAddCardScreen(){
    return AppNavigator.pushNextPage(
        state.context, AddCardScreen(userModel: user,),
        name: AddCardScreen.screenName,
    );
  }

  void deleteCard(){
    final js = <String, dynamic>{};
    js[Keys.request] = 'DeleteUserBankCard';
    js[Keys.forUserId] = user.userId;
    js['card'] = bankCard!.toMap();

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.SetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await state.hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      SheetCenter.showSheet$ServerNotRespondProperly(state.context);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      user.bankCardModel = null;
      bankCard = null;

      await Session.sinkUserInfo(user).then((value) async{
        state.stateController.updateMain();
      });

    };

    state.showLoading(canBack: false);
    commonRequester.request(state.context);
  }
}

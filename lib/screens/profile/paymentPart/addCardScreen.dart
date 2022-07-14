import 'package:flutter/material.dart';

import 'package:awesome_card/awesome_card.dart';
import 'package:iris_tools/api/helpers/maskHelper.dart';
import 'package:iris_tools/api/helpers/mathHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';
import 'package:iris_tools/widgets/text/autoDirection.dart';

import '/abstracts/stateBase.dart';
import '/models/dataModels/usersModels/bankCardModel.dart';
import '/models/dataModels/usersModels/userModel.dart';
import '/system/keys.dart';
import '/system/requester.dart';
import '/system/session.dart';
import '/tools/app/appNavigator.dart';
import '/tools/app/appThemes.dart';
import '/tools/centers/dialogCenter.dart';
import '/tools/centers/httpCenter.dart';
import '/tools/centers/sheetCenter.dart';

class AddCardScreen extends StatefulWidget {
  static final screenName = 'AddCardScreen';
  final UserModel userModel;

  const AddCardScreen({
    Key? key,
    required this.userModel,
  }) : super(key: key);

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}
///==========================================================================================
class _AddCardScreenState extends StateBase<AddCardScreen> {
  StateXController stateController = StateXController();
  late InputDecoration inputDecoration;
  late Requester commonRequester;
  TextEditingController cardNumberCtr = TextEditingController();
  String? cardNumber;

  @override
  void initState() {
    super.initState();

    commonRequester = Requester();

    inputDecoration = InputDecoration(
      border: OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(),
    );

    addPostOrCall(() {
      DialogCenter.instance.showInfoDialog(context, null, '${tInMap('paymentPage', 'registerBankCardDescription')}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${tInMap('paymentPage', 'registerBankCard')}'),
      ),
      body: getMainBuilder(),
    );
  }

  @override
  void dispose(){
    HttpCenter.cancelAndClose(commonRequester.httpRequester);

    super.dispose();
  }

  Widget getMainBuilder(){
    return StateX(
      isMain: true,
        controller: stateController,
        builder: (ctx, ctr, data){
          return getBody();
        });
  }

  Widget getBody(){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            SizedBox(height: 20,),

            Directionality(
              textDirection: TextDirection.ltr,
              child: CreditCard(
                  cardNumber: MaskHelper.bankCardMask(cardNumber)?? 'xxxx xxxx xxxx xxxx',
                  cardExpiry: ' ',/*10/25*/
                  cardHolderName: widget.userModel.userName,
                  cvv: '',
                  bankName: 'Brandfit',
                  textExpDate: ' ',
                  textName: '',
                  textExpiry: ' ',
                  mask: '#### #### #### ####',
                  height: 200,
                  cardType: CardType.other,
                  showBackSide: false,
                  showShadow: false,
                  frontBackground: Container(
                    width: double.maxFinite,
                    height: double.maxFinite,
                    color: AppThemes.currentTheme.accentColor,
                  ),
                  backBackground: CardBackgrounds.white,
              ),
            ),

            SizedBox(height: 20,),

            AutoDirection(
              builder: (context, aCtr) {
                return TextField(
                  controller: cardNumberCtr,
                  keyboardType: TextInputType.number,
                  textDirection: aCtr.getTextDirection(cardNumberCtr.text),
                  maxLength: 16,
                  onChanged: (t){
                    //no: aCtr.onChangeText(t);
                    cardNumber = MathHelper.clearToInt(t).toString();

                    if(cardNumber == '0'){
                      cardNumber = null;
                    }

                    stateController.updateMain();
                  },
                  onTap: (){
                    aCtr.manageSelection(cardNumberCtr);
                  },
                  decoration: inputDecoration.copyWith(
                    hintText: '${tInMap('paymentPage', 'cardNumber')}',
                  ),
                );
              }
            ),

            /*SizedBox(height: 10,),
            TextField(decoration: inputDecoration.copyWith(
                hintText: '${t('no')}',
              ),
            ),*/

            SizedBox(height: 30,),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: requestSaveCard,
                  child: Text('${t('save')}')
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool checkCardNumber(){
    if(cardNumber == null || cardNumber!.isEmpty){
      return false;
    }

    if(cardNumber!.length != 16){
      return false;
    }

    return true;
  }

  void requestSaveCard(){
    if(!checkCardNumber()){
      SheetCenter.showSheetNotice(context, '${tInMap('paymentPage', 'cardNumberNotValid')}');
      return;
    }

    final cb = BankCardModel();
    cb.userId = widget.userModel.userId;
    cb.cardNumber = cardNumber!;
    cb.isMain = true;

    final js = <String, dynamic>{};
    js[Keys.request] = 'AddUserBankCard';
    js[Keys.forUserId] = widget.userModel.userId;
    js['card'] = cb.toMap();

    commonRequester.bodyJson = js;
    commonRequester.requestPath = RequestPath.SetData;

    commonRequester.httpRequestEvents.onAnyState = (req) async {
      await hideLoading();
    };

    commonRequester.httpRequestEvents.onFailState = (req) async {
      SheetCenter.showSheet$ServerNotRespondProperly(context);
    };

    commonRequester.httpRequestEvents.onResultError = (req, data) async {
      return true;
    };

    commonRequester.httpRequestEvents.onResultOk = (req, data) async {
      widget.userModel.bankCardModel = cb;

      await Session.sinkUserInfo(widget.userModel).then((value) async{
        AppNavigator.pop(context);
      });

      //stateController.updateMain();
    };

    showLoading(canBack: false);
    commonRequester.request(context);
  }
}

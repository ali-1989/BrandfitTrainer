import 'package:flutter/material.dart';

import 'package:awesome_card/awesome_card.dart';
import 'package:iris_tools/api/helpers/maskHelper.dart';
import 'package:iris_tools/modules/stateManagers/stateX.dart';

import '/abstracts/stateBase.dart';
import '/screens/profile/paymentPart/paymentsCtr.dart';
import '/system/extensions.dart';
import '/system/icons.dart';
import '/tools/app/appSizes.dart';

class PaymentsScreen extends StatefulWidget {
  static const screenName = 'PaymentsScreen';

  PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return PaymentsScreenState();
  }
}
///=====================================================================================
class PaymentsScreenState extends StateBase<PaymentsScreen> {
  StateXController stateController = StateXController();
  PaymentsCtr controller = PaymentsCtr();


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
      onWillPop: () => onWillBack(this),
      child: SizedBox(
        width: AppSizes.getScreenWidth(context),
        height: AppSizes.getScreenHeight(context),
        child: Scaffold(
          key: scaffoldKey,
          appBar: getAppbar(),
          body: getBuilder(),
        ),
      ),
    );
  }

  PreferredSizeWidget getAppbar() {
    if(controller.isSelected){
      return AppBar(
        leading: IconButton(
          icon: Icon(IconList.close),
          onPressed: (){
            controller.isSelected = false;
            update();
          },
        ),

        actions: [
          IconButton(
            icon: Icon(IconList.delete),
            onPressed: (){
              controller.isSelected = false;
              update();
              controller.deleteCard();
            },
          ),
        ],
      );
    }

    return AppBar(
      title: Text(tInMap('paymentPage', 'pageTitle')!),
      actions: [
        Visibility(
          visible: controller.bankCard == null,
          child: IconButton(
            icon: Icon(IconList.add),
            onPressed: controller.onAddCardClick,
          ),
        )
      ],
    );
  }

  Widget getBuilder(){
    return StateX(
        controller: stateController,
        isMain: true,
        builder: (ctx, ctr, data){
          if(controller.user.bankCardModel == null){
            return haveNotCard();
          }

          return getBody();
        });
  }

  Widget getBody() {
    return Column(
      children: [
        SizedBox(height: 20,),

        Directionality(
          textDirection: TextDirection.ltr,
          child: GestureDetector(
            onLongPress: (){
              controller.isSelected = true;
              update();
            },
            child: Stack(
              children: [
                CreditCard(
                  cardNumber: MaskHelper.bankCardMask(controller.bankCard!.cardNumber),
                  cardExpiry: ' ',/*10/25*/
                  cardHolderName: controller.user.userName,
                  cvv: controller.bankCard!.cvvCode?? '',
                  bankName: 'Brandfit',
                  textExpDate: ' ',
                  textName: '',
                  textExpiry: controller.bankCard!.expiryDate?? '',
                  height: 200,
                  cardType: CardType.other,
                  showBackSide: false,
                  showShadow: false,
                  frontBackground: CardBackgrounds.black,
                  backBackground: CardBackgrounds.white,
                ),

                Positioned(
                  top: 5,
                  left: 30,
                  child: Visibility(
                    visible: controller.isSelected,
                      child: Icon(IconList.checkCircleM, color: Colors.green,)
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  ///========================================================================================================
  Widget haveNotCard() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('${tInMap('paymentPage', 'youHaveNotCard')}')
            .alpha().boldFont().fsR(2),
      ),
    );
  }
}

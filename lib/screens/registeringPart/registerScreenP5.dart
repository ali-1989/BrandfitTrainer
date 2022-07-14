part of 'registerScreen.dart';

class RegisterScreenP5 extends StatefulWidget {
  static const screenName = 'RegisterScreenP5';
  final RegisterScreenCtr parentCtr;

  RegisterScreenP5(this.parentCtr, {Key? key,}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return RegisterScreenP5State();
  }
}
///========================================================================================================
class RegisterScreenP5State extends StateBase<RegisterScreenP5> with AutomaticKeepAliveClientMixin {
  var stateController = StateXController();
  var controller = RegisterScreenP5Ctr();


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller.onInitState(this);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

  Widget getScaffold() {
    return WillPopScope(
      onWillPop: () => onWillBack(this),
      child: SizedBox(
        width: AppSizes.getScreenWidth(context),
        height: AppSizes.getScreenHeight(context),
        child: Scaffold(
          body: SafeArea(
          child: getBuilder()
          ),
        ),
      ),
    );
  }

  getBuilder() {
    return StateX(
        isMain: true,
        controller: stateController,
        builder: (context, ctr, data) {
          return getBody();
        }
    );
  }

  Widget getBody(){
    return MaxWidth(
      maxWidth: 380,
      child: FlipInX(
        delay: controller.inputAnimationDelay,
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          children: <Widget>[
            SizedBox(height: AppSizes.fwSize(50),),
            Text('${tInMap('registeringPage', 'selectYourStatus')}:',
              style: TextStyle(fontSize: AppSizes.fwFontSize(16)),
            ).bold().infoColor(),

            SizedBox(height: AppSizes.fwSize(16),),
            CheckBoxRow(
              value: controller.isExerciseTrainer,
              description: Text('${tInMap('registeringPage','isExerciseTrainerDesc')}'),
              onChanged: (v){
                controller.isExerciseTrainer = v;
                stateController.updateMain();
              },
            ),

            CheckBoxRow(
              value: controller.isFoodTrainer,
              description: Text('${tInMap('registeringPage','isFoodTrainerDesc')}'),
              onChanged: (v){
                controller.isFoodTrainer = v;
                stateController.updateMain();
              },
            ),

            SizedBox(height: AppSizes.fwSize(60),),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: Offset(0, -6),
                  child: Checkbox(
                    value: controller.isAcceptTerms,
                  onChanged: (v){
                      controller.isAcceptTerms = v?? false;
                      stateController.updateMain();
                  },
                  ),
                ),
                Expanded(
                  child: ParsedText(
                    text: tInMap('registeringPage', 'myAcceptTerm&Conditions')!,
                    style: AppThemes.infoTextStyle(),
                    parse: [
                      MatchText(
                          pattern: 'XX',
                          type: ParsedType.CUSTOM,
                          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          renderText: ({required String str, required String pattern}) {
                            Map<String, String> res = {};
                            res['display'] = tInMap('registeringPage', 'term&Conditions')!;
                            res['value'] = '-';
                            return res;
                          },
                          onTap: (url){
                            AppNavigator.pushNextPage(context, TermScreen(), name: 'TermScreen');
                          }
                      ),
                    ],
                    selectable: false,
                  ),
                ),
              ],
            ),

            SizedBox(height: 25,),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.gotoNextPage();
                    },
                    child: Text(tC('register')!),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10,),
          ],
        ),
      ),
    );
  }
  ///========================================================================================================
}
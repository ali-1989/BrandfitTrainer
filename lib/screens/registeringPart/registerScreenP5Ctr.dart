import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '/abstracts/viewController.dart';
import '/screens/registeringPart/registerScreen.dart';
import '/screens/registeringPart/registerScreenCtr.dart';
import '/tools/centers/sheetCenter.dart';

class RegisterScreenP5Ctr implements ViewController {
  late RegisterScreenP5State state;
  late RegisterScreenCtr parentCtr;
  bool isAcceptTerms = false;
  bool isFoodTrainer = false;
  bool isExerciseTrainer = false;
  var inputAnimationDelay = Duration(milliseconds: 400);


  @override
  void onInitState<E extends State>(E state){
    this.state = state as RegisterScreenP5State;

    parentCtr = state.widget.parentCtr;
  }

  @override
  void onBuild(){
  }

  @override
  void onDispose(){
  }
  ///========================================================================================================
  void tryAgain(State state){
    if(state is RegisterScreenP5State) {
      state.stateController.updateMain();
    }
  }

  void gotoNextPage() async {
    parentCtr.registeringModel.isExerciseTrainer = isExerciseTrainer;
    parentCtr.registeringModel.isFoodTrainer = isFoodTrainer;

    if(!isAcceptTerms){
      SheetCenter.showSheetOk(state.context, '${state.tInMap('registeringPage', 'mustAcceptTerm')}');
      return;
    }

    parentCtr.requestRegistering(state);
  }
}

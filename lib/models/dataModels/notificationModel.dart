
import 'package:brandfit_trainer/constants.dart';
import 'package:brandfit_trainer/tools/app/appThemes.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  String name = '${Constants.appName}_channel';
  bool enableLights = true;
  bool enableVibration = true;
  bool playSound = true;
  bool isPublic = true;
  bool importanceIsHigh = false;
  Color defaultColor = AppThemes.currentTheme.successColor;
  Color ledColor = AppThemes.currentTheme.successColor;

  NotificationModel.fromMap(Map? map){
    if(map == null){
      return;
    }

    enableLights = map['enableLights']?? true;
    enableVibration = map['enableVibration']?? true;
    playSound = map['playSound']?? true;
    isPublic = map['isPublic']?? true;
    importanceIsHigh = map['importanceIsHigh']?? false;
    defaultColor = map['defaultColor']?? AppThemes.currentTheme.successColor;
    ledColor = map['ledColor']?? AppThemes.currentTheme.successColor;
  }

  Map<String, dynamic> toMap(){
    final map = <String, dynamic>{};

    map['enableLights'] = enableLights;
    map['enableVibration'] = enableVibration;
    map['playSound'] = playSound;
    map['isPublic'] = isPublic;
    map['importanceIsHigh'] = importanceIsHigh;
    map['defaultColor'] = defaultColor;
    map['ledColor'] = ledColor;

    return map;
  }
}
import 'dart:async';
import 'dart:convert';

import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_location_flutter/location_modal/key_location_model.dart';
import 'package:at_location_flutter/location_modal/location_notification.dart';
import 'package:at_location_flutter/service/request_location_service.dart';

import 'send_location_notification.dart';
import 'sharing_location_service.dart';

class KeyStreamService {
  KeyStreamService._();
  static final KeyStreamService _instance = KeyStreamService._();
  factory KeyStreamService() => _instance;

  AtClientImpl atClientInstance;
  List<KeyLocationModel> allLocationNotifications = [];
  String currentAtSign;

  StreamController _atNotificationsController;
  Stream<List<KeyLocationModel>> get atNotificationsStream =>
      _atNotificationsController.stream;
  StreamSink<List<KeyLocationModel>> get atNotificationsSink =>
      _atNotificationsController.sink;

  init(AtClientImpl clientInstance) {
    atClientInstance = clientInstance;
    currentAtSign = atClientInstance.currentAtSign;
    allLocationNotifications = [];
    _atNotificationsController =
        StreamController<List<KeyLocationModel>>.broadcast();
    getAllNotifications();
  }

  getAllNotifications() async {
    List<String> allResponse = await atClientInstance.getKeys(
      regex: 'sharelocation-',
    );

    List<String> allRequestResponse = await atClientInstance.getKeys(
      regex: 'requestlocation-',
    );

    allResponse = [...allResponse, ...allRequestResponse];

    if (allResponse.length == 0) {
      SendLocationNotification().init(atClientInstance);
      return;
    }

    allResponse.forEach((key) {
      if ('@${key.split(':')[1]}'.contains(currentAtSign)) {
        print('key -> $key');
        KeyLocationModel tempHyridNotificationModel =
            KeyLocationModel(key: key);
        allLocationNotifications.add(tempHyridNotificationModel);
      }
    });

    allLocationNotifications.forEach((notification) {
      AtKey atKey = AtKey.fromString(notification.key);
      notification.atKey = atKey;
    });

    for (int i = 0; i < allLocationNotifications.length; i++) {
      AtValue value = await getAtValue(allLocationNotifications[i].atKey);
      if (value != null) {
        allLocationNotifications[i].atValue = value;
      }
    }

    convertJsonToLocationModel();
    filterData();

    notifyListeners();
    updateEventAccordingToAcknowledgedData();

    SendLocationNotification().init(atClientInstance);
  }

  convertJsonToLocationModel() {
    print(
        'allShareLocationNotifications.length -> ${allLocationNotifications.length}');
    for (int i = 0; i < allLocationNotifications.length; i++) {
      try {
        if ((allLocationNotifications[i].atValue.value != null) &&
            (allLocationNotifications[i].atValue.value != "null")) {
          LocationNotificationModel locationNotificationModel =
              LocationNotificationModel.fromJson(
                  jsonDecode(allLocationNotifications[i].atValue.value));
          allLocationNotifications[i].locationNotificationModel =
              locationNotificationModel;
          print(
              'locationNotificationModel $i -> ${locationNotificationModel.getLatLng}');
        }
      } catch (e) {
        print('convertJsonToLocationModel error :$e');
      }
    }
  }

  filterData() {
    List<KeyLocationModel> tempArray = [];
    for (int i = 0; i < allLocationNotifications.length; i++) {
      if ((allLocationNotifications[i].locationNotificationModel == 'null') ||
          (allLocationNotifications[i].locationNotificationModel == null))
        tempArray.add(allLocationNotifications[i]);
    }
    allLocationNotifications
        .removeWhere((element) => tempArray.contains(element));

    tempArray.forEach((element) {
      print('removed data ${element.key}');
      print('${element.locationNotificationModel}');
    });
  }

  updateEventAccordingToAcknowledgedData() async {
    allLocationNotifications.forEach((notification) async {
      if (notification.key.contains('sharelocation')) {
        if ((notification.locationNotificationModel.atsignCreator ==
                currentAtSign) &&
            (!notification.locationNotificationModel.isAcknowledgment)) {
          forShareLocation(notification);
        }
      } else if (notification.key.contains('requestlocation')) {
        if ((notification.locationNotificationModel.atsignCreator ==
                currentAtSign) &&
            (!notification.locationNotificationModel.isAcknowledgment)) {
          forRequestLocation(notification);
        }
      }
    });
  }

  forShareLocation(KeyLocationModel notification) async {
    String atkeyMicrosecondId =
        notification.key.split('sharelocation-')[1].split('@')[0];
    print('atkeyMicrosecondId $atkeyMicrosecondId');
    String acknowledgedKeyId = 'sharelocationacknowledged-$atkeyMicrosecondId';

    List<String> allRegexResponses =
        await atClientInstance.getKeys(regex: acknowledgedKeyId);
    print('lenhtg ${allRegexResponses.length}');
    if ((allRegexResponses != null) && (allRegexResponses.length > 0)) {
      AtKey acknowledgedAtKey = AtKey.fromString(allRegexResponses[0]);

      AtValue result = await atClientInstance.get(acknowledgedAtKey).catchError(
          (e) => print("error in get ${e.errorCode} ${e.errorMessage}"));

      LocationNotificationModel acknowledgedEvent =
          LocationNotificationModel.fromJson(jsonDecode(result.value));
      SharingLocationService()
          .updateWithShareLocationAcknowledge(acknowledgedEvent);
    }
  }

  forRequestLocation(KeyLocationModel notification) async {
    String atkeyMicrosecondId =
        notification.key.split('requestlocation-')[1].split('@')[0];
    print('atkeyMicrosecondId $atkeyMicrosecondId');
    String acknowledgedKeyId =
        'requestlocationacknowledged-$atkeyMicrosecondId';

    List<String> allRegexResponses =
        await atClientInstance.getKeys(regex: acknowledgedKeyId);
    print('lenhtg ${allRegexResponses.length}');
    if ((allRegexResponses != null) && (allRegexResponses.length > 0)) {
      AtKey acknowledgedAtKey = AtKey.fromString(allRegexResponses[0]);

      AtValue result = await atClientInstance.get(acknowledgedAtKey).catchError(
          (e) => print("error in get ${e.errorCode} ${e.errorMessage}"));

      LocationNotificationModel acknowledgedEvent =
          LocationNotificationModel.fromJson(jsonDecode(result.value));
      RequestLocationService()
          .updateWithRequestLocationAcknowledge(acknowledgedEvent);
    }
  }

  mapUpdatedLocationDataToWidget(LocationNotificationModel locationData) {
    String newLocationDataKeyId;
    if (locationData.key.contains('sharelocation'))
      newLocationDataKeyId =
          locationData.key.split('sharelocation-')[1].split('@')[0];
    else
      newLocationDataKeyId =
          locationData.key.split('requestlocation-')[1].split('@')[0];

    for (int i = 0; i < allLocationNotifications.length; i++) {
      if (allLocationNotifications[i].key.contains(newLocationDataKeyId)) {
        allLocationNotifications[i].locationNotificationModel = locationData;
      }
    }
    notifyListeners();
    SendLocationNotification().findAtSignsToShareLocationWith();
  }

  removeData(String key) {
    allLocationNotifications
        .removeWhere((notification) => key.contains(notification.atKey.key));
    notifyListeners();
    SendLocationNotification().findAtSignsToShareLocationWith();
  }

  Future<KeyLocationModel> addDataToList(
      LocationNotificationModel locationNotificationModel) async {
    String newLocationDataKeyId;
    String tempKey;
    if (locationNotificationModel.key.contains('sharelocation')) {
      newLocationDataKeyId = locationNotificationModel.key
          .split('sharelocation-')[1]
          .split('@')[0];
      tempKey = 'sharelocation-$newLocationDataKeyId';
    } else {
      newLocationDataKeyId = locationNotificationModel.key
          .split('requestlocation-')[1]
          .split('@')[0];
      tempKey = 'requestlocation-$newLocationDataKeyId';
    }

    List<String> key = [];
    if (key.length == 0) {
      key = await atClientInstance.getKeys(
        regex: tempKey,
      );
    }
    if (key.length == 0) {
      key = await atClientInstance.getKeys(
        regex: tempKey,
        sharedWith: locationNotificationModel.receiver,
      );
    }
    if (key.length == 0) {
      key = await atClientInstance.getKeys(
        regex: tempKey,
        sharedBy: locationNotificationModel.key.contains('share')
            ? locationNotificationModel.atsignCreator
            : locationNotificationModel.receiver,
      );
    }

    KeyLocationModel tempHyridNotificationModel = KeyLocationModel(key: key[0]);

    tempHyridNotificationModel.atKey = AtKey.fromString(key[0]);
    tempHyridNotificationModel.atValue =
        await getAtValue(tempHyridNotificationModel.atKey);
    tempHyridNotificationModel.locationNotificationModel =
        locationNotificationModel;
    allLocationNotifications.add(tempHyridNotificationModel);
    print('addDataToList:${allLocationNotifications}');

    notifyListeners();
    SendLocationNotification().findAtSignsToShareLocationWith();

    return tempHyridNotificationModel;
  }

  Future<dynamic> getAtValue(AtKey key) async {
    try {
      AtValue atvalue = await atClientInstance
          .get(key)
          .catchError((e) => print("error in in key_stream_service get $e"));

      if (atvalue != null)
        return atvalue;
      else
        return null;
    } catch (e) {
      print('error in key_stream_service getAtValue:$e');
      return null;
    }
  }

  notifyListeners() {
    atNotificationsSink.add(allLocationNotifications);
  }
}
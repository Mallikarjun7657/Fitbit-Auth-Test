import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:carp_health_package/health_package.dart';
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:health/health.dart';

import 'dart:async';
import 'dart:io';

import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:wear_poc/fitbit_home.dart';

void main() {
  runApp(MyApp());
}


Future<void> redirect(Uri url) async {
  // Client implementation detail
}

Future<Uri> listen(Uri url) async {
  // Client implementation detail
  return null;
}


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum AppState { DATA_NOT_FETCHED, FETCHING_DATA, DATA_READY, NO_DATA }

class _MyAppState extends State<MyApp> {
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  int stepsCount;
  double energyBurned;
  int heartRate;
  int weight;
  double height;
  int bloodPressureDiastolic;
  int bloodPressureSystolic;

  @override
  void initState() {
    stepsCount = 0;
    energyBurned = 0.0;
    heartRate = 0;
    weight = 0;
    height = 0;
    bloodPressureDiastolic = 0;
    super.initState();
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        _state = AppState.FETCHING_DATA;
      });

      /// Get everything from midnight until now
      DateTime endDate = DateTime.now();
//      DateTime startDate = DateTime(2020, 09, 01);
      DateTime now = new DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day); // current date from midnight

      print('Start Date: $startDate');
      HealthFactory health = HealthFactory();

      /// Define the types to get.
      List<HealthDataType> types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.HEART_RATE,
        HealthDataType.HEIGHT,
        HealthDataType.WEIGHT,
        HealthDataType.WATER,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
//        HealthDataType.SLEEP_IN_BED, // ONLY for IOS
//        HealthDataType.MINDFULNESS, // ONLY for IOS
      ];

      /// You can request types pre-emptively, if you want to
      /// which will make sure access is granted before the data is requested
//    bool granted = await health.requestAuthorization(types);

      /// Fetch new data
      List<HealthDataPoint> healthData =
//      await health.getHealthDataFromTypes(startDate, endDate, types);
          await health.getHealthDataFromTypes(startDate, endDate, types);

      /// Save all the new data points
      _healthDataList.addAll(healthData);

      /// Filter out duplicates
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      /// Print the results
      int localStepsCount = 0;
      double localEnergyCount = 0;
      int localHeartRate = 0;
      int localWeight = 0;
      double localHeight = 0;
      int localBloodPressureDiastolic = 0;
      int localBloodPressureSystolic = 0;
      print('Health Data List: ${_healthDataList}');
      _healthDataList.forEach((x) {
        print("Data point: ${x.toJson()}");
        if (x.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          print('Type of Energy: ${x.value.runtimeType}');
          if(x.value != null) {
            localEnergyCount += x.value;
          }
        }
        if (x.type == HealthDataType.STEPS) {
          print('Type of Steps: ${x.value.runtimeType}');
          localStepsCount += x.value;
        }
        if (x.type == HealthDataType.HEART_RATE) {
          print('Type of HeartRate: ${x.value.runtimeType}');
          print('HeartRate Value: ${x.value}');
          localHeartRate += x.value;
        }
        if (x.type == HealthDataType.WEIGHT) { //TODO: latest weight value only will come
          print('Type of Weight: ${x.value.runtimeType}');
          print('Weight Value: ${x.value}');
          localWeight = x.value.toInt();
        }
        if (x.type == HealthDataType.HEIGHT) { //TODO: latest height value only will come i think!
          print('Type of Height: ${x.value.runtimeType}');
          if(x.value != null) {
            print('Height Value: ${x.value}');
            localHeight = x.value;
          }
        }
        if (x.type == HealthDataType.BLOOD_PRESSURE_DIASTOLIC) {
          //TODO: Should take latest value
          if(x.value != null) {
            print('Type of Blood pressure diastolic: ${x.value.runtimeType}');
            print('Blood pressure diastolic Value: ${x.value}');
            localBloodPressureDiastolic = x.value.toInt();
          }
        }
        if (x.type == HealthDataType.BLOOD_PRESSURE_SYSTOLIC) {
          //TODO: Should take latest value
          if(x.value != null) {
            print('Type of Blood pressure systolic: ${x.value.runtimeType}');
            print('Blood pressure systolic Value: ${x.value}');
            localBloodPressureSystolic = x.value.toInt();
          }
        }

//        localStepsCount += x.value;
      });

      print('Total Steps today: Global -> $stepsCount, Local -> $localStepsCount');
      print('Total Energy burned today: Global -> $energyBurned, Local -> $localEnergyCount');
      print('HeartRate today: Global -> $heartRate, Local -> $localHeartRate');
      print('Weight today: Global -> $weight, Local -> $localWeight');
      print('Height today: Global -> $height, Local -> $localHeight');

      /// Update the UI to display the results
      setState(() {
        stepsCount = localStepsCount;
        energyBurned = localEnergyCount;
        heartRate = localHeartRate;
        weight = localWeight;
        height = localHeight;
        bloodPressureDiastolic = localBloodPressureDiastolic;
        bloodPressureSystolic = localBloodPressureSystolic;
        _state =
            _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
      });
    } catch (err) {
      print('Err=> $err');
    }
  }

  Widget _contentFetchingData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              strokeWidth: 2,
            )),
        Text('Fetching data...')
      ],
    );
  }

  Widget _contentDataReady() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            'Total Steps count today: $stepsCount',
            style: TextStyle(
                color: Colors.green,
                fontStyle: FontStyle.italic,
                fontSize: 16,
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.only(top: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            'Total Energy burned: $energyBurned',
            style: TextStyle(
                color: Colors.redAccent,
                fontStyle: FontStyle.italic,
                fontSize: 16,
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.only(top: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            'HeartRate: $heartRate Beats Per Minute',
            style: TextStyle(
                color: Colors.redAccent,
                fontStyle: FontStyle.italic,
                fontSize: 16,
            ),
          ),
        ),

        Container(
          margin: const EdgeInsets.only(top: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            'Weight: $weight KG',
            style: TextStyle(
                color: Colors.redAccent,
                fontStyle: FontStyle.italic,
                fontSize: 16),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            'Height: $height Mts',
            style: TextStyle(
                color: Colors.redAccent,
                fontStyle: FontStyle.italic,
                fontSize: 16),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 10),
          alignment: Alignment.centerLeft,
          child: Text(
            'Blood Pressure: $bloodPressureDiastolic / $bloodPressureSystolic ',
            style: TextStyle(
                color: Colors.redAccent,
                fontStyle: FontStyle.italic,
                fontSize: 16),
          ),
        ),

        Expanded(
          child: ListView.builder(
              itemCount: _healthDataList.length,
              shrinkWrap: true,
              itemBuilder: (_, index) {
                HealthDataPoint p = _healthDataList[index];
                return ListTile(
                  title: Text("${p.typeString}: ${p.value}"),
                  trailing: Text(
                    '${p.unitString}',
                    style: TextStyle(color: Colors.green),
                  ),
                  subtitle: Text(
                    '${p.dateFrom} - ${p.dateTo}',
                    style: TextStyle(color: Colors.blue),
                  ),
                );
              }),
        ),
      ],
    );
  }

  Widget _contentNoData() {
    return Text('No Data to show');
  }

  Widget _contentNotFetched() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RaisedButton(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          color: Colors.blue,
          onPressed: () {
            fetchData();
          },
          child: Text('Fetch Fitness Data', style: TextStyle(color: Colors.white),),
        ),
        Text('Press the download button to fetch data'),
      ],
    );
  }

  Widget _content() {
    if (_state == AppState.DATA_READY)
      return _contentDataReady();
    else if (_state == AppState.NO_DATA)
      return _contentNoData();
    else if (_state == AppState.FETCHING_DATA) return _contentFetchingData();

    return _contentNotFetched();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FitbitHome()
      /*home: Scaffold(
          appBar: AppBar(
            title: const Text('Fitness Data'),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  fetchData();
                },
              ),
            ],
          ),
          body: Center(
            child: _content(),
          )),*/
    );
  }
}

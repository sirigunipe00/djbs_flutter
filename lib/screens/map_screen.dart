import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/donor.dart';
import '../services/app_services.dart';
import '../strings.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.donors});

  final List<Donor> donors;

  @override
  Widget build(BuildContext context) {
    final you = LatLng(AppLocation.lat, AppLocation.lng);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('you'),
        position: you,
        infoWindow: const InfoWindow(title: 'Your Position'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
    for (var i = 0; i < donors.length; i++) {
      final donor = donors[i];
      final lat = double.tryParse(donor.lat);
      final lng = double.tryParse(donor.lan);
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('donor_$i'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: '${donor.name} ${donor.mobileNumber}'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(s('title_activity_maps'))),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: you, zoom: 15),
        markers: markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}

class Donor {

  factory Donor.fromMap(Map<dynamic, dynamic> data) {
    String read(String key) => data[key]?.toString() ?? '';
    return Donor(
      name: read('name'),
      mobileNumber: read('mobileNumber'),
      bloodGroup: read('bloodGroup'),
      city: read('city'),
      lat: read('lat'),
      lan: read('lan'),
      adhar: read('adhar'),
      email: read('email'),
    );
  }
  Donor({
    required this.name,
    required this.mobileNumber,
    required this.bloodGroup,
    required this.city,
    required this.lat,
    required this.lan,
    this.adhar = '',
    this.email = '',
  });

  final String name;
  final String mobileNumber;
  final String bloodGroup;
  final String city;
  final String lat;
  final String lan;
  final String adhar;
  final String email;

  Map<String, String> toMap() => {
        'name': name,
        'mobileNumber': mobileNumber,
        'bloodGroup': bloodGroup,
        'city': city,
        'lat': lat,
        'lan': lan,
        'adhar': adhar,
        if (email.isNotEmpty) 'email': email,
      };
}

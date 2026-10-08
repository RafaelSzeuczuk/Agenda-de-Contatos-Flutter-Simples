const String idColumn = 'idColumn';
const String nameColumn = 'nameColumn';
const String emailColumn = 'emailColumn';
const String phoneColumn = 'phoneColumn';
const String imgColumn = 'imgColumn';
const String cepColumn = 'cepColumn';
const String addressColumn = 'addressColumn';
const String numberColumn = 'numberColumn';
const String complementColumn = 'complementColumn';
const String neighborhoodColumn = 'neighborhoodColumn';
const String cityColumn = 'cityColumn';
const String stateColumn = 'stateColumn';
const String contactTable = 'contactTable';

class Contact {
  Contact({
    required this.name,
    required this.email,
    required this.phone,
    this.img,
    this.cep,
    this.address,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.id,
  });

  int? id;
  String name;
  String email;
  String phone;
  String? img;
  String? cep;
  String? address;
  String? number;
  String? complement;
  String? neighborhood;
  String? city;
  String? state;

  Contact.fromMap(Map<String, dynamic> map)
    : id = map[idColumn] as int?,
      name = map[nameColumn] as String? ?? '',
      email = map[emailColumn] as String? ?? '',
      phone = map[phoneColumn] as String? ?? '',
      img = map[imgColumn] as String?,
      cep = map[cepColumn] as String?,
      address = map[addressColumn] as String?,
      number = map[numberColumn] as String?,
      complement = map[complementColumn] as String?,
      neighborhood = map[neighborhoodColumn] as String?,
      city = map[cityColumn] as String?,
      state = map[stateColumn] as String?;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      nameColumn: name,
      emailColumn: email,
      phoneColumn: phone,
      imgColumn: img,
      cepColumn: cep,
      addressColumn: address,
      numberColumn: number,
      complementColumn: complement,
      neighborhoodColumn: neighborhood,
      cityColumn: city,
      stateColumn: state,
    };
    if (id != null) {
      map[idColumn] = id;
    }
    return map;
  }

  @override
  String toString() =>
      'Contact(id: $id, name: $name, email: $email, phone: $phone, '
      'cep: $cep, address: $address, number: $number)';
}

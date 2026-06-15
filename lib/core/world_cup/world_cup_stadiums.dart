/// Static World Cup 2026 stadium dataset (no backend required).

class WorldCupStadium {

  const WorldCupStadium({

    required this.id,

    required this.name,

    required this.city,

    required this.country,

    required this.capacity,

    this.surface = 'Grass',

    this.accentColor = 0xFF0B5E4A,

    this.assetFileName,

  });



  final String id;

  final String name;

  final String city;

  final String country;

  final int capacity;

  final String surface;

  final int accentColor;



  /// Optional bundled photo under `assets/stadiums/` — only used when verified.

  final String? assetFileName;



  /// Verified local photos approved for production (empty until real assets added).

  static const verifiedAssetIds = <String>{};



  bool get hasVerifiedBundledPhoto =>

      assetFileName != null && verifiedAssetIds.contains(id);



  String? get assetPath => hasVerifiedBundledPhoto

      ? 'assets/stadiums/$assetFileName'

      : null;



  static WorldCupStadium? byId(String id) {

    for (final v in WorldCupStadiums.venues) {

      if (v.id == id) return v;

    }

    return null;

  }

}



class WorldCupStadiums {

  WorldCupStadiums._();



  static const venues = [

    WorldCupStadium(

      id: 'metlife',

      name: 'MetLife Stadium',

      city: 'East Rutherford',

      country: 'USA',

      capacity: 82500,

      accentColor: 0xFF1A3A6B,

    ),

    WorldCupStadium(

      id: 'att',

      name: 'AT&T Stadium',

      city: 'Arlington',

      country: 'USA',

      capacity: 80000,

      accentColor: 0xFF003594,

    ),

    WorldCupStadium(

      id: 'sofi',

      name: 'SoFi Stadium',

      city: 'Inglewood',

      country: 'USA',

      capacity: 70240,

      accentColor: 0xFF0080C8,

    ),

    WorldCupStadium(

      id: 'mercedes',

      name: 'Mercedes-Benz Stadium',

      city: 'Atlanta',

      country: 'USA',

      capacity: 71000,

      accentColor: 0xFF8B0000,

    ),

    WorldCupStadium(

      id: 'hard_rock',

      name: 'Hard Rock Stadium',

      city: 'Miami Gardens',

      country: 'USA',

      capacity: 65326,

      accentColor: 0xFF008E97,

    ),

    WorldCupStadium(

      id: 'nrg',

      name: 'NRG Stadium',

      city: 'Houston',

      country: 'USA',

      capacity: 72220,

      accentColor: 0xFF03202F,

    ),

    WorldCupStadium(

      id: 'lincoln',

      name: 'Lincoln Financial Field',

      city: 'Philadelphia',

      country: 'USA',

      capacity: 69796,

      accentColor: 0xFF004C54,

    ),

    WorldCupStadium(

      id: 'levis',

      name: 'Levi\'s Stadium',

      city: 'Santa Clara',

      country: 'USA',

      capacity: 68500,

      accentColor: 0xFFAA0000,

    ),

    WorldCupStadium(

      id: 'lumen',

      name: 'Lumen Field',

      city: 'Seattle',

      country: 'USA',

      capacity: 68740,

      accentColor: 0xFF002244,

    ),

    WorldCupStadium(

      id: 'arrowhead',

      name: 'Arrowhead Stadium',

      city: 'Kansas City',

      country: 'USA',

      capacity: 76416,

      accentColor: 0xFFE31837,

    ),

    WorldCupStadium(

      id: 'gillette',

      name: 'Gillette Stadium',

      city: 'Foxborough',

      country: 'USA',

      capacity: 65878,

      accentColor: 0xFF002244,

    ),

    WorldCupStadium(

      id: 'bmo',

      name: 'BMO Field',

      city: 'Toronto',

      country: 'Canada',

      capacity: 45000,

      accentColor: 0xFFCE1141,

    ),

    WorldCupStadium(

      id: 'bc_place',

      name: 'BC Place',

      city: 'Vancouver',

      country: 'Canada',

      capacity: 54500,

      accentColor: 0xFF00205B,

    ),

    WorldCupStadium(

      id: 'azteca',

      name: 'Estadio Azteca',

      city: 'Mexico City',

      country: 'Mexico',

      capacity: 87523,

      accentColor: 0xFF006847,

    ),

    WorldCupStadium(

      id: 'akron',

      name: 'Estadio Akron',

      city: 'Guadalajara',

      country: 'Mexico',

      capacity: 49850,

      accentColor: 0xFF8B0000,

    ),

    WorldCupStadium(

      id: 'bbva',

      name: 'Estadio BBVA',

      city: 'Monterrey',

      country: 'Mexico',

      capacity: 53500,

      accentColor: 0xFF004B87,

    ),

  ];



  static int matchCountFor(String stadiumName, Iterable<String> matchVenues) {

    final normalized = stadiumName.toLowerCase();

    return matchVenues.where((v) {

      final venue = v.toLowerCase();

      return venue.contains(normalized) ||

          normalized.contains(venue.split(' ').first);

    }).length;

  }

}



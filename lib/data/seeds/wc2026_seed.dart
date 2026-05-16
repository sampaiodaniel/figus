/// Seed data for the FIFA World Cup 2026 album.
///
/// 980 stickers total: FWC00 (logo Panini foil) + FWC1–FWC8 (intro) +
/// FWC9–FWC19 (Legends) + 48 nations × 20 stickers.
///
/// Order of nations and player names per nation are factual data taken
/// from the public FIFA WC 2026 squads (Panini Adrenalyn XL checklist).
library;

class SeedNation {
  final String code;
  final String name;
  final String flag;
  final String? group;
  final int orderInAlbum;
  const SeedNation({
    required this.code,
    required this.name,
    required this.flag,
    required this.orderInAlbum,
    this.group,
  });
}

class SeedSticker {
  final String number;
  final String? nationCode;
  final String type; // crest | team_photo | player | intro | legend | logo
  final bool isFoil;
  final int pageNumber;
  final int positionInPage;
  final String label;
  final String? playerName;
  const SeedSticker({
    required this.number,
    required this.nationCode,
    required this.type,
    required this.isFoil,
    required this.pageNumber,
    required this.positionInPage,
    required this.label,
    this.playerName,
  });
}

class WC2026Seed {
  static const albumCode = 'WC2026';
  static const albumName = 'Copa do Mundo FIFA 2026';
  static const albumYear = 2026;

  /// Nation order matches the printed Panini album sequence.
  static final List<SeedNation> nations = _buildNations();

  static final List<SeedSticker> stickers = _buildStickers();

  static List<SeedNation> _buildNations() {
    // [code, pt-BR name, flag emoji]
    final raw = <List<String>>[
      ['MEX', 'México', '🇲🇽'],
      ['RSA', 'África do Sul', '🇿🇦'],
      ['KOR', 'Coreia do Sul', '🇰🇷'],
      ['CZE', 'Tchéquia', '🇨🇿'],
      ['CAN', 'Canadá', '🇨🇦'],
      ['BIH', 'Bósnia e Herzegovina', '🇧🇦'],
      ['QAT', 'Catar', '🇶🇦'],
      ['SUI', 'Suíça', '🇨🇭'],
      ['BRA', 'Brasil', '🇧🇷'],
      ['MAR', 'Marrocos', '🇲🇦'],
      ['HAI', 'Haiti', '🇭🇹'],
      ['SCO', 'Escócia', '🏴󠁧󠁢󠁳󠁣󠁴󠁿'],
      ['USA', 'Estados Unidos', '🇺🇸'],
      ['PAR', 'Paraguai', '🇵🇾'],
      ['AUS', 'Austrália', '🇦🇺'],
      ['TUR', 'Turquia', '🇹🇷'],
      ['GER', 'Alemanha', '🇩🇪'],
      ['CUW', 'Curaçao', '🇨🇼'],
      ['CIV', 'Costa do Marfim', '🇨🇮'],
      ['ECU', 'Equador', '🇪🇨'],
      ['NED', 'Holanda', '🇳🇱'],
      ['JPN', 'Japão', '🇯🇵'],
      ['SWE', 'Suécia', '🇸🇪'],
      ['TUN', 'Tunísia', '🇹🇳'],
      ['BEL', 'Bélgica', '🇧🇪'],
      ['EGY', 'Egito', '🇪🇬'],
      ['IRN', 'Irã', '🇮🇷'],
      ['NZL', 'Nova Zelândia', '🇳🇿'],
      ['ESP', 'Espanha', '🇪🇸'],
      ['CPV', 'Cabo Verde', '🇨🇻'],
      ['KSA', 'Arábia Saudita', '🇸🇦'],
      ['URU', 'Uruguai', '🇺🇾'],
      ['FRA', 'França', '🇫🇷'],
      ['SEN', 'Senegal', '🇸🇳'],
      ['IRQ', 'Iraque', '🇮🇶'],
      ['NOR', 'Noruega', '🇳🇴'],
      ['ARG', 'Argentina', '🇦🇷'],
      ['ALG', 'Argélia', '🇩🇿'],
      ['AUT', 'Áustria', '🇦🇹'],
      ['JOR', 'Jordânia', '🇯🇴'],
      ['POR', 'Portugal', '🇵🇹'],
      ['COD', 'RD Congo', '🇨🇩'],
      ['UZB', 'Uzbequistão', '🇺🇿'],
      ['COL', 'Colômbia', '🇨🇴'],
      ['ENG', 'Inglaterra', '🏴󠁧󠁢󠁥󠁮󠁧󠁿'],
      ['CRO', 'Croácia', '🇭🇷'],
      ['GHA', 'Gana', '🇬🇭'],
      ['PAN', 'Panamá', '🇵🇦'],
    ];
    return [
      for (var i = 0; i < raw.length; i++)
        SeedNation(
          code: raw[i][0],
          name: raw[i][1],
          flag: raw[i][2],
          orderInAlbum: i,
        ),
    ];
  }

  /// Factual squad names per nation, sourced from the public Panini
  /// Adrenalyn XL FIFA WC 2026 checklist. Position 1 = team crest (no name);
  /// positions 2..12 hold the 11 player names from the checklist; positions
  /// 13 = team photo (no name); 14..20 left empty for the user to fill in
  /// once the full album roster is published.
  static const Map<String, List<String>> playerNames = {
    'MEX': [
      'Edson Álvarez', 'Raúl Jiménez', 'Luis Malagón', 'Israel Reyes',
      'Johan Vásquez', 'César Montes', 'Jesús Gallardo', 'Carlos Rodríguez',
      'Orbelín Pineda', 'Hirving Lozano', 'Santiago Giménez',
    ],
    'KOR': [
      'Min-Jae Kim', 'Heung-Min Son', 'Hyeon-Woo Jo', 'Young-Woo Seol',
      'Yumin Cho', 'Tae-Seok Lee', 'In-Seon Hwang', 'Jae-Sung Lee',
      'Kang-In Lee', 'Hyeon-Gyu Oh', 'Hee-Chan Hwang',
    ],
    'CAN': [
      'Jonathan David', 'Alphonso Davies', 'Dayne St. Clair', 'Richie Laryea',
      'Derek Cornelius', 'Stephen Eustáquio', 'Ismaël Koné', 'Jonathan Osorio',
      'Jacob Shaffelburg', 'Tajon Buchanan', 'Cyle Larin',
    ],
    'QAT': [
      'Almoez Ali', 'Hassan Al-Haydos', 'Meshaal Barsham', 'Boualem Khoukhi',
      'Lucas Mendes', 'Pedro Miguel', 'Homam Al-Amin', 'Ahmed Fathi',
      'Edmilson Junior', 'Ahmed Al-Ganehi', 'Akram Hassan Afif',
    ],
    'SUI': [
      'Manuel Akanji', 'Granit Xhaka', 'Gregor Kobel', 'Nico Elvedi',
      'Ricardo Rodríguez', 'Silvan Widmer', 'Remo Freuler', 'Breel Embolo',
      'Rubén Vargas', 'Dan Ndoye', 'Manuel Akanji',
    ],
    'BRA': [
      'Marquinhos', 'Vinícius Júnior', 'Alisson', 'Danilo',
      'Éder Militão', 'Gabriel Magalhães', 'Casemiro', 'Bruno Guimarães',
      'Rodrygo', 'Matheus Cunha', 'Raphinha',
    ],
    'MAR': [
      'Achraf Hakimi', 'Yassine Bounou', 'Noussair Mazraoui', 'Nayef Aguerd',
      'Sofyan Amrabat', 'Eliesse Ben Seghir', 'Ismael Saibari', 'Brahim Díaz',
      'Abde Ezzalzouli', 'Ayoub El Kaabi', 'Munir El Kajoui',
    ],
    'HAI': [
      'Frantzdy Perrot', 'Duckens Nazon', 'Johnny Placide', 'Ricardo Adé',
      'Carlens Arcus', 'Hannes Delcroix', 'Leverton Pierre', 'Danley Jean Jacques',
      'Jean-Ricner Bellegarde', 'Ruben Providence', 'Don Deedson Louicius',
    ],
    'SCO': [
      'Scott McTominay', 'Andrew Robertson', 'Angus Gunn', 'Kieran Tierney',
      'Grant Hanley', 'Billy Gilmour', 'Lewis Ferguson', 'Ryan Christie',
      'John McGinn', 'Ben Gannon-Doak', 'Ché Adams',
    ],
    'USA': [
      'Weston McKennie', 'Christian Pulisic', 'Matt Freese', 'Chris Richards',
      'Tim Ream', 'Antonee Robinson', 'Tanner Tessmann', 'Tyler Adams',
      'Timothy Weah', 'Malik Tillman', 'Folarin Balogun',
    ],
    'PAR': [
      'Gustavo Gómez', 'Miguel Almirón', 'Roberto Fernández', 'Juan José Cáceres',
      'Moussa Niakhaté', 'El Hadji Malick Diouf', 'Idrissa Gana Gueye', 'Pape Matar Sarr',
      'Mathías Villasanti', 'Julio Enciso', 'Ramón Sosa',
    ],
    'AUS': [
      'Harry Souttar', 'Mathew Ryan', 'Alessandro Circati', 'Jordan Bos',
      'Lewis Miller', 'Milos Degenek', 'Jackson Irvine', 'Riley McGree',
      'Aiden O\'Neill', 'Connor Metcalfe', 'Craig Goodwin',
    ],
    'GER': [
      'Jamal Musiala', 'Joshua Kimmich', 'Marc-André ter Stegen', 'Antonio Rüdiger',
      'Jonathan Tah', 'Felix Nmecha', 'Florian Wirtz', 'Serge Gnabry',
      'Kai Havertz', 'Leroy Sané', 'Niclas Füllkrug',
    ],
    'CUW': [
      'Jurién Gaari', 'Leandro Bacuna', 'Eloy Room', 'Sherel Floranus',
      'Roshon van Eijma', 'Armando Obispo', 'Livano Comenencia', 'Juninho Bacuna',
      'Kenji Gorré', 'Sontje Hansen', 'Jearl Margaritha',
    ],
    'CIV': [
      'Franck Kessié', 'Sébastien Haller', 'Yahia Fofana', 'Ghislain Konan',
      'Odilon Kossounou', 'Evann N\'Dicka', 'Wilfried Singo', 'Ibrahim Sangaré',
      'Nicolas Pépé', 'Simon Adingra', 'Yan Diomandé',
    ],
    'ECU': [
      'Moisés Caicedo', 'Enner Valencia', 'Hernán Galíndez', 'Piero Hincapié',
      'Pervis Estupiñán', 'Willian Pacho', 'Ángelo Preciado', 'Joel Ordóñez',
      'Alan Franco', 'Gonzalo Plata', 'Kendry Páez',
    ],
    'NED': [
      'Memphis Depay', 'Virgil van Dijk', 'Bart Verbruggen', 'Nathan Aké',
      'Jeremie Frimpong', 'Denzel Dumfries', 'Tijjani Reijnders', 'Ryan Gravenberch',
      'Cody Gakpo', 'Donyell Malen', 'Wout Weghorst',
    ],
    'JPN': [
      'Takumi Minamino', 'Takefusa Kubo', 'Zion Suzuki', 'Tsuyoshi Watanabe',
      'Kaishu Sano', 'Ao Tanaka', 'Daichi Kamada', 'Ritsu Doan',
      'Keito Nakamura', 'Shuto Machino', 'Ayase Ueda',
    ],
    'BEL': [
      'Youri Tielemans', 'Kevin De Bruyne', 'Thibaut Courtois', 'Arthur Theate',
      'Timothy Castagne', 'Maxim De Cuyper', 'Amadou Onana', 'Jérémy Doku',
      'Charles De Ketelaere', 'Leandro Trossard', 'Romelu Lukaku',
    ],
    'EGY': [
      'Omar Marmoush', 'Mohamed Salah', 'Mohamed El Shenawy', 'Mohamed Hany',
      'Mohamed Abdelmonem', 'Ramy Rabia', 'Marwan Attia', 'Zizo',
      'Hamdy Fathy', 'Mostafa Mohamed', 'Trézéguet',
    ],
    'IRN': [
      'Mehdi Taremi', 'Sardar Azmoun', 'Alireza Beiranvand', 'Shoja Khalilzadeh',
      'Milad Mohammadi', 'Ramin Rezaeian', 'Hossein Kanaani', 'Saeid Ezatolahi',
      'Samaan Ghoddos', 'Mohammad Mohebi', 'Alireza Jahanbakhsh',
    ],
    'NZL': [
      'Marko Stamenic', 'Chris Wood', 'Max Crocombe', 'Michael Boxall',
      'Liberato Cacace', 'Tim Payne', 'Finn Surman', 'Cody Gordon',
      'Matt Garbett', 'Elijah Just', 'Marko Stamenic',
    ],
    'ESP': [
      'Lamine Yamal', 'Rodri', 'Unai Simón', 'Robin Le Normand',
      'Dean Huijsen', 'Marc Cucurella', 'Martín Zubimendi', 'Pedri',
      'Fabián Ruiz', 'Nico Williams', 'Mikel Oyarzabal',
    ],
    'CPV': [
      'Vozinha', 'Ryan Mendes', 'Logan Costa', 'Pico',
      'Steven Moreira', 'João Paulo', 'Kevyn Pina', 'Jamiro Monteiro',
      'Yannick Semedo', 'Jovane Cabral', 'Dailon Livramento',
    ],
    'KSA': [
      'Feras Albrikan', 'Salem Aldawsari', 'Nawaf Alaqidi', 'Hassan Altambakti',
      'Jehad Thekri', 'Saud Abdulhamid', 'Nasser Aldawsari', 'Abdullah Alhaibari',
      'Mussab Aljuwayr', 'Saleh Abu Al Shamat', 'Saleh Alsherri',
    ],
    'URU': [
      'José María Giménez', 'Federico Valverde', 'Sergio Rochet', 'Ronald Araújo',
      'Sebastián Cáceres', 'Mathías Olivera', 'Nahitan Nández', 'Rodrigo Bentancur',
      'Manuel Ugarte', 'Facundo Pellistri', 'Darwin Núñez',
    ],
    'FRA': [
      'Ousmane Dembélé', 'Kylian Mbappé', 'Mike Maignan', 'William Saliba',
      'Jules Koundé', 'Théo Hernández', 'Aurélien Tchouaméni', 'Eduardo Camavinga',
      'Bradley Barcola', 'Marcus Thuram', 'Randal Kolo Muani',
    ],
    'SEN': [
      'Kalidou Koulibaly', 'Sadio Mané', 'Edouard Mendy', 'Moussa Niakhaté',
      'El Hadji Malick Diouf', 'Idrissa Gana Gueye', 'Pape Matar Sarr', 'Ilman Ndiaye',
      'Krépin Diatta', 'Ismaïla Sarr', 'Nicolas Jackson',
    ],
    'NOR': [
      'Martin Ødegaard', 'Erling Haaland', 'Ørjan Nyland', 'Julian Ryerson',
      'Kristoffer Vassbakk Ajer', 'David Møller Wolfe', 'Sander Berge', 'Patrick Berg',
      'Antonio Nusa', 'Oscar Bobb', 'Alexander Sørloth',
    ],
    'ARG': [
      'Julián Álvarez', 'Lionel Messi', 'Emiliano Martínez', 'Nahuel Molina',
      'Cristian Romero', 'Nicolás Otamendi', 'Enzo Fernández', 'Alexis Mac Allister',
      'Rodrigo De Paul', 'Giuliano Simeone', 'Lautaro Martínez',
    ],
    'ALG': [
      'Rayan Aït-Nouri', 'Riyad Mahrez', 'Alexis Guendouz', 'Ramy Bensebaini',
      'Youcef Atal', 'Aïssa Mandi', 'Nabil Bentaleb', 'Saïd Benrahma',
      'Amine Gouiri', 'Mohamed Amoura', 'Baghdad Bounedjah',
    ],
    'AUT': [
      'Marko Arnautović', 'David Alaba', 'Alexander Schlager', 'Kevin Danso',
      'Philipp Lienhart', 'Konrad Laimer', 'Nicolas Seiwald', 'Marcel Sabitzer',
      'Florian Grillitsch', 'Christoph Baumgartner', 'Michael Gregoritsch',
    ],
    'JOR': [
      'Yazan Al-Naimat', 'Musa Al-Taamari', 'Yazeed Abulaila', 'Mohammad Abu Hashish',
      'Yazan Al-Arab', 'Abdallah Nasib', 'Ibrahim Saadeh', 'Nizar Al-Rashdan',
      'Noor Al-Rawabdeh', 'Mahmoud Al-Mardi', 'Ali Olwan',
    ],
    'POR': [
      'Vitinha', 'Cristiano Ronaldo', 'Diogo Costa', 'Rúben Dias',
      'Nuno Mendes', 'Bernardo Silva', 'Bruno Fernandes', 'Rúben Neves',
      'Francisco Conceição', 'Pedro Neto', 'Rafael Leão',
    ],
    'COL': [
      'Luis Díaz', 'James Rodríguez', 'Camilo Vargas', 'Dávinson Sánchez',
      'Yerry Mina', 'Daniel Muñoz', 'Jefferson Lerma', 'Richard Ríos',
      'Juan Fernando Quintero', 'Jhon Arias', 'Luis Suárez',
    ],
    'ENG': [
      'Jude Bellingham', 'Harry Kane', 'Jordan Pickford', 'Reece James',
      'John Stones', 'Declan Rice', 'Jordan Henderson', 'Phil Foden',
      'Bukayo Saka', 'Cole Palmer', 'Marcus Rashford',
    ],
    'CRO': [
      'Ivan Perišić', 'Luka Modrić', 'Dominik Livaković', 'Duje Caleta-Car',
      'Josip Stanišić', 'Mateo Kovačić', 'Lovro Majer', 'Mario Pašalić',
      'Ante Budimir', 'Andrej Kramarić', 'Joško Gvardiol',
    ],
    'GHA': [
      'Thomas Partey', 'Mohammed Kudus', 'Lawrence Ati Zigi', 'Alidu Sedu',
      'Alexander Djiku', 'Gideon Mensah', 'Caleb Yirenkyi', 'Abdul Fatawu Issahaku',
      'Kamaldeen Sulemana', 'Jordan Ayew', 'Antoine Semenyo',
    ],
  };

  static List<SeedSticker> _buildStickers() {
    final list = <SeedSticker>[];

    list.add(const SeedSticker(
      number: 'FWC00',
      nationCode: null,
      type: 'logo',
      isFoil: true,
      pageNumber: 0,
      positionInPage: 0,
      label: 'Logo Panini',
    ));

    const intro = [
      'Emblema FIFA WC 2026',
      'Mascote Maple',
      'Mascote Zayu',
      'Mascote Clutch',
      'Slogan oficial',
      'Bola oficial',
      'Cidades-sede CAN',
      'Cidades-sede MEX/USA',
    ];
    for (var i = 0; i < 8; i++) {
      list.add(SeedSticker(
        number: 'FWC${i + 1}',
        nationCode: null,
        type: 'intro',
        isFoil: false,
        pageNumber: 0,
        positionInPage: i + 1,
        label: intro[i],
      ));
    }

    const legends = [
      'Itália 1934',
      'Itália 1938',
      'Uruguai 1950',
      'Alemanha 1954',
      'Brasil 1958',
      'Brasil 1962',
      'Inglaterra 1966',
      'Brasil 1970',
      'Alemanha 1974',
      'Argentina 1978',
      'Argentina 2022',
    ];
    for (var i = 0; i < 11; i++) {
      list.add(SeedSticker(
        number: 'FWC${9 + i}',
        nationCode: null,
        type: 'legend',
        isFoil: true,
        pageNumber: 100, // sits AFTER the nations in display order
        positionInPage: i,
        label: legends[i],
      ));
    }

    // Coca-Cola section (CC) — 14 stickers (4 blocks of 3 + 1 block of 2).
    const ccLabels = [
      'Coca-Cola × FIFA WC 2026',
      'Celebração',
      'Torcedores',
      'Momentos',
      'Estádios',
      'Gols históricos',
      'Heróis da Copa',
      'Troféu',
      'Próxima Copa',
      'Fan Zone',
      'Família',
      'Copo Colecionável',
      'Mascote',
      'Brinde',
    ];
    for (var i = 0; i < ccLabels.length; i++) {
      list.add(SeedSticker(
        number: 'CC${i + 1}',
        nationCode: null,
        type: 'intro',
        isFoil: false,
        pageNumber: 200, // after FWC9+ (100) — always last section
        positionInPage: i,
        label: ccLabels[i],
      ));
    }

    // Legendary cards — 16 players × 4 rarities (Bronze, Prata, Ouro, Diamante)
    const lgdPlayers = [
      'Cristiano Ronaldo', 'Moisés Caicedo', 'Luis Díaz', 'Erling Haaland',
      'Lionel Messi', 'Lamine Yamal', 'Raúl Jiménez', 'Kylian Mbapé',
      'Vinícius Júnior', 'Jérémy Doku', 'Christian Pulisic', 'Mohamed Salah',
      'Jude Bellingham', 'Achraf Hakimi', 'Florian Wirtz', 'Neymar Jr',
    ];
    const lgdRarityLabels = ['Bronze', 'Prata', 'Ouro', 'Diamante'];
    const lgdRarityTypes = [
      'legendary_bronze', 'legendary_prata', 'legendary_ouro', 'legendary_diamante'
    ];
    var lgdPos = 0;
    for (var p = 0; p < lgdPlayers.length; p++) {
      for (var r = 0; r < lgdRarityLabels.length; r++) {
        list.add(SeedSticker(
          number: 'LGD${(lgdPos + 1).toString().padLeft(2, '0')}',
          nationCode: null,
          type: lgdRarityTypes[r],
          isFoil: false,
          pageNumber: 300,
          positionInPage: lgdPos,
          label: lgdRarityLabels[r],
          playerName: lgdPlayers[p],
        ));
        lgdPos++;
      }
    }

    // 48 nations × 20 stickers
    for (final nation in nations) {
      final pageNum = nation.orderInAlbum + 2;
      final names = playerNames[nation.code];
      for (var i = 1; i <= 20; i++) {
        String type;
        bool isFoil = false;
        String label;
        String? name;
        if (i == 1) {
          type = 'crest';
          isFoil = true;
          label = 'Escudo';
        } else if (i == 13) {
          type = 'team_photo';
          label = 'Equipe';
        } else {
          type = 'player';
          label = '';
          // Map sticker positions to roster: BRA2..BRA12 → names[0..10],
          // BRA14..BRA20 left empty (Adrenalyn checklist only carries 11
          // names per team; the album holds 18 player slots).
          if (names != null) {
            final rosterIdx = i <= 12 ? (i - 2) : -1;
            if (rosterIdx >= 0 && rosterIdx < names.length) {
              name = names[rosterIdx];
            }
          }
        }
        list.add(SeedSticker(
          number: '${nation.code}$i',
          nationCode: nation.code,
          type: type,
          isFoil: isFoil,
          pageNumber: pageNum,
          positionInPage: i - 1,
          label: label,
          playerName: name,
        ));
      }
    }

    return list;
  }
}

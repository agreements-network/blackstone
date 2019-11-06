pragma solidity ^0.5;

import "commons-standards/IsoCountries.sol";
    
//** Country: https://en.wikipedia.org/wiki/ISO_3166-1
//** Regions: https://en.wikipedia.org/wiki/ISO_3166-2

contract IsoCountries100 is VersionLinkedAppendOnly([1,0,0]), IsoCountries {
    // Country keys are held as dedicated bytes2 values. 
    // The key matches the ISO 3166-1 Alpha2 code of the country.
    // The key will also match the country code of the region struct.
    // This key is to be used by other contracts as the primary key to reference the country.
    // Region keys are hashes of the country key and bytes3 region code

    /**
    * @dev Constructor
    */
    constructor() public {
        /** AFGHANISTAN INITIALIZATION */
        registerCountry("AF", "AFG", "4", "Afghanistan");

        /** ÅLAND ISLANDS INITIALIZATION */
        registerCountry("AX", "ALA", "248", "Åland Islands");

        /** ALBANIA INITIALIZATION */
        registerCountry("AL", "ALB", "8", "Albania");

        /** ALGERIA INITIALIZATION */
        registerCountry("DZ", "DZA", "12", "Algeria");

        /** AMERICAN SAMOA INITIALIZATION */
        registerCountry("AS", "ASM", "16", "American Samoa");

        /** ANDORRA INITIALIZATION */
        registerCountry("AD", "AND", "20", "Andorra");

        /** ANGOLA INITIALIZATION */
        registerCountry("AO", "AGO", "24", "Angola");

        /** ANGUILLA INITIALIZATION */
        registerCountry("AI", "AIA", "660", "Anguilla");

        /** ANTARCTICA INITIALIZATION */
        registerCountry("AQ", "ATA", "10", "Antarctica");

        /** ANTIGUA AND BARBUDA INITIALIZATION */
        registerCountry("AG", "ATG", "28", "Antigua and Barbuda");

        /** ARGENTINA INITIALIZATION */
        registerCountry("AR", "ARG", "32", "Argentina");

        /** ARMENIA INITIALIZATION */
        registerCountry("AM", "ARM", "51", "Armenia");

        /** ARUBA INITIALIZATION */
        registerCountry("AW", "ABW", "533", "Aruba");

        /** AUSTRALIA INITIALIZATION */
        registerCountry("AU", "AUS", "36", "Australia");
        /** AUSTRIA INITIALIZATION */
        registerCountry("AT", "AUT", "40", "Austria");

        /** AZERBAIJAN INITIALIZATION */
        registerCountry("AZ", "AZE", "31", "Azerbaijan");

        /** BAHAMAS INITIALIZATION */
        registerCountry("BS", "BHS", "44", "Bahamas");

        /** BAHRAIN INITIALIZATION */
        registerCountry("BH", "BHR", "48", "Bahrain");

        /** BANGLADESH INITIALIZATION */
        registerCountry("BD", "BGD", "50", "Bangladesh");

        /** BARBADOS INITIALIZATION */
        registerCountry("BB", "BRB", "52", "Barbados");

        /** BELARUS INITIALIZATION */
        registerCountry("BY", "BLR", "112", "Belarus");

        /** BELGIUM INITIALIZATION */
        registerCountry("BE", "BEL", "56", "Belgium");

        /** BELIZE INITIALIZATION */
        registerCountry("BZ", "BLZ", "84", "Belize");

        /** BENIN INITIALIZATION */
        registerCountry("BJ", "BEN", "204", "Benin");

        /** BERMUDA INITIALIZATION */
        registerCountry("BM", "BMU", "60", "Bermuda");

        /** BHUTAN INITIALIZATION */
        registerCountry("BT", "BTN", "64", "Bhutan");

        /** BOLIVIA (PLURINATIONAL STATE OF) INITIALIZATION */
        registerCountry("BO", "BOL", "68", "Bolivia (Plurinational State of)");

        /** BONAIRE, SINT EUSTATIUS AND SABA INITIALIZATION */
        registerCountry("BQ", "BES", "535", "Bonaire, Sint Eustatius and Saba");

        /** BOSNIA AND HERZEGOVINA INITIALIZATION */
        registerCountry("BA", "BIH", "70", "Bosnia and Herzegovina");

        /** BOTSWANA INITIALIZATION */
        registerCountry("BW", "BWA", "72", "Botswana");

        /** BOUVET ISLAND INITIALIZATION */
        registerCountry("BV", "BVT", "74", "Bouvet Island");

        /** BRAZIL INITIALIZATION */
        registerCountry("BR", "BRA", "76", "Brazil");
        /** BRITISH INDIAN OCEAN TERRITORY INITIALIZATION */
        registerCountry("IO", "IOT", "86", "British Indian Ocean Territory");

        /** BRUNEI DARUSSALAM INITIALIZATION */
        registerCountry("BN", "BRN", "96", "Brunei Darussalam");

        /** BULGARIA INITIALIZATION */
        registerCountry("BG", "BGR", "100", "Bulgaria");

        /** BURKINA FASO INITIALIZATION */
        registerCountry("BF", "BFA", "854", "Burkina Faso");

        /** BURUNDI INITIALIZATION */
        registerCountry("BI", "BDI", "108", "Burundi");

        /** CABO VERDE INITIALIZATION */
        registerCountry("CV", "CPV", "132", "Cabo Verde");

        /** CAMBODIA INITIALIZATION */
        registerCountry("KH", "KHM", "116", "Cambodia");

        /** CAMEROON INITIALIZATION */
        registerCountry("CM", "CMR", "120", "Cameroon");

        /** CANADA INITIALIZATION */
        registerCountry("CA", "CAN", "124", "Canada");
        /** CAYMAN ISLANDS INITIALIZATION */
        registerCountry("KY", "CYM", "136", "Cayman Islands");

        /** CENTRAL AFRICAN REPUBLIC INITIALIZATION */
        registerCountry("CF", "CAF", "140", "Central African Republic");

        /** CHAD INITIALIZATION */
        registerCountry("TD", "TCD", "148", "Chad");

        /** CHILE INITIALIZATION */
        registerCountry("CL", "CHL", "152", "Chile");

        /** CHINA INITIALIZATION */
        registerCountry("CN", "CHN", "156", "China");

        /** CHRISTMAS ISLAND INITIALIZATION */
        registerCountry("CX", "CXR", "162", "Christmas Island");

        /** COCOS (KEELING) ISLANDS INITIALIZATION */
        registerCountry("CC", "CCK", "166", "Cocos (Keeling) Islands");

        /** COLOMBIA INITIALIZATION */
        registerCountry("CO", "COL", "170", "Colombia");

        /** COMOROS INITIALIZATION */
        registerCountry("KM", "COM", "174", "Comoros");

        /** CONGO INITIALIZATION */
        registerCountry("CG", "COG", "178", "Congo");

        /** CONGO (DEMOCRATIC REPUBLIC OF THE) INITIALIZATION */
        registerCountry("CD", "COD", "180", "Congo (Democratic Republic of the)");

        /** COOK ISLANDS INITIALIZATION */
        registerCountry("CK", "COK", "184", "Cook Islands");

        /** COSTA RICA INITIALIZATION */
        registerCountry("CR", "CRI", "188", "Costa Rica");

        /** CROATIA INITIALIZATION */
        registerCountry("HR", "HRV", "191", "Croatia");

        /** CUBA INITIALIZATION */
        registerCountry("CU", "CUB", "192", "Cuba");

        /** CURAÇAO INITIALIZATION */
        registerCountry("CW", "CUW", "531", "Curaçao");

        /** CYPRUS INITIALIZATION */
        registerCountry("CY", "CYP", "196", "Cyprus");

        /** CZECHIA INITIALIZATION */
        registerCountry("CZ", "CZE", "203", "Czechia");

        /** DENMARK INITIALIZATION */
        registerCountry("DK", "DNK", "208", "Denmark");

        /** DJIBOUTI INITIALIZATION */
        registerCountry("DJ", "DJI", "262", "Djibouti");

        /** DOMINICA INITIALIZATION */
        registerCountry("DM", "DMA", "212", "Dominica");

        /** DOMINICAN REPUBLIC INITIALIZATION */
        registerCountry("DO", "DOM", "214", "Dominican Republic");

        /** ECUADOR INITIALIZATION */
        registerCountry("EC", "ECU", "218", "Ecuador");

        /** EGYPT INITIALIZATION */
        registerCountry("EG", "EGY", "818", "Egypt");

        /** EL SALVADOR INITIALIZATION */
        registerCountry("SV", "SLV", "222", "El Salvador");

        /** EQUATORIAL GUINEA INITIALIZATION */
        registerCountry("GQ", "GNQ", "226", "Equatorial Guinea");

        /** ERITREA INITIALIZATION */
        registerCountry("ER", "ERI", "232", "Eritrea");

        /** ESTONIA INITIALIZATION */
        registerCountry("EE", "EST", "233", "Estonia");

        /** ESWATINI INITIALIZATION */
        registerCountry("SZ", "SWZ", "748", "Eswatini");

        /** ETHIOPIA INITIALIZATION */
        registerCountry("ET", "ETH", "231", "Ethiopia");

        /** FALKLAND ISLANDS (MALVINAS) INITIALIZATION */
        registerCountry("FK", "FLK", "238", "Falkland Islands (Malvinas)");

        /** FAROE ISLANDS INITIALIZATION */
        registerCountry("FO", "FRO", "234", "Faroe Islands");

        /** FIJI INITIALIZATION */
        registerCountry("FJ", "FJI", "242", "Fiji");

        /** FINLAND INITIALIZATION */
        registerCountry("FI", "FIN", "246", "Finland");

        /** FRANCE INITIALIZATION */
        registerCountry("FR", "FRA", "250", "France");
        /** FRENCH GUIANA INITIALIZATION */
        registerCountry("GF", "GUF", "254", "French Guiana");

        /** FRENCH POLYNESIA INITIALIZATION */
        registerCountry("PF", "PYF", "258", "French Polynesia");

        /** FRENCH SOUTHERN TERRITORIES INITIALIZATION */
        registerCountry("TF", "ATF", "260", "French Southern Territories");

        /** GABON INITIALIZATION */
        registerCountry("GA", "GAB", "266", "Gabon");

        /** GAMBIA INITIALIZATION */
        registerCountry("GM", "GMB", "270", "Gambia");

        /** GEORGIA INITIALIZATION */
        registerCountry("GE", "GEO", "268", "Georgia");

        /** GERMANY INITIALIZATION */
        registerCountry("DE", "DEU", "276", "Germany");
        /** GHANA INITIALIZATION */
        registerCountry("GH", "GHA", "288", "Ghana");

        /** GIBRALTAR INITIALIZATION */
        registerCountry("GI", "GIB", "292", "Gibraltar");

        /** GREECE INITIALIZATION */
        registerCountry("GR", "GRC", "300", "Greece");

        /** GREENLAND INITIALIZATION */
        registerCountry("GL", "GRL", "304", "Greenland");

        /** GRENADA INITIALIZATION */
        registerCountry("GD", "GRD", "308", "Grenada");

        /** GUADELOUPE INITIALIZATION */
        registerCountry("GP", "GLP", "312", "Guadeloupe");

        /** GUAM INITIALIZATION */
        registerCountry("GU", "GUM", "316", "Guam");

        /** GUATEMALA INITIALIZATION */
        registerCountry("GT", "GTM", "320", "Guatemala");

        /** GUERNSEY INITIALIZATION */
        registerCountry("GG", "GGY", "831", "Guernsey");

        /** GUINEA INITIALIZATION */
        registerCountry("GN", "GIN", "324", "Guinea");

        /** GUINEA-BISSAU INITIALIZATION */
        registerCountry("GW", "GNB", "624", "Guinea-Bissau");

        /** GUYANA INITIALIZATION */
        registerCountry("GY", "GUY", "328", "Guyana");

        /** HAITI INITIALIZATION */
        registerCountry("HT", "HTI", "332", "Haiti");

        /** HEARD ISLAND AND MCDONALD ISLANDS INITIALIZATION */
        registerCountry("HM", "HMD", "334", "Heard Island and McDonald Islands");

        /** HOLY SEE INITIALIZATION */
        registerCountry("VA", "VAT", "336", "Holy See");

        /** HONDURAS INITIALIZATION */
        registerCountry("HN", "HND", "340", "Honduras");

        /** HONG KONG INITIALIZATION */
        registerCountry("HK", "HKG", "344", "Hong Kong");

        /** HUNGARY INITIALIZATION */
        registerCountry("HU", "HUN", "348", "Hungary");

        /** ICELAND INITIALIZATION */
        registerCountry("IS", "ISL", "352", "Iceland");

        /** INDIA INITIALIZATION */
        registerCountry("IN", "IND", "356", "India");

        /** INDONESIA INITIALIZATION */
        registerCountry("ID", "IDN", "360", "Indonesia");

        /** IRAN (ISLAMIC REPUBLIC OF) INITIALIZATION */
        registerCountry("IR", "IRN", "364", "Iran (Islamic Republic of)");

        /** IRAQ INITIALIZATION */
        registerCountry("IQ", "IRQ", "368", "Iraq");

        /** IRELAND INITIALIZATION */
        registerCountry("IE", "IRL", "372", "Ireland");
        /** ISLE OF MAN INITIALIZATION */
        registerCountry("IM", "IMN", "833", "Isle of Man");

        /** ISRAEL INITIALIZATION */
        registerCountry("IL", "ISR", "376", "Israel");
        /** ITALY INITIALIZATION */
        registerCountry("IT", "ITA", "380", "Italy");
        /** JAMAICA INITIALIZATION */
        registerCountry("JM", "JAM", "388", "Jamaica");

        /** JAPAN INITIALIZATION */
        registerCountry("JP", "JPN", "392", "Japan");

        /** JERSEY INITIALIZATION */
        registerCountry("JE", "JEY", "832", "Jersey");

        /** JORDAN INITIALIZATION */
        registerCountry("JO", "JOR", "400", "Jordan");

        /** KAZAKHSTAN INITIALIZATION */
        registerCountry("KZ", "KAZ", "398", "Kazakhstan");

        /** KENYA INITIALIZATION */
        registerCountry("KE", "KEN", "404", "Kenya");

        /** KIRIBATI INITIALIZATION */
        registerCountry("KI", "KIR", "296", "Kiribati");

        /** KOREA (REPUBLIC OF) INITIALIZATION */
        registerCountry("KR", "KOR", "410", "Korea (Republic of)");

        /** KUWAIT INITIALIZATION */
        registerCountry("KW", "KWT", "414", "Kuwait");

        /** KYRGYZSTAN INITIALIZATION */
        registerCountry("KG", "KGZ", "417", "Kyrgyzstan");

        /** LATVIA INITIALIZATION */
        registerCountry("LV", "LVA", "428", "Latvia");

        /** LEBANON INITIALIZATION */
        registerCountry("LB", "LBN", "422", "Lebanon");

        /** LESOTHO INITIALIZATION */
        registerCountry("LS", "LSO", "426", "Lesotho");

        /** LIBERIA INITIALIZATION */
        registerCountry("LR", "LBR", "430", "Liberia");

        /** LIBYA INITIALIZATION */
        registerCountry("LY", "LBY", "434", "Libya");

        /** LIECHTENSTEIN INITIALIZATION */
        registerCountry("LI", "LIE", "438", "Liechtenstein");

        /** LITHUANIA INITIALIZATION */
        registerCountry("LT", "LTU", "440", "Lithuania");

        /** LUXEMBOURG INITIALIZATION */
        registerCountry("LU", "LUX", "442", "Luxembourg");

        /** MACAO INITIALIZATION */
        registerCountry("MO", "MAC", "446", "Macao");

        /** MACEDONIA (THE FORMER YUGOSLAV REPUBLIC OF) INITIALIZATION */
        registerCountry("MK", "MKD", "807", "Macedonia (the former Yugoslav Republic of)");

        /** MADAGASCAR INITIALIZATION */
        registerCountry("MG", "MDG", "450", "Madagascar");

        /** MALAWI INITIALIZATION */
        registerCountry("MW", "MWI", "454", "Malawi");

        /** MALAYSIA INITIALIZATION */
        registerCountry("MY", "MYS", "458", "Malaysia");

        /** MALDIVES INITIALIZATION */
        registerCountry("MV", "MDV", "462", "Maldives");

        /** MALI INITIALIZATION */
        registerCountry("ML", "MLI", "466", "Mali");

        /** MALTA INITIALIZATION */
        registerCountry("MT", "MLT", "470", "Malta");

        /** MARSHALL ISLANDS INITIALIZATION */
        registerCountry("MH", "MHL", "584", "Marshall Islands");

        /** MARTINIQUE INITIALIZATION */
        registerCountry("MQ", "MTQ", "474", "Martinique");

        /** MAURITANIA INITIALIZATION */
        registerCountry("MR", "MRT", "478", "Mauritania");

        /** MAURITIUS INITIALIZATION */
        registerCountry("MU", "MUS", "480", "Mauritius");

        /** MAYOTTE INITIALIZATION */
        registerCountry("YT", "MYT", "175", "Mayotte");

        /** MEXICO INITIALIZATION */
        registerCountry("MX", "MEX", "484", "Mexico");

        /** MICRONESIA (FEDERATED STATES OF) INITIALIZATION */
        registerCountry("FM", "FSM", "583", "Micronesia (Federated States of)");

        /** MOLDOVA (REPUBLIC OF) INITIALIZATION */
        registerCountry("MD", "MDA", "498", "Moldova (Republic of)");

        /** MONACO INITIALIZATION */
        registerCountry("MC", "MCO", "492", "Monaco");

        /** MONGOLIA INITIALIZATION */
        registerCountry("MN", "MNG", "496", "Mongolia");

        /** MONTENEGRO INITIALIZATION */
        registerCountry("ME", "MNE", "499", "Montenegro");

        /** MONTSERRAT INITIALIZATION */
        registerCountry("MS", "MSR", "500", "Montserrat");

        /** MOROCCO INITIALIZATION */
        registerCountry("MA", "MAR", "504", "Morocco");

        /** MOZAMBIQUE INITIALIZATION */
        registerCountry("MZ", "MOZ", "508", "Mozambique");

        /** MYANMAR INITIALIZATION */
        registerCountry("MM", "MMR", "104", "Myanmar");

        /** NAMIBIA INITIALIZATION */
        registerCountry("NA", "NAM", "516", "Namibia");

        /** NAURU INITIALIZATION */
        registerCountry("NR", "NRU", "520", "Nauru");

        /** NEPAL INITIALIZATION */
        registerCountry("NP", "NPL", "524", "Nepal");

        /** NETHERLANDS INITIALIZATION */
        registerCountry("NL", "NLD", "528", "Netherlands");

        /** NEW CALEDONIA INITIALIZATION */
        registerCountry("NC", "NCL", "540", "New Caledonia");

        /** NEW ZEALAND INITIALIZATION */
        registerCountry("NZ", "NZL", "554", "New Zealand");

        /** NICARAGUA INITIALIZATION */
        registerCountry("NI", "NIC", "558", "Nicaragua");

        /** NIGER INITIALIZATION */
        registerCountry("NE", "NER", "562", "Niger");

        /** NIGERIA INITIALIZATION */
        registerCountry("NG", "NGA", "566", "Nigeria");

        /** NIUE INITIALIZATION */
        registerCountry("NU", "NIU", "570", "Niue");

        /** NORFOLK ISLAND INITIALIZATION */
        registerCountry("NF", "NFK", "574", "Norfolk Island");

        /** NORTHERN MARIANA ISLANDS INITIALIZATION */
        registerCountry("MP", "MNP", "580", "Northern Mariana Islands");

        /** NORWAY INITIALIZATION */
        registerCountry("NO", "NOR", "578", "Norway");

        /** OMAN INITIALIZATION */
        registerCountry("OM", "OMN", "512", "Oman");

        /** PAKISTAN INITIALIZATION */
        registerCountry("PK", "PAK", "586", "Pakistan");

        /** PALAU INITIALIZATION */
        registerCountry("PW", "PLW", "585", "Palau");

        /** PALESTINE, STATE OF INITIALIZATION */
        registerCountry("PS", "PSE", "275", "Palestine, State of");

        /** PANAMA INITIALIZATION */
        registerCountry("PA", "PAN", "591", "Panama");

        /** PAPUA NEW GUINEA INITIALIZATION */
        registerCountry("PG", "PNG", "598", "Papua New Guinea");

        /** PARAGUAY INITIALIZATION */
        registerCountry("PY", "PRY", "600", "Paraguay");

        /** PERU INITIALIZATION */
        registerCountry("PE", "PER", "604", "Peru");

        /** PHILIPPINES INITIALIZATION */
        registerCountry("PH", "PHL", "608", "Philippines");

        /** PITCAIRN INITIALIZATION */
        registerCountry("PN", "PCN", "612", "Pitcairn");

        /** POLAND INITIALIZATION */
        registerCountry("PL", "POL", "616", "Poland");

        /** PORTUGAL INITIALIZATION */
        registerCountry("PT", "PRT", "620", "Portugal");

        /** PUERTO RICO INITIALIZATION */
        registerCountry("PR", "PRI", "630", "Puerto Rico");

        /** QATAR INITIALIZATION */
        registerCountry("QA", "QAT", "634", "Qatar");

        /** RÉUNION INITIALIZATION */
        registerCountry("RE", "REU", "638", "Réunion");

        /** ROMANIA INITIALIZATION */
        registerCountry("RO", "ROU", "642", "Romania");

        /** RUSSIAN FEDERATION INITIALIZATION */
        registerCountry("RU", "RUS", "643", "Russian Federation");

        /** RWANDA INITIALIZATION */
        registerCountry("RW", "RWA", "646", "Rwanda");

        /** SAINT BARTHÉLEMY INITIALIZATION */
        registerCountry("BL", "BLM", "652", "Saint Barthélemy");

        /** SAINT HELENA, ASCENSION AND TRISTAN DA CUNHA INITIALIZATION */
        registerCountry("SH", "SHN", "654", "Saint Helena, Ascension and Tristan da Cunha");

        /** SAINT KITTS AND NEVIS INITIALIZATION */
        registerCountry("KN", "KNA", "659", "Saint Kitts and Nevis");

        /** SAINT LUCIA INITIALIZATION */
        registerCountry("LC", "LCA", "662", "Saint Lucia");

        /** SAINT MARTIN (FRENCH PART) INITIALIZATION */
        registerCountry("MF", "MAF", "663", "Saint Martin (French part)");

        /** SAINT PIERRE AND MIQUELON INITIALIZATION */
        registerCountry("PM", "SPM", "666", "Saint Pierre and Miquelon");

        /** SAINT VINCENT AND THE GRENADINES INITIALIZATION */
        registerCountry("VC", "VCT", "670", "Saint Vincent and the Grenadines");

        /** SAMOA INITIALIZATION */
        registerCountry("WS", "WSM", "882", "Samoa");

        /** SAN MARINO INITIALIZATION */
        registerCountry("SM", "SMR", "674", "San Marino");

        /** SAO TOME AND PRINCIPE INITIALIZATION */
        registerCountry("ST", "STP", "678", "Sao Tome and Principe");

        /** SAUDI ARABIA INITIALIZATION */
        registerCountry("SA", "SAU", "682", "Saudi Arabia");

        /** SENEGAL INITIALIZATION */
        registerCountry("SN", "SEN", "686", "Senegal");

        /** SERBIA INITIALIZATION */
        registerCountry("RS", "SRB", "688", "Serbia");

        /** SEYCHELLES INITIALIZATION */
        registerCountry("SC", "SYC", "690", "Seychelles");

        /** SIERRA LEONE INITIALIZATION */
        registerCountry("SL", "SLE", "694", "Sierra Leone");

        /** SINGAPORE INITIALIZATION */
        registerCountry("SG", "SGP", "702", "Singapore");

        /** SINT MAARTEN (DUTCH PART) INITIALIZATION */
        registerCountry("SX", "SXM", "534", "Sint Maarten (Dutch part)");

        /** SLOVAKIA INITIALIZATION */
        registerCountry("SK", "SVK", "703", "Slovakia");

        /** SLOVENIA INITIALIZATION */
        registerCountry("SI", "SVN", "705", "Slovenia");

        /** SOLOMON ISLANDS INITIALIZATION */
        registerCountry("SB", "SLB", "90", "Solomon Islands");

        /** SOMALIA INITIALIZATION */
        registerCountry("SO", "SOM", "706", "Somalia");

        /** SOUTH AFRICA INITIALIZATION */
        registerCountry("ZA", "ZAF", "710", "South Africa");

        /** SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS INITIALIZATION */
        registerCountry("GS", "SGS", "239", "South Georgia and the South Sandwich Islands");

        /** SOUTH SUDAN INITIALIZATION */
        registerCountry("SS", "SSD", "728", "South Sudan");

        /** SPAIN INITIALIZATION */
        registerCountry("ES", "ESP", "724", "Spain");
        /** SRI LANKA INITIALIZATION */
        registerCountry("LK", "LKA", "144", "Sri Lanka");

        /** SUDAN INITIALIZATION */
        registerCountry("SD", "SDN", "729", "Sudan");

        /** SURINAME INITIALIZATION */
        registerCountry("SR", "SUR", "740", "Suriname");

        /** SVALBARD AND JAN MAYEN INITIALIZATION */
        registerCountry("SJ", "SJM", "744", "Svalbard and Jan Mayen");

        /** SWEDEN INITIALIZATION */
        registerCountry("SE", "SWE", "752", "Sweden");

        /** SWITZERLAND INITIALIZATION */
        registerCountry("CH", "CHE", "756", "Switzerland");

        /** SYRIAN ARAB REPUBLIC INITIALIZATION */
        registerCountry("SY", "SYR", "760", "Syrian Arab Republic");

        /** TAIWAN, PROVINCE OF CHINA[A] INITIALIZATION */
        registerCountry("TW", "TWN", "158", "Taiwan, Province of China[a]");

        /** TAJIKISTAN INITIALIZATION */
        registerCountry("TJ", "TJK", "762", "Tajikistan");

        /** TANZANIA, UNITED REPUBLIC OF INITIALIZATION */
        registerCountry("TZ", "TZA", "834", "Tanzania, United Republic of");

        /** THAILAND INITIALIZATION */
        registerCountry("TH", "THA", "764", "Thailand");

        /** TIMOR-LESTE INITIALIZATION */
        registerCountry("TL", "TLS", "626", "Timor-Leste");

        /** TOGO INITIALIZATION */
        registerCountry("TG", "TGO", "768", "Togo");

        /** TOKELAU INITIALIZATION */
        registerCountry("TK", "TKL", "772", "Tokelau");

        /** TONGA INITIALIZATION */
        registerCountry("TO", "TON", "776", "Tonga");

        /** TRINIDAD AND TOBAGO INITIALIZATION */
        registerCountry("TT", "TTO", "780", "Trinidad and Tobago");

        /** TUNISIA INITIALIZATION */
        registerCountry("TN", "TUN", "788", "Tunisia");

        /** TURKEY INITIALIZATION */
        registerCountry("TR", "TUR", "792", "Turkey");

        /** TURKMENISTAN INITIALIZATION */
        registerCountry("TM", "TKM", "795", "Turkmenistan");

        /** TURKS AND CAICOS ISLANDS INITIALIZATION */
        registerCountry("TC", "TCA", "796", "Turks and Caicos Islands");

        /** TUVALU INITIALIZATION */
        registerCountry("TV", "TUV", "798", "Tuvalu");

        /** UGANDA INITIALIZATION */
        registerCountry("UG", "UGA", "800", "Uganda");

        /** UKRAINE INITIALIZATION */
        registerCountry("UA", "UKR", "804", "Ukraine");

        /** UNITED ARAB EMIRATES INITIALIZATION */
        registerCountry("AE", "ARE", "784", "United Arab Emirates");

        /** UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND INITIALIZATION */
        registerCountry("GB", "GBR", "826", "United Kingdom of Great Britain and Northern Ireland");
        /** UNITED STATES OF AMERICA INITIALIZATION */
        registerCountry("US", "USA", "840", "United States of America");
        /** UNITED STATES MINOR OUTLYING ISLANDS INITIALIZATION */
        registerCountry("UM", "UMI", "581", "United States Minor Outlying Islands");

        /** URUGUAY INITIALIZATION */
        registerCountry("UY", "URY", "858", "Uruguay");

        /** UZBEKISTAN INITIALIZATION */
        registerCountry("UZ", "UZB", "860", "Uzbekistan");

        /** VANUATU INITIALIZATION */
        registerCountry("VU", "VUT", "548", "Vanuatu");

        /** VENEZUELA (BOLIVARIAN REPUBLIC OF) INITIALIZATION */
        registerCountry("VE", "VEN", "862", "Venezuela (Bolivarian Republic of)");
        /** VIET NAM INITIALIZATION */
        registerCountry("VN", "VNM", "704", "Viet Nam");

        /** VIRGIN ISLANDS (BRITISH) INITIALIZATION */
        registerCountry("VG", "VGB", "92", "Virgin Islands (British)");

        /** VIRGIN ISLANDS (U.S.) INITIALIZATION */
        registerCountry("VI", "VIR", "850", "Virgin Islands (U.S.)");

        /** WALLIS AND FUTUNA INITIALIZATION */
        registerCountry("WF", "WLF", "876", "Wallis and Futuna");

        /** WESTERN SAHARA INITIALIZATION */
        registerCountry("EH", "ESH", "732", "Western Sahara");

        /** YEMEN INITIALIZATION */
        registerCountry("YE", "YEM", "887", "Yemen");

        /** ZAMBIA INITIALIZATION */
        registerCountry("ZM", "ZMB", "894", "Zambia");

        /** ZIMBABWE INITIALIZATION */
        registerCountry("ZW", "ZWE", "716", "Zimbabwe");

        registerRegion("AU", "", "NSW", "New South Wales", keccak256(abi.encodePacked("AU", "NSW")));
        registerRegion("AU", "", "QLD", "Queensland", keccak256(abi.encodePacked("AU", "QLD")));
        registerRegion("AU", "SA", "", "South Australia", keccak256(abi.encodePacked("AU", "SA")));
        registerRegion("AU", "", "TAS", "Tasmania", keccak256(abi.encodePacked("AU", "TAS")));
        registerRegion("AU", "", "VIC", "Victoria", keccak256(abi.encodePacked("AU", "VIC")));
        registerRegion("AU", "WA", "", "Western Australia", keccak256(abi.encodePacked("AU", "WA")));
        registerRegion("AU", "", "ACT", "Australian Capital Territory", keccak256(abi.encodePacked("AU", "ACT")));
        registerRegion("AU", "NT", "", "Northern Territory", keccak256(abi.encodePacked("AU", "NT")));

        registerRegion("BR", "DF", "", "Distrito Federal", keccak256(abi.encodePacked("BR", "DF")));
        registerRegion("BR", "AC", "", "Acre", keccak256(abi.encodePacked("BR", "AC")));
        registerRegion("BR", "AL", "", "Alagoas", keccak256(abi.encodePacked("BR", "AL")));
        registerRegion("BR", "AP", "", "Amapá", keccak256(abi.encodePacked("BR", "AP")));
        registerRegion("BR", "AM", "", "Amazonas", keccak256(abi.encodePacked("BR", "AM")));
        registerRegion("BR", "BA", "", "Bahia", keccak256(abi.encodePacked("BR", "BA")));
        registerRegion("BR", "CE", "", "Ceará", keccak256(abi.encodePacked("BR", "CE")));
        registerRegion("BR", "ES", "", "Espírito Santo", keccak256(abi.encodePacked("BR", "ES")));
        registerRegion("BR", "GO", "", "Goiás", keccak256(abi.encodePacked("BR", "GO")));
        registerRegion("BR", "MA", "", "Maranhão", keccak256(abi.encodePacked("BR", "MA")));
        registerRegion("BR", "MT", "", "Mato Grosso", keccak256(abi.encodePacked("BR", "MT")));
        registerRegion("BR", "MS", "", "Mato Grosso do Sul", keccak256(abi.encodePacked("BR", "MS")));
        registerRegion("BR", "MG", "", "Minas Gerais", keccak256(abi.encodePacked("BR", "MG")));
        registerRegion("BR", "PA", "", "Pará", keccak256(abi.encodePacked("BR", "PA")));
        registerRegion("BR", "PB", "", "Paraíba", keccak256(abi.encodePacked("BR", "PB")));
        registerRegion("BR", "PR", "", "Paraná", keccak256(abi.encodePacked("BR", "PR")));
        registerRegion("BR", "PE", "", "Pernambuco", keccak256(abi.encodePacked("BR", "PE")));
        registerRegion("BR", "PI", "", "Piauí", keccak256(abi.encodePacked("BR", "PI")));
        registerRegion("BR", "RJ", "", "Rio de Janeiro", keccak256(abi.encodePacked("BR", "RJ")));
        registerRegion("BR", "RN", "", "Rio Grande do Norte", keccak256(abi.encodePacked("BR", "RN")));
        registerRegion("BR", "RS", "", "Rio Grande do Sul", keccak256(abi.encodePacked("BR", "RS")));
        registerRegion("BR", "RO", "", "Rondônia", keccak256(abi.encodePacked("BR", "RO")));
        registerRegion("BR", "RR", "", "Roraima", keccak256(abi.encodePacked("BR", "RR")));
        registerRegion("BR", "SC", "", "Santa Catarina", keccak256(abi.encodePacked("BR", "SC")));
        registerRegion("BR", "SP", "", "São Paulo", keccak256(abi.encodePacked("BR", "SP")));
        registerRegion("BR", "SE", "", "Sergipe", keccak256(abi.encodePacked("BR", "SE")));
        registerRegion("BR", "TO", "", "Tocantins", keccak256(abi.encodePacked("BR", "TO")));

        registerRegion("CA", "AB", "", "Alberta", keccak256(abi.encodePacked("CA", "AB")));
        registerRegion("CA", "BC", "", "British Columbia", keccak256(abi.encodePacked("CA", "BC")));
        registerRegion("CA", "MB", "", "Manitoba", keccak256(abi.encodePacked("CA", "MB")));
        registerRegion("CA", "NB", "", "New Brunswick", keccak256(abi.encodePacked("CA", "NB")));
        registerRegion("CA", "NL", "", "Newfoundland and Labrador", keccak256(abi.encodePacked("CA", "NL")));
        registerRegion("CA", "NS", "", "Nova Scotia", keccak256(abi.encodePacked("CA", "NS")));
        registerRegion("CA", "ON", "", "Ontario", keccak256(abi.encodePacked("CA", "ON")));
        registerRegion("CA", "PE", "", "Prince Edward Island", keccak256(abi.encodePacked("CA", "PE")));
        registerRegion("CA", "QC", "", "Quebec", keccak256(abi.encodePacked("CA", "QC")));
        registerRegion("CA", "SK", "", "Saskatchewan", keccak256(abi.encodePacked("CA", "SK")));
        registerRegion("CA", "NT", "", "Northwest Territories", keccak256(abi.encodePacked("CA", "NT")));
        registerRegion("CA", "NU", "", "Nunavut", keccak256(abi.encodePacked("CA", "NU")));
        registerRegion("CA", "YT", "", "Yukon", keccak256(abi.encodePacked("CA", "YT")));

        registerRegion("FR", "", "ARA", "Auvergne-Rhône-Alpes", keccak256(abi.encodePacked("FR", "ARA")));
        registerRegion("FR", "", "BFC", "Bourgogne-Franche-Comté", keccak256(abi.encodePacked("FR", "BFC")));
        registerRegion("FR", "", "BRE", "Bretagne", keccak256(abi.encodePacked("FR", "BRE")));
        registerRegion("FR", "", "CVL", "Centre-Val de Loire", keccak256(abi.encodePacked("FR", "CVL")));
        registerRegion("FR", "", "COR", "Corse", keccak256(abi.encodePacked("FR", "COR")));
        registerRegion("FR", "", "GES", "Grand Est", keccak256(abi.encodePacked("FR", "GES")));
        registerRegion("FR", "", "GUA", "Guadeloupe", keccak256(abi.encodePacked("FR", "GUA")));
        registerRegion("FR", "", "HDF", "Hauts-de-France", keccak256(abi.encodePacked("FR", "HDF")));
        registerRegion("FR", "", "IDF", "Île-de-France", keccak256(abi.encodePacked("FR", "IDF")));
        registerRegion("FR", "", "MAY", "Mayotte", keccak256(abi.encodePacked("FR", "MAY")));
        registerRegion("FR", "", "NOR", "Normandie", keccak256(abi.encodePacked("FR", "NOR")));
        registerRegion("FR", "", "NAQ", "Nouvelle-Aquitaine", keccak256(abi.encodePacked("FR", "NAQ")));
        registerRegion("FR", "", "OCC", "Occitanie", keccak256(abi.encodePacked("FR", "OCC")));
        registerRegion("FR", "", "PDL", "Pays de la Loire", keccak256(abi.encodePacked("FR", "PDL")));
        registerRegion("FR", "", "PAC", "Provence-Alpes-Côte dAzur", keccak256(abi.encodePacked("FR", "PAC")));
        registerRegion("FR", "", "LRE", "La Réunion", keccak256(abi.encodePacked("FR", "LRE")));

        registerRegion("DE", "BW", "", "Baden-Württemberg", keccak256(abi.encodePacked("DE", "BW")));
        registerRegion("DE", "BY", "", "Bayern", keccak256(abi.encodePacked("DE", "BY")));
        registerRegion("DE", "BE", "", "Berlin", keccak256(abi.encodePacked("DE", "BE")));
        registerRegion("DE", "BB", "", "Brandenburg", keccak256(abi.encodePacked("DE", "BB")));
        registerRegion("DE", "HB", "", "Bremen", keccak256(abi.encodePacked("DE", "HB")));
        registerRegion("DE", "HH", "", "Hamburg", keccak256(abi.encodePacked("DE", "HH")));
        registerRegion("DE", "HE", "", "Hessen", keccak256(abi.encodePacked("DE", "HE")));
        registerRegion("DE", "MV", "", "Mecklenburg-Vorpommern", keccak256(abi.encodePacked("DE", "MV")));
        registerRegion("DE", "NI", "", "Niedersachsen", keccak256(abi.encodePacked("DE", "NI")));
        registerRegion("DE", "NW", "", "Nordrhein-Westfalen", keccak256(abi.encodePacked("DE", "NW")));
        registerRegion("DE", "RP", "", "Rheinland-Pfalz", keccak256(abi.encodePacked("DE", "RP")));
        registerRegion("DE", "SL", "", "Saarland", keccak256(abi.encodePacked("DE", "SL")));
        registerRegion("DE", "SN", "", "Sachsen", keccak256(abi.encodePacked("DE", "SN")));
        registerRegion("DE", "ST", "", "Sachsen-Anhalt", keccak256(abi.encodePacked("DE", "ST")));
        registerRegion("DE", "SH", "", "Schleswig-Holstein", keccak256(abi.encodePacked("DE", "SH")));
        registerRegion("DE", "TH", "", "Thüringen", keccak256(abi.encodePacked("DE", "TH")));

        registerRegion("IE", "C", "", "Connacht", keccak256(abi.encodePacked("IE", "C")));
        registerRegion("IE", "L", "", "Leinster", keccak256(abi.encodePacked("IE", "L")));
        registerRegion("IE", "M", "", "Munster", keccak256(abi.encodePacked("IE", "M")));
        registerRegion("IE", "U", "", "Ulster", keccak256(abi.encodePacked("IE", "U")));

        registerRegion("IL", "D", "", "HaDarom", keccak256(abi.encodePacked("IL", "D")));
        registerRegion("IL", "M", "", "HaMerkaz", keccak256(abi.encodePacked("IL", "M")));
        registerRegion("IL", "Z", "", "HaTsafon", keccak256(abi.encodePacked("IL", "Z")));
        registerRegion("IL", "HA", "", "H̱efa", keccak256(abi.encodePacked("IL", "HA")));
        registerRegion("IL", "TA", "", "Tel-Aviv", keccak256(abi.encodePacked("IL", "TA")));
        registerRegion("IL", "JM", "", "Yerushalayim", keccak256(abi.encodePacked("IL", "JM")));

        registerRegion("IT", "65", "", "Abruzzo", keccak256(abi.encodePacked("IT", "65")));
        registerRegion("IT", "77", "", "Basilicata", keccak256(abi.encodePacked("IT", "77")));
        registerRegion("IT", "78", "", "Calabria", keccak256(abi.encodePacked("IT", "78")));
        registerRegion("IT", "72", "", "Campania", keccak256(abi.encodePacked("IT", "72")));
        registerRegion("IT", "45", "", "Emilia-Romagna", keccak256(abi.encodePacked("IT", "45")));
        registerRegion("IT", "36", "", "Friuli-Venezia Giulia", keccak256(abi.encodePacked("IT", "36")));
        registerRegion("IT", "62", "", "Lazio", keccak256(abi.encodePacked("IT", "62")));
        registerRegion("IT", "42", "", "Liguria", keccak256(abi.encodePacked("IT", "42")));
        registerRegion("IT", "25", "", "Lombardia", keccak256(abi.encodePacked("IT", "25")));
        registerRegion("IT", "57", "", "Marche", keccak256(abi.encodePacked("IT", "57")));
        registerRegion("IT", "67", "", "Molise", keccak256(abi.encodePacked("IT", "67")));
        registerRegion("IT", "21", "", "Piemonte", keccak256(abi.encodePacked("IT", "21")));
        registerRegion("IT", "75", "", "Puglia", keccak256(abi.encodePacked("IT", "75")));
        registerRegion("IT", "88", "", "Sardegna", keccak256(abi.encodePacked("IT", "88")));
        registerRegion("IT", "82", "", "Sicilia", keccak256(abi.encodePacked("IT", "82")));
        registerRegion("IT", "52", "", "Toscana", keccak256(abi.encodePacked("IT", "52")));
        registerRegion("IT", "32", "", "Trentino-Alto Adige, Trentino-Südtirol (de)", keccak256(abi.encodePacked("IT", "32")));
        registerRegion("IT", "55", "", "Umbria", keccak256(abi.encodePacked("IT", "55")));
        registerRegion("IT", "23", "", "Valle dAosta", keccak256(abi.encodePacked("IT", "23")));
        registerRegion("IT", "34", "", "Veneto", keccak256(abi.encodePacked("IT", "34")));

        registerRegion("ES", "AN", "", "Andalucía", keccak256(abi.encodePacked("ES", "AN")));
        registerRegion("ES", "AR", "", "Aragón", keccak256(abi.encodePacked("ES", "AR")));
        registerRegion("ES", "AS", "", "Asturias, Principado de", keccak256(abi.encodePacked("ES", "AS")));
        registerRegion("ES", "CN", "", "Canarias", keccak256(abi.encodePacked("ES", "CN")));
        registerRegion("ES", "CB", "", "Cantabria", keccak256(abi.encodePacked("ES", "CB")));
        registerRegion("ES", "CM", "", "Castilla-La Mancha", keccak256(abi.encodePacked("ES", "CM")));
        registerRegion("ES", "CL", "", "Castilla y León", keccak256(abi.encodePacked("ES", "CL")));
        registerRegion("ES", "CT", "", "Catalunya (ca) [Cataluña]", keccak256(abi.encodePacked("ES", "CT")));
        registerRegion("ES", "EX", "", "Extremadura", keccak256(abi.encodePacked("ES", "EX")));
        registerRegion("ES", "GA", "", "Galicia (gl) [Galicia]", keccak256(abi.encodePacked("ES", "GA")));
        registerRegion("ES", "IB", "", "Illes Balears (ca) [Islas Baleares]", keccak256(abi.encodePacked("ES", "IB")));
        registerRegion("ES", "RI", "", "La Rioja", keccak256(abi.encodePacked("ES", "RI")));
        registerRegion("ES", "MD", "", "Madrid, Comunidad de", keccak256(abi.encodePacked("ES", "MD")));
        registerRegion("ES", "MC", "", "Murcia, Región de", keccak256(abi.encodePacked("ES", "MC")));
        registerRegion("ES", "NC", "", "Navarra, Comunidad Foral de Nafarroako", keccak256(abi.encodePacked("ES", "NC")));
        registerRegion("ES", "PV", "", "País Vasco Euskal Herria (eu)", keccak256(abi.encodePacked("ES", "PV")));
        registerRegion("ES", "VC", "", "Valenciana, Comunidad", keccak256(abi.encodePacked("ES", "VC")));
        registerRegion("ES", "CE", "", "Ceuta", keccak256(abi.encodePacked("ES", "CE")));
        registerRegion("ES", "ML", "", "Melilla", keccak256(abi.encodePacked("ES", "ML")));

        registerRegion("US", "AL", "", "Alabama", keccak256(abi.encodePacked("US", "AL")));
        registerRegion("US", "AK", "", "Alaska", keccak256(abi.encodePacked("US", "AK")));
        registerRegion("US", "AZ", "", "Arizona", keccak256(abi.encodePacked("US", "AZ")));
        registerRegion("US", "AR", "", "Arkansas", keccak256(abi.encodePacked("US", "AR")));
        registerRegion("US", "CA", "", "California", keccak256(abi.encodePacked("US", "CA")));
        registerRegion("US", "CO", "", "Colorado", keccak256(abi.encodePacked("US", "CO")));
        registerRegion("US", "CT", "", "Connecticut", keccak256(abi.encodePacked("US", "CT")));
        registerRegion("US", "DE", "", "Delaware", keccak256(abi.encodePacked("US", "DE")));
        registerRegion("US", "FL", "", "Florida", keccak256(abi.encodePacked("US", "FL")));
        registerRegion("US", "GA", "", "Georgia", keccak256(abi.encodePacked("US", "GA")));
        registerRegion("US", "HI", "", "Hawaii", keccak256(abi.encodePacked("US", "HI")));
        registerRegion("US", "ID", "", "Idaho", keccak256(abi.encodePacked("US", "ID")));
        registerRegion("US", "IL", "", "Illinois", keccak256(abi.encodePacked("US", "IL")));
        registerRegion("US", "IN", "", "Indiana", keccak256(abi.encodePacked("US", "IN")));
        registerRegion("US", "IA", "", "Iowa", keccak256(abi.encodePacked("US", "IA")));
        registerRegion("US", "KS", "", "Kansas", keccak256(abi.encodePacked("US", "KS")));
        registerRegion("US", "KY", "", "Kentucky", keccak256(abi.encodePacked("US", "KY")));
        registerRegion("US", "LA", "", "Louisiana", keccak256(abi.encodePacked("US", "LA")));
        registerRegion("US", "ME", "", "Maine", keccak256(abi.encodePacked("US", "ME")));
        registerRegion("US", "MD", "", "Maryland", keccak256(abi.encodePacked("US", "MD")));
        registerRegion("US", "MA", "", "Massachusetts", keccak256(abi.encodePacked("US", "MA")));
        registerRegion("US", "MI", "", "Michigan", keccak256(abi.encodePacked("US", "MI")));
        registerRegion("US", "MN", "", "Minnesota", keccak256(abi.encodePacked("US", "MN")));
        registerRegion("US", "MS", "", "Mississippi", keccak256(abi.encodePacked("US", "MS")));
        registerRegion("US", "MO", "", "Missouri", keccak256(abi.encodePacked("US", "MO")));
        registerRegion("US", "MT", "", "Montana", keccak256(abi.encodePacked("US", "MT")));
        registerRegion("US", "NE", "", "Nebraska", keccak256(abi.encodePacked("US", "NE")));
        registerRegion("US", "NV", "", "Nevada", keccak256(abi.encodePacked("US", "NV")));
        registerRegion("US", "NH", "", "New Hampshire", keccak256(abi.encodePacked("US", "NH")));
        registerRegion("US", "NJ", "", "New Jersey", keccak256(abi.encodePacked("US", "NJ")));
        registerRegion("US", "NM", "", "New Mexico", keccak256(abi.encodePacked("US", "NM")));
        registerRegion("US", "NY", "", "New York", keccak256(abi.encodePacked("US", "NY")));
        registerRegion("US", "NC", "", "North Carolina", keccak256(abi.encodePacked("US", "NC")));
        registerRegion("US", "ND", "", "North Dakota", keccak256(abi.encodePacked("US", "ND")));
        registerRegion("US", "OH", "", "Ohio", keccak256(abi.encodePacked("US", "OH")));
        registerRegion("US", "OK", "", "Oklahoma", keccak256(abi.encodePacked("US", "OK")));
        registerRegion("US", "OR", "", "Oregon", keccak256(abi.encodePacked("US", "OR")));
        registerRegion("US", "PA", "", "Pennsylvania", keccak256(abi.encodePacked("US", "PA")));
        registerRegion("US", "RI", "", "Rhode Island", keccak256(abi.encodePacked("US", "RI")));
        registerRegion("US", "SC", "", "South Carolina", keccak256(abi.encodePacked("US", "SC")));
        registerRegion("US", "SD", "", "South Dakota", keccak256(abi.encodePacked("US", "SD")));
        registerRegion("US", "TN", "", "Tennessee", keccak256(abi.encodePacked("US", "TN")));
        registerRegion("US", "TX", "", "Texas", keccak256(abi.encodePacked("US", "TX")));
        registerRegion("US", "UT", "", "Utah", keccak256(abi.encodePacked("US", "UT")));
        registerRegion("US", "VT", "", "Vermont", keccak256(abi.encodePacked("US", "VT")));
        registerRegion("US", "VA", "", "Virginia", keccak256(abi.encodePacked("US", "VA")));
        registerRegion("US", "WA", "", "Washington", keccak256(abi.encodePacked("US", "WA")));
        registerRegion("US", "WV", "", "West Virginia", keccak256(abi.encodePacked("US", "WV")));
        registerRegion("US", "WI", "", "Wisconsin", keccak256(abi.encodePacked("US", "WI")));
        registerRegion("US", "WY", "", "Wyoming", keccak256(abi.encodePacked("US", "WY")));
        registerRegion("US", "DC", "", "District of Columbia", keccak256(abi.encodePacked("US", "DC")));
        registerRegion("US", "AS", "", "American Samoa", keccak256(abi.encodePacked("US", "AS")));
        registerRegion("US", "GU", "", "Guam", keccak256(abi.encodePacked("US", "GU")));
        registerRegion("US", "MP", "", "Northern Mariana Islands", keccak256(abi.encodePacked("US", "MP")));
        registerRegion("US", "PR", "", "Puerto Rico", keccak256(abi.encodePacked("US", "PR")));
        registerRegion("US", "UM", "", "United States Minor Outlying Islands", keccak256(abi.encodePacked("US", "UM")));
        registerRegion("US", "VI", "", "Virgin Islands, U.S.", keccak256(abi.encodePacked("US", "VI")));

        registerRegion("GB", "", "ENG", "England", keccak256(abi.encodePacked("GB", "ENG")));
        registerRegion("GB", "", "NIR", "Northern Ireland", keccak256(abi.encodePacked("GB", "NIR")));
        registerRegion("GB", "", "SCT", "Scotland", keccak256(abi.encodePacked("GB", "SCT")));
        registerRegion("GB", "", "WLS", "Wales [Cymru GB-CYM]", keccak256(abi.encodePacked("GB", "WLS")));
        registerRegion("GB", "", "EAW", "England and Wales", keccak256(abi.encodePacked("GB", "EAW")));
        registerRegion("GB", "", "GBN", "Great Britain", keccak256(abi.encodePacked("GB", "GBN")));
        registerRegion("GB", "", "UKM", "United Kingdom", keccak256(abi.encodePacked("GB", "UKM")));
        registerRegion("GB", "", "BKM", "Buckinghamshire", keccak256(abi.encodePacked("GB", "BKM")));
        registerRegion("GB", "", "CAM", "Cambridgeshire", keccak256(abi.encodePacked("GB", "CAM")));
        registerRegion("GB", "", "CMA", "Cumbria", keccak256(abi.encodePacked("GB", "CMA")));
        registerRegion("GB", "", "DBY", "Derbyshire", keccak256(abi.encodePacked("GB", "DBY")));
        registerRegion("GB", "", "DEV", "Devon", keccak256(abi.encodePacked("GB", "DEV")));
        registerRegion("GB", "", "DOR", "Dorset", keccak256(abi.encodePacked("GB", "DOR")));
        registerRegion("GB", "", "ESX", "East Sussex", keccak256(abi.encodePacked("GB", "ESX")));
        registerRegion("GB", "", "ESS", "Essex", keccak256(abi.encodePacked("GB", "ESS")));
        registerRegion("GB", "", "GLS", "Gloucestershire", keccak256(abi.encodePacked("GB", "GLS")));
        registerRegion("GB", "", "HAM", "Hampshire", keccak256(abi.encodePacked("GB", "HAM")));
        registerRegion("GB", "", "HRT", "Hertfordshire", keccak256(abi.encodePacked("GB", "HRT")));
        registerRegion("GB", "", "KEN", "Kent", keccak256(abi.encodePacked("GB", "KEN")));
        registerRegion("GB", "", "LAN", "Lancashire", keccak256(abi.encodePacked("GB", "LAN")));
        registerRegion("GB", "", "LEC", "Leicestershire", keccak256(abi.encodePacked("GB", "LEC")));
        registerRegion("GB", "", "LIN", "Lincolnshire", keccak256(abi.encodePacked("GB", "LIN")));
        registerRegion("GB", "", "NFK", "Norfolk", keccak256(abi.encodePacked("GB", "NFK")));
        registerRegion("GB", "", "NYK", "North Yorkshire", keccak256(abi.encodePacked("GB", "NYK")));
        registerRegion("GB", "", "NTH", "Northamptonshire", keccak256(abi.encodePacked("GB", "NTH")));
        registerRegion("GB", "", "NTT", "Nottinghamshire", keccak256(abi.encodePacked("GB", "NTT")));
        registerRegion("GB", "", "OXF", "Oxfordshire", keccak256(abi.encodePacked("GB", "OXF")));
        registerRegion("GB", "", "SOM", "Somerset", keccak256(abi.encodePacked("GB", "SOM")));
        registerRegion("GB", "", "STS", "Staffordshire", keccak256(abi.encodePacked("GB", "STS")));
        registerRegion("GB", "", "SFK", "Suffolk", keccak256(abi.encodePacked("GB", "SFK")));
        registerRegion("GB", "", "SRY", "Surrey", keccak256(abi.encodePacked("GB", "SRY")));
        registerRegion("GB", "", "WAR", "Warwickshire", keccak256(abi.encodePacked("GB", "WAR")));
        registerRegion("GB", "", "WSX", "West Sussex", keccak256(abi.encodePacked("GB", "WSX")));
        registerRegion("GB", "", "WOR", "Worcestershire", keccak256(abi.encodePacked("GB", "WOR")));
        registerRegion("GB", "", "LND", "London, City of", keccak256(abi.encodePacked("GB", "LND")));
        registerRegion("GB", "", "BDG", "Barking and Dagenham", keccak256(abi.encodePacked("GB", "BDG")));
        registerRegion("GB", "", "BNE", "Barnet", keccak256(abi.encodePacked("GB", "BNE")));
        registerRegion("GB", "", "BEX", "Bexley", keccak256(abi.encodePacked("GB", "BEX")));
        registerRegion("GB", "", "BEN", "Brent", keccak256(abi.encodePacked("GB", "BEN")));
        registerRegion("GB", "", "BRY", "Bromley", keccak256(abi.encodePacked("GB", "BRY")));
        registerRegion("GB", "", "CMD", "Camden", keccak256(abi.encodePacked("GB", "CMD")));
        registerRegion("GB", "", "CRY", "Croydon", keccak256(abi.encodePacked("GB", "CRY")));
        registerRegion("GB", "", "EAL", "Ealing", keccak256(abi.encodePacked("GB", "EAL")));
        registerRegion("GB", "", "ENF", "Enfield", keccak256(abi.encodePacked("GB", "ENF")));
        registerRegion("GB", "", "GRE", "Greenwich", keccak256(abi.encodePacked("GB", "GRE")));
        registerRegion("GB", "", "HCK", "Hackney", keccak256(abi.encodePacked("GB", "HCK")));
        registerRegion("GB", "", "HMF", "Hammersmith and Fulham", keccak256(abi.encodePacked("GB", "HMF")));
        registerRegion("GB", "", "HRY", "Haringey", keccak256(abi.encodePacked("GB", "HRY")));
        registerRegion("GB", "", "HRW", "Harrow", keccak256(abi.encodePacked("GB", "HRW")));
        registerRegion("GB", "", "HAV", "Havering", keccak256(abi.encodePacked("GB", "HAV")));
        registerRegion("GB", "", "HIL", "Hillingdon", keccak256(abi.encodePacked("GB", "HIL")));
        registerRegion("GB", "", "HNS", "Hounslow", keccak256(abi.encodePacked("GB", "HNS")));
        registerRegion("GB", "", "ISL", "Islington", keccak256(abi.encodePacked("GB", "ISL")));
        registerRegion("GB", "", "KEC", "Kensington and Chelsea", keccak256(abi.encodePacked("GB", "KEC")));
        registerRegion("GB", "", "KTT", "Kingston upon Thames", keccak256(abi.encodePacked("GB", "KTT")));
        registerRegion("GB", "", "LBH", "Lambeth", keccak256(abi.encodePacked("GB", "LBH")));
        registerRegion("GB", "", "LEW", "Lewisham", keccak256(abi.encodePacked("GB", "LEW")));
        registerRegion("GB", "", "MRT", "Merton", keccak256(abi.encodePacked("GB", "MRT")));
        registerRegion("GB", "", "NWM", "Newham", keccak256(abi.encodePacked("GB", "NWM")));
        registerRegion("GB", "", "RDB", "Redbridge", keccak256(abi.encodePacked("GB", "RDB")));
        registerRegion("GB", "", "RIC", "Richmond upon Thames", keccak256(abi.encodePacked("GB", "RIC")));
        registerRegion("GB", "", "SWK", "Southwark", keccak256(abi.encodePacked("GB", "SWK")));
        registerRegion("GB", "", "STN", "Sutton", keccak256(abi.encodePacked("GB", "STN")));
        registerRegion("GB", "", "TWH", "Tower Hamlets", keccak256(abi.encodePacked("GB", "TWH")));
        registerRegion("GB", "", "WFT", "Waltham Forest", keccak256(abi.encodePacked("GB", "WFT")));
        registerRegion("GB", "", "WND", "Wandsworth", keccak256(abi.encodePacked("GB", "WND")));
        registerRegion("GB", "", "WSM", "Westminster", keccak256(abi.encodePacked("GB", "WSM")));
        registerRegion("GB", "", "BNS", "Barnsley", keccak256(abi.encodePacked("GB", "BNS")));
        registerRegion("GB", "", "BIR", "Birmingham", keccak256(abi.encodePacked("GB", "BIR")));
        registerRegion("GB", "", "BOL", "Bolton", keccak256(abi.encodePacked("GB", "BOL")));
        registerRegion("GB", "", "BRD", "Bradford", keccak256(abi.encodePacked("GB", "BRD")));
        registerRegion("GB", "", "BUR", "Bury", keccak256(abi.encodePacked("GB", "BUR")));
        registerRegion("GB", "", "CLD", "Calderdale", keccak256(abi.encodePacked("GB", "CLD")));
        registerRegion("GB", "", "COV", "Coventry", keccak256(abi.encodePacked("GB", "COV")));
        registerRegion("GB", "", "DNC", "Doncaster", keccak256(abi.encodePacked("GB", "DNC")));
        registerRegion("GB", "", "DUD", "Dudley", keccak256(abi.encodePacked("GB", "DUD")));
        registerRegion("GB", "", "GAT", "Gateshead", keccak256(abi.encodePacked("GB", "GAT")));
        registerRegion("GB", "", "KIR", "Kirklees", keccak256(abi.encodePacked("GB", "KIR")));
        registerRegion("GB", "", "KWL", "Knowsley", keccak256(abi.encodePacked("GB", "KWL")));
        registerRegion("GB", "", "LDS", "Leeds", keccak256(abi.encodePacked("GB", "LDS")));
        registerRegion("GB", "", "LIV", "Liverpool", keccak256(abi.encodePacked("GB", "LIV")));
        registerRegion("GB", "", "MAN", "Manchester", keccak256(abi.encodePacked("GB", "MAN")));
        registerRegion("GB", "", "NET", "Newcastle upon Tyne", keccak256(abi.encodePacked("GB", "NET")));
        registerRegion("GB", "", "NTY", "North Tyneside", keccak256(abi.encodePacked("GB", "NTY")));
        registerRegion("GB", "", "OLD", "Oldham", keccak256(abi.encodePacked("GB", "OLD")));
        registerRegion("GB", "", "RCH", "Rochdale", keccak256(abi.encodePacked("GB", "RCH")));
        registerRegion("GB", "", "ROT", "Rotherham", keccak256(abi.encodePacked("GB", "ROT")));
        registerRegion("GB", "", "SHN", "St. Helens", keccak256(abi.encodePacked("GB", "SHN")));
        registerRegion("GB", "", "SLF", "Salford", keccak256(abi.encodePacked("GB", "SLF")));
        registerRegion("GB", "", "SAW", "Sandwell", keccak256(abi.encodePacked("GB", "SAW")));
        registerRegion("GB", "", "SFT", "Sefton", keccak256(abi.encodePacked("GB", "SFT")));
        registerRegion("GB", "", "SHF", "Sheffield", keccak256(abi.encodePacked("GB", "SHF")));
        registerRegion("GB", "", "SOL", "Solihull", keccak256(abi.encodePacked("GB", "SOL")));
        registerRegion("GB", "", "STY", "South Tyneside", keccak256(abi.encodePacked("GB", "STY")));
        registerRegion("GB", "", "SKP", "Stockport", keccak256(abi.encodePacked("GB", "SKP")));
        registerRegion("GB", "", "SND", "Sunderland", keccak256(abi.encodePacked("GB", "SND")));
        registerRegion("GB", "", "TAM", "Tameside", keccak256(abi.encodePacked("GB", "TAM")));
        registerRegion("GB", "", "TRF", "Trafford", keccak256(abi.encodePacked("GB", "TRF")));
        registerRegion("GB", "", "WKF", "Wakefield", keccak256(abi.encodePacked("GB", "WKF")));
        registerRegion("GB", "", "WLL", "Walsall", keccak256(abi.encodePacked("GB", "WLL")));
        registerRegion("GB", "", "WGN", "Wigan", keccak256(abi.encodePacked("GB", "WGN")));
        registerRegion("GB", "", "WRL", "Wirral", keccak256(abi.encodePacked("GB", "WRL")));
        registerRegion("GB", "", "WLV", "Wolverhampton", keccak256(abi.encodePacked("GB", "WLV")));
        registerRegion("GB", "", "BAS", "Bath and North East Somerset", keccak256(abi.encodePacked("GB", "BAS")));
        registerRegion("GB", "", "BDF", "Bedford", keccak256(abi.encodePacked("GB", "BDF")));
        registerRegion("GB", "", "BBD", "Blackburn with Darwen", keccak256(abi.encodePacked("GB", "BBD")));
        registerRegion("GB", "", "BPL", "Blackpool", keccak256(abi.encodePacked("GB", "BPL")));
        registerRegion("GB", "", "BMH", "Bournemouth", keccak256(abi.encodePacked("GB", "BMH")));
        registerRegion("GB", "", "BRC", "Bracknell Forest", keccak256(abi.encodePacked("GB", "BRC")));
        registerRegion("GB", "", "BNH", "Brighton and Hove", keccak256(abi.encodePacked("GB", "BNH")));
        registerRegion("GB", "", "BST", "Bristol, City of", keccak256(abi.encodePacked("GB", "BST")));
        registerRegion("GB", "", "CBF", "Central Bedfordshire", keccak256(abi.encodePacked("GB", "CBF")));
        registerRegion("GB", "", "CHE", "Cheshire East", keccak256(abi.encodePacked("GB", "CHE")));
        registerRegion("GB", "", "CHW", "Cheshire West and Chester", keccak256(abi.encodePacked("GB", "CHW")));
        registerRegion("GB", "", "CON", "Cornwall", keccak256(abi.encodePacked("GB", "CON")));
        registerRegion("GB", "", "DAL", "Darlington", keccak256(abi.encodePacked("GB", "DAL")));
        registerRegion("GB", "", "DER", "Derby", keccak256(abi.encodePacked("GB", "DER")));
        registerRegion("GB", "", "DUR", "Durham, County", keccak256(abi.encodePacked("GB", "DUR")));
        registerRegion("GB", "", "ERY", "East Riding of Yorkshire", keccak256(abi.encodePacked("GB", "ERY")));
        registerRegion("GB", "", "HAL", "Halton", keccak256(abi.encodePacked("GB", "HAL")));
        registerRegion("GB", "", "HPL", "Hartlepool", keccak256(abi.encodePacked("GB", "HPL")));
        registerRegion("GB", "", "HEF", "Herefordshire", keccak256(abi.encodePacked("GB", "HEF")));
        registerRegion("GB", "", "IOW", "Isle of Wight", keccak256(abi.encodePacked("GB", "IOW")));
        registerRegion("GB", "", "IOS", "Isles of Scilly", keccak256(abi.encodePacked("GB", "IOS")));
        registerRegion("GB", "", "KHL", "Kingston upon Hull", keccak256(abi.encodePacked("GB", "KHL")));
        registerRegion("GB", "", "LCE", "Leicester", keccak256(abi.encodePacked("GB", "LCE")));
        registerRegion("GB", "", "LUT", "Luton", keccak256(abi.encodePacked("GB", "LUT")));
        registerRegion("GB", "", "MDW", "Medway", keccak256(abi.encodePacked("GB", "MDW")));
        registerRegion("GB", "", "MDB", "Middlesbrough", keccak256(abi.encodePacked("GB", "MDB")));
        registerRegion("GB", "", "MIK", "Milton Keynes", keccak256(abi.encodePacked("GB", "MIK")));
        registerRegion("GB", "", "NEL", "North East Lincolnshire", keccak256(abi.encodePacked("GB", "NEL")));
        registerRegion("GB", "", "NLN", "North Lincolnshire", keccak256(abi.encodePacked("GB", "NLN")));
        registerRegion("GB", "", "NSM", "North Somerset", keccak256(abi.encodePacked("GB", "NSM")));
        registerRegion("GB", "", "NBL", "Northumberland", keccak256(abi.encodePacked("GB", "NBL")));
        registerRegion("GB", "", "NGM", "Nottingham", keccak256(abi.encodePacked("GB", "NGM")));
        registerRegion("GB", "", "PTE", "Peterborough", keccak256(abi.encodePacked("GB", "PTE")));
        registerRegion("GB", "", "PLY", "Plymouth", keccak256(abi.encodePacked("GB", "PLY")));
        registerRegion("GB", "", "POL", "Poole", keccak256(abi.encodePacked("GB", "POL")));
        registerRegion("GB", "", "POR", "Portsmouth", keccak256(abi.encodePacked("GB", "POR")));
        registerRegion("GB", "", "RDG", "Reading", keccak256(abi.encodePacked("GB", "RDG")));
        registerRegion("GB", "", "RCC", "Redcar and Cleveland", keccak256(abi.encodePacked("GB", "RCC")));
        registerRegion("GB", "", "RUT", "Rutland", keccak256(abi.encodePacked("GB", "RUT")));
        registerRegion("GB", "", "SHR", "Shropshire", keccak256(abi.encodePacked("GB", "SHR")));
        registerRegion("GB", "", "SLG", "Slough", keccak256(abi.encodePacked("GB", "SLG")));
        registerRegion("GB", "", "SGC", "South Gloucestershire", keccak256(abi.encodePacked("GB", "SGC")));
        registerRegion("GB", "", "STH", "Southampton", keccak256(abi.encodePacked("GB", "STH")));
        registerRegion("GB", "", "SOS", "Southend-on-Sea", keccak256(abi.encodePacked("GB", "SOS")));
        registerRegion("GB", "", "STT", "Stockton-on-Tees", keccak256(abi.encodePacked("GB", "STT")));
        registerRegion("GB", "", "STE", "Stoke-on-Trent", keccak256(abi.encodePacked("GB", "STE")));
        registerRegion("GB", "", "SWD", "Swindon", keccak256(abi.encodePacked("GB", "SWD")));
        registerRegion("GB", "", "TFW", "Telford and Wrekin", keccak256(abi.encodePacked("GB", "TFW")));
        registerRegion("GB", "", "THR", "Thurrock", keccak256(abi.encodePacked("GB", "THR")));
        registerRegion("GB", "", "TOB", "Torbay", keccak256(abi.encodePacked("GB", "TOB")));
        registerRegion("GB", "", "WRT", "Warrington", keccak256(abi.encodePacked("GB", "WRT")));
        registerRegion("GB", "", "WBK", "West Berkshire", keccak256(abi.encodePacked("GB", "WBK")));
        registerRegion("GB", "", "WIL", "Wiltshire", keccak256(abi.encodePacked("GB", "WIL")));
        registerRegion("GB", "", "WNM", "Windsor and Maidenhead", keccak256(abi.encodePacked("GB", "WNM")));
        registerRegion("GB", "", "WOK", "Wokingham", keccak256(abi.encodePacked("GB", "WOK")));
        registerRegion("GB", "", "YOR", "York", keccak256(abi.encodePacked("GB", "YOR")));
        registerRegion("GB", "", "ANN", "Antrim and Newtownabbey", keccak256(abi.encodePacked("GB", "ANN")));
        registerRegion("GB", "", "AND", "Ards and North Down", keccak256(abi.encodePacked("GB", "AND")));
        registerRegion("GB", "", "ABC", "Armagh, Banbridge and Craigavon", keccak256(abi.encodePacked("GB", "ABC")));
        registerRegion("GB", "", "BFS", "Belfast", keccak256(abi.encodePacked("GB", "BFS")));
        registerRegion("GB", "", "CCG", "Causeway Coast and Glens", keccak256(abi.encodePacked("GB", "CCG")));
        registerRegion("GB", "", "DRS", "Derry and Strabane", keccak256(abi.encodePacked("GB", "DRS")));
        registerRegion("GB", "", "FMO", "Fermanagh and Omagh", keccak256(abi.encodePacked("GB", "FMO")));
        registerRegion("GB", "", "LBC", "Lisburn and Castlereagh", keccak256(abi.encodePacked("GB", "LBC")));
        registerRegion("GB", "", "MEA", "Mid and East Antrim", keccak256(abi.encodePacked("GB", "MEA")));
        registerRegion("GB", "", "MUL", "Mid Ulster", keccak256(abi.encodePacked("GB", "MUL")));
        registerRegion("GB", "", "NMD", "Newry, Mourne and Down", keccak256(abi.encodePacked("GB", "NMD")));
        registerRegion("GB", "", "ABE", "Aberdeen City", keccak256(abi.encodePacked("GB", "ABE")));
        registerRegion("GB", "", "ABD", "Aberdeenshire", keccak256(abi.encodePacked("GB", "ABD")));
        registerRegion("GB", "", "ANS", "Angus", keccak256(abi.encodePacked("GB", "ANS")));
        registerRegion("GB", "", "AGB", "Argyll and Bute", keccak256(abi.encodePacked("GB", "AGB")));
        registerRegion("GB", "", "CLK", "Clackmannanshire", keccak256(abi.encodePacked("GB", "CLK")));
        registerRegion("GB", "", "DGY", "Dumfries and Galloway", keccak256(abi.encodePacked("GB", "DGY")));
        registerRegion("GB", "", "DND", "Dundee City", keccak256(abi.encodePacked("GB", "DND")));
        registerRegion("GB", "", "EAY", "East Ayrshire", keccak256(abi.encodePacked("GB", "EAY")));
        registerRegion("GB", "", "EDU", "East Dunbartonshire", keccak256(abi.encodePacked("GB", "EDU")));
        registerRegion("GB", "", "ELN", "East Lothian", keccak256(abi.encodePacked("GB", "ELN")));
        registerRegion("GB", "", "ERW", "East Renfrewshire", keccak256(abi.encodePacked("GB", "ERW")));
        registerRegion("GB", "", "EDH", "Edinburgh, City of", keccak256(abi.encodePacked("GB", "EDH")));
        registerRegion("GB", "", "ELS", "Eilean Siar", keccak256(abi.encodePacked("GB", "ELS")));
        registerRegion("GB", "", "FAL", "Falkirk", keccak256(abi.encodePacked("GB", "FAL")));
        registerRegion("GB", "", "FIF", "Fife", keccak256(abi.encodePacked("GB", "FIF")));
        registerRegion("GB", "", "GLG", "Glasgow City", keccak256(abi.encodePacked("GB", "GLG")));
        registerRegion("GB", "", "HLD", "Highland", keccak256(abi.encodePacked("GB", "HLD")));
        registerRegion("GB", "", "IVC", "Inverclyde", keccak256(abi.encodePacked("GB", "IVC")));
        registerRegion("GB", "", "MLN", "Midlothian", keccak256(abi.encodePacked("GB", "MLN")));
        registerRegion("GB", "", "MRY", "Moray", keccak256(abi.encodePacked("GB", "MRY")));
        registerRegion("GB", "", "NAY", "North Ayrshire", keccak256(abi.encodePacked("GB", "NAY")));
        registerRegion("GB", "", "NLK", "North Lanarkshire", keccak256(abi.encodePacked("GB", "NLK")));
        registerRegion("GB", "", "ORK", "Orkney Islands", keccak256(abi.encodePacked("GB", "ORK")));
        registerRegion("GB", "", "PKN", "Perth and Kinross", keccak256(abi.encodePacked("GB", "PKN")));
        registerRegion("GB", "", "RFW", "Renfrewshire", keccak256(abi.encodePacked("GB", "RFW")));
        registerRegion("GB", "", "SCB", "Scottish Borders, The", keccak256(abi.encodePacked("GB", "SCB")));
        registerRegion("GB", "", "ZET", "Shetland Islands", keccak256(abi.encodePacked("GB", "ZET")));
        registerRegion("GB", "", "SAY", "South Ayrshire", keccak256(abi.encodePacked("GB", "SAY")));
        registerRegion("GB", "", "SLK", "South Lanarkshire", keccak256(abi.encodePacked("GB", "SLK")));
        registerRegion("GB", "", "STG", "Stirling", keccak256(abi.encodePacked("GB", "STG")));
        registerRegion("GB", "", "WDU", "West Dunbartonshire", keccak256(abi.encodePacked("GB", "WDU")));
        registerRegion("GB", "", "WLN", "West Lothian", keccak256(abi.encodePacked("GB", "WLN")));
        registerRegion("GB", "", "BGW", "Blaenau Gwent", keccak256(abi.encodePacked("GB", "BGW")));
        registerRegion("GB", "", "BGE", "Bridgend [Pen-y-bont ar Ogwr GB-POG]", keccak256(abi.encodePacked("GB", "BGE")));
        registerRegion("GB", "", "CAY", "Caerphilly [Caerffili GB-CAF]", keccak256(abi.encodePacked("GB", "CAY")));
        registerRegion("GB", "", "CRF", "Cardiff [Caerdydd GB-CRD]", keccak256(abi.encodePacked("GB", "CRF")));
        registerRegion("GB", "", "CMN", "Carmarthenshire [Sir Gaerfyrddin GB-GFY]", keccak256(abi.encodePacked("GB", "CMN")));
        registerRegion("GB", "", "CGN", "Ceredigion [Sir Ceredigion]", keccak256(abi.encodePacked("GB", "CGN")));
        registerRegion("GB", "", "CWY", "Conwy", keccak256(abi.encodePacked("GB", "CWY")));
        registerRegion("GB", "", "DEN", "Denbighshire [Sir Ddinbych GB-DDB]", keccak256(abi.encodePacked("GB", "DEN")));
        registerRegion("GB", "", "FLN", "Flintshire [Sir y Fflint GB-FFL]", keccak256(abi.encodePacked("GB", "FLN")));
        registerRegion("GB", "", "GWN", "Gwynedd", keccak256(abi.encodePacked("GB", "GWN")));
        registerRegion("GB", "", "AGY", "Isle of Anglesey [Sir Ynys Môn GB-YNM]", keccak256(abi.encodePacked("GB", "AGY")));
        registerRegion("GB", "", "MTY", "Merthyr Tydfil [Merthyr Tudful GB-MTU]", keccak256(abi.encodePacked("GB", "MTY")));
        registerRegion("GB", "", "MON", "Monmouthshire [Sir Fynwy GB-FYN]", keccak256(abi.encodePacked("GB", "MON")));
        registerRegion("GB", "", "NTL", "Neath Port Talbot [Castell-nedd Port Talbot GB-CTL]", keccak256(abi.encodePacked("GB", "NTL")));
        registerRegion("GB", "", "NWP", "Newport [Casnewydd GB-CNW]", keccak256(abi.encodePacked("GB", "NWP")));
        registerRegion("GB", "", "PEM", "Pembrokeshire [Sir Benfro GB-BNF]", keccak256(abi.encodePacked("GB", "PEM")));
        registerRegion("GB", "", "POW", "Powys", keccak256(abi.encodePacked("GB", "POW")));
        registerRegion("GB", "", "RCT", "Rhondda, Cynon, Taff [Rhondda, Cynon, Taf]", keccak256(abi.encodePacked("GB", "RCT")));
        registerRegion("GB", "", "SWA", "Swansea [Abertawe GB-ATA]", keccak256(abi.encodePacked("GB", "SWA")));
        registerRegion("GB", "", "TOF", "Torfaen [Tor-faen]", keccak256(abi.encodePacked("GB", "TOF")));
        registerRegion("GB", "", "VGL", "Vale of Glamorgan, The [Bro Morgannwg GB-BMG]", keccak256(abi.encodePacked("GB", "VGL")));
        registerRegion("GB", "", "WRX", "Wrexham [Wrecsam GB-WRC]", keccak256(abi.encodePacked("GB", "WRX")));

        registerRegion("VE", "W", "", "Dependencias Federales", keccak256(abi.encodePacked("VE", "W")));
        registerRegion("VE", "A", "", "Distrito Federal [note 1]", keccak256(abi.encodePacked("VE", "A")));
        registerRegion("VE", "Z", "", "Amazonas", keccak256(abi.encodePacked("VE", "Z")));
        registerRegion("VE", "B", "", "Anzoátegui", keccak256(abi.encodePacked("VE", "B")));
        registerRegion("VE", "C", "", "Apure", keccak256(abi.encodePacked("VE", "C")));
        registerRegion("VE", "D", "", "Aragua", keccak256(abi.encodePacked("VE", "D")));
        registerRegion("VE", "E", "", "Barinas", keccak256(abi.encodePacked("VE", "E")));
        registerRegion("VE", "F", "", "Bolívar", keccak256(abi.encodePacked("VE", "F")));
        registerRegion("VE", "G", "", "Carabobo", keccak256(abi.encodePacked("VE", "G")));
        registerRegion("VE", "H", "", "Cojedes", keccak256(abi.encodePacked("VE", "H")));
        registerRegion("VE", "Y", "", "Delta Amacuro", keccak256(abi.encodePacked("VE", "Y")));
        registerRegion("VE", "I", "", "Falcón", keccak256(abi.encodePacked("VE", "I")));
        registerRegion("VE", "J", "", "Guárico", keccak256(abi.encodePacked("VE", "J")));
        registerRegion("VE", "K", "", "Lara", keccak256(abi.encodePacked("VE", "K")));
        registerRegion("VE", "L", "", "Mérida", keccak256(abi.encodePacked("VE", "L")));
        registerRegion("VE", "M", "", "Miranda", keccak256(abi.encodePacked("VE", "M")));
        registerRegion("VE", "N", "", "Monagas", keccak256(abi.encodePacked("VE", "N")));
        registerRegion("VE", "O", "", "Nueva Esparta", keccak256(abi.encodePacked("VE", "O")));
        registerRegion("VE", "P", "", "Portuguesa", keccak256(abi.encodePacked("VE", "P")));
        registerRegion("VE", "R", "", "Sucre", keccak256(abi.encodePacked("VE", "R")));
        registerRegion("VE", "S", "", "Táchira", keccak256(abi.encodePacked("VE", "S")));
        registerRegion("VE", "T", "", "Trujillo", keccak256(abi.encodePacked("VE", "T")));
        registerRegion("VE", "X", "", "Vargas", keccak256(abi.encodePacked("VE", "X")));
        registerRegion("VE", "U", "", "Yaracuy", keccak256(abi.encodePacked("VE", "U")));
        registerRegion("VE", "V", "", "Zulia", keccak256(abi.encodePacked("VE", "V")));

    }

    function registerCountry(bytes2 _alpha2, bytes3 _alpha3, bytes3 _m49, string memory _name) internal {
        bytes32[] memory regionKeys;
        countries[_alpha2] = Country({ alpha2: _alpha2, alpha3: _alpha3, m49: _m49, name: _name, regionKeys: regionKeys, exists: true });
        countryKeys.push(_alpha2);
        emit LogCountryRegistration(
            EVENT_ID_ISO_COUNTRIES,
            _alpha2,
            _alpha3,
            _m49,
            _name
        );
    }

    function registerRegion(bytes2 _alpha2, bytes2 _code2, bytes3 _code3, string memory _name, bytes32 _regionKey) internal {
        countries[_alpha2].regions[_regionKey] = Region({ country: _alpha2, code2: _code2, code3: _code3, name: _name, exists: true });
        countries[_alpha2].regionKeys.push(_regionKey);
        emit LogRegionRegistration(
            EVENT_ID_ISO_REGIONS,
            _alpha2,
            _regionKey,
            _code2,
            _code3,
            _name
        );
    }

}

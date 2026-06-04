// O'rta Osiyo davlatlari va ularning viloyatlari (mijoz formasi uchun).
// value — bazada saqlanadigan qiymat, label — ko'rsatiladigan nom.

export interface CountryOpt {
  value: string;
  label: string;
  /** Twemoji bayroq kodi (PhoneInput bilan bir xil CDN) */
  flagCodes: string;
  regions: string[];
}

export const CENTRAL_ASIA: CountryOpt[] = [
  {
    value: 'Uzbekistan',
    label: "O'zbekiston",
    flagCodes: '1f1fa-1f1ff',
    regions: [
      'Toshkent shahri', 'Toshkent', 'Andijon', 'Buxoro', "Farg'ona", 'Jizzax',
      'Namangan', 'Navoiy', 'Qashqadaryo', "Qoraqalpog'iston", 'Samarqand',
      'Sirdaryo', 'Surxondaryo', 'Xorazm',
    ],
  },
  {
    value: 'Kazakhstan',
    label: "Qozog'iston",
    flagCodes: '1f1f0-1f1ff',
    regions: [
      'Almati shahri', 'Astana shahri', 'Shimkent shahri', 'Abay', 'Aqmola',
      "Aqto'be", 'Almati', 'Atirau', 'Sharqiy Qozog\'iston', 'Jambil', 'Jetisu',
      "G'arbiy Qozog'iston", "Qarag'anda", 'Qostanay', "Qizilo'rda", "Mang'istau",
      'Pavlodar', 'Shimoliy Qozog\'iston', 'Turkiston', 'Ulitau',
    ],
  },
  {
    value: 'Kyrgyzstan',
    label: "Qirg'iziston",
    flagCodes: '1f1f0-1f1ec',
    regions: [
      'Bishkek shahri', 'Osh shahri', 'Batken', 'Chuy', 'Jalolobod',
      "Issiqko'l", 'Norin', 'Osh', 'Talas',
    ],
  },
  {
    value: 'Tajikistan',
    label: 'Tojikiston',
    flagCodes: '1f1f9-1f1ef',
    regions: [
      'Dushanbe shahri', "Sug'd", 'Xatlon', "Tog'li Badaxshon",
      'Respublika bo\'ysunuvidagi tumanlar',
    ],
  },
  {
    value: 'Turkmenistan',
    label: 'Turkmaniston',
    flagCodes: '1f1f9-1f1f2',
    regions: ['Ashxobod shahri', 'Ahal', 'Balkan', "Dashog'uz", 'Lebap', 'Mari'],
  },
];

export function regionsOf(country: string): string[] {
  return CENTRAL_ASIA.find((c) => c.value === country)?.regions ?? [];
}

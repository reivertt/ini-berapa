int parseCurrencyValue(String label) {
  final cleanLabel = label.toLowerCase().replaceAll(' rupiah', '').replaceAll('-', ' ');
  
  switch (cleanLabel) {
    case 'seribu':
    case '1000 perak':
      return 1000;
    case 'dua ribu':
      return 2000;
    case 'lima ribu':
      return 5000;
    case 'sepuluh ribu':
      return 10000;
    case 'dua puluh ribu':
      return 20000;
    case 'lima puluh ribu':
      return 50000;
    case 'seratus ribu':
      return 100000;
    // Tambahkan denominasi lain jika ada
    default:
      return 0;
  }
}
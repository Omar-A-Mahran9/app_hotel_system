// Deterministic dummy dataset for the discovery feature.
//
// Everything here is fixed: stable ids, names, cities, ratings, prices, room
// types and per-hotel offerings. No `Random`, no `DateTime.now()`. This stands
// in for the group catalogue until the Laravel API is wired; it is intentionally
// shaped like a JSON payload so swapping in the API layer is a localized change.
//
// The dataset is small (8 hotels) but the "total matched" count shown in the UI
// always reflects the real filtered length, so it never claims more than exists.

import '../../domain/entities/money.dart';
import '../models/discovery_models.dart';

abstract final class DiscoveryFixtures {
  // ── Cities ────────────────────────────────────────────────────────────────
  static const List<Json> cities = <Json>[
    <String, Object?>{
      'id': 'riyadh',
      'name': <String, Object?>{'ar': 'الرياض', 'en': 'Riyadh'},
      'hotel_count': 3,
    },
    <String, Object?>{
      'id': 'jeddah',
      'name': <String, Object?>{'ar': 'جدة', 'en': 'Jeddah'},
      'hotel_count': 2,
    },
    <String, Object?>{
      'id': 'khobar',
      'name': <String, Object?>{'ar': 'الخبر', 'en': 'Khobar'},
      'hotel_count': 2,
    },
    <String, Object?>{
      'id': 'alula',
      'name': <String, Object?>{'ar': 'العُلا', 'en': 'AlUla'},
      'hotel_count': 1,
    },
  ];

  // ── Room-type catalogue ───────────────────────────────────────────────────
  // Shared across hotels; each hotel picks a subset and sets its own prices.
  static const Map<String, Json> roomCatalogue = <String, Json>{
    'standard': <String, Object?>{
      'id': 'standard',
      'name': <String, Object?>{'ar': 'غرفة قياسية', 'en': 'Standard Room'},
      'description': <String, Object?>{
        'ar': 'غرفة عملية بإطلالة هادئة على المدينة.',
        'en': 'A practical room with a calm city outlook.',
      },
      'bed_type': <String, Object?>{'ar': 'سرير مزدوج', 'en': 'Double bed'},
      'max_occupancy': 2,
      'area_sqm': 26,
      'amenities': <Object?>['free_wifi', 'air_conditioning'],
      'breakfast_included': true,
      'refundable': true,
    },
    'twin': <String, Object?>{
      'id': 'twin',
      'name': <String, Object?>{'ar': 'غرفة توأم', 'en': 'Twin Room'},
      'description': <String, Object?>{
        'ar': 'سريران منفصلان، مناسبة للمسافرين معًا.',
        'en': 'Two separate beds, made for travelling companions.',
      },
      'bed_type': <String, Object?>{'ar': 'سريران مفردان', 'en': 'Two single beds'},
      'max_occupancy': 2,
      'area_sqm': 28,
      'amenities': <Object?>['free_wifi', 'air_conditioning'],
      'breakfast_included': true,
      'refundable': true,
    },
    'deluxe': <String, Object?>{
      'id': 'deluxe',
      'name': <String, Object?>{'ar': 'غرفة ديلوكس', 'en': 'Deluxe Room'},
      'description': <String, Object?>{
        'ar': 'غرفة أوسع وإطلالة أفضل ومساحة جلوس.',
        'en': 'A wider room with a better view and a seating nook.',
      },
      'bed_type': <String, Object?>{'ar': 'سرير كينغ', 'en': 'King bed'},
      'max_occupancy': 3,
      'area_sqm': 32,
      'amenities': <Object?>['free_wifi', 'air_conditioning', 'city_view'],
      'breakfast_included': true,
      'refundable': true,
      // Room Detail sample content (dashboard-managed on the real API).
      'tag': <String, Object?>{'ar': 'غرفة مميزة', 'en': 'Featured room'},
      'inclusions': <Object?>[
        <String, Object?>{'ar': 'واي فاي مجاني', 'en': 'Free Wi-Fi'},
        <String, Object?>{'ar': 'دخول المسبح', 'en': 'Pool access'},
        <String, Object?>{'ar': 'خدمة تنظيف يومية', 'en': 'Daily housekeeping'},
        <String, Object?>{'ar': 'خدمة استقبال 24 ساعة', 'en': '24-hour reception'},
      ],
      'facilities': <Object?>[
        <String, Object?>{'key': 'air_conditioning', 'label': <String, Object?>{'ar': 'تكييف', 'en': 'Air conditioning'}, 'icon': 'fan'},
        <String, Object?>{'key': 'smart_tv', 'label': <String, Object?>{'ar': 'تلفزيون ذكي', 'en': 'Smart TV'}, 'icon': 'tv'},
        <String, Object?>{'key': 'in_room_safe', 'label': <String, Object?>{'ar': 'خزنة', 'en': 'Safe'}, 'icon': 'vault'},
        <String, Object?>{'key': 'coffee_machine', 'label': <String, Object?>{'ar': 'ماكينة قهوة', 'en': 'Coffee machine'}, 'icon': 'coffee'},
        <String, Object?>{'key': 'private_bathroom', 'label': <String, Object?>{'ar': 'حمام خاص', 'en': 'Private bathroom'}, 'icon': 'bath'},
      ],
    },
    'deluxe_balcony': <String, Object?>{
      'id': 'deluxe_balcony',
      'name': <String, Object?>{
        'ar': 'غرفة ديلوكس بشرفة',
        'en': 'Deluxe Room with Balcony',
      },
      'description': <String, Object?>{
        'ar': 'شرفة خاصة تطل على الواجهة.',
        'en': 'A private balcony over the frontage.',
      },
      'bed_type': <String, Object?>{'ar': 'سرير كينغ', 'en': 'King bed'},
      'max_occupancy': 3,
      'area_sqm': 34,
      'amenities': <Object?>['free_wifi', 'air_conditioning', 'balcony', 'city_view'],
      'breakfast_included': true,
      'refundable': true,
    },
    'executive': <String, Object?>{
      'id': 'executive',
      'name': <String, Object?>{'ar': 'غرفة تنفيذية', 'en': 'Executive Room'},
      'description': <String, Object?>{
        'ar': 'طابق مرتفع ودخول إلى صالة الأعمال.',
        'en': 'A high floor with executive-lounge access.',
      },
      'bed_type': <String, Object?>{'ar': 'سرير كينغ', 'en': 'King bed'},
      'max_occupancy': 3,
      'area_sqm': 38,
      'amenities': <Object?>['free_wifi', 'air_conditioning', 'city_view'],
      'breakfast_included': true,
      'refundable': true,
    },
    'junior_suite': <String, Object?>{
      'id': 'junior_suite',
      'name': <String, Object?>{'ar': 'جناح جونيور', 'en': 'Junior Suite'},
      'description': <String, Object?>{
        'ar': 'غرفة نوم ومنطقة معيشة مفتوحة.',
        'en': 'A bedroom with an open living area.',
      },
      'bed_type': <String, Object?>{'ar': 'سرير كينغ + أريكة', 'en': 'King bed + sofa'},
      'max_occupancy': 4,
      'area_sqm': 45,
      'amenities': <Object?>['free_wifi', 'air_conditioning', 'city_view', 'kitchenette'],
      'breakfast_included': true,
      'refundable': true,
    },
    'family_suite': <String, Object?>{
      'id': 'family_suite',
      'name': <String, Object?>{'ar': 'جناح عائلي', 'en': 'Family Suite'},
      'description': <String, Object?>{
        'ar': 'غرفتا نوم منفصلتان ومطبخ صغير.',
        'en': 'Two separate bedrooms and a kitchenette.',
      },
      'bed_type': <String, Object?>{
        'ar': 'سرير كينغ + سريران مفردان',
        'en': 'King bed + two singles',
      },
      'max_occupancy': 5,
      'area_sqm': 60,
      'amenities': <Object?>['free_wifi', 'air_conditioning', 'balcony', 'kitchenette'],
      'breakfast_included': true,
      'refundable': true,
    },
    'royal_suite': <String, Object?>{
      'id': 'royal_suite',
      'name': <String, Object?>{'ar': 'الجناح الملكي', 'en': 'Royal Suite'},
      'description': <String, Object?>{
        'ar': 'أوسع الأجنحة مع خدمة مخصّصة.',
        'en': 'The largest suite, with dedicated service.',
      },
      'bed_type': <String, Object?>{'ar': 'سرير كينغ', 'en': 'King bed'},
      'max_occupancy': 4,
      'area_sqm': 90,
      'amenities': <Object?>['free_wifi', 'air_conditioning', 'balcony', 'city_view'],
      'breakfast_included': true,
      'refundable': false,
    },
  };

  // ── Hotels ────────────────────────────────────────────────────────────────
  // `featured_rank` also defines the "recommended" sort order.
  static const List<Json> hotels = <Json>[
    <String, Object?>{
      'id': 'oasis',
      'name': <String, Object?>{'ar': 'فندق الواحة', 'en': 'The Oasis Hotel'},
      'city_id': 'alula',
      'city_name': <String, Object?>{'ar': 'العُلا', 'en': 'AlUla'},
      'country': <String, Object?>{'ar': 'السعودية', 'en': 'Saudi Arabia'},
      'tagline': <String, Object?>{
        'ar': 'إطلالة صحراوية واسعة وإفطار يومي.',
        'en': 'A wide desert outlook and daily breakfast.',
      },
      'description': <String, Object?>{
        'ar':
            'غرفة واسعة بإطلالة على المدينة، تشمل إفطارًا يوميًا وواي فاي مجاني. تسجيل الدخول من التطبيق دون المرور بالاستقبال.',
        'en':
            'Spacious rooms overlooking the valley, with daily breakfast and free Wi-Fi. Check in from the app without stopping at the front desk.',
      },
      'rating': 4.96,
      'star_rating': 5,
      'review_count': 217,
      // Hotel detail content (dashboard-managed on the real API).
      'check_in_time': '15:00',
      'check_out_time': '12:00',
      'prices_include_taxes': true,
      'service_fee': <String, Object?>{'type': 'fixed', 'value': 45},
      'nightly_rate_from': <String, Object?>{'amount': 320, 'currency': Money.fallbackCurrency},
      'is_available': true,
      'amenities': <Object?>[
        'free_wifi', 'breakfast', 'pool', 'gym', 'parking', 'room_service',
      ],
      'room_type_count': 6,
      'photo_count': 48,
      'featured': true,
      'featured_rank': 1,
      'room_offerings': <Object?>[
        <String, Object?>{'room_type_id': 'standard', 'nightly_rate': 320, 'available': true},
        <String, Object?>{'room_type_id': 'twin', 'nightly_rate': 420, 'available': true},
        <String, Object?>{'room_type_id': 'deluxe', 'nightly_rate': 450, 'available': true},
        <String, Object?>{'room_type_id': 'deluxe_balcony', 'nightly_rate': 520, 'available': true},
        <String, Object?>{'room_type_id': 'executive', 'nightly_rate': 690, 'available': true},
        <String, Object?>{'room_type_id': 'junior_suite', 'nightly_rate': 780, 'available': true},
        <String, Object?>{'room_type_id': 'family_suite', 'nightly_rate': 950, 'available': true},
        // Listed but sold out — exercises the "sold out" room row.
        <String, Object?>{'room_type_id': 'royal_suite', 'nightly_rate': 1450, 'available': false},
      ],
    },
    <String, Object?>{
      'id': 'marina',
      'name': <String, Object?>{'ar': 'فندق المرسى', 'en': 'The Marina Hotel'},
      'city_id': 'jeddah',
      'city_name': <String, Object?>{'ar': 'جدة', 'en': 'Jeddah'},
      'country': <String, Object?>{'ar': 'السعودية', 'en': 'Saudi Arabia'},
      'tagline': <String, Object?>{
        'ar': 'على الواجهة البحرية مباشرة.',
        'en': 'Right on the waterfront.',
      },
      'description': <String, Object?>{
        'ar': 'فندق على الكورنيش بغرف تطل على البحر ومسبح خارجي.',
        'en': 'A corniche hotel with sea-facing rooms and an outdoor pool.',
      },
      'rating': 4.90,
      'star_rating': 5,
      'review_count': 184,
      'nightly_rate_from': <String, Object?>{'amount': 460, 'currency': Money.fallbackCurrency},
      'is_available': true,
      'amenities': <Object?>['free_wifi', 'breakfast', 'pool', 'parking', 'airport_shuttle'],
      'room_type_count': 5,
      'photo_count': 32,
      'featured': true,
      'featured_rank': 2,
      'room_offerings': <Object?>[
        <String, Object?>{'room_type_id': 'standard', 'nightly_rate': 460, 'available': true},
        <String, Object?>{'room_type_id': 'deluxe', 'nightly_rate': 560, 'available': true},
        <String, Object?>{'room_type_id': 'deluxe_balcony', 'nightly_rate': 640, 'available': true},
        <String, Object?>{'room_type_id': 'junior_suite', 'nightly_rate': 880, 'available': true},
        <String, Object?>{'room_type_id': 'family_suite', 'nightly_rate': 1120, 'available': true},
      ],
    },
    <String, Object?>{
      'id': 'palm',
      'name': <String, Object?>{'ar': 'فندق النخيل', 'en': 'The Palm Hotel'},
      'city_id': 'riyadh',
      'city_name': <String, Object?>{'ar': 'الرياض', 'en': 'Riyadh'},
      'country': <String, Object?>{'ar': 'السعودية', 'en': 'Saudi Arabia'},
      'tagline': <String, Object?>{
        'ar': 'قريب من حي المال والأعمال.',
        'en': 'Close to the business district.',
      },
      'description': <String, Object?>{
        'ar': 'فندق أعمال هادئ بغرف مكتبية ومركز لياقة على مدار الساعة.',
        'en': 'A quiet business hotel with desk-equipped rooms and a 24-hour gym.',
      },
      'rating': 4.85,
      'star_rating': 4,
      'review_count': 203,
      'nightly_rate_from': <String, Object?>{'amount': 380, 'currency': Money.fallbackCurrency},
      'is_available': true,
      'amenities': <Object?>['free_wifi', 'breakfast', 'gym', 'parking', 'room_service'],
      'room_type_count': 4,
      'photo_count': 21,
      'featured': true,
      'featured_rank': 3,
      'room_offerings': <Object?>[
        <String, Object?>{'room_type_id': 'standard', 'nightly_rate': 380, 'available': true},
        <String, Object?>{'room_type_id': 'twin', 'nightly_rate': 400, 'available': true},
        <String, Object?>{'room_type_id': 'deluxe', 'nightly_rate': 480, 'available': true},
        <String, Object?>{'room_type_id': 'executive', 'nightly_rate': 620, 'available': true},
      ],
    },
    <String, Object?>{
      'id': 'citywalk',
      'name': <String, Object?>{'ar': 'فندق الممشى', 'en': 'The Citywalk Hotel'},
      'city_id': 'riyadh',
      'city_name': <String, Object?>{'ar': 'الرياض', 'en': 'Riyadh'},
      'country': <String, Object?>{'ar': 'السعودية', 'en': 'Saudi Arabia'},
      'tagline': <String, Object?>{
        'ar': 'وسط منطقة المطاعم والمشي.',
        'en': 'In the middle of the dining and walking quarter.',
      },
      'description': <String, Object?>{
        'ar': 'فندق حديث فوق ممشى تجاري، بمداخل مباشرة إلى المقاهي.',
        'en': 'A modern hotel above a retail promenade, steps from the cafés.',
      },
      'rating': 4.70,
      'star_rating': 5,
      'review_count': 96,
      'nightly_rate_from': <String, Object?>{'amount': 540, 'currency': Money.fallbackCurrency},
      'is_available': true,
      'amenities': <Object?>['free_wifi', 'breakfast', 'gym', 'family_rooms'],
      'room_type_count': 4,
      'photo_count': 18,
      'featured': false,
      'featured_rank': 4,
      'room_offerings': <Object?>[
        <String, Object?>{'room_type_id': 'deluxe', 'nightly_rate': 540, 'available': true},
        <String, Object?>{'room_type_id': 'deluxe_balcony', 'nightly_rate': 610, 'available': true},
        <String, Object?>{'room_type_id': 'junior_suite', 'nightly_rate': 860, 'available': true},
        <String, Object?>{'room_type_id': 'family_suite', 'nightly_rate': 1040, 'available': true},
      ],
    },
    <String, Object?>{
      'id': 'pearl',
      'name': <String, Object?>{'ar': 'فندق اللؤلؤة', 'en': 'The Pearl Hotel'},
      'city_id': 'khobar',
      'city_name': <String, Object?>{'ar': 'الخبر', 'en': 'Khobar'},
      'country': <String, Object?>{'ar': 'السعودية', 'en': 'Saudi Arabia'},
      'tagline': <String, Object?>{
        'ar': 'الأوفر ضمن فنادق المجموعة.',
        'en': 'The best value in the group.',
      },
      'description': <String, Object?>{
        'ar': 'فندق مريح قرب الكورنيش بأسعار مناسبة وغرف عائلية.',
        'en': 'A comfortable seafront-adjacent hotel with fair prices and family rooms.',
      },
      'rating': 4.60,
      'star_rating': 4,
      'review_count': 142,
      'nightly_rate_from': <String, Object?>{'amount': 300, 'currency': Money.fallbackCurrency},
      'is_available': true,
      'amenities': <Object?>['free_wifi', 'breakfast', 'parking', 'family_rooms'],
      'room_type_count': 4,
      'photo_count': 14,
      'featured': true,
      'featured_rank': 5,
      'room_offerings': <Object?>[
        <String, Object?>{'room_type_id': 'standard', 'nightly_rate': 300, 'available': true},
        <String, Object?>{'room_type_id': 'twin', 'nightly_rate': 320, 'available': true},
        <String, Object?>{'room_type_id': 'deluxe', 'nightly_rate': 410, 'available': true},
        <String, Object?>{'room_type_id': 'family_suite', 'nightly_rate': 720, 'available': true},
      ],
    },
    <String, Object?>{
      'id': 'dunes',
      'name': <String, Object?>{'ar': 'فندق الكثبان', 'en': 'The Dunes Hotel'},
      'city_id': 'alula',
      'city_name': <String, Object?>{'ar': 'العُلا', 'en': 'AlUla'},
      'country': <String, Object?>{'ar': 'السعودية', 'en': 'Saudi Arabia'},
      'tagline': <String, Object?>{
        'ar': 'أجنحة صحراوية مع مسبح خاص.',
        'en': 'Desert suites with a private pool.',
      },
      'description': <String, Object?>{
        'ar': 'نُزل صغير من الأجنحة وسط الكثبان، لكل جناح فِناء خاص.',
        'en': 'A small suite lodge among the dunes, each suite with its own courtyard.',
      },
      'rating': 4.55,
      'star_rating': 3,
      'review_count': 61,
      'nightly_rate_from': <String, Object?>{'amount': 720, 'currency': Money.fallbackCurrency},
      'is_available': true,
      'amenities': <Object?>['free_wifi', 'breakfast', 'pool', 'airport_shuttle', 'room_service'],
      'room_type_count': 3,
      'photo_count': 12,
      'featured': false,
      'featured_rank': 6,
      'room_offerings': <Object?>[
        <String, Object?>{'room_type_id': 'junior_suite', 'nightly_rate': 720, 'available': true},
        <String, Object?>{'room_type_id': 'family_suite', 'nightly_rate': 980, 'available': true},
        <String, Object?>{'room_type_id': 'royal_suite', 'nightly_rate': 1480, 'available': true},
      ],
    },
    <String, Object?>{
      'id': 'harbor',
      'name': <String, Object?>{'ar': 'فندق المرفأ', 'en': 'The Harbor Hotel'},
      'city_id': 'jeddah',
      'city_name': <String, Object?>{'ar': 'جدة', 'en': 'Jeddah'},
      'country': <String, Object?>{'ar': 'السعودية', 'en': 'Saudi Arabia'},
      'tagline': <String, Object?>{
        'ar': 'قرب السوق التاريخي.',
        'en': 'Near the historic market.',
      },
      'description': <String, Object?>{
        'ar': 'فندق تراثي في البلد، غرف بطراز محلي وسطح للإفطار.',
        'en': 'A heritage hotel in Al-Balad, locally styled rooms and a breakfast terrace.',
      },
      'rating': 4.40,
      'star_rating': 4,
      'review_count': 74,
      'nightly_rate_from': <String, Object?>{'amount': 350, 'currency': Money.fallbackCurrency},
      'is_available': true,
      'amenities': <Object?>['free_wifi', 'breakfast', 'room_service'],
      'room_type_count': 3,
      'photo_count': 10,
      'featured': false,
      'featured_rank': 7,
      'room_offerings': <Object?>[
        <String, Object?>{'room_type_id': 'standard', 'nightly_rate': 350, 'available': true},
        <String, Object?>{'room_type_id': 'twin', 'nightly_rate': 360, 'available': true},
        <String, Object?>{'room_type_id': 'deluxe', 'nightly_rate': 470, 'available': true},
      ],
    },
    <String, Object?>{
      'id': 'summit',
      'name': <String, Object?>{'ar': 'فندق القمة', 'en': 'The Summit Hotel'},
      'city_id': 'khobar',
      'city_name': <String, Object?>{'ar': 'الخبر', 'en': 'Khobar'},
      'country': <String, Object?>{'ar': 'السعودية', 'en': 'Saudi Arabia'},
      'tagline': <String, Object?>{
        'ar': 'مغلق مؤقتًا للتجديد.',
        'en': 'Temporarily closed for refurbishment.',
      },
      'description': <String, Object?>{
        'ar': 'برج إقامة طويلة المدى، مغلق حاليًا لأعمال التجديد.',
        'en': 'A long-stay tower, currently closed for refurbishment.',
      },
      'rating': null,
      'star_rating': 3,
      'review_count': null,
      'nightly_rate_from': <String, Object?>{'amount': 430, 'currency': Money.fallbackCurrency},
      'is_available': false,
      'amenities': <Object?>['free_wifi', 'gym', 'parking'],
      'room_type_count': 2,
      'photo_count': 6,
      'featured': false,
      'featured_rank': 8,
      'room_offerings': <Object?>[
        <String, Object?>{'room_type_id': 'standard', 'nightly_rate': 430, 'available': false},
        <String, Object?>{'room_type_id': 'deluxe', 'nightly_rate': 530, 'available': false},
      ],
    },
  ];
}

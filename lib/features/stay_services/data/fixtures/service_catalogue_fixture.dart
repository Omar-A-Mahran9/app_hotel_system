import '../../../discovery/domain/entities/localized_text.dart';
import '../../../discovery/domain/entities/money.dart';
import '../../domain/entities/hotel_service.dart';

/// Deterministic **dummy/test** service catalogue used while no guest-facing
/// stay-services API is approved. Shapes mirror `ServiceCategoryResource` /
/// `ServiceResource` (plus the not-yet-approved `estimated_minutes`). Values
/// are fixed — no `Random`, no time. Kept small: just enough to render
/// `11 · Services & requests` faithfully.
abstract final class ServiceCatalogueFixture {
  static const List<ServiceCategory> categories = <ServiceCategory>[
    ServiceCategory(
      id: '1',
      name: LocalizedText(ar: 'خدمة الغرف', en: 'Housekeeping'),
      isActive: true,
    ),
    ServiceCategory(
      id: '2',
      name: LocalizedText(ar: 'وسائل الراحة', en: 'In-room comfort'),
      isActive: true,
    ),
  ];

  static const List<HotelService> services = <HotelService>[
    HotelService(
      id: '101',
      categoryId: '1',
      name: LocalizedText(ar: 'تنظيف الغرفة', en: 'Room cleaning'),
      description: LocalizedText(
        ar: 'تنظيف كامل لغرفتك من قبل فريق التدبير الفندقي.',
        en: 'A full refresh of your room by housekeeping.',
      ),
      price: Money(amount: 0),
      isActive: true,
      estimatedMinutes: 20,
    ),
    HotelService(
      id: '102',
      categoryId: '1',
      name: LocalizedText(ar: 'خدمة الطعام في الغرفة', en: 'Room service'),
      description: LocalizedText(
        ar: 'اطلب الطعام والمشروبات إلى غرفتك من المطبخ.',
        en: 'Order food and drinks to your room from the kitchen.',
      ),
      price: Money(amount: 30),
      isActive: true,
      estimatedMinutes: 30,
    ),
    HotelService(
      id: '103',
      categoryId: '1',
      name: LocalizedText(ar: 'غسيل الملابس', en: 'Laundry'),
      description: LocalizedText(
        ar: 'غسيل وكيّ الملابس في نفس اليوم.',
        en: 'Same-day laundry and pressing.',
      ),
      price: Money(amount: 45),
      isActive: true,
    ),
    HotelService(
      id: '201',
      categoryId: '2',
      name: LocalizedText(
          ar: 'مناشف ومستلزمات إضافية', en: 'Extra towels & amenities'),
      description: LocalizedText(
        ar: 'مناشف ومستلزمات وأغطية إضافية عند الطلب.',
        en: 'Fresh towels, toiletries and bedding on request.',
      ),
      price: Money(amount: 0),
      isActive: true,
      estimatedMinutes: 15,
    ),
    HotelService(
      id: '202',
      categoryId: '2',
      name: LocalizedText(ar: 'الصيانة', en: 'Maintenance'),
      description: LocalizedText(
        ar: 'أبلغ عن شيء يحتاج إلى إصلاح في غرفتك.',
        en: 'Report something that needs fixing in your room.',
      ),
      price: Money(amount: 0),
      isActive: true,
      estimatedMinutes: 45,
    ),
    HotelService(
      id: '203',
      categoryId: '2',
      name: LocalizedText(ar: 'النقل من وإلى المطار', en: 'Airport transfer'),
      description: LocalizedText(
        ar: 'رتّب سيارة من أو إلى المطار.',
        en: 'Arrange a car to or from the airport.',
      ),
      price: Money(amount: 120),
      isActive: true,
    ),
  ];

  static const ServiceCatalogue catalogue =
      ServiceCatalogue(categories: categories, services: services);

  static HotelService? serviceById(String id) => catalogue.serviceById(id);
}

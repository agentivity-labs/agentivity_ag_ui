import 'package:flutter/material.dart';

// ── Flight ────────────────────────────────────────────────────────────────────

class TravelFlight {
  const TravelFlight({
    required this.id,
    required this.airline,
    required this.flightNumber,
    required this.originCode,
    required this.origin,
    required this.destinationCode,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.price,
    required this.cabin,
    required this.gradient,
    this.badge,
  });

  final String id;
  final String airline;
  final String flightNumber;
  final String originCode;
  final String origin;
  final String destinationCode;
  final String destination;
  final String departure;
  final String arrival;
  final String duration;
  final double price;
  final String cabin;
  final List<Color> gradient;
  final String? badge;
}

// ── Hotel ─────────────────────────────────────────────────────────────────────

class TravelHotel {
  const TravelHotel({
    required this.id,
    required this.name,
    required this.neighborhood,
    required this.stars,
    required this.rating,
    required this.reviews,
    required this.pricePerNight,
    required this.nights,
    required this.amenities,
    required this.gradient,
    this.badge,
  });

  final String id;
  final String name;
  final String neighborhood;
  final int stars;
  final double rating;
  final int reviews;
  final double pricePerNight;
  final int nights;
  final List<String> amenities;
  final List<Color> gradient;
  final String? badge;

  double get hotelTotal => pricePerNight * nights;
}

// ── Data ──────────────────────────────────────────────────────────────────────

const kFlights = [
  TravelFlight(
    id: 'f1',
    airline: 'Vueling',
    flightNumber: 'VY 1234',
    originCode: 'CDG',
    origin: 'Paris',
    destinationCode: 'BCN',
    destination: 'Barcelona',
    departure: '08:30',
    arrival: '10:45',
    duration: '2h 15m',
    price: 189.0,
    cabin: 'Economy Plus',
    gradient: [Color(0xFF0077B6), Color(0xFF00B4D8)],
    badge: 'Best Value',
  ),
  TravelFlight(
    id: 'f2',
    airline: 'Iberia',
    flightNumber: 'IB 3521',
    originCode: 'ORY',
    origin: 'Paris',
    destinationCode: 'BCN',
    destination: 'Barcelona',
    departure: '14:15',
    arrival: '16:30',
    duration: '2h 15m',
    price: 245.0,
    cabin: 'Economy',
    gradient: [Color(0xFF1A237E), Color(0xFF3949AB)],
  ),
];

const kHotels = [
  TravelHotel(
    id: 'h1',
    name: 'Hotel Arts Barcelona',
    neighborhood: 'Barceloneta',
    stars: 5,
    rating: 4.8,
    reviews: 2841,
    pricePerNight: 320.0,
    nights: 3,
    amenities: ['🏊 Pool', '🍽️ Restaurant', '🌊 Sea view', '🏋️ Gym'],
    gradient: [Color(0xFF0D3B5E), Color(0xFF0077B6)],
    badge: '⭐ Top Pick',
  ),
  TravelHotel(
    id: 'h2',
    name: 'Mandarin Oriental',
    neighborhood: 'Passeig de Gràcia',
    stars: 5,
    rating: 4.9,
    reviews: 1523,
    pricePerNight: 480.0,
    nights: 3,
    amenities: ['🧖 Spa', '🍽️ Restaurant', '🌆 City view', '🏋️ Gym'],
    gradient: [Color(0xFF1B003E), Color(0xFF5C0099)],
    badge: '💎 Luxury',
  ),
  TravelHotel(
    id: 'h3',
    name: 'Praktik Rambla',
    neighborhood: 'Las Ramblas',
    stars: 4,
    rating: 4.5,
    reviews: 3102,
    pricePerNight: 145.0,
    nights: 3,
    amenities: ['☕ Breakfast', '📍 Central', '🏊 Pool'],
    gradient: [Color(0xFF003D2E), Color(0xFF00695C)],
  ),
];

TravelFlight? flightById(String id) =>
    kFlights.where((f) => f.id == id).firstOrNull;

TravelHotel? hotelById(String id) =>
    kHotels.where((h) => h.id == id).firstOrNull;

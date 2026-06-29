## Core Value
Ciervo is not just about discovering places.

It is about making group decisions easier:
- where to go
- who is joining
- how to split the cost

The main focus is reducing friction in social planning.
# Ciervo App Context

## Overview
Ciervo is a mobile app focused on nightlife discovery, social planning, and payments.

The goal is to provide a premium experience where users can:
- Discover places (bars, clubs, events)
- Plan outings with friends (Vakupli)
- Split payments easily
- Interact through temporary chat

## Core Features

### 1. Explore
- Discover places based on location
- View recommendations
- Ratings and match percentage

### 2. Place Detail
- View full info about a place
- Promotions
- Reviews
- Reserve or pay

### 3. Vakupli (Core Feature)
- Create group plans
- Select friends
- Split payments
- Temporary chat (self-destruct)

### 4. Payments
- Pay for self or others
- Wallet (Upli)
- Card and QR options

### 5. Profile
- Preferences
- History
- Reviews
- Wallet info

## Design Philosophy
- Cinematic nightlife experience
- Premium, dark UI
- Premium gold, deep emerald, black, grays, and ivory
- No borders, only depth and contrast

## Architecture
- Flutter
- BLoC / Cubit for state management
- Repository pattern
- Feature-based structure

## Rules for AI
- Do NOT invent new features
- Follow design system strictly
- Prioritize reusable components
- Keep code clean and modular
- Maintain consistent UI across screens

## Experience Modes
Ciervo supports two contextual experience modes:
- Day Mode
- Night Mode

The selected mode affects:
- visual theme
- recommended categories
- featured places
- cards imagery and overlays
- microcopy tone

The app must not duplicate screens for day and night.
Instead, it must use the same feature structure with theme/context-aware rendering.

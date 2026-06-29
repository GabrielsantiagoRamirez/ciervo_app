You are a senior Flutter architect.

Create the base structure for a scalable Flutter app called "Ciervo".

🎯 Requirements:
- Flutter 3.x
- Clean architecture (lightweight)
- Use BLoC (flutter_bloc)
- Use repository pattern
- Responsive ready

📦 Folder structure:

lib/
 ├── core/
 │   ├── theme/
 │   ├── utils/
 │
 ├── shared/
 │   ├── widgets/
 │
 ├── features/
 │   ├── home/
 │   ├── place_detail/
 │   ├── vakupli/
 │   ├── payments/
 │   ├── profile/
 │
 ├── app.dart
 ├── main.dart

🎯 Setup:
- Add flutter_bloc
- Create AppBlocObserver
- Setup MaterialApp with routes

🎯 Navigation:
- BottomNavigationBar with:
  - Explore
  - Vakupli
  - Search
  - Wallet
  - Profile

Return clean, runnable code.
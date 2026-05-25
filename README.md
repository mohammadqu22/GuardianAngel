<div align="center">
  <h1>🛡️ Guardian Angel</h1>
  
  <p>
    <strong>Interactive mobile app for hands-free guidance during medical emergencies</strong>
  </p>
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
  [![Project Status](https://img.shields.io/badge/Status-Alpha-blue.svg)](#-overview)
</div>

---

## 📋 Table of Contents

- [🎯 Overview](#-overview)
- [❗ Problem Statement](#-problem-statement)
- [🚀 Getting Started](#-getting-started)
- [👨‍💻 Developers](#developers)



---

## 🎯 Overview

**Guardian Angel** is an innovative mobile application providing **step-by-step, interactive guidance during medical emergencies**.  

- Aims to bridge the gap for the ~90% of people lacking proper first-aid knowledge.  
- Designed for **parents, teachers, travelers, and caregivers**.  
- Offers **hands-free, voice-assisted, offline guidance** with visual aids for high-stress situations.  
- Transforms the smartphone into a reliable **life-saving companion**.

The app originated from a real-life incident where a friend suffered severe burns, highlighting the need for **immediate, clear instructions under stress**.

---

## ❗ Problem Statement
- **Too much information:** Guides are overwhelming under stress  
- **Panic & confusion:** Users may freeze or act incorrectly  
- **Hard to use phones:** Emergencies limit reading/holding devices  
- **No internet:** Many incidents occur offline  

**Target users:** Parents, teachers, hikers, cooks, workers.  
**Statistics:** 90% of people in Israel don’t know CPR; only 30% have basic first-aid training.

---

**System Architecture:**

- **Frontend:** Flutter (Dart)  
- **Storage:** JSON (protocols) + SQLite (user data, settings)  
- **Audio:** Native TTS for offline voice guidance  
- **Logic:** Deterministic state machine  

**Core Flow:**

1. User selects emergency category  
2. System loads JSON protocol  
3. Step[i] is displayed & TTS reads instruction  
4. User completes step → taps "Next"  
5. Repeat until procedure ends  
6. System logs incident in local history  

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.5.4+)  
- Dart SDK (included)  
- Android Studio or VS Code with Flutter extension  

### Installation

```bash
# Clone the repo
git clone https://github.com/mohammadqu22/GuardianAngel.git
cd GuardianAngel

# Install dependencies
flutter pub get

# Run the app
flutter run

```
###  Developers

- **Mohammad Quttaineh** – Flutter & Backend  
- **Amru Alyan** – UI/UX & Architecture  
- **Academic Supervisor:** Mrs. Alida'at Adler




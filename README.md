# LostAndFound

**LostAndFound** est une application mobile innovante développée dans le cadre du module **Programmation Mobile** (Semestre 4) à l'Université Hassan 1er - Faculté des Sciences et Techniques de Settat.
Elle résout le problème quotidien des objets perdus en connectant les utilisateurs : ceux qui perdent un objet et ceux qui en trouvent un.

---

## 📋 Table des matières

- [À propos](#-à-propos)
- [Fonctionnalités principales](#-fonctionnalités-principales)
- [Technologies utilisées](#-technologies-utilisées)
- [Architecture](#-architecture)
- [Démonstration](#-démonstration)
- [Installation et configuration](#-installation-et-configuration)
- [Utilisation](#-utilisation)
- [Perspectives d'amélioration](#-perspectives-damélioration)
- [Auteur](#-auteur)
- [Licence](#-licence)

---

## 🧭 À propos

Lorsqu'un objet est perdu ou trouvé, il est souvent difficile de savoir vers qui se tourner. **LostAndFound** permet de :

- **Signaler** un objet perdu ou trouvé avec des détails précis (lieu, description, photos, etc.).
- **Visualiser** tous les rapports d'objets en temps réel.
- **Interagir** via des commentaires pour faciliter les contacts et les récupérations.

L'application vise à créer une communauté solidaire au sein du campus et au-delà, en rendant les objets perdus plus facilement retrouvables.

**Statut du projet** : Version prototype (développée pour un projet universitaire).

---

## ✨ Fonctionnalités principales

- **Authentification sécurisée** : Connexion via email (gérée par Supabase Auth).
- **Rapport d'objets** : Formulaire intuitif pour déclarer un objet perdu ou trouvé (lieu, description, type, photos).
- **Espace de visualisation** : Liste paginée et filtrée des objets reportés.
- **Système de commentaires** : Échanges directs pour coordonner les récupérations.
- **Recherche avancée** : Par nom d'objet, type de rapport (perdu/trouvé) et lieu.
- **Statistiques** : Dashboard avec graphiques sur la nature des objets (ex. : électronique, vêtements, documents).
- **Interface responsive** : Optimisée pour mobile (Android/iOS) avec Flutter.

---

## 🛠 Technologies utilisées

| Composant       | Technologie          | Rôle |
|-----------------|----------------------|------|
| **Frontend**   | **Flutter** (Dart)  | UI/UX, logique métier, appels API |
| **Backend**    | **Supabase**        | Base de données PostgreSQL, Authentification, Stockage fichiers, APIs en temps réel |
| **Outils**     | Dart, Firebase (optionnel pour notifications futures) | Développement multiplateforme |

- **Flutter** : Framework open-source de Google pour des interfaces natives performantes et un code partagé.
- **Supabase** : Alternative open-source à Firebase, idéale pour les apps mobiles avec auth, DB et realtime.

---

## 🏗 Architecture

L'architecture suit un modèle **client-serveur** simple et scalable :

- **Côté client (Flutter)** :
  - Interface utilisateur (UI/UX moderne avec Material Design).
  - Gestion des états (Provider ou Riverpod).
  - Appels API asynchrones vers Supabase.

- **Côté serveur (Supabase)** :
  - **Base de données** : Tables `items` (objets), `user_reports`, `comments`.
  - **Authentification** : Gestion des utilisateurs (email/password).
  - **Stockage** : Upload de photos d'objets.
  - **Realtime** : Mises à jour en direct des rapports et commentaires.

**Diagramme d'architecture** :

```
[Utilisateur (Actor)]
          ↓
    [LostAndFound (Flutter)]
          ├── Authentification
          ├── Rapport d'objet
          └── Visualisation des objets
                    ↓ (API REST + Realtime)
             [Supabase]
                    ├── DATABASE
                    │   ├── items
                    │   ├── user_reports
                    │   └── comments
                    └── AUTHENTICATION
                        └── users
```

---

## 🚀 Installation et configuration

### Prérequis

- [Flutter SDK](https://flutter.dev) (version 3.19+)
- [Supabase CLI](https://supabase.com/docs/guides/cli) ou compte Supabase gratuit
- Android Studio / Xcode pour émulation

### Étapes

1. **Cloner le repository** :
   ```bash
   git clone https://github.com/votre-username/lostandfound.git
   cd lostandfound
   ```

2. **Installer les dépendances** :
   ```bash
   flutter pub get
   ```

3. **Configurer Supabase** :
   - Créez un projet sur [supabase.com](https://supabase.com).
   - Copiez les clés `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans `lib/config/supabase_config.dart`.
   - Exécutez les migrations SQL (fournies dans `supabase/migrations/`).

4. **Lancer l'application** :
   ```bash
   flutter run
   ```

**Variables d'environnement** : Créez un fichier `.env` à la racine (non tracké par Git) :
```
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-anon-key
```

---

## 📱 Utilisation

1. **Inscription/Connexion** : Via email.
2. **Signaler un objet** : Allez dans "Nouveau rapport" > Remplissez les champs.
3. **Explorer** : Filtrez et commentez les objets.
4. **Statistiques** : Consultez le dashboard pour des insights.

**Astuce** : Activez les notifications push pour être alerté des nouveaux rapports.

---

## 🔮 Perspectives d'amélioration

LostAndFound est en phase de prototypage. Voici les évolutions prévues :

- **UI/UX avancée** : Thèmes sombres, animations fluides, accessibilité.
- **Suppression d'objets** : Marquer comme "récupéré".
- **Profils utilisateurs** : Affichage des contacts (nom, téléphone).
- **Géolocalisation** : Intégration Google Maps pour les lieux.
- **Notifications push** : Ciblées par zone géographique (Firebase Cloud Messaging).
- **Chat en direct** : Intégration Supabase Realtime ou Stream Chat.
- **Multilingue** : Support arabe/français/anglais.
- **Admin panel** : Pour modération (web avec Next.js).

---

## 👤 Auteur

**SAWADOGO S. Abdel**  
*Étudiant en Computer Engineering*  
**Université Hassan 1er**  
**Faculté des Sciences et Techniques de Settat**  
**Module : Programmation Mobile** (Semestre 4, 2024-2025)  
**Encadrant** : Mr. Toufik

**Merci d'avoir consulté LostAndFound !**  
N'hésitez pas à contribuer, forker ou signaler des bugs. 🌟

*Made with ❤️ by Abdel*

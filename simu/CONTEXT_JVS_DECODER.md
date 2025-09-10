# Contexte - Décodeur de trames JVS

## Vue d'ensemble

Le décodeur de trames JVS est un outil HTML/JavaScript qui permet d'analyser des fichiers de capture JVS et de décoder les échanges entre le host et les périphériques JVS (JAMMA Video Standard).

## Fichiers

- **jvs_decoder.html** : Décodeur principal (HTML + CSS + JavaScript intégré)
- **Fichiers de référence** :
  - `src/fpga/analogizer/jvs_controller.sv` : Implémentation FPGA du protocole JVS
  - `src/fpga/analogizer/jvs_node_info_pkg.sv` : Structure des informations de nœuds JVS
  - `simu/jvs_capture/naomi_tekken6_io_board_2.jvs` : Fichier de capture d'exemple

## Fonctionnalités principales

### 1. Parsing des trames JVS
- **Format d'entrée** : Fichiers .jvs avec trames en hexadécimal (une par ligne)
- **Parsing byte-par-byte** utilisant SYNC_BYTE (0xE0) comme délimiteur
- **Support des séquences d'escape** : D0 DF → E0, D0 CF → D0
- **Vérification de checksum** : Somme simple des bytes (hors SYNC_BYTE)

### 2. Décodage multi-commandes
- **Requêtes multi-commandes** : Une trame JVS peut contenir plusieurs commandes
- **Réponses multi-résultats** : Chaque commande a sa réponse préfixée par un report byte
- **Association commande-résultat** : Respect de l'ordre des commandes dans la réponse

### 3. Types de commandes supportées

#### Commandes de contrôle
- **RESET** (0xF0) : Réinitialisation du système
- **SETADDR** (0xF1) : Attribution d'adresse au périphérique
- **COMMCHG** (0xF2) : Changement de communication

#### Commandes d'identification
- **IOIDENT** (0x10) : Identification du périphérique (nom)
- **CMDREV** (0x11) : Version des commandes supportées
- **JVSREV** (0x12) : Version du protocole JVS
- **COMMVER** (0x13) : Version de communication
- **FEATCHK** (0x14) : Vérification des capacités (Feature Check)
- **MAINID** (0x15) : ID principal

#### Commandes d'entrée
- **SWINP** (0x20) : Lecture des entrées digitales (boutons)
- **COININP** (0x21) : Lecture des entrées monnaie
- **ANLINP** (0x22) : Lecture des entrées analogiques
- **ROTINP** (0x23) : Lecture des entrées rotatives
- **KEYINP** (0x24) : Lecture des entrées clavier
- **SCRPOSINP** (0x25) : Lecture position écran (touch/gun)
- **MISCSWINP** (0x26) : Lecture entrées diverses

#### Commandes de sortie
- **OUTPUT1/2/3** (0x32/0x37/0x38) : Sorties digitales
- **ANLOUT** (0x33) : Sorties analogiques
- **CHAROUT** (0x34) : Affichage caractères

### 4. Décodage spécialisé des données

#### SWINP (Entrées digitales)
- **System byte** : État du système (Test, Tilt1-3)
- **Données joueurs** : État des boutons par joueur
- **Format** : `System:[Test,Tilt1] J1:[B1,B3] J2:[-]`

#### COININP (Entrées monnaie)
- **Taille dynamique** : Basée sur les capacités du Feature Check
- **Format** : `Slot1:120 Slot2:0` (valeurs 16-bit par slot)

#### ANLINP (Entrées analogiques)
- **Format** : `CH1:1024 CH2:2048` (valeurs 16-bit par canal)

#### FEATCHK (Capacités)
- **Parsing complet** des blocs de fonctions
- **Affichage détaillé** : joueurs, boutons, canaux, etc.
- **Sauvegarde** des capacités par nœud JVS

### 5. Interface utilisateur

#### Navigation
- **Échanges requête/réponse** : Paires logiques au lieu de liste de trames
- **Contrôles** : Boutons + navigation clavier (←→, Espace, Home/End)
- **Lecture automatique** : Mode auto-play avec pause

#### Affichage
- **Multi-commandes** : Blocs séparés pour chaque commande
- **Multi-résultats** : Association claire commande → résultat
- **Données brutes** : Affichage hexadécimal avec highlight au survol
- **Décodage intelligent** : Interprétation selon le type de commande

#### Fonctionnalités visuelles
- **Survol interactif** : Highlight des bytes correspondants dans les données brutes
- **Thème sombre** : Interface optimisée pour l'analyse
- **Codes couleur** : Commandes (bleu), résultats (vert), erreurs (rouge)

### 6. Gestion des nœuds JVS
- **Détection automatique** des périphériques via SETADDR/IOIDENT
- **Sauvegarde des capacités** via Feature Check
- **Utilisation contexuelle** : Taille des données basée sur les capacités réelles

## Structure du protocole JVS

### Format de trame
```
SYNC_BYTE (E0) | DEST_ADDR | LENGTH | DATA... | CHECKSUM
```

### Types de réponse
- **STATUS_BYTE** : Succès global de la requête (0x01 = NORMAL)
- **REPORT_BYTE** : Succès individuel de chaque commande (0x01 = succès)

### Multi-commandes
```
Requête:  E0 01 08 20 02 02 21 02 22 08 7A
         (SWINP + COININP + ANLINP)

Réponse:  E0 00 1E 01 01 00 00 00 00 00 01 00 00 00 00 01 CA 00 BA...
         STATUS │ SWINP──────────────┘ COININP─────┘ ANLINP─────────...
```

## Utilisation

1. **Charger** un fichier .jvs
2. **Naviguer** dans les échanges avec les boutons ou le clavier
3. **Analyser** les commandes et réponses décodées
4. **Survol** des résultats pour voir les bytes correspondants
5. **Inspecter** les informations des nœuds JVS

## Debugging

### Logs console
- Parsing des multi-commandes
- Calcul des tailles de données
- Association commande-résultat
- Recherche des nœuds JVS

### Vérifications
- Checksums valides/invalides
- Séquences d'escape correctes
- Trames malformées
- Données manquantes

## Limitations connues

- **Feature Check requis** : Certaines tailles de données dépendent des capacités
- **Ordre strict** : Les réponses doivent respecter l'ordre des commandes
- **Périphérique unique** : Support limité aux captures mono-device

## Extensions possibles

- Support multi-périphériques
- Export des données décodées
- Analyse statistique des échanges
- Visualisation graphique des entrées analogiques
- Détection des patterns d'utilisation
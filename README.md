# Lab SQL Server — Mercato

Environnement Docker pour s'entraîner sur SQL Server : création de bases,
tables, utilisateurs, sauvegardes, vues et un job SQL Server Agent
planifié (sauvegarde → réindexation → purge).

## Prérequis

- Docker Desktop
- Git Bash (Windows) ou tout shell compatible `make`
- `make` installé (via chocolatey sur Windows : `choco install make`)

## Installation

1. Cloner le repo :
   ```bash
   git clone <url-du-repo>
   cd cours
   ```

2. Créer le fichier `.env` à partir de l'exemple, puis changer le mot de
   passe :
   ```bash
   cp .env.example .env
   ```

3. Démarrer le conteneur :
   ```bash
   make up
   ```

4. Vérifier que SQL Server répond :
   ```bash
   make ping
   ```

## Utilisation

Toutes les commandes disponibles :
```bash
make help
```

### Initialiser les bases

```bash
make create-boutique-db   # base Boutique
make create-mercato-db    # base Mercato
make create.table         # tables Player / PlayerCurrentClub
make populate.table       # peuple 10 clubs + 110 joueurs
```

### Consulter les données

```bash
make list_tables    # liste les tables de Mercato
make pop.players     # liste les joueurs avec leur club
make view            # crée la vue vw_PlayerPublic
```

### Utilisateurs restreints

```bash
make create.users    # crée boris et caroline (lecture seule)
```

### Sauvegarde

```bash
make backup           # sauvegarde manuelle horodatée dans ./backups
```

### Job planifié (SQL Server Agent)

Pipeline automatisé : sauvegarde → réindexation → purge des sauvegardes
de plus de 7 jours, planifié chaque jour à 14h00.

```bash
make create.job    # crée/recrée le job
make test.job       # le déclenche manuellement
make history         # affiche l'historique d'exécution
make delete.job     # supprime le job
```

## Structure du projet

```
.
├── compose.yaml          # définition du service SQL Server
├── Makefile               # toutes les commandes du lab
├── .env.example            # modèle de configuration (mot de passe à changer)
├── backups/                 # sauvegardes générées (non versionnées)
└── sql/
    ├── 00_init_boutique.sql   # création base Boutique
    ├── 01_init_mercato.sql    # création base Mercato
    ├── 02_create_tables.sql   # tables Player / PlayerCurrentClub
    ├── 03_populate.sql        # peuplement clubs + joueurs
    ├── 04_users.sql           # utilisateurs restreints
    ├── 05_backup.sql          # sauvegarde manuelle horodatée
    ├── 06_view.sql            # vue vw_PlayerPublic
    ├── 07_list_players.sql    # requête liste joueurs/clubs
    └── 08_agent_job.sql       # job SQL Server Agent (pipeline nocturne)
```

## Notes

- SQL Server Agent sous Linux ne supporte que les étapes en T-SQL
  (pas de CmdExec/PowerShell/SSIS).
- Le fichier `.env` contient un mot de passe et n'est jamais commité
  (voir `.gitignore`).

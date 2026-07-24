SHELL := /bin/bash
INFO_COLOR := \033[36;1m
NO_COLOR := \033[0m
COMPOSE ?= docker compose up
STOP ?= docker compose stop
SQLCMD = MSYS_NO_PATHCONV=1 docker compose exec -T sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$(shell cat .env | grep MSSQL_SA_PASSWORD | cut -f2 -d '=')" -C -b
.PHONY: help activate up stop logs sqlcmd test ping down refresh \
        create-boutique-db create-mercato-db create.table populate.table \
        create.users list_tables view pop.players backup create.job \
        test.job history delete.job db_list check-client

help: ## shows this
	@echo -e "\n\033[34;1m======== MENU ===========$(NO_COLOR)\n"
	@grep -E "^[a-zA-Z_.-]+: ##.*$$" $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS=": ##"}{printf "$(INFO_COLOR)%s$(NO_COLOR)%s\n", $$1, $$2}'
	@echo -e "\n\033[34;1m======== MENU ===========$(NO_COLOR)\n"

activate: ## run Docker
	@powershell -Command "Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"

up: ## creates the container
	@$(COMPOSE) -d

stop: ## stop the container
	@$(STOP)

logs: ## affiche les logs du conteneur
	@docker container logs -f lab-sqlserver

sqlcmd: ## ouvre une session sqlcmd
	@$(SQLCMD)

test: ## teste la connexion et affiche la version
	@$(SQLCMD) -Q "SELECT @@VERSION;"

ping: ## vérifie que le serveur répond
	@$(SQLCMD) -Q "SELECT 1;"

down: ## supprime les conteneurs et volumes
	@docker compose down -v

refresh: stop down up ## redémarre l'environnement complet
	sleep 2
	$(MAKE) ping

create-boutique-db: ## crée la base Boutique
	@$(SQLCMD) -i /sql/00_init_boutique.sql

create-mercato-db: ## crée la base Mercato
	@$(SQLCMD) -i /sql/01_init_mercato.sql

create.table: ## crée les tables Player/PlayerCurrentClub
	@$(SQLCMD) -i /sql/02_create_tables.sql

populate.table: ## peuple les tables avec clubs et joueurs
	@$(SQLCMD) -i /sql/03_populate.sql

create.users: ## crée les utilisateurs boris et caroline (droits restreints)
	@$(SQLCMD) -i /sql/04_users.sql

backup: ## sauvegarde complète de la base Mercato (nom horodaté)
	@$(SQLCMD) -i /sql/05_backup.sql

view: ## crée la vue vw_PlayerPublic
	@$(SQLCMD) -i /sql/06_view.sql

pop.players: ## liste les joueurs avec leur club
	@$(SQLCMD) -i /sql/07_list_players.sql

create.job: ## crée le job Maintenance_Mercato planifié à 14h
	@$(SQLCMD) -i /sql/08_agent_job.sql

test.job: ## lance le job manuellement
	@$(SQLCMD) -Q "EXEC msdb.dbo.sp_start_job @job_name = N'Maintenance_Mercato'; WAITFOR DELAY '00:00:06';"

history: ## affiche l'historique détaillé du job
	@$(SQLCMD) -Q "SELECT h.step_id, h.step_name, h.run_status, h.run_date, h.run_time, h.message FROM msdb.dbo.sysjobhistory h JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id WHERE j.name = N'Maintenance_Mercato' ORDER BY h.run_date DESC, h.run_time DESC;"

delete.job: ## supprime le job Maintenance_Mercato
	@$(SQLCMD) -Q "EXEC msdb.dbo.sp_delete_job @job_name = N'Maintenance_Mercato';"

list_tables: ## liste les tables de la base Mercato
	@$(SQLCMD) -d Mercato -Q "SELECT name FROM sys.tables;"

db_list: ## liste les bases de données
	@$(SQLCMD) -Q 'SELECT name FROM sys.databases;'

check-client: ## vérifie que la table Client existe (Boutique)
	@$(SQLCMD) -d Boutique -Q "IF OBJECT_ID('dbo.Client', 'U') IS NOT NULL PRINT 'La table Client existe.'; ELSE PRINT 'La table Client n''existe PAS.';"

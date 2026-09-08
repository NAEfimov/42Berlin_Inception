NAME = inception
COMPOSE = docker compose -f ./srcs/docker-compose.yml --env-file srcs/.env
DATA_DIR = $(HOME)/data

all: setup
	@printf "Launch configuration ${name}...\n"
	@$(COMPOSE) up -d

build: setup
	@printf "Building configuration ${name}...\n"
	@$(COMPOSE) up -d --build

down:
	@printf "Stopping configuration ${name}...\n"
	@$(COMPOSE) down

re: down
	@printf "Rebuild configuration ${name}...\n"
	@$(COMPOSE) up -d --build

clean:
	@printf "Cleaning configuration $(NAME)...\n"
	@$(COMPOSE) down --rmi local

fclean:
	@printf "Total clean of configuration $(NAME)...\n"
	@$(COMPOSE) down -v --rmi all
	@sudo rm -rf $(DATA_DIR)/wordpress/*
	@sudo rm -rf $(DATA_DIR)/mariadb/*

setup:
	@mkdir -p $(DATA_DIR)
	@mkdir -p $(DATA_DIR)/mariadb
	@mkdir -p $(DATA_DIR)/wordpress

.PHONY	: all build down re clean fclean

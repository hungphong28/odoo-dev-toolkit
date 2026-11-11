# Git release workflow

Authoritative source: the project-approved ByeBeo GIT_WORKFLOW.md.

main    = production
pilot   = approved release staging
dev     = shared development integration
task/*  = individual features from origin/main
fix/*   = normal fixes from origin/main
hotfix/* = urgent production fixes from origin/main

Normal release:

task -> dev (DEV PASS)
task -> pilot (review / Pilot PASS)
pilot -> main (approval / PROD PASS)

Never merge entire dev into pilot or main.

Main and pilot are protected and require Pull Requests.
Do not directly modify runtime worktrees to develop features.
Do not commit secrets, filestores, database dumps or backups.

Hotfix: review PR to main, deploy, then integrate the same
hotfix branch into pilot and dev.

The full project-approved GIT_WORKFLOW.md takes precedence.

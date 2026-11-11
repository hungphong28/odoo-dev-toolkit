# Odoo DEV Toolkit

Version 0.1.0

Reusable Git workspace management for Odoo Community projects
running on one or many DEV servers.

## Architecture

- LOCAL: independent coding worktree
- DEV: integration runtime (`dev`)
- PILOT: separately tested release (`pilot`)
- PROD: approved release (`main`)

LOCAL can be on the same VPS as DEV. The running Odoo and
Bridge must never mount LOCAL as their active source.

## Install

Clone the repository using an authorized GitHub SSH identity,
then run:

    sudo bash install.sh

## Commands

    max-workspace discover
    max-workspace init-all
    max-workspace init /opt/project-dev/source
    max-workspace check
    max-workspace task /opt/workspaces/project/project task/example

The discovery command handles common `/opt/*-dev` and
`/opt/*-staging` layouts. Other Git roots can be passed to init.

## Git workflow

For projects adopting the approved ByeBeo workflow:

1. Create task/fix from latest origin/main in LOCAL.
2. Develop, validate, commit and push task/fix.
3. Independently integrate into dev for DEV testing.
4. Independently review and integrate approved task into pilot.
5. Record Pilot PASS and receive release approval.
6. PR pilot into main.
7. Backup, deploy main and record PROD PASS.

Never merge all dev into pilot or main.
Main and pilot use protected Pull Requests.

Critical production hotfixes use hotfix/* from main,
with review and subsequent back-integration into pilot and dev.

## Safety

This toolkit does not change runtime branches, Docker, Odoo,
PostgreSQL, Zalo sessions, production systems or remote
application repositories.

It does not automatically deploy or merge code.

No PASS status is claimed without verification.

# Snapshot Module for LOCAL-LLM-Stack

This module provides a simple way to create snapshots (backups) of your LOCAL-LLM-Stack installation.

## Usage

To create a snapshot, simply run:

```bash
./modules/snapshot/create_snapshot.sh
```

**Note:** The script requires sudo privileges to access files owned by Docker containers. You will be prompted for your sudo password during execution.

This will create a compressed tar.gz archive of all data and folders in the LOCAL-LLM-Stack directory and save it as `data/snapshots/snapshot-YYYY-MM-DD.tar.gz` (where YYYY-MM-DD is the current date).

## What Gets Backed Up

The snapshot includes all configuration files, environment files, and data directories, with the following exceptions:

- The `data/snapshots` directory itself (to avoid recursion)
- The `data/models` directory (to avoid backing up large model files that can be re-downloaded)

## Restoring from a Snapshot

To restore from a snapshot, you can use the following steps:

1. Stop all running containers:
   ```bash
   docker-compose down
   ```

2. Extract the files from the snapshot archive to the main directory:
   ```bash
   tar -xzf data/snapshots/snapshot-YYYY-MM-DD.tar.gz -C ./
   ```
   (Replace YYYY-MM-DD with the date of the snapshot you want to restore)

3. Restart the containers:
   ```bash
   docker-compose up -d
   ```

## Automating Snapshots

You can automate the snapshot process by adding a cron job. For example, to create a daily snapshot at 2 AM:

```bash
# Edit the crontab
crontab -e

# Add the following line
0 2 * * * /home/skr/LOCAL-LLM-Stack/modules/snapshot/create_snapshot.sh >> /home/skr/LOCAL-LLM-Stack/data/snapshots/snapshot.log 2>&1
```

This will run the snapshot script every day at 2 AM and log the output to `data/snapshots/snapshot.log`.
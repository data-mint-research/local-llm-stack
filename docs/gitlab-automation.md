# GitLab Automation

This guide explains how to use the provided scripts to automatically transfer the LOCAL-LLM-Stack project to GitLab.

## Available Scripts

There are two scripts for automating the GitLab setup:

1. **setup-gitlab.sh**: Interactive script with user prompts
2. **auto-gitlab.sh**: Fully automated script without user interaction

## Prerequisites

- Git is installed
- GitLab access is configured in VS Code
- You have permissions to create a repository and push code

## Interactive Setup (setup-gitlab.sh)

The interactive script guides you through the process and asks for confirmation at important steps:

1. Make the script executable:

```bash
chmod +x setup-gitlab.sh
```

2. Run the script:

```bash
./setup-gitlab.sh
```

3. Follow the instructions:
   - Enter the GitLab repository URL
   - Confirm the commit
   - Confirm the push

## Automated Setup (auto-gitlab.sh)

The automated script performs all steps without user interaction:

1. Make the script executable:

```bash
chmod +x auto-gitlab.sh
```

2. Run the script with the GitLab repository URL as a parameter:

```bash
./auto-gitlab.sh https://gitlab.com/your-username/local-llm-stack.git
```

Or use the default URL (https://gitlab.com/mint-research/local-llm-stack.git):

```bash
./auto-gitlab.sh
```

## What the Scripts Do

Both scripts perform the following steps:

1. Initialize a Git repository (if it doesn't exist already)
2. Configure the remote repository (origin)
3. Add all files to the staging area (except those in .gitignore)
4. Create an initial commit
5. Rename the branch to "main"
6. Push the code to GitLab
7. Display a summary of the available documentation

## Troubleshooting

### Authentication Issues

If you have problems pushing, make sure your Git credentials are correctly configured:

```bash
git config --global credential.helper store
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

Then try to authenticate manually:

```bash
git push -u origin main
```

### Repository Already Exists

If the repository already exists on GitLab and you want to overwrite it:

```bash
git push -f -u origin main
```

Be careful with this command as it overwrites existing data.

### Reset Local Repository

If you want to start over:

```bash
rm -rf .git
./auto-gitlab.sh
```

## After Pushing

After successfully pushing, you can:

1. Open the repository on GitLab and verify that all files were transferred correctly
2. Configure CI/CD settings
3. Protect branches
4. Set up access permissions for team members

## Automation in CI/CD

You can also use the auto-gitlab.sh script in a CI/CD pipeline to automatically push to another GitLab repository:

```yaml
deploy:
  script:
    - chmod +x auto-gitlab.sh
    - ./auto-gitlab.sh https://gitlab.com/target-repository.git
```

## Further Information

For more detailed information about GitLab setup, see [GitLab Setup Guide](gitlab-setup.md).
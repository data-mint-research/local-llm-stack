# GitLab Repository Setup

This guide walks you through the process of creating a private GitLab repository and pushing the LOCAL-LLM-Stack project.

## Creating a New GitLab Repository

1. Sign in to GitLab (https://gitlab.com/).

2. Click on the "New project" button.

3. Select "Create blank project".

4. Enter the following information:
   - **Project name**: LOCAL-LLM-Stack
   - **Project slug**: local-llm-stack
   - **Visibility Level**: Private
   - **Initialize repository with a README**: No (uncheck)

5. Click "Create project".

## Initializing and Pushing the Local Repository

1. Open a terminal and navigate to the project directory:

```bash
cd /path/to/LOCAL-LLM-Stack
```

2. Initialize a Git repository if not already done:

```bash
git init
```

3. Add the remote URL (replace `your-username` with your GitLab username):

```bash
git remote add origin https://gitlab.com/your-username/local-llm-stack.git
```

4. Ensure the `.gitignore` file is properly set up to exclude data directories and sensitive configuration files:

```bash
cat .gitignore
```

The output should include data directories and configuration files with secrets.

5. Stop the stack if it's running to ensure no processes are accessing the files:

```bash
./llm stop
```

6. Add all files that are not listed in `.gitignore`:

```bash
git add .
```

7. Check which files have been added:

```bash
git status
```

Make sure no sensitive files or large data directories have been added.

8. Create the first commit:

```bash
git commit -m "Initial commit of LOCAL-LLM-Stack"
```

9. Push the code to the GitLab repository:

```bash
git push -u origin master
```

Or, if you want to name the main branch `main`:

```bash
git branch -M main
git push -u origin main
```

## Verifying the Repository Structure

After pushing, you should see the following structure in your GitLab repository:

```
LOCAL-LLM-Stack/
├── .gitignore
├── LICENSE
├── README.md
├── config/
│   └── librechat/
├── core/
│   ├── docker-compose.debug.yml
│   └── docker-compose.yml
├── docs/
│   ├── README.md
│   ├── architecture.md
│   ├── getting-started.md
│   ├── gitlab-setup.md
│   ├── security.md
│   └── troubleshooting.md
├── lib/
│   ├── common.sh
│   ├── config.sh
│   ├── generate_secrets.sh
│   ├── update_librechat_secrets.sh
│   └── utils.sh
└── llm
```

The `data/` directories and sensitive configuration files should not be included in the repository.

## Cloning the Repository on a New System

To set up the project on a new system:

1. Clone the repository:

```bash
git clone https://gitlab.com/your-username/local-llm-stack.git
cd local-llm-stack
```

2. Make the management script executable:

```bash
chmod +x llm
```

3. Start the stack:

```bash
./llm start
```

The system will automatically:
- Create the required directories
- Generate secure secrets
- Download the Docker images
- Start the containers

## Collaboration Tips

1. **Use branches**: Create separate branches for new features or bug fixes:

```bash
git checkout -b feature/new-feature
```

2. **Pull Requests**: Use Pull Requests for code reviews and discussions.

3. **Issues**: Use GitLab Issues for tracking tasks and bugs.

4. **CI/CD**: Set up GitLab CI/CD to enable automatic testing and deployments.

## Common Issues

### Accidentally Pushed Sensitive Data

If you accidentally pushed sensitive data:

1. Remove the sensitive data from the repository:

```bash
git rm --cached config/.env
git commit -m "Remove sensitive data"
git push
```

2. Change all compromised secrets.

3. Update the `.gitignore` file to prevent similar issues in the future.

### Large Files

If you accidentally pushed large files:

1. Use Git LFS (Large File Storage) for large files:

```bash
git lfs install
git lfs track "*.bin"
git add .gitattributes
git commit -m "Configure Git LFS"
git push
```

2. Or remove the large files from the Git history:

```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/large/file" \
  --prune-empty --tag-name-filter cat -- --all
git push --force
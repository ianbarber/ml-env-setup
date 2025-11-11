# Setting Up Claude Code GitHub Integration

This guide walks you through setting up the Claude Code GitHub integration for automated code reviews on this repository.

## Official Claude GitHub App

The official Claude Code app provides automated security reviews and code assistance directly in pull requests.

### Installation Steps

1. **Install the Claude GitHub App**

   Visit: https://github.com/apps/claude

   Click "Install" and select the `ml-env-setup` repository.

2. **Add Anthropic API Key**

   a. Get your API key from: https://console.anthropic.com/

   b. Go to your repository settings:
      - Navigate to https://github.com/ianbarber/ml-env-setup/settings/secrets/actions
      - Click "New repository secret"
      - Name: `ANTHROPIC_API_KEY`
      - Value: Your Anthropic API key
      - Click "Add secret"

3. **Create GitHub Actions Workflow**

   The app will create a PR with a workflow file. Alternatively, create manually:

   Create `.github/workflows/claude.yml`:

   ```yaml
   name: Claude Code Review

   on:
     pull_request:
       types: [opened, synchronize, reopened]
     issue_comment:
       types: [created]

   permissions:
     contents: read
     pull-requests: write
     issues: write

   jobs:
     claude-review:
       runs-on: ubuntu-latest
       if: |
         github.event_name == 'pull_request' ||
         (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude'))

       steps:
         - name: Checkout code
           uses: actions/checkout@v4
           with:
             fetch-depth: 0

         - name: Claude Code Review
           uses: anthropics/claude-code-action@v1
           with:
             anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
             command: security-review
   ```

4. **Commit and Push the Workflow**

   ```bash
   git add .github/workflows/claude.yml
   git commit -m "Add Claude Code review workflow"
   git push
   ```

## Usage

### Automatic Reviews

Once set up, Claude will automatically review all pull requests for:
- Security vulnerabilities
- Code quality issues
- Potential bugs
- Best practice violations

### Manual Invocation

Mention `@claude` in PR comments or issues:

```
@claude review this PR
@claude check for security issues
@claude explain this code
@claude suggest improvements
```

### Security Review Command

Use the `/security-review` command in PR comments to trigger a focused security analysis.

## Alternative: Claude-Hub (Community)

For more advanced integration, consider Claude-Hub:

Repository: https://github.com/claude-did-this/claude-hub

Features:
- Webhook service connecting Claude Code to GitHub
- AI-powered code assistance in PRs and issues
- Repository analysis
- Technical questions via @mentions

### Setup

1. Visit: https://claude-did-this.com/claude-hub/overview
2. Follow the installation guide
3. Configure webhooks for your repository

## Verification

After setup:

1. Create a test PR
2. Check that Claude comments appear
3. Try mentioning `@claude` in a comment
4. Review the Actions tab for workflow runs

## Troubleshooting

### Claude Not Responding

- Verify ANTHROPIC_API_KEY is set correctly in secrets
- Check GitHub Actions permissions (Settings > Actions > General)
- Ensure the workflow file is in `.github/workflows/`
- Look at Actions tab for error logs

### Permission Issues

The workflow needs these permissions:
- `contents: read` - Read repository code
- `pull-requests: write` - Comment on PRs
- `issues: write` - Comment on issues

Update in Settings > Actions > General > Workflow permissions

### API Rate Limits

If hitting rate limits:
- Consider upgrading your Anthropic plan
- Adjust the workflow to run less frequently
- Use manual @mentions instead of automatic reviews

## Cost Considerations

- Each review uses Claude API credits
- Monitor usage in Anthropic console
- Set up budget alerts if needed
- Consider limiting to specific PR patterns

## Best Practices

1. **Start with Security Reviews**: Focus on security-critical PRs first
2. **Use @mentions for Complex Questions**: Manual invocation for detailed analysis
3. **Review Claude's Suggestions**: AI is a tool, not a replacement for human review
4. **Iterate on Prompts**: Refine your @claude questions for better responses
5. **Monitor Costs**: Keep track of API usage

## Resources

- **Claude Code Docs**: https://code.claude.com/docs
- **GitHub App**: https://github.com/apps/claude
- **Anthropic Console**: https://console.anthropic.com/
- **Claude-Hub**: https://github.com/claude-did-this/claude-hub
- **API Documentation**: https://docs.anthropic.com/

## Example Workflow

```
1. Developer creates PR
2. Claude automatically reviews (if workflow enabled)
3. Claude comments with findings
4. Developer can ask follow-up questions with @claude
5. Developer addresses issues
6. Merge when approved
```

## Advanced Configuration

### Custom Review Prompts

Modify the workflow to use custom prompts:

```yaml
- name: Claude Code Review
  uses: anthropics/claude-code-action@v1
  with:
    anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
    command: security-review
    prompt: |
      Focus on:
      1. GPU/CUDA code patterns
      2. Environment variable usage
      3. Path handling across platforms
      4. Shell script security
```

### Selective Reviews

Only review specific file types:

```yaml
on:
  pull_request:
    types: [opened, synchronize]
    paths:
      - '**.sh'
      - '**.py'
      - '**.md'
```

### Multiple Review Types

Run different reviews for different scenarios:

```yaml
jobs:
  security-review:
    if: contains(github.event.pull_request.labels.*.name, 'security')
    # ... security review steps

  code-quality:
    if: contains(github.event.pull_request.labels.*.name, 'enhancement')
    # ... code quality review steps
```

## Support

For issues with:
- **Claude Code**: Anthropic support or Claude Code GitHub discussions
- **GitHub Actions**: GitHub support
- **This Setup**: Open an issue in the ml-env-setup repository

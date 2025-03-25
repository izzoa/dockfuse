# Setting Up CI/CD Pipeline for DockFuse

This guide explains how to set up the Continuous Integration and Continuous Deployment (CI/CD) pipeline that automatically builds and pushes your Docker image to Docker Hub whenever changes are pushed to your GitHub repository.

## Prerequisites

1. A GitHub account with your DockFuse repository
2. A Docker Hub account
3. Docker Hub repository created (amizzo/dockfuse)

## Step 1: Create a Docker Hub Access Token

1. Log in to [Docker Hub](https://hub.docker.com/)
2. Click on your username in the top right corner and select "Account Settings"
3. Go to the "Security" tab
4. Click "New Access Token"
5. Provide a description (e.g., "GitHub Actions")
6. Select the appropriate permissions (at minimum, "Read & Write")
7. Click "Generate"
8. **IMPORTANT**: Copy the generated token immediately and store it securely. You won't be able to see it again.

## Step 2: Add Secrets to GitHub Repository

1. Go to your GitHub repository
2. Click on "Settings" tab
3. In the left sidebar, click on "Secrets and variables" then "Actions"
4. Click "New repository secret"
5. Add the following secrets:
   - Name: `DOCKERHUB_USERNAME`
   - Value: Your Docker Hub username (e.g., `amizzo`)
   - Click "Add secret"
6. Add another secret:
   - Name: `DOCKERHUB_TOKEN`
   - Value: The access token you generated in Step 1
   - Click "Add secret"

## Step 3: Setup GitHub Actions Workflow

The workflow file `.github/workflows/docker-build.yml` has already been created in your repository. This workflow:

- Runs when you push to the main/master branch or add version tags
- Builds your Docker image from the `src` directory for multiple architectures (AMD64 and ARM64)
- Pushes the image to Docker Hub with appropriate tags
- Updates the Docker Hub description from your `DOCKER_HUB_README.md` file

### Multi-Architecture Support

The workflow is configured to build Docker images for both ARM64 (Apple Silicon, Raspberry Pi) and AMD64 (x86-64) architectures. This means your image will work on:

- Traditional Intel/AMD servers and desktops
- Apple M1/M2 Macs
- ARM-based servers and devices
- Raspberry Pi and similar ARM devices

The multi-architecture support is implemented using:
- QEMU emulation for cross-platform builds
- Docker Buildx for multi-platform image creation
- Docker manifests to create a single, multi-architecture image

## Step 4: Triggering the Workflow

The CI/CD pipeline will be triggered automatically on:

1. **Pushes to main/master branch**: Updates the `latest` tag on Docker Hub
2. **Pushing a tag starting with 'v'**: Creates a version-specific tag (e.g., pushing tag `v1.2.0` creates Docker image tag `1.2.0`)
3. **Manual trigger**: You can also manually trigger a build from the "Actions" tab in GitHub

## Step 5: Verify Your Setup

1. Make a small change to a file in the `src` directory
2. Commit and push the change to your main or master branch
3. Go to the "Actions" tab in your GitHub repository to see the workflow running
4. Once complete, check your Docker Hub repository to verify the image was updated

## Additional Information

### Tagging

To create a version tag:

```bash
git tag v1.1.0  # Replace with your version
git push origin v1.1.0
```

This will trigger a build that creates the version tags: `1.1.0` and `1.1` in addition to the short commit SHA.

### Workflow Customization

You can modify the `.github/workflows/docker-build.yml` file to:

- Change when the workflow triggers
- Add additional build steps or tests
- Modify the tagging strategy
- Add notifications (e.g., Slack, email)

## Troubleshooting

If your workflow fails:

1. Check the workflow logs in the GitHub Actions tab
2. Verify your Docker Hub credentials are correct
3. Ensure your Docker Hub account has write access to the repository
4. Check that your Dockerfile builds successfully locally 
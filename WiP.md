# Work in Progress

## Step 1: Dockerfile

Created a multi-stage `Dockerfile` to build container images for the project's services. This approach optimizes image size and build times.

**Key Features:**
- **Common Base Image:** A `base` stage installs Python and all dependencies from `requirements.txt`.
- **Service-Specific Images:** Separate final stages for the `api` and `executor` services ensure the images are lightweight and secure.
- **Non-Root User:** A non-root user (`app`) is created and used for security best practices.

**Build Commands:**
- **API Service:** `docker build --target api -t drl-api:latest .`
- **Executor Service:** `docker build --target executor -t drl-executor:latest .`

## Step 2: Dependencies

Populated the `requirements.txt` file with a comprehensive list of Python libraries required for the project, based on the architecture described in `context.md`. The dependencies are grouped into the following categories:

- MLOps & Orchestration
- ML & Deep Reinforcement Learning
- API & Services
- Graph Database (Neo4j)
- Blockchain (Ethereum)
- Tooling & Code Quality
- Utilities
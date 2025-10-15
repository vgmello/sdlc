Help debug issues with the GitHub Actions runners.

1. Check if the runners are running with `docker-compose ps`
2. View the logs with `docker-compose logs -f`
3. Verify the .env file configuration
4. Check if runners are registered in GitHub repository settings (Settings → Actions → Runners)
5. Diagnose common issues:
   - Token authentication problems
   - Network connectivity issues
   - Container build failures
   - Runner registration failures
6. Provide solutions for identified issues

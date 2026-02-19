# Employee Onboarding Agent Fabric Demo (No License)

## Prerequisites
1. Docker & Docker Compose
2. Groq API key (console.groq.com)
3. PostgreSQL JDBC: Download `postgresql-42.7.3.jar` to each `mule-*/libs/`

## Setup
```bash
# Clone/create project
mkdir employee-onboarding-agent-demo && cd employee-onboarding-agent-demo

# Copy all files above
# Update .env with your groq.apiKey

# Init database
docker-compose up postgres -d
docker exec -i $(docker ps -qf "name=postgres") psql -U mule -d onboarding < init-db.sql
